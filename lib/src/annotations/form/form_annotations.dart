import 'package:meta/meta_meta.dart';

/// Marks a method as an `application/x-www-form-urlencoded` request.
@Target({TargetKind.method})
class FormUrlEncoded {
  /// Creates a form-urlencoded annotation.
  const FormUrlEncoded();
}

/// Binds a method parameter to a form field.
@Target({TargetKind.parameter})
class Field {
  /// Creates a field annotation.
  ///
  /// When [name] is omitted, the Dart parameter name is used.
  const Field([this.name]);

  /// Form field name.
  final String? name;
}

/// Binds a `Map` parameter as multiple form fields.
@Target({TargetKind.parameter})
class FieldMap {
  /// Creates a field-map annotation.
  const FieldMap();
}
