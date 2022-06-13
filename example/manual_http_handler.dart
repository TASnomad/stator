import 'dart:async';
import "dart:io";

import "package:stator/stator.dart";

Future<HttpContext> test(HttpContext ctx, Map<String, String> params) async {
  return ctx..sendJson({"test": "hello"});
}

Future<HttpContext> testEcho(HttpContext ctx, Map<String, String> params) async {
  if (!params.containsKey("echo")) {
    return ctx..send(value: {"error": "Missing echo parameter"}, status: HttpStatus.badRequest);
  }
  return ctx..sendJson({"value": params["echo"]});
}

Future<void> main() async {
  Map<String, String> env = Platform.environment;
  int httpPort = env.containsKey("PORT") ? int.parse(env["PORT"]!) : 9000;
  HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, httpPort);

  unawaited(ProcessSignal.sigint.watch().first.then((_) async {
    print("Shutting down the server");
    await server.close();
  }));

  StatorRouter routes = StatorRouter(routes: {
    "GET@/": test,
    "GET@/hello/:echo": testEcho,
  });

  RequestHandler engine = Stator.compile([routes]);

  print("Server running on port ${server.port}");

  await server.forEach((request) async {
    HttpContext ctx = HttpContext(request, request.response);
    HttpContext res = await engine(ctx);

    if (!res.closed) {
      await res.end();
    }
  });
}
