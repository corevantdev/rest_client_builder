// source_gen still exposes the classic element APIs; Element2 migration comes later.
// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';

import '../../annotations/models/rest_model.dart';
import '../model/generation_models.dart';
import 'library_model_visitor.dart';

/// Default visitor that builds [RestModelClassModel] from analyzer elements.
class DefaultRestModelVisitor implements RestModelVisitor {
  /// Creates a RestModel visitor.
  const DefaultRestModelVisitor();

  static const TypeChecker _restModelChecker = TypeChecker.typeNamed(
    RestModel,
    inPackage: 'rest_client_builder',
  );
  static const TypeChecker _jsonKeyChecker = TypeChecker.typeNamed(
    JsonKey,
    inPackage: 'json_annotation',
  );

  @override
  RestModelClassModel? visitClass(ClassElement element) {
    final annotation = _restModelChecker.firstAnnotationOf(
      element,
      throwOnUnresolved: false,
    );
    if (annotation == null) {
      return null;
    }

    final reader = ConstantReader(annotation);
    final constructor = element.unnamedConstructor;
    if (constructor == null) {
      throw InvalidGenerationSourceError(
        '`@RestModel` class `${element.name}` must declare an unnamed constructor.',
        element: element,
      );
    }

    final fields = <RestModelFieldModel>[
      for (final parameter in constructor.formalParameters)
        _visitParameter(element, parameter),
    ];

    return RestModelClassModel(
      name: element.name ?? '',
      createFactory: reader.read('createFactory').boolValue,
      createToJson: reader.read('createToJson').boolValue,
      explicitToJson: reader.read('explicitToJson').boolValue,
      fields: fields,
    );
  }

  @override
  RestModelFieldModel visitField(FieldElement element) {
    return _buildFieldModel(
      name: element.name ?? '',
      type: element.type,
      annotationHost: element,
    );
  }

  RestModelFieldModel _visitParameter(
    ClassElement clazz,
    FormalParameterElement parameter,
  ) {
    final field = clazz.getField(parameter.name ?? '');
    final annotationHost = _annotationHost(parameter, field);
    return _buildFieldModel(
      name: parameter.name ?? '',
      type: parameter.type,
      annotationHost: annotationHost,
    );
  }

  Element _annotationHost(
    FormalParameterElement parameter,
    FieldElement? field,
  ) {
    if (_jsonKeyChecker.hasAnnotationOf(parameter, throwOnUnresolved: false)) {
      return parameter;
    }
    if (field != null &&
        _jsonKeyChecker.hasAnnotationOf(field, throwOnUnresolved: false)) {
      return field;
    }
    return field ?? parameter;
  }

  RestModelFieldModel _buildFieldModel({
    required String name,
    required DartType type,
    required Element annotationHost,
  }) {
    final jsonKey = _jsonKeyChecker.firstAnnotationOf(
      annotationHost,
      throwOnUnresolved: false,
    );
    final keyReader = jsonKey == null ? null : ConstantReader(jsonKey);

    _rejectCustomConverters(keyReader, annotationHost);

    final ignore = keyReader?.peek('ignore')?.boolValue ?? false;
    final namePeek = keyReader?.peek('name');
    final jsonName = namePeek != null && namePeek.isString
        ? namePeek.stringValue
        : null;
    final defaultValueCode = _defaultValueCode(keyReader?.peek('defaultValue'));
    final typeRef = _resolveTypeRef(type, annotationHost);

    return RestModelFieldModel(
      name: name,
      typeName: type.getDisplayString(),
      jsonType: typeRef.type,
      isNullable: typeRef.isNullable,
      jsonKeyName: jsonName,
      ignore: ignore,
      defaultValueCode: defaultValueCode,
    );
  }

  void _rejectCustomConverters(ConstantReader? keyReader, Element host) {
    if (keyReader == null) {
      return;
    }
    for (final field in ['fromJson', 'toJson', 'readValue']) {
      final value = keyReader.peek(field);
      if (value != null && !value.isNull) {
        throw InvalidGenerationSourceError(
          '`@JsonKey.$field` is not supported. '
          'rest_client_builder does not generate custom converters.',
          element: host,
        );
      }
    }
  }

