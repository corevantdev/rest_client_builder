/// Serializable JSON type graph used by RestModel generation.
sealed class RestJsonType {
  /// Creates a JSON type node.
  const RestJsonType();

  /// Dart type display string without nullability (e.g. `String`, `List<User>`).
  String get displayName;
}

/// A [RestJsonType] plus nullability.
class RestJsonTypeRef {
  /// Creates a type reference.
  const RestJsonTypeRef(this.type, {this.isNullable = false});

  /// Underlying JSON type.
  final RestJsonType type;

  /// Whether the value may be `null`.
  final bool isNullable;

  /// Display name including a trailing `?` when nullable.
  String get displayName =>
      isNullable ? '${type.displayName}?' : type.displayName;
}

/// JSON primitive / dynamic values.
enum RestPrimitiveKind {
  /// `String`
  string,

  /// `int`
  int_,

  /// `double`
  double_,

  /// `num`
  num_,

  /// `bool`
  bool_,

  /// `dynamic`
  dynamic_,

  /// `Object`
  object,
}

/// Primitive JSON-compatible type.
class RestPrimitiveJsonType extends RestJsonType {
  /// Creates a primitive type.
  const RestPrimitiveJsonType(this.kind);

  /// Primitive kind.
  final RestPrimitiveKind kind;

  @override
  String get displayName => switch (kind) {
    RestPrimitiveKind.string => 'String',
    RestPrimitiveKind.int_ => 'int',
    RestPrimitiveKind.double_ => 'double',
    RestPrimitiveKind.num_ => 'num',
    RestPrimitiveKind.bool_ => 'bool',
    RestPrimitiveKind.dynamic_ => 'dynamic',
    RestPrimitiveKind.object => 'Object',
  };
}

/// `DateTime` encoded as ISO-8601 strings.
class RestDateTimeJsonType extends RestJsonType {
  /// Creates a DateTime type.
  const RestDateTimeJsonType();

  @override
  String get displayName => 'DateTime';
}

/// Enum encoded via `.name` / `values.byName`.
class RestEnumJsonType extends RestJsonType {
  /// Creates an enum type.
  const RestEnumJsonType(this.enumName);

  /// Enum type name.
  final String enumName;

  @override
  String get displayName => enumName;
}

/// Nested model with `fromJson` / `toJson`.
class RestNestedJsonType extends RestJsonType {
  /// Creates a nested model type.
  const RestNestedJsonType(this.className);

  /// Nested class name.
  final String className;

  @override
  String get displayName => className;
}

/// `List<T>` type.
class RestListJsonType extends RestJsonType {
  /// Creates a list type.
  const RestListJsonType(this.itemType);

  /// Element type.
  final RestJsonTypeRef itemType;

  @override
  String get displayName => 'List<${itemType.displayName}>';
}

/// `Map<String, V>` type.
class RestMapJsonType extends RestJsonType {
  /// Creates a map type.
  const RestMapJsonType(this.valueType);

  /// Value type. Keys are always `String` for JSON objects.
  final RestJsonTypeRef valueType;

  @override
  String get displayName => 'Map<String, ${valueType.displayName}>';
}
