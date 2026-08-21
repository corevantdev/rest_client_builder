import '../cancel/cancel_token.dart';
import '../multipart/rest_multipart_body.dart';
import '../progress/progress_callback.dart';
import 'rest_body_type.dart';

/// Immutable view of an outgoing HTTP request.
///
/// Built by generated clients or handwritten code. The runtime pipeline may
/// produce modified copies via interceptors before the [RestHttpEngine] sends
/// it. This type does not perform networking.
abstract interface class RestRequest {
  /// HTTP method name (e.g. `GET`, `POST`).
  String get method;

  /// Relative path joined with the configured base URL.
  String get path;

  /// Absolute URL override. When non-null, replaces base URL + [path].
  String? get url;

  /// Request headers.
  Map<String, String> get headers;

  /// Query parameters.
  Map<String, String> get queryParameters;

  /// Request body payload (JSON object, form map, bytes, text, etc.).
  Object? get body;

  /// How [body] / [multipartBody] should be encoded.
  RestBodyType get bodyType;

  /// Multipart payload when [bodyType] is [RestBodyType.multipart].
  RestMultipartBody? get multipartBody;

  /// Optional connect timeout override.
  Duration? get connectTimeout;

  /// Optional receive timeout override.
  Duration? get receiveTimeout;

  /// Optional send timeout override.
  Duration? get sendTimeout;

  /// Optional cancellation token for this call.
  CancelToken? get cancelToken;

  /// Optional upload progress listener.
  RestProgressCallback? get onSendProgress;

  /// Optional download progress listener.
  RestProgressCallback? get onReceiveProgress;

  /// Opaque per-request extras for interceptors / adapters.
  Map<String, Object?> get extras;
}
