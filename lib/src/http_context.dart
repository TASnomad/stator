import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:stator/src/content_types.dart';

class HttpContext extends Stream<Uint8List> implements HttpRequest {
  HttpRequest req;
  HttpResponse res;

  final Map<String, String> _params = {};
  bool _closed = false;
  String? _contentType;
  String? _contentTypeOnly;

  HttpContext(this.req, this.res) {
    _params.addAll(req.uri.queryParameters);
    _contentType = req.headers[HttpHeaders.contentTypeHeader] != null
        ? req.headers[HttpHeaders.contentTypeHeader]![0]
        : null;
    res.done.then((_) => _closed = true, onError: (_) => _closed = true);
  }

  bool get closed => _closed;
  String? get contentType =>
      _contentType ??
      (req.headers[HttpHeaders.contentTypeHeader] != null
          ? req.headers[HttpHeaders.contentTypeHeader]![0]
          : null);

  String get responseContentType => _contentTypeOnly ?? "";

  set responseContentType(String? value) {
    if (value == null || value.isEmpty) return;
    res.headers.set(HttpHeaders.contentTypeHeader, value);
    _contentTypeOnly = (value).split(";")[0];
  }

  Map<String, String> get params => _params;

  Future<List<int>> readAsByte() {
    Completer<List<int>> ret = Completer();
    List<int> buf = List.filled(req.contentLength, 0, growable: false);

    req.listen(buf.addAll)
      ..onError(ret.completeError)
      ..onDone(() => ret.complete(buf));
    return ret.future;
  }

  Future<String> readAsText([Encoding encoding = utf8]) {
    Completer<String> ret = Completer();
    StringBuffer buf = StringBuffer();

    req
        .map<List<int>>((event) => event.toList())
        .transform(encoding.decoder)
        .listen(buf.write)
      ..onError(ret.completeError)
      ..onDone(() => ret.complete(buf.toString()));
    return ret.future;
  }

  Future<Object> readAsJson({Encoding encoding = utf8}) =>
      readAsText(encoding).then((raw) => json.decode(raw));

  Future<Object> readAsObject({Encoding encoding = utf8}) =>
      readAsText(encoding).then((txt) =>
          contentType == ContentType.json.mimeType ? json.encode(txt) : txt);

  // ignore: avoid_returning_this
  void write(Object value, {String? contentType}) {
    responseContentType = contentType;

    switch (_contentTypeOnly) {
      case ContentTypes.json:
        res.write(json.encode(value));
        break;
      default:
        bool isBin =
            value is List<int> || ContentTypes.isBinary(_contentTypeOnly!);
        res.write(isBin ? value : value.toString());
        break;
    }
  }

  // ignore: avoid_returning_this
  void writeString(String txt) {
    write(txt);
  }

  // ignore: avoid_returning_this
  void writeBytes(List<int> bytes) {
    write(bytes);
  }

  // ignore: avoid_returning_this
  void head([int? status, String? contentType, Map<String, String>? headers]) {
    if (status != null) {
      res.statusCode = status;
    }

    responseContentType = contentType;

    if (headers != null) {
      headers.forEach((key, value) => res.headers.set(key, value));
    }
  }

  void send({Object? value, String? contentType, int? status}) {
    head(status, contentType);
    if (value != null) {
      write(value);
    }
    end();
  }

  void sendJson(Object value, {int? status}) =>
      send(value: value, contentType: ContentTypes.json, status: status);

  void sendText(Object value, {int? status}) =>
      send(value: value, contentType: ContentTypes.text, status: status);

  void sendBytes(List<int> bytes, {int? status, String? contentType}) {
    head(status, contentType);
    writeBytes(bytes);
    end();
  }

  Future<dynamic> end() {
    if (_closed) {
      return Future(() => {});
    }
    _closed = true;
    return res.close();
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return req.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  // HttpRequest overrides
  @override
  Uri get uri => req.uri;

  @override
  Uri get requestedUri => req.requestedUri;

  @override
  String get method => req.method;

  @override
  HttpSession get session => req.session;

  @override
  HttpConnectionInfo? get connectionInfo => req.connectionInfo;

  @override
  X509Certificate? get certificate => req.certificate;

  @override
  List<Cookie> get cookies => req.cookies;

  @override
  HttpHeaders get headers => req.headers;

  @override
  bool get persistentConnection => req.persistentConnection;

  @override
  int get contentLength => req.contentLength;

  @override
  String get protocolVersion => req.protocolVersion;

  @override
  HttpResponse get response => req.response;
}
