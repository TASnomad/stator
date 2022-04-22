import "dart:io";

class ContentTypes {
  static final String binary = ContentType.binary.mimeType;
  static final String css = "text/css";
  static final String dart = "application/dart";
  static final String formUrlEncoded = "application/x-www-form-urlencoded";
  static final String js = "application/javascript";
  static const String json = "application/json";
  static final String html = ContentType.html.mimeType;
  static final String multipartFormData = "multipart/form-data";
  static final String text = ContentType.text.mimeType;
  static final String xml = "application/xml";

  static String? _default;
  static set defaultType(String contentType) => _default = contentType;
  static String get defaultType => _default ?? html;

  static Map<String, String> _extensionsMap = {};
  static Map<String, String> get extensions {
    if (_extensionsMap.isEmpty) {
      _extensionsMap = {
        "txt": text,
        "json": json,
        "htm": html,
        "html": html,
        "css": css,
        "js": js,
        "dart": dart,
        "png": "application/png",
        "gif": "application/gif",
        "jpg": "application/jpeg",
        "jpeg": "application/jpeg",
      };
    }
    return _extensionsMap;
  }

  static final List<String> binaryContentTypes = [ "image/jpeg", "image/gif", "image/png", "application/octet" ];

  static bool matches(String contentType, String withContentType) =>
    contentType.length > withContentType.length
      ? withContentType.startsWith(contentType)
      : contentType.startsWith(withContentType);

  static bool isBinary(String contentType) => binaryContentTypes.contains(contentType);

  static bool isJson(String contentType) => matches(contentType, json);
}
