/// A single part in a multipart request.
///
/// Implementations may wrap bytes, files, or streams. No I/O is defined here.
abstract interface class RestMultipartPart {
  /// Form field name.
  String get name;

  /// Optional file name for file parts.
  String? get fileName;

  /// Optional MIME type.
  String? get contentType;

  /// Opaque part payload (bytes, string, or adapter-specific handle).
  Object get value;
}
