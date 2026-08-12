import '../../core/logger/rest_logger.dart';
import '../client/rest_response_mapper.dart';
import '../interceptor/rest_interceptor.dart';

/// Standard application-wide REST settings.
///
/// Constructor values are nullable so an app can specify only what it needs.
/// Unspecified values resolve to the package defaults: no configured retries,
/// 10 s connection timeout, 30 s receive/send timeout, and logging on.
class RestGlobalConfig extends BasicRestClientConfig {
  /// Creates global settings with safe defaults.
  const RestGlobalConfig({
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    int? connectTimeoutMs,
    int? receiveTimeoutMs,
    int? sendTimeoutMs,
    bool? enableLog,
    int? retryMaxAttempts,
    int? retryDelayMs,
    super.retryStatusCodes,
    List<RestInterceptor>? interceptors,
    RestLogger? logger,
  }) : super(
          baseUrl: baseUrl ?? '',
          defaultHeaders: defaultHeaders ?? const <String, String>{},
          connectTimeoutMs: connectTimeoutMs ?? 10000,
          receiveTimeoutMs: receiveTimeoutMs ?? 30000,
          sendTimeoutMs: sendTimeoutMs ?? 30000,
          enableLog: enableLog ?? true,
          retryMaxAttempts: retryMaxAttempts ?? 0,
          retryDelayMs: retryDelayMs ?? 0,
          interceptors: interceptors ?? const <RestInterceptor>[],
          logger: logger ?? const NoOpRestLogger(),
        );
}
