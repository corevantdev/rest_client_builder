/// Severity levels for [RestLogger].
enum RestLogLevel {
  /// Disable all logging.
  none(0),

  /// Errors only.
  error(1),

  /// Warnings and errors.
  warning(2),

  /// Informational messages and above.
  info(3),

  /// Debug diagnostics and above.
  debug(4),

  /// Most verbose tracing.
  verbose(5);

  /// Creates a [RestLogLevel] with a comparable [value].
  const RestLogLevel(this.value);

  /// Numeric rank used for threshold comparisons.
  final int value;

  /// Whether this level is enabled when the logger threshold is [minimum].
  bool isEnabled(RestLogLevel minimum) => value <= minimum.value && value > 0;
}

/// Abstract logger contract used by core and future runtime layers.
///
/// Implementations must not perform networking. Use [NoOpRestLogger] in tests
/// or [ConsoleRestLogger] for local diagnostics.
abstract class RestLogger {
  /// Creates a [RestLogger].
  const RestLogger();

  /// Minimum level that will be emitted.
  RestLogLevel get level;

  /// Logs [message] at [level] when enabled.
  void log(
    RestLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  /// Logs an error-level message.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(RestLogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  /// Logs a warning-level message.
  void warning(String message) {
    log(RestLogLevel.warning, message);
  }

  /// Logs an info-level message.
  void info(String message) {
    log(RestLogLevel.info, message);
  }

  /// Logs a debug-level message.
  void debug(String message) {
    log(RestLogLevel.debug, message);
  }

  /// Logs a verbose-level message.
  void verbose(String message) {
    log(RestLogLevel.verbose, message);
  }
}

/// [RestLogger] that writes to the console via `print`.
class ConsoleRestLogger extends RestLogger {
  /// Creates a console logger with the given minimum [level].
  const ConsoleRestLogger({this.level = RestLogLevel.info});

  @override
  final RestLogLevel level;

  @override
  void log(
    RestLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level == RestLogLevel.none || !level.isEnabled(this.level)) {
      return;
    }

    final buffer = StringBuffer('[rest_client_builder][${level.name}] $message');
    if (error != null) {
      buffer.write(' | error: $error');
    }
    // ignore: avoid_print
    print(buffer.toString());
    if (stackTrace != null) {
      // ignore: avoid_print
      print(stackTrace);
    }
  }
}

/// [RestLogger] that discards all messages.
class NoOpRestLogger extends RestLogger {
  /// Creates a no-op logger.
  const NoOpRestLogger();

  @override
  RestLogLevel get level => RestLogLevel.none;

  @override
  void log(
    RestLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Intentionally empty.
  }
}
