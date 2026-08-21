/// Per-request overrides emitted from API and endpoint annotations.
abstract final class RestExecutionExtras {
  /// Extra key for a retry-attempt override.
  static const retryMaxAttempts = 'rest.retryMaxAttempts';

  /// Extra key for a retry-delay override.
  static const retryDelay = 'rest.retryDelay';

  /// Extra key for retryable HTTP status codes.
  static const retryStatusCodes = 'rest.retryStatusCodes';

  /// Extra key for a logging override.
  static const enableLog = 'rest.enableLog';
}

/// Resolved annotation values for one request.
class RestExecutionOptions {
  /// Creates resolved execution options.
  const RestExecutionOptions({
    this.retryMaxAttempts,
    this.retryDelay,
    this.retryStatusCodes,
    this.enableLog,
  });

  /// Retry-attempt override.
  final int? retryMaxAttempts;

  /// Retry-delay override.
  final Duration? retryDelay;

  /// Retryable status-code override.
  final List<int>? retryStatusCodes;

  /// Logging override.
  final bool? enableLog;
}

/// Reads execution options from request extras.
RestExecutionOptions readRestExecutionOptions(Map<String, Object?> extras) {
  final codes = extras[RestExecutionExtras.retryStatusCodes];
  final delayMs = extras[RestExecutionExtras.retryDelay] as int?;
  return RestExecutionOptions(
    retryMaxAttempts: extras[RestExecutionExtras.retryMaxAttempts] as int?,
    retryDelay: delayMs != null ? Duration(milliseconds: delayMs) : null,
    retryStatusCodes: codes is List ? codes.cast<int>() : null,
    enableLog: extras[RestExecutionExtras.enableLog] as bool?,
  );
}
