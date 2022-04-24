import "package:stator/stator.dart";
import "package:test/test.dart";

void main() {
  group("StatorRouter", () {
    setUp(() {});

    test("Compile a single router without prefix, with a valid router", () {
      StatorRouter r = StatorRouter(routes: {
        "GET@/": (ctx, _) => Future(() => ctx),
      });

      var routes = r.compile();
      expect(routes.length, equals(1), reason: "Should only have one route");
      expect(routes.entries.first.key, equals("/"), reason: "The HTTP route equals '/'");
    });

    test("Compile a single router without prefix, with an invalid router", () {
      StatorRouter r = StatorRouter(routes: {
        "GET/@": (ctx, _) => Future(() => ctx),
      });

      var routes = r.compile();
      expect(routes.length, equals(1), reason: "Should only have one route");
      expect(routes.entries.first.key, equals("GET/@"), reason: "The HTTP route equals 'GET/@'");
    });

    test("Compile multiple routers", () {
      Map<String, Map<String, MatchHandler>> routes = {};

      var routers = [
        StatorRouter(routes: {
          "GET/@": (ctx, _) => Future(() => ctx),
        }),
        StatorRouter(prefix: "/test", routes: {
          "GET/@": (ctx, _) => Future(() => ctx),
        }),
      ];

      for (var entry in routers) {
        routes.addAll(entry.compile());
      }

      expect(routes.length, equals(2), reason: "Should only have 2 routes");
    });
  });
}
