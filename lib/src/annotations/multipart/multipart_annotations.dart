import 'package:meta/meta_meta.dart';

/// Marks a method as a `multipart/form-data` request.
@Target({TargetKind.method})
class Multipart {
  /// Creates a multipart annotation.
  const Multipart();
}

/// Binds a method parameter to a multipart form part.
@Target({TargetKind.parameter})
class Part {
  /// Creates a part annotation.
  const Part({
    this.name,
    this.fileName,
    this.contentType,
  });

  /// Form field name. Defaults to the Dart parameter name when `null`.
  final String? name;

  /// Optional file name when the part is a file.
  final String? fileName;

  /// Optional MIME type for the part.
  final String? contentType;
}

/// Binds a `Map` parameter as multiple multipart parts.
@Target({TargetKind.parameter})
class PartMap {
  /// Creates a part-map annotation.
  const PartMap();
}
