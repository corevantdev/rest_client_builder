import 'package:rest_client_builder/rest_client_builder.dart';
import 'package:test/test.dart' hide Retry;

/// Minimal stubs proving runtime interfaces are implementable without HTTP.
class _StubConfig implements RestClientConfig {
  @override
  String get baseUrl => 'https://api.example.com';

  @override
  Map<String, String> get defaultHeaders => const {};

  @override
  int get connectTimeoutMs => 1000;

  @override
  int get receiveTimeoutMs => 1000;

  @override
  int get sendTimeoutMs => 1000;

  @override
  bool get enableLog => false;

  @override
  int get retryMaxAttempts => 1;

  @override
  int get retryDelayMs => 0;

  @override
  List<int>? get retryStatusCodes => null;

  @override
  List<RestInterceptor> get interceptors => const [];

  @override
  RestLogger get logger => const NoOpRestLogger();
}

class _StubClient implements RestClient {
  @override
  RestClientConfig get config => _StubConfig();

  @override
  Future<RestResult<RestResponse>> execute(RestRequest request) async {
    return Failure<RestResponse>(
      RestError.unknown('HTTP engine not implemented'),
    );
  }

  @override
  Stream<SSEEvent> executeSSE(RestRequest request) => const Stream.empty();
}

void main() {
  group('runtime architecture', () {
    test('interfaces are exportable and stub-implementable', () {
      final client = _StubClient();
      expect(client.config.baseUrl, 'https://api.example.com');
      expect(RestBodyType.json.name, 'json');
      expect(RestBodyType.values, contains(RestBodyType.multipart));
    });

    test('stub client can return failure results', () async {
      final result = await _StubClient().execute(_FakeRequest());
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, contains('not implemented'));
    });
  });
}

class _FakeRequest implements RestRequest {
  @override
  String get method => HttpMethodNames.get;

  @override
  String get path => '/ping';

  @override
  String? get url => null;

  @override
  Map<String, String> get headers => const {};

  @override
  Map<String, String> get queryParameters => const {};

  @override
  Object? get body => null;

  @override
  RestBodyType get bodyType => RestBodyType.none;

  @override
  RestMultipartBody? get multipartBody => null;

  @override
  int? get connectTimeoutMs => null;

  @override
  int? get receiveTimeoutMs => null;

  @override
  int? get sendTimeoutMs => null;

  @override
  CancelToken? get cancelToken => null;

  @override
  RestProgressCallback? get onSendProgress => null;

  @override
  RestProgressCallback? get onReceiveProgress => null;

  @override
  Map<String, Object?> get extras => const {};
}
