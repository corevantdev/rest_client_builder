/// A structured, transport-agnostic error used by [Failure] and core helpers.
///
/// [RestError] carries a human-readable [message] plus optional machine-readable
/// metadata. It does not depend on any HTTP client.
class RestError implements Exception {
  /// Creates a [RestError].
  const RestError({
    required this.message,
    this.code,
    this.statusCode,
    this.cause,
    this.stackTrace,
    this.details,
  });

  /// Human-readable description of what went wrong.
  final String message;

  /// Optional machine-readable error code (e.g. `'validation'`, `'timeout'`).
  final String? code;

  /// Optional HTTP-like status code when known. Not tied to any client.
  final int? statusCode;

  /// Underlying cause, if any.
  final Object? cause;

  /// Stack trace associated with [cause], if available.
  final StackTrace? stackTrace;

  /// Arbitrary structured details for diagnostics or UI mapping.
  final Map<String, Object?>? details;

  /// Generic unknown failure.
  factory RestError.unknown(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) {
    return RestError(
      message: message,
      code: RestErrorCodes.unknown,
      cause: cause,
      stackTrace: stackTrace,
      details: details,
    );
  }

  /// Validation / input failure.
  factory RestError.validation(
    String message, {
    Map<String, Object?>? details,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return RestError(
      message: message,
      code: RestErrorCodes.validation,
      statusCode: 400,
      cause: cause,
      stackTrace: stackTrace,
      details: details,
    );
  }

  /// Operation timed out.
  factory RestError.timeout(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) {
    return RestError(
      message: message,
      code: RestErrorCodes.timeout,
      statusCode: 408,
      cause: cause,
      stackTrace: stackTrace,
      details: details,
    );
  }

  /// Operation was cancelled.
  factory RestError.cancelled(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) {
    return RestError(
      message: message,
      code: RestErrorCodes.cancelled,
      cause: cause,
      stackTrace: stackTrace,
      details: details,
    );
  }

  /// Transport / connection failure.
  factory RestError.connection(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) {
    return RestError(
      message: message,
      code: RestErrorCodes.connection,
      cause: cause,
      stackTrace: stackTrace,
      details: details,
    );
  }

  /// HTTP response failure (non-success status).
  factory RestError.http(
    String message, {
    required int statusCode,
    Object? cause,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) {
    return RestError(
      message: message,
      code: RestErrorCodes.http,
      statusCode: statusCode,
      cause: cause,
      stackTrace: stackTrace,
      details: details,
    );
  }

  /// JSON serialization or deserialization failure.
  factory RestError.serialization(
    String message, {
    Object? cause,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) {
    return RestError(
      message: message,
      code: RestErrorCodes.serialization,
      cause: cause,
      stackTrace: stackTrace,
      details: details,
    );
  }

  /// Wraps an arbitrary [error] into a [RestError].
  factory RestError.fromException(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (error is RestError) {
      return error;
    }
    return RestError.unknown(
      error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Returns a copy with selected fields replaced.
  RestError copyWith({
    String? message,
    String? code,
    int? statusCode,
    Object? cause,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) {
    return RestError(
      message: message ?? this.message,
      code: code ?? this.code,
      statusCode: statusCode ?? this.statusCode,
      cause: cause ?? this.cause,
      stackTrace: stackTrace ?? this.stackTrace,
      details: details ?? this.details,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('RestError(message: $message');
    if (code != null) {
      buffer.write(', code: $code');
    }
    if (statusCode != null) {
      buffer.write(', statusCode: $statusCode');
    }
    if (cause != null) {
      buffer.write(', cause: $cause');
    }
    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RestError &&
        other.message == message &&
        other.code == code &&
        other.statusCode == statusCode &&
        other.cause == cause &&
        _mapEquals(other.details, details);
  }

  @override
  int get hashCode => Object.hash(
        message,
        code,
        statusCode,
        cause,
        _mapHash(details),
      );
}

/// Well-known [RestError.code] values used by factory constructors.
abstract final class RestErrorCodes {
  /// Unclassified failure.
  static const String unknown = 'unknown';

  /// Input or contract validation failure.
  static const String validation = 'validation';

  /// Deadline exceeded.
  static const String timeout = 'timeout';

  /// Caller cancelled the operation.
  static const String cancelled = 'cancelled';

  /// Network / connection failure.
  static const String connection = 'connection';

  /// HTTP non-success status.
  static const String http = 'http';

  /// JSON serialization or deserialization failure.
  static const String serialization = 'serialization';
}

bool _mapEquals(Map<String, Object?>? a, Map<String, Object?>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _mapHash(Map<String, Object?>? map) {
  if (map == null) {
    return 0;
  }
  return Object.hashAllUnordered(
    map.entries.map((e) => Object.hash(e.key, e.value)),
  );
}
