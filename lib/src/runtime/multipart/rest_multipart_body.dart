import 'rest_multipart_part.dart';

/// Multipart request body composed of [parts].
///
/// Used when [RestBodyType.multipart] is selected. No HTTP is performed here.
abstract interface class RestMultipartBody {
  /// Ordered multipart parts.
  List<RestMultipartPart> get parts;

  /// Optional explicit multipart boundary. Adapters may generate one.
  String? get boundary;
}
