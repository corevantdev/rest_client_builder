import '../multipart/rest_multipart_body.dart';
import '../multipart/rest_multipart_part.dart';

/// Concrete multipart part.
class BasicMultipartPart implements RestMultipartPart {
  /// Creates a multipart part.
  const BasicMultipartPart({
    required this.name,
    required this.value,
    this.fileName,
    this.contentType,
  });

  @override
  final String name;

  @override
  final String? fileName;

  @override
  final String? contentType;

  @override
  final Object value;
}

/// Concrete multipart body.
class BasicMultipartBody implements RestMultipartBody {
  /// Creates a multipart body.
  const BasicMultipartBody({
    required this.parts,
    this.boundary,
  });

  @override
  final List<RestMultipartPart> parts;

  @override
  final String? boundary;
}
