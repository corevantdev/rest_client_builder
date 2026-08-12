// The `library.element.firstFragment.source.uri` call below uses analyzer's
// classic element API. It will be updated when source_gen migrates to Element2.
// ignore_for_file: deprecated_member_use

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'model/generation_models.dart';
import 'utils/import_uri_resolver.dart';
import 'validator/generation_validator.dart';
import 'validator/rest_api_validator_impl.dart';
import 'validator/validation_issue.dart';
import 'visitor/library_model_visitor.dart';
import 'visitor/rest_api_visitor_impl.dart';
import 'writer/rest_api_writer_impl.dart';
import 'writer/source_writer.dart';

/// Generates `_Api` implementations for `@RestApi` classes (`*.rest.g.dart`).
class RestApiGenerator extends Generator {
  /// Creates a RestApi generator.
  const RestApiGenerator({
    this.visitor = const DefaultRestApiVisitor(),
    this.validator = const DefaultRestApiValidator(),
    this.writer = const DefaultRestApiWriter(),
  });

  /// Element → model visitor.
  final RestApiVisitor visitor;

  /// Model validator.
  final RestApiValidator validator;

  /// Source writer.
  final RestApiWriter writer;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final unit = RestApiLibraryVisitor(apiVisitor: visitor).visitLibrary(library);
    if (unit.apis.isEmpty) return '';

    final sourceUri = unit.sourceLibraryName;
    final importBuffer = StringBuffer();
    importBuffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    importBuffer.writeln('// ignore_for_file: type=lint');
    importBuffer.writeln("import 'package:rest_client_builder/rest_client_builder.dart';");
    importBuffer.writeln("import '$sourceUri';");

    final modelUris = <String>{};
    for (final api in unit.apis) {
      for (final method in api.methods) {
        if (method.returnType.modelSourceUri != null) {
          modelUris.add(method.returnType.modelSourceUri!);
        }
        for (final param in method.parameters) {
          if (param.modelSourceUri != null) {
            modelUris.add(param.modelSourceUri!);
          }
        }
      }
    }

    for (final uri in modelUris) {
      if (uri != sourceUri) {
        importBuffer.writeln("import '${resolveGeneratedImportUri(uri)}';");
        importBuffer.writeln("import '$uri';");
      }
    }

    final codeBuffer = StringBuffer();
    for (final model in unit.apis) {
      final issues = validator.validateApi(model);
      final errors = issues
          .where((issue) => issue.severity == ValidationSeverity.error)
          .toList(growable: false);

      for (final issue in issues) {
        if (issue.severity == ValidationSeverity.warning) {
          log.warning(issue.message);
        } else if (issue.severity == ValidationSeverity.info) {
          log.info(issue.message);
        }
      }

      if (errors.isNotEmpty) {
        final combined = errors.map((issue) => issue.message).join('\n');
        throw InvalidGenerationSourceError(combined);
      }

      codeBuffer.writeln(writer.writeApi(model));
    }

    return '${importBuffer.toString()}\n${codeBuffer.toString()}';
  }
}

/// Library visitor that collects `@RestApi` classes.
class RestApiLibraryVisitor implements LibraryModelVisitor {
  /// Creates a library visitor.
  const RestApiLibraryVisitor({
    this.apiVisitor = const DefaultRestApiVisitor(),
  });

  /// Per-class visitor.
  final RestApiVisitor apiVisitor;

  @override
  GenerationUnit visitLibrary(LibraryReader library) {
    final apis = <RestApiClassModel>[
      for (final element in library.classes)
        ?apiVisitor.visitClass(element),
    ];

    return GenerationUnit(
      apis: apis,
      sourceLibraryName: library.element.firstFragment.source.uri.toString(),
    );
  }
}
