import 'package:rest_client_builder/rest_client_builder.dart';

import 'interceptors.dart';

export '../rest_client_builder/core/app_config.rest.config.g.dart';

/// The application's single source of REST configuration.
///
/// [RestApiGlobalConfigurationClientFactory] supplies [createRestClient]
/// (shared per config type via [RestApiClientRegistry]). Inject that client
/// into every API. No Dio type is exposed to app code.
///
/// Omit any nullable policy field to use the `RestGlobalConfig` defaults: no
/// configured retries, 500ms connect timeout, 1000ms receive/send timeout,
/// and logging enabled.
@RestConfiguration()
class AppRestConfiguration implements RestApiGlobalConfiguration {
  @override
  final String baseUrl = Environment.api;
  @override
  final Map<String, String> headers = const {
    'Accept': 'application/json',
    'X-Client': 'rest_client_builder_example',
  };
  @override
  final int? retryMaxAttempts = 3;
  @override
  final Duration? retryDelay = const Duration(milliseconds: 200);
  @override
  final List<int>? retryStatusCodes = const [502, 503];
  @override
  final Duration? connectTimeout = const Duration(seconds: 10);
  @override
  final Duration? receiveTimeout = const Duration(seconds: 30);
  @override
  final Duration? sendTimeout = const Duration(seconds: 15);
  @override
  final bool? enableLog = true;
  @override
  final List<RestInterceptor> interceptors = [
    AuthInterceptor(tokenReader: AppSession.token),
    UploadInterceptor(),
  ];
}

/// Environment-specific values supplied at build time.
abstract final class Environment {
  static const api = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.example.com',
  );
}

/// Replace this with your secure-storage/local-storage implementation.
abstract final class AppSession {
  static Future<String?> token() async {
    // Example: return await secureStorage.read(key: 'access_token');
    return null;
  }
}
