import '../interceptor/rest_interceptor.dart';
import '../client/rest_client.dart';
import 'rest_api_client_registry.dart';
import 'rest_global_config.dart';

/// Contract for application-wide REST settings.
///
/// Implement this on an application / package configuration class. The runtime
/// factory extension reads its fields and provides [createRestClient].
abstract interface class RestApiGlobalConfiguration {
  /// The base URL for the API.
  String get baseUrl;

  /// Default headers to apply to all requests.
  Map<String, String> get headers;

  /// Maximum number of retry attempts.
  int? get retryMaxAttempts;

  /// Delay between retry attempts.
  int? get retryDelayMs;

  /// Status codes that should trigger a retry.
  List<int>? get retryStatusCodes;

  /// Connection timeout in milliseconds.
  int? get connectTimeoutMs;

  /// Receive timeout in milliseconds.
  int? get receiveTimeoutMs;

  /// Send timeout in milliseconds.
  int? get sendTimeoutMs;

  /// Whether to enable logging.
  bool? get enableLog;

  /// List of interceptors to apply.
  List<RestInterceptor> get interceptors;
}

/// Runtime factory available to every [RestApiGlobalConfiguration].
///
/// This keeps Dio as an implementation detail: application code depends only
/// on [RestClient] and can inject that interface into generated APIs.
extension RestApiGlobalConfigurationClientFactory
    on RestApiGlobalConfiguration {
  /// Resolves nullable global fields into concrete runtime settings.
  RestGlobalConfig get restClientConfig => RestGlobalConfig(
        baseUrl: baseUrl,
        defaultHeaders: headers,
        connectTimeoutMs: connectTimeoutMs,
        receiveTimeoutMs: receiveTimeoutMs,
        sendTimeoutMs: sendTimeoutMs,
        enableLog: enableLog,
        retryMaxAttempts: retryMaxAttempts,
        retryDelayMs: retryDelayMs,
        retryStatusCodes: retryStatusCodes,
        interceptors: List<RestInterceptor>.unmodifiable(interceptors),
      );

  /// Returns the **shared** REST client for this configuration type.
  ///
  /// The first call creates a [RestClient] (and Dio connection pool); later
  /// calls reuse it so package/app APIs stay on one connection.
  RestClient createRestClient() => RestApiClientRegistry.sharedClient(this);

  /// Creates a new REST client that is not cached.
  ///
  /// Prefer [createRestClient] in app code. Use this in tests when isolation
  /// is required.
  RestClient createFreshRestClient() =>
      RestApiClientRegistry.freshClient(this);
}
