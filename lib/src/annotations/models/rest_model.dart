import 'package:meta/meta_meta.dart';

/// Marks a class as a REST data model eligible for (de)serialization helpers.
///
/// Field-level JSON naming and defaults use [`JsonKey`] from
/// `package:json_annotation` — this package does not define a custom field
/// annotation.
///
/// Example:
/// ```dart
/// @RestModel()
/// class User {
///   const User({required this.id, required this.name});
///
///   final String id;
///
///   @JsonKey(name: 'user_name')
///   final String name;
/// }
/// ```
@Target({TargetKind.classType})
class RestModel {
  /// Creates a REST model annotation.
  const RestModel({
    this.createFactory = true,
    this.createToJson = true,
    this.explicitToJson = true,
  });

  /// Whether a `fromJson` factory should be generated.
  final bool createFactory;

  /// Whether a `toJson` method should be generated.
  final bool createToJson;

  /// Whether nested models should call `toJson` explicitly.
  final bool explicitToJson;
}
