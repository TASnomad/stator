Map<String, String>? pathMatcher(String route, String matchesPath) {
  Map<String, String> params = {};

  if (route == matchesPath) return params;
  List<String> pathChunks = matchesPath.split("/");
  List<String> routeChunks = route.split("/");

  if (pathChunks.length == routeChunks.length) {
    for (int i = 0; i < pathChunks.length; i++) {
      String p = pathChunks[i];
      String r = routeChunks[i];

      if (p == r) continue;
      if (r.startsWith(":")) {
        params[r.substring(1)] = p;
        continue;
      }
      return null;
    }
    return params;
  }
  return null;
}

bool routeMatches(String route, String uri) => pathMatcher(route, uri) != null;
