import 'dart:async';
import "dart:io";

import 'package:stator/src/url_pattern.dart';

final List<String> httpMethods = const [ "HEAD", "OPTIONS", "GET", "PUT", "PATCH", "POST", "DELETE" ];

/// A Dartt compatible request handler which can be either async
/// and gets passed the `HttpRequest`, it then eventually returns a `Future<HttpResponse>`
typedef RequestHandler = Future<HttpResponse> Function(HttpRequest request);

/// A handler type for anytime the `MatchHandler` or `other` parameter handler fails
typedef ErrorHandler = Future<HttpResponse> Function(HttpRequest request, Exception error);

/// A handler type for anytime a method is received that is not defined
typedef UnknownMethodHandler = Future<HttpResponse> Function(HttpRequest request, List<String> knownMethods);

/// A handler type for a router path which get passed the matched values
typedef MatchHandler = Future<HttpResponse> Function(HttpRequest request, Map<String, String> match);

/// A record of route paths and `MatchHandler`s which are called when a match is
/// found along with it's value
/// The route paths follow the path-to-regexp format with the addition of being able
/// to prefix a route with a method name and the `@` sign. For example a route only
/// accepting `GET` requests would look like: `GET@/`.
typedef Routes = Map<String, MatchHandler>;

/// Default Not found error
Future<HttpResponse> defaultNotFoundError(HttpRequest request) async {
  request.response.statusCode = HttpStatus.notFound;
  request.response.contentLength = 0;

  await request.response.flush();
  // await request.response.close();

  return request.response;
}

/// Default error handler
Future<HttpResponse> defaultErrorHandler(HttpRequest request, Exception _error) async {
  request.response.statusCode = HttpStatus.internalServerError;
  request.response.contentLength = 0;

  await request.response.flush();
  // await request.response.close();

  return request.response;
}

/// Default unknown method handler for the router
Future<HttpResponse> defaultUnknownMethodHandler(HttpRequest request, List<String> knownMethods) async {
  request.response.headers.add("Accept", knownMethods.join(", "));
  request.response.statusCode = HttpStatus.methodNotAllowed;
  request.response.contentLength = 0;

  await request.response.flush();
  // await request.response.close();

  return request.response;
}

final RegExp methodRegex = RegExp("(?<=^(?:${httpMethods.join("|")}))@");
final urlRegExp = RegExp(r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");

RequestHandler router(Routes routes, {
  RequestHandler other = defaultNotFoundError,
  ErrorHandler error = defaultErrorHandler,
  UnknownMethodHandler unknwonMethod = defaultUnknownMethodHandler
  }) {
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

    Future<HttpResponse> mainRouterHandler(HttpRequest req) {
      try {
        for (var internalRouteEntry in internalRoutes.entries) {
          String path = internalRouteEntry.key;
          var methods = internalRouteEntry.value;

          var pattern = UrlPattern(path);
          bool patternRes = pattern.matches(req.uri.toString());

          if (patternRes) {
            for (var methodEntry in methods.entries) {
              String method = methodEntry.key;
              MatchHandler handler = methodEntry.value;
              List<String> res = pattern.parse(req.uri.toString());

              if (req.method == method) {
                Map<String, String> groups = { for (var v in res) v[0] : v[1] };
                return handler(req, groups);
              }

              if (methods.containsKey("any")) {
                Map<String, String> groups = { for (var v in res) v[0] : v[1] };
                return methods["any"]!(req, groups);
              } else {
                return unknwonMethod(req, methods.keys.toList());
              }
            }
          }
        }
      }
      on Exception catch(e) {
        return error(req, e);
      }
      return other(req);
    }
    return mainRouterHandler;
  }
