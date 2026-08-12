import 'package:dart_style/dart_style.dart';

import '../model/generation_models.dart';
import 'source_writer.dart';

/// Writes `_$ModelFromJson` / `_$ModelToJson` helpers for `@RestModel` classes.
class DefaultRestModelWriter implements RestModelWriter {
  /// Creates a RestModel writer.
  const DefaultRestModelWriter();

  static final DartFormatter _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  @override
  String writeModel(RestModelClassModel model) {
    final buffer = StringBuffer();

    if (model.createFactory) {
      buffer.writeln(_fromJsonMethod(model));
      buffer.writeln();
    }
    if (model.createToJson) {
      buffer.writeln(_toJsonMethod(model));
      buffer.writeln();
    }

    // Generate convenience extension for toJson on instances.
    if (model.createToJson) {
      buffer.writeln('''
extension ${model.name}RestModelExtension on ${model.name} {
  Map<String, dynamic> toJson() => rest${model.name}ToJson(this);
}
''');
    }

    final raw = buffer.toString().trimRight();
    if (raw.isEmpty) {
      return '';
    }
    return _formatter.format(raw);
  }

  String _fromJsonMethod(RestModelClassModel model) {
    final args = model.fields
        .map((field) {
          if (field.ignore) {
            if (field.defaultValueCode != null) {
              return '${field.name}: ${field.defaultValueCode}';
            }
            if (field.isNullable) {
              return '${field.name}: null';
            }
            return '${field.name}: null /* invalid ignored non-nullable field */';
          }
          return '${field.name}: ${_fromJsonExpression(field)}';
        })
        .join(',\n    ');

    return '''
${model.name} rest${model.name}FromJson(Map<String, dynamic> json) {
  return ${model.name}(
    $args
  );
}
''';
  }

  String _toJsonMethod(RestModelClassModel model) {
    final entries = model.serializableFields
        .map((field) {
          return "'${_escape(field.jsonName)}': "
              '${_toJsonExpression(field, model.explicitToJson)}';
        })
        .join(',\n  ');

    return '''
Map<String, dynamic> rest${model.name}ToJson(${model.name} instance) {
  return <String, dynamic>{
  $entries
  };
}
''';
  }

  String _fromJsonExpression(RestModelFieldModel field) {
    final key = _escape(field.jsonName);
    final read = "json['$key']";
    if (field.defaultValueCode != null) {
      // Decode as nullable so a missing key can fall back to defaultValue.
      final decoded = _decode(
        read,
        RestJsonTypeRef(field.jsonType, isNullable: true),
      );
      return '$decoded ?? ${field.defaultValueCode}';
    }
    return _decode(
      read,
      RestJsonTypeRef(field.jsonType, isNullable: field.isNullable),
    );
  }

  String _decode(String expression, RestJsonTypeRef typeRef) {
    final type = typeRef.type;
    final nullable = typeRef.isNullable;

    switch (type) {
      case RestPrimitiveJsonType(:final kind):
        return _decodePrimitive(expression, kind, nullable);
      case RestDateTimeJsonType():
        if (nullable) {
          return '$expression == null '
              '? null '
              ': DateTime.parse($expression as String)';
        }
        return 'DateTime.parse($expression as String)';
      case RestEnumJsonType(:final enumName):
        if (nullable) {
          return '$expression == null '
              '? null '
              ': $enumName.values.byName($expression as String)';
        }
        return '$enumName.values.byName($expression as String)';
      case RestNestedJsonType(:final className):
        if (nullable) {
          return '$expression == null '
              '? null '
              ': rest${className}FromJson($expression as Map<String, dynamic>)';
        }
        return 'rest${className}FromJson($expression as Map<String, dynamic>)';
      case RestListJsonType(:final itemType):
        final mapExpr = _decode('e', itemType);
        if (nullable) {
          return '($expression as List<dynamic>?)'
              '?.map((e) => $mapExpr).toList()';
        }
        return '($expression as List<dynamic>).map((e) => $mapExpr).toList()';
      case RestMapJsonType(:final valueType):
        final valueExpr = _decode('v', valueType);
        if (nullable) {
          return '($expression as Map<String, dynamic>?)'
              '?.map((k, v) => MapEntry(k, $valueExpr))';
        }
        return '($expression as Map<String, dynamic>)'
            '.map((k, v) => MapEntry(k, $valueExpr))';
    }
  }

  String _decodePrimitive(
    String expression,
    RestPrimitiveKind kind,
    bool nullable,
  ) {
    switch (kind) {
      case RestPrimitiveKind.double_:
        return nullable
            ? '($expression as num?)?.toDouble()'
            : '($expression as num).toDouble()';
      case RestPrimitiveKind.dynamic_:
        return expression;
      case RestPrimitiveKind.object:
        return nullable ? '$expression as Object?' : '$expression as Object';
      case RestPrimitiveKind.string:
        return nullable ? '$expression as String?' : '$expression as String';
      case RestPrimitiveKind.int_:
        return nullable ? '$expression as int?' : '$expression as int';
      case RestPrimitiveKind.num_:
        return nullable ? '$expression as num?' : '$expression as num';
      case RestPrimitiveKind.bool_:
        return nullable ? '$expression as bool?' : '$expression as bool';
    }
  }

  String _toJsonExpression(RestModelFieldModel field, bool explicitToJson) {
    return _encode(
      'instance.${field.name}',
      RestJsonTypeRef(field.jsonType, isNullable: field.isNullable),
      explicitToJson,
    );
  }

  String _encode(
    String expression,
    RestJsonTypeRef typeRef,
    bool explicitToJson,
  ) {
    final type = typeRef.type;
    final nullable = typeRef.isNullable;

    switch (type) {
      case RestPrimitiveJsonType():
        return expression;
      case RestDateTimeJsonType():
        return nullable
            ? '$expression?.toIso8601String()'
            : '$expression.toIso8601String()';
      case RestEnumJsonType():
        return nullable ? '$expression?.name' : '$expression.name';
      case RestNestedJsonType():
        if (!explicitToJson) {
          return expression;
        }
        return nullable ? '$expression?.toJson()' : '$expression.toJson()';
      case RestListJsonType(:final itemType):
        final item = _encode('e', itemType, explicitToJson);
        if (item == 'e') {
          return expression;
        }
        return nullable
            ? '$expression?.map((e) => $item).toList()'
            : '$expression.map((e) => $item).toList()';
      case RestMapJsonType(:final valueType):
        final value = _encode('v', valueType, explicitToJson);
        if (value == 'v') {
          return expression;
        }
        return nullable
            ? '$expression?.map((k, v) => MapEntry(k, $value))'
            : '$expression.map((k, v) => MapEntry(k, $value))';
    }
  }

  String _escape(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  }
}

/// Source writer that emits all `@RestModel` helpers in a [GenerationUnit].
class RestModelSourceWriter implements SourceWriter {
  /// Creates a unit writer.
  const RestModelSourceWriter({
    this.modelWriter = const DefaultRestModelWriter(),
  });

  /// Per-model writer.
  final RestModelWriter modelWriter;

  @override
  String? write(GenerationUnit unit) {
    if (unit.models.isEmpty) {
      return null;
    }
    final chunks = <String>[
      for (final model in unit.models) modelWriter.writeModel(model),
    ].where((chunk) => chunk.trim().isNotEmpty);

    if (chunks.isEmpty) {
      return null;
    }
    
    final output = StringBuffer();
    output.writeln("import '${unit.sourceLibraryName}';");
    output.writeln();
    output.writeln(chunks.join('\n\n'));
    
    return output.toString();
  }
}
