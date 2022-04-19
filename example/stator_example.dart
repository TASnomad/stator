import "dart:convert";
import "dart:io";

import "package:stator/stator.dart";

Future<HttpResponse> test(HttpRequest req, Map<String, String> params) async {
  req.response.write(jsonEncode({ "test": "hello" }));
  req.headers.set(HttpHeaders.contentTypeHeader, ContentType.json);
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

  Routes routes = {
    "GET@/": test,
  };

  print("Server running on port 8080");
  await server.forEach((request) async {
    HttpResponse res = await router(routes)(request);

    await res.flush();
    await res.close();
  });
}
