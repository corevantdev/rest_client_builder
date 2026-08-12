/// Reports transfer progress for uploads or downloads.
///
/// [count] is the number of bytes transferred so far. [total] is the expected
/// total, or `-1` when unknown.
typedef RestProgressCallback = void Function(int count, int total);

/// Optional object-oriented progress listener.
///
/// Prefer [RestProgressCallback] on [RestRequest] for simple cases.
abstract interface class RestProgressListener {
  /// Called when transfer progress updates.
  void onProgress(int count, int total);
}
