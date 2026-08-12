// ignore_for_file: deprecated_member_use

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'model/generation_models.dart';
import 'validator/generation_validator.dart';
import 'validator/rest_model_validator_impl.dart';
import 'validator/validation_issue.dart';
import 'visitor/library_model_visitor.dart';
import 'visitor/rest_model_visitor_impl.dart';
import 'writer/rest_model_writer_impl.dart';
import 'writer/source_writer.dart';

/// Generates `fromJson` / `toJson` helpers for `@RestModel` classes.
class RestModelGenerator extends Generator {
  /// Creates a RestModel generator.
  const RestModelGenerator({
    this.visitor = const DefaultRestModelVisitor(),
    this.validator = const DefaultRestModelValidator(),
    this.writer = const DefaultRestModelWriter(),
  });

  /// Element → model visitor.
  final RestModelVisitor visitor;

  /// Model validator.
  final RestModelValidator validator;

  /// Model source writer.
  final RestModelWriter writer;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final unit = RestModelLibraryVisitor(modelVisitor: visitor).visitLibrary(library);
    if (unit.models.isEmpty) return '';

    final sourceUri = unit.sourceLibraryName;
    final importBuffer = StringBuffer();
    importBuffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    importBuffer.writeln('// ignore_for_file: type=lint');
    importBuffer.writeln("import 'package:rest_client_builder/rest_client_builder.dart';");
    importBuffer.writeln("import '$sourceUri';");

    final codeBuffer = StringBuffer();
    for (final model in unit.models) {
      final issues = validator.validateModel(model);
      for (final issue in issues) {
        if (issue.severity == ValidationSeverity.error) {
          throw InvalidGenerationSourceError(issue.message);
        }
      }

      for (final field in model.fields.where((field) => field.ignore)) {
        if (!field.isNullable && field.defaultValueCode == null) {
          throw InvalidGenerationSourceError(
            'Ignored field `${field.name}` on `${model.name}` must be nullable '
            'or provide `@JsonKey(defaultValue: …)`.',
          );
        }
      }

      codeBuffer.writeln(writer.writeModel(model));
    }

    return '${importBuffer.toString()}\n${codeBuffer.toString()}';
  }
}

/// Library visitor that collects `@RestModel` classes.
class RestModelLibraryVisitor implements LibraryModelVisitor {
  /// Creates a library visitor.
  const RestModelLibraryVisitor({
    this.modelVisitor = const DefaultRestModelVisitor(),
  });

  /// Per-class visitor.
  final RestModelVisitor modelVisitor;

  @override
  GenerationUnit visitLibrary(LibraryReader library) {
    final models = <RestModelClassModel>[
      for (final element in library.classes)
        ?modelVisitor.visitClass(element),
    ];

    return GenerationUnit(
      models: models,
      sourceLibraryName: library.element.firstFragment.source.uri.toString(),
    );
  }
}
