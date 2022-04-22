import "package:stator/stator.dart";
import "package:test/test.dart";

void main() {
  group("Utils: patchMatcher", () {
    setUp(() {
      // Additional setup goes here.
    });

    test("Simple route matches", () {
      expect(pathMatcher("/test", "/test"), equals({}),
          reason: "matches exact path");
      expect(pathMatcher("/test/:id", "/test/42"), equals({"id": "42"}),
          reason: "matches path with route parameter");
    });
  });
}
