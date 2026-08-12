import '../model/generation_models.dart';
import 'validation_issue.dart';

/// Validates [GenerationUnit] models before source writing.
///
/// Validators operate on generator models only — not on raw AST nodes.
abstract interface class GenerationValidator {
  /// Returns issues found in [unit]. Empty means valid.
  List<ValidationIssue> validate(GenerationUnit unit);
}

/// Validates API class models.
abstract interface class RestApiValidator {
  /// Validates a single API class model.
  List<ValidationIssue> validateApi(RestApiClassModel api);
}

/// Validates REST model class models.
abstract interface class RestModelValidator {
  /// Validates a single `@RestModel` class model.
  List<ValidationIssue> validateModel(RestModelClassModel model);
}

/// No-op validator scaffold. Real rules will be added later.
class NoOpGenerationValidator implements GenerationValidator {
  /// Creates a no-op validator.
  const NoOpGenerationValidator();

  @override
  List<ValidationIssue> validate(GenerationUnit unit) =>
      const <ValidationIssue>[];
}
