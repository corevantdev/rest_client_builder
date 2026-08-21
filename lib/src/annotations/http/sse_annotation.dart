import 'package:meta/meta_meta.dart';

/// Marks an abstract REST API method as a Server-Sent Events (SSE) endpoint.
///
/// Methods annotated with `@SSE` must return `Stream<SSEEvent>` directly
/// (not wrapped in `Future<RestResult<...>>`), since SSE is a persistent
/// long-lived connection rather than a one-shot request/response.
///
/// ```dart
/// @SSE()
/// @GET('/notifications/stream')
/// Stream<SSEEvent> watchNotifications();
/// ```
///
/// The generator emits `_client.executeSSE(request)` for annotated methods.
/// The runtime uses Dio's `ResponseType.stream` under the hood and pipes the
/// raw bytes through the SSE text-frame parser.
///
/// [reconnectDelay] is a hint embedded in the request extras. The actual
/// reconnect logic must be implemented in a `RestInterceptor` or by the
/// caller — the package does not manage reconnect loops automatically.
@Target({TargetKind.method})
class SSE {
  /// Creates an SSE annotation.
  const SSE({this.reconnectDelay = const Duration(seconds: 3)});

  /// Suggested reconnect delay (for client retry logic).
  final Duration reconnectDelay;
}

