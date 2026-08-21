import '../../core/logger/rest_logger.dart';
import '../interceptor/rest_interceptor.dart';

/// Runtime configuration for a [RestClient].
///
/// Typically derived from configuration annotations (`@BaseUrl`, `@Headers`,
/// timeouts, etc.). This type does not perform networking.
abstract interface class RestClientConfig {
  /// Absolute base URL for relative request paths.
  String get baseUrl;

  /// Default headers applied to every request.
  Map<String, String> get defaultHeaders;

  /// Default connect timeout.
  Duration get connectTimeout;

  /// Default receive timeout.
  Duration get receiveTimeout;

  /// Default send timeout.
  Duration get sendTimeout;

  /// Whether request/response logging is enabled.
  bool get enableLog;

  /// Maximum attempts including the original request.
  int get retryMaxAttempts;

  /// Delay between retries.
  Duration get retryDelay;

  /// Status codes that should trigger a retry, if any.
  List<int>? get retryStatusCodes;

  /// Interceptors applied to every call (global + client level).
  List<RestInterceptor> get interceptors;

  /// Logger used when [enableLog] is true.
  RestLogger get logger;
}
