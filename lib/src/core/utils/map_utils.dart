/// Map helpers for headers, query maps, and JSON-like structures.
abstract final class MapUtils {
  /// Returns a new map without entries whose values are `null`.
  static Map<String, V> compactNulls<V>(Map<String, V?> source) {
    final result = <String, V>{};
    source.forEach((key, value) {
      if (value != null) {
        result[key] = value as V;
      }
    });
    return result;
  }

  /// Returns a new map without blank string values.
  static Map<String, String> compactBlank(Map<String, String?> source) {
    final result = <String, String>{};
    source.forEach((key, value) {
      if (value != null && value.trim().isNotEmpty) {
        result[key] = value;
      }
    });
    return result;
  }

  /// Shallow-merges [overrides] onto [base]. Later keys win.
  static Map<String, V> merge<V>(
    Map<String, V> base,
    Map<String, V> overrides,
  ) {
    return <String, V>{...base, ...overrides};
  }

  /// Converts values to strings suitable for query parameters.
  ///
  /// `null` values are omitted. Non-string values use `toString()`.
  static Map<String, String> stringifyValues(Map<String, Object?> source) {
    final result = <String, String>{};
    source.forEach((key, value) {
      if (value == null) {
        return;
      }
      result[key] = value.toString();
    });
    return result;
  }

  /// Reads [key] as [T], or returns `null` when missing / wrong type.
  static T? getAs<T>(Map<String, Object?> source, String key) {
    final value = source[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Whether [source] is null or empty.
  static bool isNullOrEmpty(Map<Object?, Object?>? source) {
    return source == null || source.isEmpty;
  }
}
