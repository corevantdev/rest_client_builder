import 'package:rest_client_builder/rest_client_builder.dart';
import 'package:test/test.dart' hide Retry;

/// Minimal stubs proving runtime interfaces are implementable without HTTP.
class _StubConfig implements RestClientConfig {
  @override
  String get baseUrl => 'https://api.example.com';

  @override
  Map<String, String> get defaultHeaders => const {};

  @override
  Duration get connectTimeout => const Duration(seconds: 1);

  @override
  Duration get receiveTimeout => const Duration(seconds: 1);

  @override
  Duration get sendTimeout => const Duration(seconds: 1);

  @override
  Duration? get idleTimeout => const Duration(seconds: 90);

  @override
  int? get maxConnectionsPerHost => 12;

  @override
  bool get enableLog => false;

  @override
  int get retryMaxAttempts => 1;

  @override
  Duration get retryDelay => Duration.zero;

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
      expect(client.config.idleTimeout, const Duration(seconds: 90));
      expect(client.config.maxConnectionsPerHost, 12);
      expect(RestBodyType.json.name, 'json');
      expect(RestBodyType.values, contains(RestBodyType.multipart));
    });

    test('RestClientBuilder configures connection pool settings', () {
      final client = RestClientBuilder()
          .baseUrl('https://api.example.com')
          .connectionPool(
            idleTimeout: const Duration(seconds: 90),
            maxConnectionsPerHost: 12,
          )
          .build();

      expect(client.config.idleTimeout, const Duration(seconds: 90));
      expect(client.config.maxConnectionsPerHost, 12);

      final client2 = RestClientBuilder()
          .baseUrl('https://api.example.com')
          .idleTimeout(const Duration(seconds: 45))
          .maxConnectionsPerHost(8)
          .build();

      expect(client2.config.idleTimeout, const Duration(seconds: 45));
      expect(client2.config.maxConnectionsPerHost, 8);
    });

    test('stub client can return failure results', () async {
      final result = await _StubClient().execute(_FakeRequest());
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.message, contains('not implemented'));
    });

    group('RestResponseMapper model conversion try-catch', () {
      final successResponse = Success<RestResponse>(
        BasicRestResponse(
          statusCode: 200,
          request: _FakeRequest(),
          data: {'name': 'Alice', 'age': 30},
        ),
      );

      test('mapModel succeeds for valid model conversion', () {
        final res = RestResponseMapper.mapModel(
          successResponse,
          (json) => json['name'] as String,
        );
        expect(res.isSuccess, isTrue);
        expect(res.getOrThrow(), 'Alice');
      });

      test('mapModel catches exceptions in fromJson and returns Failure', () {
        final res = RestResponseMapper.mapModel<String>(
          successResponse,
          (json) => throw const FormatException('Corrupt user field'),
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull?.message, contains('Corrupt user field'));
      });

      test('mapModel catches validation error for non-map data', () {
        final nonMapResponse = Success<RestResponse>(
          BasicRestResponse(
            statusCode: 200,
            request: _FakeRequest(),
            data: 'not a map',
          ),
        );
        final res = RestResponseMapper.mapModel<String>(
          nonMapResponse,
          (json) => json['name'] as String,
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull?.message, contains('Expected JSON object'));
      });

      test('mapModelList catches item conversion error', () {
        final listResponse = Success<RestResponse>(
          BasicRestResponse(
            statusCode: 200,
            request: _FakeRequest(),
            data: [
              {'id': 1},
              {'id': 'not-int'},
            ],
          ),
        );
        final res = RestResponseMapper.mapModelList<int>(
          listResponse,
          (json) {
            if (json['id'] is! int) {
              throw const FormatException('Expected integer id');
            }
            return json['id'] as int;
          },
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull?.message, contains('Expected integer id'));
      });

      test('mapModelList catches non-list data', () {
        final res = RestResponseMapper.mapModelList<String>(
          successResponse,
          (json) => json['name'] as String,
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull?.message, contains('Expected JSON array'));
      });

      test('mapCustom catches custom decoder error', () {
        final res = RestResponseMapper.mapCustom<int>(
          successResponse,
          (data) => throw StateError('Decoder failed'),
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull?.message, contains('Decoder failed'));
      });

      test('mapModel extracts backend error message on non-2xx response', () {
        final errorResponse = Success<RestResponse>(
          BasicRestResponse(
            statusCode: 404,
            request: _FakeRequest(),
            data: {'message': 'Location not found'},
          ),
        );
        final res = RestResponseMapper.mapModel<String>(
          errorResponse,
          (json) => json['name'] as String,
        );
        expect(res.isFailure, isTrue);
        expect(res.errorOrNull?.message, 'Location not found');
        expect(res.errorOrNull?.statusCode, 404);
      });
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
  Duration? get connectTimeout => null;

  @override
  Duration? get receiveTimeout => null;

  @override
  Duration? get sendTimeout => null;

  @override
  CancelToken? get cancelToken => null;

  @override
  RestProgressCallback? get onSendProgress => null;

  @override
  RestProgressCallback? get onReceiveProgress => null;

  @override
  Map<String, Object?> get extras => const {};
}
