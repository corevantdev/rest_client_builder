import 'package:meta/meta_meta.dart';

/// Enables response caching for an API method or class.
///
/// Cached responses are stored in memory and returned immediately for requests
/// with identical URLs until the duration expires.
@Target({TargetKind.classType, TargetKind.method})
class Cache {
  /// Creates a cache annotation.
  ///
  /// [durationMs] specifies the cache TTL (Time-To-Live) in milliseconds.
  /// Default is 300,000 ms (5 minutes).
  const Cache({this.durationMs = 300000});

  /// Cache duration in milliseconds.
  final int durationMs;
}
