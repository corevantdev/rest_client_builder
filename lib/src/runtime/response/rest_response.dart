import '../request/rest_request.dart';

/// Immutable view of an HTTP response.
///
/// Produced by a future [RestHttpEngine] implementation and passed through
/// response interceptors. This type does not perform networking.
abstract interface class RestResponse {
  /// HTTP status code.
  int get statusCode;

  /// Response headers. Multi-valued headers are joined or listed by adapter.
  Map<String, String> get headers;

  /// Decoded body when available (JSON map/list, string, etc.).
  Object? get data;

  /// Raw response bytes when available.
  List<int>? get bodyBytes;

  /// Response body as string when available.
  String? get bodyString;

  /// The request that produced this response.
  RestRequest get request;

  /// Whether [statusCode] indicates success (typically 2xx).
  bool get isSuccess;
}
