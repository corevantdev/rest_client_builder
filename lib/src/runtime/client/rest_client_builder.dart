import '../../core/logger/rest_logger.dart';
import '../config/rest_global_config.dart';
import '../interceptor/rest_interceptor.dart';
import 'dio_rest_client.dart';
import 'rest_client.dart';

/// Builder pattern for creating a [RestClient] without exposing Dio directly.
class RestClientBuilder {
  String? _baseUrl;
  Map<String, String>? _defaultHeaders;
  Duration? _connectTimeout;
  Duration? _receiveTimeout;
  Duration? _sendTimeout;
  bool? _enableLog;
  int? _retryMaxAttempts;
  Duration? _retryDelay;
  List<int>? _retryStatusCodes;
  List<RestInterceptor>? _interceptors;
  RestLogger? _logger;

  /// Sets the base URL for the client.
  RestClientBuilder baseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    return this;
  }

  /// Sets default headers applied to every request.
  RestClientBuilder defaultHeaders(Map<String, String> headers) {
    _defaultHeaders = headers;
    return this;
  }

  /// Adds a single default header.
  RestClientBuilder addHeader(String key, String value) {
    _defaultHeaders ??= {};
    _defaultHeaders![key] = value;
    return this;
  }

  /// Sets timeouts.
  RestClientBuilder timeouts({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    if (connectTimeout != null) _connectTimeout = connectTimeout;
    if (receiveTimeout != null) _receiveTimeout = receiveTimeout;
    if (sendTimeout != null) _sendTimeout = sendTimeout;
    return this;
  }

  /// Configures automatic retries for failed requests.
  RestClientBuilder retry({
    required int maxAttempts,
    Duration delay = Duration.zero,
    List<int>? statusCodes,
  }) {
    _retryMaxAttempts = maxAttempts;
    _retryDelay = delay;
    _retryStatusCodes = statusCodes;
    return this;
  }

  /// Enables or disables request/response logging.
  RestClientBuilder logging({bool enable = true, RestLogger? logger}) {
    _enableLog = enable;
    if (logger != null) _logger = logger;
    return this;
  }

  /// Sets the interceptors for this client.
  RestClientBuilder interceptors(List<RestInterceptor> interceptors) {
    _interceptors = interceptors;
    return this;
  }

  /// Adds a single interceptor.
  RestClientBuilder addInterceptor(RestInterceptor interceptor) {
    _interceptors ??= [];
    _interceptors!.add(interceptor);
    return this;
  }

  /// Builds and returns the [RestClient].
  RestClient build() {
    final config = RestGlobalConfig(
      baseUrl: _baseUrl,
      defaultHeaders: _defaultHeaders,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
      enableLog: _enableLog,
      retryMaxAttempts: _retryMaxAttempts,
      retryDelay: _retryDelay,
      retryStatusCodes: _retryStatusCodes,
      interceptors: _interceptors,
      logger: _logger,
    );
    return DioRestClient(config: config);
  }
}
