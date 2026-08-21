import '../cancel/cancel_token.dart';
import '../multipart/rest_multipart_body.dart';
import '../progress/progress_callback.dart';
import 'rest_body_type.dart';
import 'rest_request.dart';

// Private sentinel: distinguishes "not supplied" from explicit null in copyWith.
const _$absent = Object();

/// Concrete [RestRequest] used by generated API clients.
class BasicRestRequest implements RestRequest {
  /// Creates a basic request.
  const BasicRestRequest({
    required this.method,
    required this.path,
    this.url,
    this.headers = const <String, String>{},
    this.queryParameters = const <String, String>{},
    this.body,
    this.bodyType = RestBodyType.none,
    this.multipartBody,
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
    this.cancelToken,
    this.onSendProgress,
    this.onReceiveProgress,
    this.extras = const <String, Object?>{},
  });

  @override
  final String method;

  @override
  final String path;

  @override
  final String? url;

  @override
  final Map<String, String> headers;

  @override
  final Map<String, String> queryParameters;

  @override
  final Object? body;

  @override
  final RestBodyType bodyType;

  @override
  final RestMultipartBody? multipartBody;

  @override
  final Duration? connectTimeout;

  @override
  final Duration? receiveTimeout;

  @override
  final Duration? sendTimeout;

  @override
  final CancelToken? cancelToken;

  @override
  final RestProgressCallback? onSendProgress;

  @override
  final RestProgressCallback? onReceiveProgress;

  @override
  final Map<String, Object?> extras;

  /// Returns a copy with selected fields replaced.
  ///
  /// Pass `url: null` to explicitly clear a URL override (setting it back to
  /// `null`). Omitting `url` entirely preserves the current value.
  BasicRestRequest copyWith({
    String? method,
    String? path,
    Object? url = _$absent, // Object? so callers can explicitly pass null
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
    RestBodyType? bodyType,
    RestMultipartBody? multipartBody,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    CancelToken? cancelToken,
    RestProgressCallback? onSendProgress,
    RestProgressCallback? onReceiveProgress,
    Map<String, Object?>? extras,
  }) {
    return BasicRestRequest(
      method: method ?? this.method,
      path: path ?? this.path,
      url: identical(url, _$absent) ? this.url : url as String?,
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
      body: body ?? this.body,
      bodyType: bodyType ?? this.bodyType,
      multipartBody: multipartBody ?? this.multipartBody,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      cancelToken: cancelToken ?? this.cancelToken,
      onSendProgress: onSendProgress ?? this.onSendProgress,
      onReceiveProgress: onReceiveProgress ?? this.onReceiveProgress,
      extras: extras ?? this.extras,
    );
  }
}

/// Replaces `{name}` path placeholders with encoded values.
String resolveRestPath(String template, Map<String, String> pathParams) {
  var path = template;
  pathParams.forEach((key, value) {
    path = path.replaceAll('{$key}', Uri.encodeComponent(value));
  });
  return path;
}

/// Converts a value into a query/header string.
String stringifyRestValue(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  return value.toString();
}

/// Joins [baseUrl] and [path], normalizing slashes.
String joinRestUrl(String baseUrl, String path) {
  if (baseUrl.isEmpty) {
    return path;
  }
  if (path.isEmpty) {
    return baseUrl;
  }
  final baseEnds = baseUrl.endsWith('/');
  final pathStarts = path.startsWith('/');
  if (baseEnds && pathStarts) {
    return '$baseUrl${path.substring(1)}';
  }
  if (!baseEnds && !pathStarts) {
    return '$baseUrl/$path';
  }
  return '$baseUrl$path';
}
