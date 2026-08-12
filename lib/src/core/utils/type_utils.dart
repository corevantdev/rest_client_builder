/// Lightweight type helpers for diagnostics and safe casting.
abstract final class TypeUtils {
  /// Runtime type name of [value], or `'null'`.
  static String typeName(Object? value) {
    return value == null ? 'null' : value.runtimeType.toString();
  }

  /// Casts [value] to [T], or returns `null` when the cast is not possible.
  static T? asOrNull<T>(Object? value) {
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Whether [value] is a JSON-primitive (`null`, [bool], [num], [String]).
  static bool isJsonPrimitive(Object? value) {
    return value == null || value is bool || value is num || value is String;
  }

  /// Whether [value] is a JSON-compatible structure (primitives, lists, maps).
  static bool isJsonCompatible(Object? value) {
    if (isJsonPrimitive(value)) {
      return true;
    }
    if (value is List) {
      return value.every(isJsonCompatible);
    }
    if (value is Map) {
      return value.keys.every((key) => key is String) &&
          value.values.every(isJsonCompatible);
    }
    return false;
  }
}
