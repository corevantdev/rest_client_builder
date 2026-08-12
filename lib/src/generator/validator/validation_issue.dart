/// Severity of a generator validation finding.
enum ValidationSeverity {
  /// Informational note; generation may continue.
  info,

  /// Suspicious usage; generation may continue.
  warning,

  /// Invalid annotation usage; generation should not emit code.
  error,
}

/// A single validation finding produced while checking generator models.
class ValidationIssue {
  /// Creates a validation issue.
  const ValidationIssue({
    required this.message,
    required this.severity,
    this.elementName,
  });

  /// Human-readable description.
  final String message;

  /// Severity of the issue.
  final ValidationSeverity severity;

  /// Optional related element name (class, method, parameter).
  final String? elementName;

  @override
  String toString() {
    final target = elementName == null ? '' : ' ($elementName)';
    return '${severity.name}: $message$target';
  }
}
