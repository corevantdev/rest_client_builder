import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:rest_client_builder/rest_client_builder.dart' hide Headers;
import 'package:test/test.dart' hide Retry;

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);

  final Future<ResponseBody> Function(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
  ) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options, requestStream);
  }

  @override
  void close({bool force = false}) {}
}

class _TrackingInterceptor implements RestInterceptor {
  _TrackingInterceptor(this.hits);

  final List<String> hits;

  String get label => runtimeType.toString();

  @override
  Future<RestRequest> onRequest(RestRequest request) async {
    hits.add(label);
    return request;
  }

  @override
  Future<RestResponse> onResponse(RestResponse response) async => response;

  @override
  Future<RestResult<RestResponse>> onError(RestError error) async =>
      Failure<RestResponse>(error);
}

class AuthInterceptor extends _TrackingInterceptor {
  AuthInterceptor(super.hits);
}

class UploadInterceptor extends _TrackingInterceptor {
  UploadInterceptor(super.hits);
}

class OtherInterceptor extends _TrackingInterceptor {
  OtherInterceptor(super.hits);
}

void main() {
  group('RestPart', () {
    test('fromBytes and fromBase64 round-trip without dart:io', () {
      final bytes = utf8.encode('hello-upload');
      final part = RestPart.fromBytes(
        name: 'file',
        bytes: bytes,
        fileName: 'note.txt',
        contentType: 'text/plain',
      );
      expect(part.value, bytes);
      expect(part.length, bytes.length);
      expect(part.fileName, 'note.txt');

      final encoded = part.toBase64();
      final fromBase64 = RestPart.fromBase64(
        name: 'file',
        base64: '  $encoded \n',
        fileName: 'note.txt',
      );
      expect(fromBase64.bytes, bytes);
      expect(fromBase64.withName('avatar').name, 'avatar');
    });
  });

  group('DioRestClient multipart / cancel / progress / interceptors', () {
    test('uploads RestPart multipart body and reports send progress', () async {
      final sendEvents = <(int, int)>[];
      final dio = Dio();
      dio.httpClientAdapter = _ScriptedAdapter((options, requestStream) async {
        expect(options.method, 'POST');
        expect(options.data, isA<FormData>());
        final form = options.data! as FormData;
        expect(form.files, isNotEmpty);
        expect(form.files.first.value.filename, 'avatar.png');
        if (requestStream != null) {
          await requestStream.drain<void>();
        }
        return ResponseBody.fromString(
          jsonEncode({'id': '1', 'name': 'Ada'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = DioRestClient(
        config: const BasicRestClientConfig(baseUrl: 'https://api.example.com'),
        dio: dio,
      );

      final part = RestPart.fromBytes(
        name: 'file',
        bytes: List<int>.filled(2048, 7),
        fileName: 'avatar.png',
        contentType: 'image/png',
      );

      final result = await client.execute(
        BasicRestRequest(
          method: 'POST',
          path: '/avatar',
          bodyType: RestBodyType.multipart,
          multipartBody: BasicMultipartBody(parts: [part]),
          onSendProgress: (count, total) => sendEvents.add((count, total)),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(sendEvents, isNotEmpty);
    });

    test('honours BasicCancelToken', () async {
      final token = BasicCancelToken();
      final dio = Dio();
      dio.httpClientAdapter = _ScriptedAdapter((options, requestStream) async {
        token.cancel('stop');
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          message: 'stop',
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
        BasicRestRequest(
          method: 'GET',
          path: '/slow',
          cancelToken: token,
        ),
      );
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull?.code, RestErrorCodes.cancelled);
      expect(token.isCancelled, isTrue);
    });

    test('filters interceptors with use/exclude extras', () async {
      final hits = <String>[];
      final auth = AuthInterceptor(hits);
      final upload = UploadInterceptor(hits);
      final other = OtherInterceptor(hits);

      final dio = Dio();
      dio.httpClientAdapter = _ScriptedAdapter((options, requestStream) async {
        return ResponseBody.fromString('{}', 200);
      });

      final client = DioRestClient(
        config: const BasicRestClientConfig(baseUrl: 'https://api.example.com'),
        dio: dio,
        interceptors: [auth, upload, other],
      );

      await client.execute(
        const BasicRestRequest(
          method: 'POST',
          path: '/avatar',
          extras: {
            RestInterceptorExtras.useInterceptors: <String>[
              'AuthInterceptor',
              'UploadInterceptor',
            ],
          },
        ),
      );

      expect(hits, ['AuthInterceptor', 'UploadInterceptor']);
      hits.clear();

      await client.execute(
        const BasicRestRequest(
          method: 'GET',
          path: '/health',
          extras: {
            RestInterceptorExtras.excludeInterceptors: <String>[
              'AuthInterceptor',
            ],
          },
        ),
      );

      expect(hits, ['UploadInterceptor', 'OtherInterceptor']);
    });

    test('resolveRestInterceptors supports distinct type names', () {
      final logging = const LoggingRestInterceptor(NoOpRestLogger());
      final selected = resolveRestInterceptors(
        global: [logging],
        useTypeNames: const ['LoggingRestInterceptor'],
      );
      expect(selected, hasLength(1));

      final excluded = resolveRestInterceptors(
        global: [logging],
        excludeTypeNames: const ['LoggingRestInterceptor'],
      );
      expect(excluded, isEmpty);
    });
  });
}
