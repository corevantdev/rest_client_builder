/// A single event received over a Server-Sent Events (SSE) connection.
///
/// Maps directly to the SSE wire-format fields defined in the
/// [HTML Living Standard §9.2](https://html.spec.whatwg.org/multipage/server-sent-events.html).
///
/// | Wire field | Dart field | Default |
/// |---|---|---|
/// | `id: <value>` | [id] | `null` |
/// | `event: <type>` | [event] | `'message'` |
/// | `data: <text>` | [data] | `''` |
/// | `retry: <ms>` | [retry] | `null` |
///
/// Multiple `data:` lines in a single frame are joined with `\n`.
class SSEEvent {
  /// Creates an SSE event.
  const SSEEvent({
    this.id,
    this.event,
    required this.data,
    this.retry,
  });

  /// Last event ID string (`id:` field). `null` if not provided.
  final String? id;

  /// Event type (`event:` field). Defaults to `'message'` per spec when
  /// `null`.
  final String? event;

  /// Event payload. Multiple `data:` lines are concatenated with `\n`.
  final String data;

  /// Reconnect timeout hint in milliseconds (`retry:` field). `null` if not
  /// present.
  final int? retry;

  @override
  String toString() =>
      'SSEEvent(id: $id, event: ${event ?? "message"}, data: $data'
      '${retry != null ? ", retry: $retry" : ""})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SSEEvent &&
          other.id == id &&
          other.event == event &&
          other.data == data &&
          other.retry == retry);

  @override
  int get hashCode => Object.hash(id, event, data, retry);
}
