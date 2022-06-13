import "dart:async";

import "package:stator/stator.dart";

/// A Dartt compatible request handler which can be either async
/// and gets passed the `HttpRequest`, it then eventually returns a `Future<HttpResponse>`
typedef RequestHandler = Future<HttpContext> Function(HttpContext ctx);

/// A handler type for anytime the `MatchHandler` or `other` parameter handler fails
typedef ErrorHandler = Future<HttpContext> Function(HttpContext ctx, Exception error);

/// A handler type for anytime a method is received that is not defined
typedef UnknownMethodHandler = Future<HttpContext> Function(HttpContext ctx, List<String> knownMethods);

/// A handler type for a router path which get passed the matched values
typedef MatchHandler = Future<HttpContext> Function(HttpContext ctx, Map<String, String> match);

/// A record of route paths and `MatchHandler`s which are called when a match is
/// found along with it's value
/// The route paths follow the path-to-regexp format with the addition of being able
/// to prefix a route with a method name and the `@` sign. For example a route only
/// accepting `GET` requests would look like: `GET@/`.
typedef Routes = Map<String, MatchHandler>;
