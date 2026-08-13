import 'dart:async';
import 'dart:convert';

import 'package:rest_client_builder/rest_client_builder.dart';
import 'package:test/test.dart';

void main() {
  group('SseParser', () {
    test('parses single SSE frame with data, event, and id', () async {
      final input = utf8.encode('id: 101\nevent: user_joined\ndata: {"name": "Alice"}\n\n');
      final stream = Stream<List<int>>.value(input);

      final events = await SseParser.parse(stream).toList();

      expect(events.length, 1);
      expect(events.first.id, '101');
      expect(events.first.event, 'user_joined');
      expect(events.first.data, '{"name": "Alice"}');
    });

    test('handles multi-line data fields concatenated with newline', () async {
      final input = utf8.encode('data: line 1\ndata: line 2\ndata: line 3\n\n');
      final stream = Stream<List<int>>.value(input);

      final events = await SseParser.parse(stream).toList();

      expect(events.length, 1);
      expect(events.first.data, 'line 1\nline 2\nline 3');
    });

    test('ignores comment lines starting with colon', () async {
      final input = utf8.encode(': heart-beat ping\ndata: hello\n\n');
      final stream = Stream<List<int>>.value(input);

      final events = await SseParser.parse(stream).toList();

      expect(events.length, 1);
      expect(events.first.data, 'hello');
    });
  });

  group('RestRequestQueue & RestQueueInterceptor', () {
    late RestRequestQueue queue;

    setUp(() {
      queue = RestRequestQueue();
    });

    tearDown(() {
      queue.dispose();
    });

    test('enqueue adds item and updates items stream and length', () async {
      const request = BasicRestRequest(method: 'POST', path: '/orders');

      expect(queue.length, 0);
      expect(queue.isEmpty, isTrue);

      final queueEmissions = <List<QueuedItem>>[];
      final sub = queue.itemsStream.listen(queueEmissions.add);

      queue.enqueue(request, removeWhen: [200, 201]);

      await pumpEventQueue();

      expect(queue.length, 1);
      expect(queue.isNotEmpty, isTrue);
      expect(queue.items.first.request.path, '/orders');
      expect(queue.items.first.removeWhen, [200, 201]);
      expect(queueEmissions.length, 1);
      expect(queueEmissions.first.length, 1);

      await sub.cancel();
    });

    test('removeWhere filters queued items', () {
      queue.enqueue(const BasicRestRequest(method: 'POST', path: '/orders/1'));
      queue.enqueue(const BasicRestRequest(method: 'POST', path: '/orders/2'));
      queue.enqueue(const BasicRestRequest(method: 'DELETE', path: '/orders/3'));

      expect(queue.length, 3);

      final removed = queue.removeWhere((item) => item.request.method == 'DELETE');
      expect(removed, 1);
      expect(queue.length, 2);
      expect(queue.items.any((item) => item.request.path == '/orders/3'), isFalse);
    });

    test('flush replays queued requests and removes succeeded items', () async {
      queue.enqueue(const BasicRestRequest(method: 'POST', path: '/sync/1'), removeWhen: [200]);
      queue.enqueue(const BasicRestRequest(method: 'POST', path: '/sync/2'), removeWhen: [200]);

      var executedCount = 0;
      final testClient = CallbackRestClient(
        onExecute: (req) async {
          executedCount++;
          if (req.path == '/sync/1') {
            return Success(BasicRestResponse(statusCode: 200, data: 'ok', request: req));
          } else {
            return Success(BasicRestResponse(statusCode: 500, data: 'error', request: req));
          }
        },
      );

      final result = await queue.flush(testClient);

      expect(executedCount, 2);
      expect(result.succeeded, 1);
      expect(result.kept, 1);
      expect(queue.length, 1);
      expect(queue.items.first.request.path, '/sync/2');
      expect(queue.items.first.retryCount, 1);
    });

    test('RestQueueInterceptor handles auto-enqueue on failure triggers', () {
      final queuedEvents = <RestRequest>[];
      final interceptor = RestQueueInterceptor(
        queue: queue,
        onQueued: (req, item) => queuedEvents.add(req),
      );

      const requestWithQueue = BasicRestRequest(
        method: 'POST',
        path: '/offline-action',
        extras: {
          'offlineQueue.enabled': true,
          'offlineQueue.enqueueOnConnectionError': true,
          'offlineQueue.enqueueOnTimeout': true,
          'offlineQueue.removeWhen': [200, 201],
        },
      );

      final connError = RestError.connection('Network unreachable');
      final handled = interceptor.handleQueueOnFailure(connError, requestWithQueue);

      expect(handled, isTrue);
      expect(queue.length, 1);
      expect(queuedEvents.length, 1);
      expect(queue.items.first.request.path, '/offline-action');

      const requestWithoutQueue = BasicRestRequest(method: 'POST', path: '/normal');
      final handledNormal = interceptor.handleQueueOnFailure(connError, requestWithoutQueue);
      expect(handledNormal, isFalse);
      expect(queue.length, 1); // unchanged
    });

    test('RestQueueInterceptor enqueues on specific HTTP status code triggers', () {
      final interceptor = RestQueueInterceptor(queue: queue);

      const statusReq = BasicRestRequest(
        method: 'POST',
        path: '/gateway-retry',
        extras: {
          'offlineQueue.enabled': true,
          'offlineQueue.enqueueOnStatusCodes': [502, 503, 429],
        },
      );

      final error502 = RestError.http('Bad Gateway', statusCode: 502);
      final error400 = RestError.http('Bad Request', statusCode: 400);

      expect(interceptor.handleQueueOnFailure(error502, statusReq), isTrue);
      expect(queue.length, 1);

      expect(interceptor.handleQueueOnFailure(error400, statusReq), isFalse);
      expect(queue.length, 1); // unchanged
    });
  });
}

