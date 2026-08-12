import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../model/generation_models.dart';
import '../validator/generation_validator.dart';
import '../validator/validation_issue.dart';
import '../visitor/library_model_visitor.dart';
import '../writer/source_writer.dart';

/// Orchestrates Analyzer → Visitors → Models → Validators → Writers.
///
/// This pipeline defines architecture only. The default implementation does
/// not emit generated source yet.
abstract interface class GenerationPipeline {
  /// Runs the generation flow for [library].
  ///
  /// Returns source text to embed in a part file, or `null` when empty/no-op.
  Future<String?> run(LibraryReader library, BuildStep buildStep);
}

/// Default pipeline wiring no-op visitor, validator, and writer stages.
class DefaultGenerationPipeline implements GenerationPipeline {
  /// Creates a pipeline with the given stages.
  const DefaultGenerationPipeline({
    this.visitor = const NoOpLibraryModelVisitor(),
    this.validator = const NoOpGenerationValidator(),
    this.writer = const NoOpSourceWriter(),
  });

  /// AST/element visitor stage.
  final LibraryModelVisitor visitor;

  /// Model validation stage.
  final GenerationValidator validator;

  /// Source writing stage.
  final SourceWriter writer;

  @override
  Future<String?> run(LibraryReader library, BuildStep buildStep) async {
    // 1) Analyzer has already resolved the library into elements.
    // 2) Visitors translate elements → generator models.
    final GenerationUnit unit = visitor.visitLibrary(library);

    // 3) Validators check models before emission.
    final List<ValidationIssue> issues = validator.validate(unit);
    final hasBlockingErrors = issues.any(
      (issue) => issue.severity == ValidationSeverity.error,
    );
    if (hasBlockingErrors) {
      // Future: surface InvalidGenerationSourceError via source_gen.
      return null;
    }

    // 4) Writers emit Dart source (no-op today).
    if (unit.isEmpty) {
      return null;
    }
    return writer.write(unit);
  }
}
