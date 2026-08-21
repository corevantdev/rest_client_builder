import 'package:meta/meta_meta.dart';

/// Enables response caching for an API method or class.
///
/// Cached responses are stored in memory and returned immediately for requests
/// with identical URLs until the duration expires.
@Target({TargetKind.classType, TargetKind.method})
class Cache {
  /// Creates a cache annotation.
  ///
  /// [duration] specifies the cache TTL (Time-To-Live).
  /// Default is 5 minutes.
  const Cache({this.duration = const Duration(minutes: 5)});

  /// Cache duration.
  final Duration duration;
}
