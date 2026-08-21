import 'package:rest_client_builder/rest_client_builder.dart';
import 'package:test/test.dart';

void main() {
  group('RestResult', () {
    test('Success exposes data and when/fold/map', () {
      const result = Success<int>(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 42);
      expect(result.errorOrNull, isNull);
      expect(result.getOrThrow(), 42);
      expect(result.getOrElse(() => 0), 42);
      expect(
        result.when(success: (data) => data * 2, failure: (_) => -1),
        84,
      );
      expect(result.fold((_) => -1, (data) => data + 1), 43);
      expect(result.map((data) => '$data'), const Success<String>('42'));
    });

    test('Failure preserves RestError across map/flatMap', () {
      final error = RestError.validation('bad');
      final result = Failure<int>(error);

      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.errorOrNull, error);
      expect(result.getOrElse(() => 7), 7);
      expect(() => result.getOrThrow(), throwsA(same(error)));
      expect(
        result.map((data) => '$data'),
        Failure<String>(error),
      );
      expect(
        result.flatMap((data) => Success<String>('$data')),
        Failure<String>(error),
      );
    });

    test('factory constructors create Success and Failure', () {
      expect(const RestResult.success(1), isA<Success<int>>());
      expect(
        RestResult<int>.failure(RestError.unknown('x')),
        isA<Failure<int>>(),
      );
    });
  });

  group('RestError', () {
    test('factories set codes and status hints', () {
      expect(RestError.unknown('u').code, RestErrorCodes.unknown);
      expect(RestError.validation('v').statusCode, 400);
      expect(RestError.timeout('t').code, RestErrorCodes.timeout);
      expect(RestError.cancelled('c').code, RestErrorCodes.cancelled);
      expect(RestError.connection('n').code, RestErrorCodes.connection);
      expect(RestError.http('h', statusCode: 502).code, RestErrorCodes.http);
    });

    test('fromException reuses RestError instances', () {
      final original = RestError.unknown('same');
      expect(RestError.fromException(original), same(original));
      expect(RestError.fromException(StateError('boom')).cause, isA<StateError>());
    });

    test('copyWith replaces selected fields', () {
      final error = RestError.unknown('a').copyWith(message: 'b', statusCode: 500);
      expect(error.message, 'b');
      expect(error.statusCode, 500);
      expect(error.code, RestErrorCodes.unknown);
    });
  });

  group('StringUtils', () {
    test('blank checks and path helpers', () {
      expect(StringUtils.isNullOrBlank('  '), isTrue);
      expect(StringUtils.isNotBlank('ok'), isTrue);
      expect(StringUtils.nullIfBlank('  '), isNull);
      expect(StringUtils.defaultIfBlank(null, 'x'), 'x');
      expect(StringUtils.capitalize('dart'), 'Dart');
      expect(StringUtils.joinPath(['/api/', '/v1/', 'users']), '/api/v1/users');
      expect(StringUtils.ensureLeadingSlash('users'), '/users');
      expect(StringUtils.removeTrailingSlash('/users/'), '/users');
    });
  });

  group('MapUtils', () {
    test('compact, merge, and stringify', () {
      expect(
        MapUtils.compactNulls(<String, int?>{'a': 1, 'b': null}),
        {'a': 1},
      );
      expect(
        MapUtils.compactBlank(<String, String?>{'a': 'x', 'b': ' '}),
        {'a': 'x'},
      );
      expect(MapUtils.merge({'a': 1}, {'b': 2}), {'a': 1, 'b': 2});
      expect(
        MapUtils.stringifyValues({'page': 2, 'q': null}),
        {'page': '2'},
      );
      expect(MapUtils.getAs<int>({'n': 3}, 'n'), 3);
      expect(MapUtils.isNullOrEmpty(null), isTrue);
    });
  });

  group('ValidationUtils', () {
    test('require helpers return Success or Failure', () {
      expect(ValidationUtils.requireNotNull(1).isSuccess, isTrue);
      expect(ValidationUtils.requireNotNull(null).isFailure, isTrue);
      expect(ValidationUtils.requireNotBlank('  ').isFailure, isTrue);
      expect(ValidationUtils.require(true, message: 'ok').isSuccess, isTrue);
      expect(
        ValidationUtils.requireInRange(5, min: 1, max: 4).isFailure,
        isTrue,
      );
    });
  });

  group('JsonUtils', () {
    test('encode and decode map/list', () {
      expect(JsonUtils.encode({'a': 1}).getOrThrow(), '{"a":1}');
      expect(
        JsonUtils.decodeMap('{"a":1}').getOrThrow(),
        {'a': 1},
      );
      expect(JsonUtils.decodeList('[1,2]').getOrThrow(), [1, 2]);
      expect(JsonUtils.decodeMap('[]').isFailure, isTrue);
      expect(JsonUtils.decode('not-json').isFailure, isTrue);
    });
  });

  group('TypeUtils', () {
    test('type helpers', () {
      expect(TypeUtils.typeName(null), 'null');
      expect(TypeUtils.asOrNull<int>('x'), isNull);
      expect(TypeUtils.isJsonPrimitive('a'), isTrue);
      expect(TypeUtils.isJsonCompatible({'a': [1, true]}), isTrue);
      expect(TypeUtils.isJsonCompatible(Object()), isFalse);
    });
  });

  group('RestLogger', () {
    test('NoOpRestLogger discards messages', () {
      const logger = NoOpRestLogger();
      expect(logger.level, RestLogLevel.none);
      logger.info('ignored');
    });

    test('RestLogLevel threshold comparison', () {
      expect(RestLogLevel.error.isEnabled(RestLogLevel.info), isTrue);
      expect(RestLogLevel.debug.isEnabled(RestLogLevel.info), isFalse);
      expect(RestLogLevel.none.isEnabled(RestLogLevel.verbose), isFalse);
    });
  });

  group('constants', () {
    test('package and HTTP constants', () {
      expect(restApiBuilderPackage, RestConstants.packageName);
      expect(HttpMethodNames.get, 'GET');
      expect(HttpHeaderNames.contentType, 'Content-Type');
      expect(HttpStatusCodes.isSuccess(201), isTrue);
      expect(HttpStatusCodes.isClientError(404), isTrue);
      expect(HttpStatusCodes.isServerError(500), isTrue);
    });
  });

  group('RestApiClientRegistry', () {
    tearDown(RestApiClientRegistry.reset);

    test('createRestClient reuses one client per configuration type', () {
      final config = _TestRestConfiguration();
      final first = config.createRestClient();
      final second = config.createRestClient();
      expect(identical(first, second), isTrue);
    });

    test('createFreshRestClient returns a new instance', () {
      final config = _TestRestConfiguration();
      final shared = config.createRestClient();
      final fresh = config.createFreshRestClient();
      expect(identical(shared, fresh), isFalse);
    });
  });
}

class _TestRestConfiguration implements RestApiGlobalConfiguration {
  @override
  final String baseUrl = 'https://example.test';
  @override
  final Map<String, String> headers = const {'Accept': 'application/json'};
  @override
  final int? retryMaxAttempts = null;
  @override
  final Duration? retryDelay = null;
  @override
  final List<int>? retryStatusCodes = null;
  @override
  final Duration? connectTimeout = null;
  @override
  final Duration? receiveTimeout = null;
  @override
  final Duration? sendTimeout = null;
  @override
  final bool? enableLog = false;
  @override
  final List<RestInterceptor> interceptors = const [];
}
