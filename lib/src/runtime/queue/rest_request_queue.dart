import 'dart:async';

import '../../core/result/rest_result.dart';
import '../client/rest_client.dart';
import '../request/rest_request.dart';
import '../response/rest_response.dart';
import 'rest_queue_resolver.dart';

/// A single queued request item held in [RestRequestQueue].
class QueuedItem {
  /// Creates a queued item.
  QueuedItem({
    required this.id,
    required this.request,
    required this.createdAt,
    this.removeWhen = const <int>[200, 201, 202, 204],
    this.retryCount = 0,
  });

  /// Unique identifier generated when enqueued.
  final String id;

  /// The original REST request payload.
  final RestRequest request;

  /// Timestamp when enqueued.
  final DateTime createdAt;

  /// Expected success HTTP status codes for removal.
  final List<int> removeWhen;

  /// How many times this queued request has been replayed via [RestRequestQueue.flush].
  final int retryCount;

  /// Creates a copy with incremented retryCount.
  QueuedItem copyWithIncrementedRetry() {
    return QueuedItem(
      id: id,
      request: request,
      createdAt: createdAt,
      removeWhen: removeWhen,
      retryCount: retryCount + 1,
    );
  }
}

/// Result summary returned by [RestRequestQueue.flush].
class RestQueueFlushResult {
  /// Creates a flush result summary.
  const RestQueueFlushResult({
    required this.succeeded,
    required this.kept,
    required this.failedResults,
  });

  /// Count of requests successfully synced and removed from queue.
  final int succeeded;

  /// Count of requests kept in queue (still failing or missing success condition).
  final int kept;

  /// List of per-request results for caller inspection.
  final List<RestResult<RestResponse>> failedResults;
}

/// An in-memory queue for offline & resilient request queueing.
///
/// Stores non-synced [RestRequest]s when network is unavailable or spotty, and
/// replays them via [flush] when network is restored.
///
/// Provides live reactive stream ([itemsStream]), filtering ([removeWhere]),
/// and full inspection ([items]) of non-synced requests.
class RestRequestQueue {
  final List<QueuedItem> _items = [];
  final StreamController<List<QueuedItem>> _controller =
      StreamController<List<QueuedItem>>.broadcast();

  int _nextId = 1;

  /// Unmodifiable view of currently queued / non-synced requests.
  List<QueuedItem> get items => List<QueuedItem>.unmodifiable(_items);

  /// Broadcast stream emitting the current list of non-synced requests whenever the queue changes.
  Stream<List<QueuedItem>> get itemsStream => _controller.stream;

  /// Total number of pending non-synced requests in queue.
  int get length => _items.length;

  /// Whether the queue is currently empty.
  bool get isEmpty => _items.isEmpty;

  /// Whether the queue contains pending items.
  bool get isNotEmpty => _items.isNotEmpty;

  /// Enqueues [request] into the offline queue.
  ///
  /// Optionally specify [removeWhen] status codes. Emits updated list on [itemsStream].
  QueuedItem enqueue(
    RestRequest request, {
    List<int>? removeWhen,
  }) {
    final item = QueuedItem(
      id: 'queue_${_nextId++}_${DateTime.now().millisecondsSinceEpoch}',
      request: request,
      createdAt: DateTime.now(),
      removeWhen: removeWhen ?? const <int>[200, 201, 202, 204],
    );
    _items.add(item);
    _notify();
    return item;
  }

  /// Removes all items matching [predicate].
  ///
  /// Returns count of removed items. Emits updated list on [itemsStream].
  int removeWhere(bool Function(QueuedItem item) predicate) {
    final initial = _items.length;
    _items.removeWhere(predicate);
    final removed = initial - _items.length;
    if (removed > 0) {
      _notify();
    }
    return removed;
  }

  /// Clears all queued requests. Emits updated list on [itemsStream].
  void clear() {
    if (_items.isNotEmpty) {
      _items.clear();
      _notify();
    }
  }

  /// Flushes (replays) all queued requests through [client].
  ///
  /// For each request:
  /// 1. Executes request through [client].
  /// 2. If [resolver] is provided, uses [resolver.shouldRemove].
  /// 3. Otherwise, checks if HTTP status code is in [item.removeWhen].
  /// 4. If removal condition is met -> item is removed from queue.
  /// 5. Otherwise -> item is kept for future replay attempt.
  Future<RestQueueFlushResult> flush(
    RestClient client, {
    RestQueueResolver? resolver,
  }) async {
    if (_items.isEmpty) {
      return const RestQueueFlushResult(
        succeeded: 0,
        kept: 0,
        failedResults: [],
      );
    }

    final snapshot = List<QueuedItem>.from(_items);
    var succeeded = 0;
    var kept = 0;
    final failedResults = <RestResult<RestResponse>>[];

    for (var i = 0; i < snapshot.length; i++) {
      final item = snapshot[i];
      final result = await client.execute(item.request);

      bool shouldRemove;
      if (resolver != null) {
        shouldRemove = resolver.shouldRemove(item.request, result);
      } else if (result.isSuccess) {
        final response = result.dataOrNull!;
        shouldRemove = item.removeWhen.contains(response.statusCode);
      } else {
        shouldRemove = false;
      }

      if (shouldRemove) {
        _items.removeWhere((el) => el.id == item.id);
        succeeded++;
      } else {
        kept++;
        failedResults.add(result);
        final idx = _items.indexWhere((el) => el.id == item.id);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWithIncrementedRetry();
        }
      }
    }

    _notify();

    return RestQueueFlushResult(
      succeeded: succeeded,
      kept: kept,
      failedResults: failedResults,
    );
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(items);
    }
  }

  /// Closes stream resources.
  void dispose() {
    _controller.close();
  }
}