  RestJsonTypeRef _resolveTypeRef(DartType type, Element host) {
    return RestJsonTypeRef(
      _resolveJsonType(type, host),
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
    );
  }

  RestJsonType _resolveJsonType(DartType type, Element host) {
    if (type is DynamicType || type.isDartCoreNull) {
      return const RestPrimitiveJsonType(RestPrimitiveKind.dynamic_);
    }
    if (type.isDartCoreString) {
      return const RestPrimitiveJsonType(RestPrimitiveKind.string);
    }
    if (type.isDartCoreInt) {
      return const RestPrimitiveJsonType(RestPrimitiveKind.int_);
    }
    if (type.isDartCoreDouble) {
      return const RestPrimitiveJsonType(RestPrimitiveKind.double_);
    }
    if (type.isDartCoreNum) {
      return const RestPrimitiveJsonType(RestPrimitiveKind.num_);
    }
    if (type.isDartCoreBool) {
      return const RestPrimitiveJsonType(RestPrimitiveKind.bool_);
    }
    if (type.isDartCoreObject) {
      return const RestPrimitiveJsonType(RestPrimitiveKind.object);
    }
    if (_isDateTime(type)) {
      return const RestDateTimeJsonType();
    }
    if (type.isDartCoreList) {
      final arg = (type as InterfaceType).typeArguments.single;
      return RestListJsonType(_resolveTypeRef(arg, host));
    }
    if (type.isDartCoreMap) {
      final args = (type as InterfaceType).typeArguments;
      final keyType = args[0];
      final valueType = args[1];
      if (!keyType.isDartCoreString) {
        throw InvalidGenerationSourceError(
          'Map keys must be `String` for JSON serialization '
          '(found `${keyType.getDisplayString()}`).',
          element: host,
        );
      }
      return RestMapJsonType(_resolveTypeRef(valueType, host));
    }

    final element = type.element;
    if (element is EnumElement) {
      return RestEnumJsonType(element.name ?? '');
    }
    if (element is ClassElement) {
      return RestNestedJsonType(element.name ?? '');
    }

    throw InvalidGenerationSourceError(
      'Unsupported RestModel field type `${type.getDisplayString()}`.',
      element: host,
    );
  }

  bool _isDateTime(DartType type) {
    final element = type.element;
    return element != null &&
        element.name == 'DateTime' &&
        (element.library?.isDartCore ?? false);
  }

  String? _defaultValueCode(ConstantReader? reader) {
    if (reader == null || reader.isNull) {
      return null;
    }
    if (reader.isString) {
      return _stringLiteral(reader.stringValue);
    }
    if (reader.isBool) {
      return reader.boolValue.toString();
    }
    if (reader.isInt) {
      return reader.intValue.toString();
    }
    if (reader.isDouble) {
      return reader.doubleValue.toString();
    }
    if (reader.isList) {
      final values = reader.listValue
          .map((value) => _defaultValueCode(ConstantReader(value)))
          .join(', ');
      return '<dynamic>[$values]';
    }
    if (reader.isMap) {
      final entries = reader.mapValue.entries
          .map((entry) {
            final key = _defaultValueCode(ConstantReader(entry.key!));
            final value = _defaultValueCode(ConstantReader(entry.value!));
            return '$key: $value';
          })
          .join(', ');
      return '<String, dynamic>{$entries}';
    }

    try {
      final revived = reader.revive();
      final accessor = revived.accessor;
      if (accessor.isNotEmpty) {
        final typeName = revived.source.fragment;
        if (typeName.isNotEmpty) {
          return '$typeName.$accessor';
        }
        return accessor;
      }
    } on Object {
      // Fall through.
    }

    throw InvalidGenerationSourceError(
      'Unsupported `@JsonKey(defaultValue: …)` literal.',
    );
  }

  String _stringLiteral(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t')
        .replaceAll('\$', r'\$');
    return "'$escaped'";
  }
}
