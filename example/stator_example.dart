import 'dart:async';
import "dart:convert";
import "dart:io";

import "package:stator/stator.dart";

Future<HttpResponse> test(HttpRequest req, Map<String, String> params) async {
  String body = jsonEncode({ "test": "hello" });
  req.response.headers.add(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);
  req.response.headers.add(HttpHeaders.contentLengthHeader, body.length);
  req.response.write(body);
  return req.response;
}


Future<HttpResponse> testEcho(HttpRequest req, Map<String, String> params) async {
  print(params);
  req.response.write(jsonEncode({ "text": "hello" }));
  await req.response.close();
  return req.response;
}

Future<void> main() async {
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);

  unawaited(ProcessSignal.sigint.watch().first.then((_) async {
    print("Shutting down the server");
    await server.close();
  }));

  Routes routes = {
    "/": test,
  };

  RequestHandler engine = router(routes);

  print("Server running on port ${server.port}");
  await server.forEach((request) async {
    HttpResponse res = await engine(request);

    await res.flush();
    await res.close();
  });
}
