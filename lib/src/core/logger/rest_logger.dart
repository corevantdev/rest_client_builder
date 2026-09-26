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

/// [RestLogger] that writes to the console via `print` with ANSI color formatting.
class ConsoleRestLogger extends RestLogger {
  /// Creates a console logger with the given minimum [level] and color support.
  const ConsoleRestLogger({
    this.level = RestLogLevel.debug,
    this.useColors = true,
  });

  @override
  final RestLogLevel level;

  /// Whether to format console output with ANSI color codes.
  final bool useColors;

  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _cyan = '\x1B[36m';
  static const _gray = '\x1B[90m';

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

    final color = _levelColor(level);
    final prefix = useColors
        ? '$_gray[rest_client_builder]$_reset$color[${level.name}]$_reset'
        : '[rest_client_builder][${level.name}]';

    final buffer = StringBuffer('$prefix $message');
    if (error != null) {
      buffer.write(useColors ? ' $_red| error: $error$_reset' : ' | error: $error');
    }
    // ignore: avoid_print
    print(buffer.toString());
    if (stackTrace != null) {
      // ignore: avoid_print
      print(stackTrace);
    }
  }

  String _levelColor(RestLogLevel level) {
    if (!useColors) return '';
    switch (level) {
      case RestLogLevel.error:
        return _red;
      case RestLogLevel.warning:
        return _yellow;
      case RestLogLevel.info:
        return _green;
      case RestLogLevel.debug:
        return _cyan;
      case RestLogLevel.verbose:
        return _gray;
      case RestLogLevel.none:
        return '';
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
