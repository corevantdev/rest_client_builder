import '../client/dio_rest_client.dart';
import '../client/rest_client.dart';
import 'rest_api_global_configuration.dart';

/// Process-wide cache of [RestClient]s keyed by configuration [Type].
///
/// Ensures every API built from the same [RestApiGlobalConfiguration]
/// implementation reuses one Dio connection pool.
abstract final class RestApiClientRegistry {
  static final Map<Type, RestClient> _clients = <Type, RestClient>{};
  static RestClient? _defaultClient;

  /// Returns the process-wide default shared [RestClient].
  ///
  /// Automatically initialized on first use if not explicitly set.
  static RestClient get defaultClient {
    return _defaultClient ??= DioRestClient();
  }

  /// Sets the process-wide default shared [RestClient].
  static set defaultClient(RestClient client) {
    _defaultClient = client;
  }

  /// Returns the shared client for [configuration]'s runtime type.
  static RestClient sharedClient(RestApiGlobalConfiguration configuration) {
    final client = _clients.putIfAbsent(
      configuration.runtimeType,
      () => DioRestClient(config: configuration.restClientConfig),
    );
    _defaultClient ??= client;
    return client;
  }

  /// Creates a new client that is not cached.
  static RestClient freshClient(RestApiGlobalConfiguration configuration) {
    return DioRestClient(config: configuration.restClientConfig);
  }

  /// Drops all cached clients. Intended for tests.
  static void reset() {
    _clients.clear();
    _defaultClient = null;
  }
}

