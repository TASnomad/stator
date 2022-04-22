import "dart:async";
import "dart:io";

import "package:stator/stator.dart";

final List<String> httpMethods = const [
  "HEAD",
  "OPTIONS",
  "GET",
  "PUT",
  "PATCH",
  "POST",
  "DELETE"
];

/// A Dartt compatible request handler which can be either async
/// and gets passed the `HttpRequest`, it then eventually returns a `Future<HttpResponse>`
typedef RequestHandler = Future<HttpContext> Function(HttpContext ctx);

/// A handler type for anytime the `MatchHandler` or `other` parameter handler fails
typedef ErrorHandler = Future<HttpContext> Function(
    HttpContext ctx, Exception error);

/// A handler type for anytime a method is received that is not defined
typedef UnknownMethodHandler = Future<HttpContext> Function(
    HttpContext ctx, List<String> knownMethods);

/// A handler type for a router path which get passed the matched values
typedef MatchHandler = Future<HttpContext> Function(
    HttpContext ctx, Map<String, String> match);

/// A record of route paths and `MatchHandler`s which are called when a match is
/// found along with it's value
/// The route paths follow the path-to-regexp format with the addition of being able
/// to prefix a route with a method name and the `@` sign. For example a route only
/// accepting `GET` requests would look like: `GET@/`.
typedef Routes = Map<String, MatchHandler>;

/// Default Not found error
Future<HttpContext> defaultNotFoundError(HttpContext ctx) async {
  return ctx..send(status: HttpStatus.notFound);
}

/// Default error handler
Future<HttpContext> defaultErrorHandler(HttpContext ctx, error) async {
  return ctx
    ..sendText(error.toString(), status: HttpStatus.internalServerError);
}

/// Default unknown method handler for the router
Future<HttpContext> defaultUnknownMethodHandler(
    HttpContext ctx, List<String> knownMethods) async {
  return ctx
    ..head(HttpStatus.methodNotAllowed, "text/plain",
        {HttpHeaders.acceptHeader: knownMethods.join(", ")})
    ..send();
  // return ctx..headers.add(HttpHeaders.acceptHeader, knownMethods.join(", "))
  // ..send(status: HttpStatus.methodNotAllowed);
}

final RegExp methodRegex = RegExp("(?<=^(?:${httpMethods.join("|")}))@");
final urlRegExp = RegExp(
    r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");

RequestHandler router(Routes routes,
    {RequestHandler other = defaultNotFoundError,
    ErrorHandler error = defaultErrorHandler,
    UnknownMethodHandler unknwonMethod = defaultUnknownMethodHandler}) {
  Map<String, Map<String, MatchHandler>> internalRoutes = {};

  // Creating entries
  for (var routeEntry in routes.entries) {
    String route = routeEntry.key;
    MatchHandler handler = routeEntry.value;

    List<String> methodEntry = route.split(methodRegex);
    String methodOrPath = methodEntry.first;
    String path = methodEntry.last;

    // TODO(TASnomad): we should remove the assert operator when acessing map fields
    if (httpMethods.contains(path) || httpMethods.contains(methodOrPath)) {
      internalRoutes[path] = {};
      internalRoutes[path]![methodOrPath] = handler;
    } else {
      internalRoutes[methodOrPath] = {};
      internalRoutes[methodOrPath]!["any"] = handler;
    }
  }

  Future<HttpContext> mainRouterHandler(HttpContext ctx) {
    try {
      for (var internalRouteEntry in internalRoutes.entries) {
        String path = internalRouteEntry.key;
        var methods = internalRouteEntry.value;

        if (routeMatches(path, ctx.uri.toString())) {
          for (var methodEntry in methods.entries) {
            String method = methodEntry.key;
            MatchHandler handler = methodEntry.value;
            var params = pathMatcher(path, ctx.uri.toString()) ?? {};

            if (ctx.method == method) {
              return handler(ctx, params);
            }
            return methods.containsKey("any")
                ? methods["any"]!(ctx, params)
                : unknwonMethod(ctx, methods.keys.toList());
          }
        }
      }
    } on Exception catch (e) {
      return error(ctx, e);
    }
    return other(ctx);
  }

  return mainRouterHandler;
}

Future<dynamic> stator(HttpRequest req, RequestHandler fct) async {
  HttpContext ctx = HttpContext(req, req.response);
  HttpContext res = await fct(ctx);

  if (!res.closed) {
    await res.end();
  }
}
