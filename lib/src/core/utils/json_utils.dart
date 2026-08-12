import 'dart:convert';

import '../error/rest_error.dart';
import '../result/rest_result.dart';

/// JSON encode/decode helpers that return [RestResult] on failure.
///
/// Uses `dart:convert` only — no networking.
abstract final class JsonUtils {
  /// Encodes [value] to a JSON string.
  static RestResult<String> encode(Object? value) {
    try {
      return Success<String>(jsonEncode(value));
    } on Object catch (error, stackTrace) {
      return Failure<String>(
        RestError.validation(
          'Failed to encode JSON',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Decodes [source] into a JSON value.
  static RestResult<Object?> decode(String source) {
    try {
      return Success<Object?>(jsonDecode(source));
    } on Object catch (error, stackTrace) {
      return Failure<Object?>(
        RestError.validation(
          'Failed to decode JSON',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Decodes [source] and requires a [Map] root.
  static RestResult<Map<String, Object?>> decodeMap(String source) {
    return decode(source).flatMap((value) {
      if (value is Map<String, dynamic>) {
        return Success<Map<String, Object?>>(
          Map<String, Object?>.from(value),
        );
      }
      if (value is Map) {
        return Success<Map<String, Object?>>(
          value.map(
            (key, dynamic item) => MapEntry(key.toString(), item as Object?),
          ),
        );
      }
      return Failure<Map<String, Object?>>(
        RestError.validation(
          'Expected a JSON object',
          details: <String, Object?>{'runtimeType': value.runtimeType.toString()},
        ),
      );
    });
  }

  /// Decodes [source] and requires a [List] root.
  static RestResult<List<Object?>> decodeList(String source) {
    return decode(source).flatMap((value) {
      if (value is List) {
        return Success<List<Object?>>(List<Object?>.from(value));
      }
      return Failure<List<Object?>>(
        RestError.validation(
          'Expected a JSON array',
          details: <String, Object?>{'runtimeType': value.runtimeType.toString()},
        ),
      );
    });
  }
}
