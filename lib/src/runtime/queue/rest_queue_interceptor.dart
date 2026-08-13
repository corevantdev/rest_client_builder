import '../../core/error/rest_error.dart';
import '../../core/result/rest_result.dart';
import '../interceptor/rest_interceptor.dart';
import '../request/rest_request.dart';
import '../response/rest_response.dart';
import 'rest_request_queue.dart';

/// Interceptor that automatically enqueues failed requests into a [RestRequestQueue].
///
/// Triggers when:
/// 1. The request has `'offlineQueue.enabled': true` in [request.extras] (injected by `@OfflineQueue`).
/// 2. The error matches configured trigger conditions (`enqueueOnConnectionError`, `enqueueOnTimeout`, `enqueueOnServerError`).
///
/// Usage:
/// ```dart
/// final offlineQueue = RestRequestQueue();
///
/// final clientConfig = BasicRestClientConfig(
///   interceptors: [
///     RestQueueInterceptor(
///       queue: offlineQueue,
///       onQueued: (req) => print('Saved offline: ${req.path}'),
///     ),
///   ],
/// );
/// ```
class RestQueueInterceptor implements RestInterceptor {
  /// Creates a queue interceptor attached to [queue].
  RestQueueInterceptor({
    required this.queue,
    this.onQueued,
  });

  /// The target queue to store failed requests into.
  final RestRequestQueue queue;

  /// Optional listener callback invoked after a request is enqueued.
  final void Function(RestRequest request, QueuedItem item)? onQueued;

  @override
  Future<RestRequest> onRequest(RestRequest request) async => request;

  @override
  Future<RestResponse> onResponse(RestResponse response) async => response;

  @override
  Future<RestResult<RestResponse>> onError(RestError error) async {
    // Basic error handler — requests pass through normally if extras are missing.
    return Failure<RestResponse>(error);
  }

  /// Evaluates an error and request to determine if it should be queued.
  ///
  /// Call this directly from error handlers or custom pipeline logic.
  bool handleQueueOnFailure(RestError error, RestRequest request) {
    final enabled = request.extras['offlineQueue.enabled'] == true;
    if (!enabled) return false;

    final onConn =
        request.extras['offlineQueue.enqueueOnConnectionError'] as bool? ?? true;
    final onTimeout =
        request.extras['offlineQueue.enqueueOnTimeout'] as bool? ?? true;
    final onServer =
        request.extras['offlineQueue.enqueueOnServerError'] as bool? ?? false;
    final onStatusCodes =
        (request.extras['offlineQueue.enqueueOnStatusCodes'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        const <int>[];

    final isConnError = error.code == RestErrorCodes.connection;
    final isTimeoutError = error.code == RestErrorCodes.timeout;
    final isServerError = error.code == RestErrorCodes.http &&
        (error.statusCode != null && error.statusCode! >= 500);
    final isMatchingStatusCode = error.code == RestErrorCodes.http &&
        error.statusCode != null &&
        onStatusCodes.contains(error.statusCode);

    final shouldEnqueue = (onConn && isConnError) ||
        (onTimeout && isTimeoutError) ||
        (onServer && isServerError) ||
        isMatchingStatusCode;

    if (shouldEnqueue) {
      final removeWhen =
          (request.extras['offlineQueue.removeWhen'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList();
      final item = queue.enqueue(request, removeWhen: removeWhen);
      onQueued?.call(request, item);
      return true;
    }

    return false;
  }
}
