import 'package:meta/meta_meta.dart';

/// Marks a REST method to stream the response body instead of buffering it.
///
/// When applied, the generator sets `ResponseType.stream` on the underlying
/// Dio request and the method must return
/// `Future<RestResult<Stream<List<int>>>>`.
///
/// This is useful for large downloads (files, videos, large exports) where
/// loading the entire body into RAM would be expensive.
///
/// ```dart
/// @Streaming()
/// @GET('/files/{id}')
/// Future<RestResult<Stream<List<int>>>> downloadFile(
///   @Path() String id,
/// );
/// ```
@Target({TargetKind.method})
class Streaming {
  /// Creates a Streaming annotation.
  const Streaming();
}

/// Convenience constant for `@Streaming()`.
const streaming = Streaming();
