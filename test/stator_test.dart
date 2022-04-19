import "dart:convert";
import "dart:io";

import "package:stator/stator.dart";
import "package:test/test.dart";

Future<HttpResponse> dummyHandler(HttpRequest req, Map<String, String> params) async {
  req.response.write(jsonEncode({ "success": true }));
  await req.response.close();
  return req.response;
}

void main() {
  group('A group of tests', () {
    final Routes routes = { "GET@/": dummyHandler };
    final RequestHandler handler = router(routes);

    setUp(() {
      // Additional setup goes here.
    });

    test("Handle registered route", () {
    });
  });
}
