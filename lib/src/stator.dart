import "dart:async";
import "dart:io";

import 'package:stator/src/http_context.dart';
import 'package:stator/src/router.dart';
import 'package:stator/src/utils.dart';

class StatorRouter {
  String? prefix;
  Routes routes;

  static final List<String> httpMethods = const ["HEAD", "OPTIONS", "GET", "PUT", "PATCH", "POST", "DELETE"];
  static final RegExp methodRegex = RegExp("(?<=^(?:${httpMethods.join("|")}))@");
  static final urlRegExp =
      RegExp(r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");

  StatorRouter({this.prefix, required this.routes});

  Map<String, Map<String, MatchHandler>> compile() {
    Map<String, Map<String, MatchHandler>> compiledRoutes = {};

    for (var entry in routes.entries) {
      String route = entry.key;
      MatchHandler handler = entry.value;

      List<String> method = route.split(methodRegex);
      String methodOrPath = method.first;
      String path = method.last;

      if (httpMethods.contains(path) || httpMethods.contains(methodOrPath)) {
        String compiledPath = (prefix != null) ? "$prefix$path" : path;
        compiledRoutes[compiledPath] = {methodOrPath: handler};
      } else {
        String compiledPath = (prefix != null) ? "$prefix$methodOrPath" : path;
        compiledRoutes[compiledPath] = {"any": handler};
      }
    }

    return compiledRoutes;
  }
}

class Stator {
  final List<String> httpMethods = const ["HEAD", "OPTIONS", "GET", "PUT", "PATCH", "POST", "DELETE"];

  /// Default Not found error
  static Future<HttpContext> defaultNotFoundError(HttpContext ctx) async {
    return ctx..send(status: HttpStatus.notFound);
  }

  /// Default error handler
  static Future<HttpContext> defaultErrorHandler(HttpContext ctx, error) async {
    return ctx..sendText(error.toString(), status: HttpStatus.internalServerError);
  }

  /// Default unknown method handler for the router
  static Future<HttpContext> defaultUnknownMethodHandler(HttpContext ctx, List<String> knownMethods) async {
    return ctx
      ..head(HttpStatus.methodNotAllowed, "text/plain", {HttpHeaders.acceptHeader: knownMethods.join(", ")})
      ..send();
  }

  /// Generate an useable HTTP entrypoint for all Stator routers
  static RequestHandler compile(
    List<StatorRouter> routers, {
    RequestHandler other = Stator.defaultNotFoundError,
    ErrorHandler error = Stator.defaultErrorHandler,
    UnknownMethodHandler unknwonMethod = Stator.defaultUnknownMethodHandler,
  }) {
    Map<String, Map<String, MatchHandler>> routes = {};

    for (StatorRouter r in routers) {
      routes.addAll(r.compile());
    }

    Future<HttpContext> httpEntryPoint(HttpContext ctx) {
      try {
        for (var compiledRoute in routes.entries) {
          String path = compiledRoute.key;
          var methods = compiledRoute.value;

          if (routeMatches(path, ctx.uri.toString())) {
            for (var methodEntry in methods.entries) {
              String method = methodEntry.key;
              MatchHandler handler = methodEntry.value;

              Map<String, String> params = pathMatcher(path, ctx.uri.toString()) ?? {};

              if (ctx.method == method) {
                return handler(ctx, params);
              }
              return methods.containsKey("any") ? methods["any"]!(ctx, params) : unknwonMethod(ctx, methods.keys.toList());
            }
          }
        }
      } on Exception catch (e) {
        return error(ctx, e);
      }
      return other(ctx);
    }

    return httpEntryPoint;
  }

  /// Minimal HTTP server entrypoint which can used with your HTTP server StreamSubscription
  /// Such as `await server.forEach((req) => Stator.run(req, router({})));`
  static Future<dynamic> run(HttpRequest req, RequestHandler fct) async {
    HttpContext ctx = HttpContext(req, req.response);
    HttpContext res = await fct(ctx);

    if (!res.closed) {
      await res.end();
    }
  }
}
