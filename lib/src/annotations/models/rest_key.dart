import 'package:meta/meta_meta.dart';

/// Declares multiple JSON key aliases for a field on an `@RestModel` class.
///
/// When deserializing, the generator tries each key in [keys] order and uses
/// the **first non-null** value found. This is useful when the same logical
/// field arrives under different names across API versions or backends
/// (e.g. REST uses `id` while MongoDB sends `_id`).
///
/// Example:
/// ```dart
/// @RestModel()
/// class User {
///   const User({required this.id, required this.name});
///
///   /// Accepts 'id', '_id', or 'userId' — whichever the server sends.
///   @RestKey(['id', '_id', 'userId'])
///   final String id;
///
///   final String name;
/// }
/// ```
///
/// `@RestKey` can be used alongside `@JsonKey` for the `ignore`,
/// `defaultValue`, and other attributes — `@RestKey` only controls the
/// **deserialization key lookup**; `@JsonKey(name:)` is ignored when
/// `@RestKey` is present on the same field.
@Target({TargetKind.field, TargetKind.parameter})
class RestKey {
  /// Creates a multi-key field annotation.
  ///
  /// [keys] must contain at least one entry. Keys are tried left-to-right;
  /// the first key whose value in the JSON map is non-null is used.
  const RestKey(this.keys);

  /// Ordered list of JSON keys to try when deserializing.
  final List<String> keys;
}
