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

Future<HttpContext> supHandler(HttpContext ctx, Map<String, String> params) async {
  if (!params.containsKey("sup")) {
    return ctx..send(value: {"error": "Missing echo parameter"}, status: HttpStatus.badRequest);
  }
  return ctx..sendJson({"value": params["sup"]});
}

Future<void> main() async {
  Map<String, String> env = Platform.environment;
  int httpPort = env.containsKey("PORT") ? int.parse(env["PORT"]!) : 9000;
  HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, httpPort);

  unawaited(ProcessSignal.sigint.watch().first.then((_) async {
    print("Shutting down the server");
    await server.close();
  }));

  StatorRouter rootRouter = StatorRouter(routes: {
    "GET@/": test,
    "GET@/:echo": testEcho,
  });

  StatorRouter testRouter = StatorRouter(prefix: "/test", routes: {
    "GET@/:sup": supHandler,
  });

  RequestHandler entryPoint = Stator.compile([rootRouter, testRouter]);

  print("Server running on port ${server.port}");

  await server.forEach((req) => Stator.run(req, entryPoint));
}
