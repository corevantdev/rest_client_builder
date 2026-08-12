/// Per-request overrides emitted from API and endpoint annotations.
abstract final class RestExecutionExtras {
  /// Extra key for a retry-attempt override.
  static const retryMaxAttempts = 'rest.retryMaxAttempts';

  /// Extra key for a retry-delay override.
  static const retryDelayMs = 'rest.retryDelayMs';

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
    this.retryDelayMs,
    this.retryStatusCodes,
    this.enableLog,
  });

  /// Retry-attempt override.
  final int? retryMaxAttempts;

  /// Retry-delay override.
  final int? retryDelayMs;

  /// Retryable status-code override.
  final List<int>? retryStatusCodes;

  /// Logging override.
  final bool? enableLog;
}

/// Reads execution options from request extras.
RestExecutionOptions readRestExecutionOptions(Map<String, Object?> extras) {
  final codes = extras[RestExecutionExtras.retryStatusCodes];
  return RestExecutionOptions(
    retryMaxAttempts: extras[RestExecutionExtras.retryMaxAttempts] as int?,
    retryDelayMs: extras[RestExecutionExtras.retryDelayMs] as int?,
    retryStatusCodes: codes is List ? codes.cast<int>() : null,
    enableLog: extras[RestExecutionExtras.enableLog] as bool?,
  );
}
