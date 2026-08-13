import 'package:rest_client_builder/rest_client_builder.dart';
import 'package:test/test.dart' hide Retry;

void main() {
  group('configuration annotations', () {
    test('constructors retain values', () {
      const config = RestConfiguration(name: 'default');
      const baseUrl = BaseUrl('https://api.example.com');
      const headers = Headers({'Accept': 'application/json'});
      const interceptors = GlobalInterceptors([Object]);
      const retry = Retry(5, 250, [500]);
      const log = EnableLog(false);
      const connect = ConnectTimeout(1000);
      const receive = ReceiveTimeout(2000);
      const send = SendTimeout(3000);

      expect(config.name, 'default');
      expect(baseUrl.value, 'https://api.example.com');
      expect(headers.value['Accept'], 'application/json');
      expect(interceptors.interceptors, [Object]);
      expect(retry.maxAttempts, 5);
      expect(retry.delayMs, 250);
      expect(retry.retryStatusCodes, [500]);
      expect(log.enabled, isFalse);
      expect(connect.milliseconds, 1000);
      expect(receive.milliseconds, 2000);
      expect(send.milliseconds, 3000);
    });
  });

  group('API annotations', () {
    test('constructors retain values', () {
      const api = RestApi(baseUrl: 'https://example.com');
      const tag = Tag('users');
      const use = UseInterceptor([Object]);
      const exclude = ExcludeInterceptor([String]);

      expect(api.baseUrl, 'https://example.com');
      expect(tag.name, 'users');
      expect(use.interceptors, [Object]);
      expect(exclude.interceptors, [String]);
    });
  });

  group('HTTP annotations', () {
    test('verbs expose method and path', () {
      const get = GET('/users');
      const post = POST('/users');
      const put = PUT('/users/{id}');
      const patch = PATCH('/users/{id}');
      const delete = DELETE('/users/{id}');
      const head = HEAD('/users');
      const options = OPTIONS('/users');

      expect(get.method, HttpMethodNames.get);
      expect(post.method, HttpMethodNames.post);
      expect(put.method, HttpMethodNames.put);
      expect(patch.method, HttpMethodNames.patch);
      expect(delete.method, HttpMethodNames.delete);
      expect(head.method, HttpMethodNames.head);
      expect(options.method, HttpMethodNames.options);
      expect(put.path, '/users/{id}');
      expect(const GET().path, isEmpty);
    });

    test('SSE annotation constructor retains reconnectMs', () {
      const sse = SSE(reconnectMs: 5000);
      expect(sse.reconnectMs, 5000);
      expect(const SSE().reconnectMs, 3000);
    });

    test('ResilientQueue annotation constructor retains defaults and custom options', () {
      const queue = ResilientQueue(
        removeWhen: [200, 201],
        enqueueOnConnectionError: true,
        enqueueOnTimeout: false,
        enqueueOnServerError: true,
        enqueueOnStatusCodes: [502, 503],
      );
      expect(queue.removeWhen, [200, 201]);
      expect(queue.enqueueOnConnectionError, isTrue);
      expect(queue.enqueueOnTimeout, isFalse);
      expect(queue.enqueueOnServerError, isTrue);
      expect(queue.enqueueOnStatusCodes, [502, 503]);

      const defaults = ResilientQueue();
      expect(defaults.removeWhen, [200, 201, 202, 204]);
      expect(defaults.enqueueOnConnectionError, isTrue);
      expect(defaults.enqueueOnTimeout, isTrue);
      expect(defaults.enqueueOnServerError, isFalse);
      expect(defaults.enqueueOnStatusCodes, isEmpty);
    });
  });

  group('parameter annotations', () {
    test('constructors retain values', () {
      expect(const Path('id').name, 'id');
      expect(const Path().name, isNull);
      expect(const Query('page', true).name, 'page');
      expect(const Query('page', true).encoded, isTrue);
      expect(const QueryMap(encoded: true).encoded, isTrue);
      expect(const Body(), isA<Body>());
      expect(const Header('Authorization').name, 'Authorization');
      expect(const HeaderMap(), isA<HeaderMap>());
      expect(const Url(), isA<Url>());
    });
  });

  group('multipart and form annotations', () {
    test('constructors retain values', () {
      expect(const Multipart(), isA<Multipart>());
      const part = Part(
        name: 'file',
        fileName: 'a.png',
        contentType: 'image/png',
      );
      expect(part.name, 'file');
      expect(part.fileName, 'a.png');
      expect(part.contentType, 'image/png');
      expect(const PartMap(), isA<PartMap>());

      expect(const FormUrlEncoded(), isA<FormUrlEncoded>());
      expect(const Field('email').name, 'email');
      expect(const FieldMap(), isA<FieldMap>());
    });
  });

  group('model annotations', () {
    test('RestModel defaults and JsonKey export', () {
      const model = RestModel();
      expect(model.createFactory, isTrue);
      expect(model.createToJson, isTrue);
      expect(model.explicitToJson, isTrue);

      const key = JsonKey(name: 'user_name', defaultValue: '');
      expect(key.name, 'user_name');
      expect(key.defaultValue, '');
    });
  });
}
