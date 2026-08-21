import 'dart:async';
import 'dart:convert';

import 'sse_event.dart';

/// Stateful SSE text-frame parser.
///
/// Parses a raw `Stream<List<int>>` (e.g. from Dio `ResponseType.stream`) into
/// `Stream<SSEEvent>` according to the HTML Living Standard §9.2 SSE spec.
///
/// **Supported fields:** `data:`, `event:`, `id:`, `retry:`, `: comment` (ignored).
/// Multi-line `data:` lines are concatenated with `\n`.
/// A blank line (empty line) terminates a frame and emits an [SSEEvent].
///
/// Usage:
/// ```dart
/// final eventStream = SseParser.parse(rawByteStream);
/// await for (final event in eventStream) {
///   print(event.data);
/// }
/// ```
abstract final class SseParser {
  /// Parses [byteStream] into a stream of [SSEEvent]s.
  ///
  /// The returned stream closes when [byteStream] closes. Errors from
  /// [byteStream] are forwarded unchanged.
  static Stream<SSEEvent> parse(Stream<List<int>> byteStream) {
    final controller = StreamController<SSEEvent>();

    final buffer = StringBuffer();
    var id = <String>[];
    var event = <String>[];
    final data = <String>[];
    var retry = <int>[];

    void dispatch() {
      if (data.isEmpty) return;
      final dataStr = data.join('\n');
      final event0 = event.isNotEmpty ? event.last : null;
      final id0 = id.isNotEmpty ? id.last : null;
      final retry0 = retry.isNotEmpty ? Duration(milliseconds: retry.last) : null;
      controller.add(SSEEvent(id: id0, event: event0, data: dataStr, retry: retry0));
      data.clear();
      event.clear();
      // id and retry are intentionally NOT cleared between frames per spec.
    }

    void processLine(String line) {
      if (line.isEmpty) {
        // Blank line → dispatch current frame.
        dispatch();
        return;
      }
      if (line.startsWith(':')) {
        // Comment — ignore.
        return;
      }
      final colonIdx = line.indexOf(':');
      String field;
      String value;
      if (colonIdx == -1) {
        field = line;
        value = '';
      } else {
        field = line.substring(0, colonIdx);
        value = line.substring(colonIdx + 1);
        // Spec: optional single leading space after colon.
        if (value.startsWith(' ')) {
          value = value.substring(1);
        }
      }
      switch (field) {
        case 'data':
          data.add(value);
        case 'event':
          event = [value];
        case 'id':
          if (!value.contains('\x00')) {
            id = [value];
          }
        case 'retry':
          final ms = int.tryParse(value);
          if (ms != null) {
            retry = [ms];
          }
        default:
          // Unknown field — ignore per spec.
          break;
      }
    }

    byteStream.listen(
      (chunk) {
        // Decode the chunk and append to the rolling buffer.
        final decoded = utf8.decode(chunk, allowMalformed: true);
        buffer.write(decoded);

        // Process complete lines from the buffer.
        final full = buffer.toString();
        final lines = full.split('\n');

        // The last element may be an incomplete line — keep it in the buffer.
        buffer.clear();
        buffer.write(lines.removeLast());

        for (final line in lines) {
          // Normalize CRLF → LF.
          processLine(line.endsWith('\r') ? line.substring(0, line.length - 1) : line);
        }
      },
      onError: controller.addError,
      onDone: () {
        // Flush any remaining content in buffer as a final line.
        final remaining = buffer.toString();
        if (remaining.isNotEmpty) {
          processLine(remaining.endsWith('\r')
              ? remaining.substring(0, remaining.length - 1)
              : remaining);
        }
        // Dispatch any partial frame accumulated before stream closed.
        dispatch();
        controller.close();
      },
      cancelOnError: false,
    );

    return controller.stream;
  }
}
