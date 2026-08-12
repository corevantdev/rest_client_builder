/// String helpers shared by core and future runtime layers.
abstract final class StringUtils {
  /// Whether [value] is `null` or empty / whitespace-only.
  static bool isNullOrBlank(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Whether [value] is non-null and contains non-whitespace characters.
  static bool isNotBlank(String? value) => !isNullOrBlank(value);

  /// Returns [value] trimmed, or `null` when blank.
  static String? nullIfBlank(String? value) {
    if (isNullOrBlank(value)) {
      return null;
    }
    return value!.trim();
  }

  /// Returns [fallback] when [value] is blank; otherwise trimmed [value].
  static String defaultIfBlank(String? value, String fallback) {
    return nullIfBlank(value) ?? fallback;
  }

  /// Capitalizes the first character of [value].
  static String capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    if (value.length == 1) {
      return value.toUpperCase();
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  /// Joins URL path segments, collapsing duplicate slashes (except after `://`).
  static String joinPath(Iterable<String> segments) {
    final parts = <String>[];
    for (final segment in segments) {
      final trimmed = segment.trim();
      if (trimmed.isEmpty || trimmed == '/') {
        continue;
      }
      parts.add(trimmed.replaceAll(RegExp(r'^/+|/+$'), ''));
    }
    if (parts.isEmpty) {
      return '/';
    }

    final joined = parts.join('/');
    if (segments.isNotEmpty && segments.first.trim().startsWith('/')) {
      return '/$joined';
    }
    return joined;
  }

  /// Ensures [value] starts with a leading `/` when non-empty.
  static String ensureLeadingSlash(String value) {
    if (value.isEmpty) {
      return '/';
    }
    return value.startsWith('/') ? value : '/$value';
  }

  /// Removes a trailing `/` unless [value] is exactly `/`.
  static String removeTrailingSlash(String value) {
    if (value.length > 1 && value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
