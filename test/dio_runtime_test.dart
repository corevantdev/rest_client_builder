import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:rest_client_builder/rest_client_builder.dart' hide Headers;
import 'package:test/test.dart' hide Retry;

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('DioRestClient execution', () {
    test('maps JSON response into RestResult via RestResponseMapper', () async {
      final dio = Dio();
      dio.httpClientAdapter = _ScriptedAdapter((options) async {
        expect(options.method, 'GET');
        expect(options.uri.path, '/users/1');
        expect(options.headers['Accept'], 'application/json');
        return ResponseBody.fromString(
          jsonEncode({'id': '1', 'name': 'Ada'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = DioRestClient(
        config: const BasicRestClientConfig(
          baseUrl: 'https://api.example.com',
          defaultHeaders: {'Accept': 'application/json'},
          connectTimeout: Duration(seconds: 1),
          receiveTimeout: Duration(seconds: 1),
          sendTimeout: Duration(seconds: 1),
        ),
        dio: dio,
      );

      final raw = await client.execute(
        const BasicRestRequest(method: 'GET', path: '/users/1'),
      );
      expect(raw.isSuccess, isTrue);

      final mapped = RestResponseMapper.mapCustom<Map<String, dynamic>>(
        raw,
        (data) => Map<String, dynamic>.from(data as Map),
      );
      expect(mapped.getOrThrow()['name'], 'Ada');
    });

    test('converts timeout Dio errors into RestError.timeout', () async {
      final dio = Dio();
      dio.httpClientAdapter = _ScriptedAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          message: 'connect timeout',
        );
      });

      final client = DioRestClient(
        config: const BasicRestClientConfig(
          baseUrl: 'https://api.example.com',
          retryMaxAttempts: 1,
        ),
        dio: dio,
      );

      final result = await client.execute(
        const BasicRestRequest(method: 'GET', path: '/slow'),
      );
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.code, RestErrorCodes.timeout);
    });

    test('retries configured status codes', () async {
      var attempts = 0;
      final dio = Dio();
      dio.httpClientAdapter = _ScriptedAdapter((options) async {
        attempts += 1;
        if (attempts < 3) {
          return ResponseBody.fromString('nope', 503);
        }
        return ResponseBody.fromString(
          jsonEncode({'ok': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = DioRestClient(
        config: const BasicRestClientConfig(
          baseUrl: 'https://api.example.com',
          retryMaxAttempts: 3,
          retryDelay: Duration(milliseconds: 1),
          retryStatusCodes: [503],
        ),
        dio: dio,
      );

      final result = await client.execute(
        const BasicRestRequest(method: 'GET', path: '/flaky'),
      );
      expect(attempts, 3);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.statusCode, 200);
    });

    test('merges global headers and resolves logging interceptor', () async {
      final logs = <String>[];
      final logger = _MemoryLogger(logs);
      final dio = Dio();
      dio.httpClientAdapter = _ScriptedAdapter((options) async {
        expect(options.headers['X-Global'], '1');
        expect(options.headers['X-Local'], '2');
        return ResponseBody.fromString('{}', 200);
      });

      final client = DioRestClient(
        config: BasicRestClientConfig(
          baseUrl: 'https://api.example.com',
          defaultHeaders: const {'X-Global': '1'},
          enableLog: true,
          logger: logger,
        ),
        dio: dio,
      );

      await client.execute(
        const BasicRestRequest(
          method: 'GET',
          path: '/h',
          headers: {'X-Local': '2'},
        ),
      );

      expect(client.resolvedInterceptors.whereType<LoggingRestInterceptor>(), isNotEmpty);
      expect(logs.any((line) => line.contains('→ GET')), isTrue);
      expect(logs.any((line) => line.contains('← 200')), isTrue);
    });

    test('DioErrorMapper maps cancel and connection errors', () {
      final cancelled = DioErrorMapper.fromDioException(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.cancel,
        ),
      );
      expect(cancelled.code, RestErrorCodes.cancelled);

      final connection = DioErrorMapper.fromDioException(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
          message: 'offline',
        ),
      );
      expect(connection.code, RestErrorCodes.connection);
    });
  });
}

class _MemoryLogger extends RestLogger {
  _MemoryLogger(this.messages);

  final List<String> messages;

  @override
  RestLogLevel get level => RestLogLevel.verbose;

  @override
  void log(
    RestLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    messages.add(message);
  }
}
