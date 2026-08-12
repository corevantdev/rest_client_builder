import '../response/rest_response.dart';

class _CacheEntry {
  _CacheEntry(this.response, this.expiresAt);

  final RestResponse response;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Process-wide in-memory response cache for `@Cache` annotated endpoints.
abstract final class RestResponseCache {
  static final Map<String, _CacheEntry> _store = <String, _CacheEntry>{};

  /// Returns cached [RestResponse] if present and not expired.
  static RestResponse? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.response;
  }

  /// Stores [response] under [key] for [durationMs] milliseconds.
  static void put(String key, RestResponse response, int durationMs) {
    final expiresAt = DateTime.now().add(Duration(milliseconds: durationMs));
    _store[key] = _CacheEntry(response, expiresAt);
  }

  /// Removes a specific cached entry.
  static void remove(String key) => _store.remove(key);

  /// Clears all cached responses.
  static void clear() => _store.clear();
}
