import '../error/rest_error.dart';
import '../result/rest_result.dart';
import 'string_utils.dart';

/// Validation helpers that return [RestResult] instead of throwing.
abstract final class ValidationUtils {
  /// Succeeds when [value] is non-null.
  static RestResult<T> requireNotNull<T>(
    T? value, {
    String message = 'Expected a non-null value',
    String field = 'value',
  }) {
    if (value == null) {
      return Failure<T>(
        RestError.validation(
          message,
          details: <String, Object?>{'field': field},
        ),
      );
    }
    return Success<T>(value);
  }

  /// Succeeds when [value] is non-blank.
  static RestResult<String> requireNotBlank(
    String? value, {
    String message = 'Expected a non-blank string',
    String field = 'value',
  }) {
    if (StringUtils.isNullOrBlank(value)) {
      return Failure<String>(
        RestError.validation(
          message,
          details: <String, Object?>{'field': field},
        ),
      );
    }
    return Success<String>(value!.trim());
  }

  /// Succeeds when [condition] is true.
  static RestResult<void> require(
    bool condition, {
    required String message,
    Map<String, Object?>? details,
  }) {
    if (!condition) {
      return Failure<void>(
        RestError.validation(message, details: details),
      );
    }
    return const Success<void>(null);
  }

  /// Succeeds when [value] is within [[min], [max]] (inclusive).
  static RestResult<int> requireInRange(
    int value, {
    required int min,
    required int max,
    String field = 'value',
  }) {
    if (value < min || value > max) {
      return Failure<int>(
        RestError.validation(
          'Expected $field in range [$min, $max], got $value',
          details: <String, Object?>{
            'field': field,
            'min': min,
            'max': max,
            'value': value,
          },
        ),
      );
    }
    return Success<int>(value);
  }
}
