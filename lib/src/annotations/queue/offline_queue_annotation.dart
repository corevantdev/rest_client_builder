/// Marks an abstract REST API method for automatic resilient request queueing.
///
/// When a request fails due to network loss, connection timeout, specific status codes
/// (e.g. 502 Bad Gateway, 503 Service Unavailable, 429 Too Many Requests), or server errors,
/// `RestQueueInterceptor` automatically stores it in `RestRequestQueue` for later replay.
///
/// ## Usage
///
/// ```dart
/// @ResilientQueue(
///   enqueueOnStatusCodes: [502, 503, 504, 429],
///   removeWhen: [200, 201],
/// )
/// @POST('/orders')
/// Future<RestResult<Order>> createOrder(@Body() Order order);
/// ```
///
/// ## Trigger Conditions
///
/// | Field | Default | When it queues |
/// |---|---|---|
/// | `enqueueOnConnectionError` | `true` | No network / DNS failure / socket reset |
/// | `enqueueOnTimeout` | `true` | Connect / receive / send timeout exceeded |
/// | `enqueueOnServerError` | `false` | All HTTP 5xx responses |
/// | `enqueueOnStatusCodes` | `[]` | Specific HTTP status codes (e.g. `[502, 503, 504, 429]`) |
///
/// ## Removal Conditions
///
/// `removeWhen` lists the HTTP status codes that mark a successful sync and
/// remove the entry from the queue. For complex logic (e.g. inspect the body),
/// implement `RestQueueResolver` and pass it to `queue.flush(resolver: ...)`.
///
/// ## Cannot be combined with `@SSE`
///
/// `@ResilientQueue` is meaningless on streaming connections; the generator
/// rejects that combination at build time.
class ResilientQueue {
  /// Creates a resilient queue annotation.
  const ResilientQueue({
    this.removeWhen = const <int>[200, 201, 202, 204],
    this.enqueueOnConnectionError = true,
    this.enqueueOnTimeout = true,
    this.enqueueOnServerError = false,
    this.enqueueOnStatusCodes = const <int>[],
  });

  /// HTTP status codes that mean "sync succeeded — remove from queue".
  final List<int> removeWhen;

  /// Queue the request when the network connection is unavailable.
  final bool enqueueOnConnectionError;

  /// Queue the request when the request times out.
  final bool enqueueOnTimeout;

  /// Queue the request when the server returns any 5xx error.
  final bool enqueueOnServerError;

  /// Specific HTTP status codes (e.g. `[502, 503, 504, 429]`) that trigger queueing.
  final List<int> enqueueOnStatusCodes;
}

/// Backward compatible alias for [ResilientQueue].
typedef OfflineQueue = ResilientQueue;
