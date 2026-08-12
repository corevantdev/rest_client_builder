import '../model/generation_models.dart';
import 'generation_validator.dart';
import 'validation_issue.dart';

/// Validates `@RestModel` generator models before source emission.
class DefaultRestModelValidator implements RestModelValidator {
  /// Creates a RestModel validator.
  const DefaultRestModelValidator();

  @override
  List<ValidationIssue> validateModel(RestModelClassModel model) {
    final issues = <ValidationIssue>[];

    if (!model.createFactory && !model.createToJson) {
      issues.add(
        ValidationIssue(
          message:
              '`@RestModel` on `${model.name}` has both createFactory and '
              'createToJson set to false; nothing will be generated.',
          severity: ValidationSeverity.warning,
          elementName: model.name,
        ),
      );
    }

    if (model.fields.isEmpty) {
      issues.add(
        ValidationIssue(
          message:
              '`@RestModel` class `${model.name}` has no constructor parameters.',
          severity: ValidationSeverity.warning,
          elementName: model.name,
        ),
      );
    }

    final seenJsonNames = <String>{};
    for (final field in model.serializableFields) {
      if (!seenJsonNames.add(field.jsonName)) {
        issues.add(
          ValidationIssue(
            message:
                'Duplicate JSON key `${field.jsonName}` in `${model.name}`.',
            severity: ValidationSeverity.error,
            elementName: '${model.name}.${field.name}',
          ),
        );
      }

      if (!field.isNullable &&
          field.defaultValueCode == null &&
          _isCollection(field.jsonType)) {
        // Allowed — collections are still required unless nullable/defaulted.
      }
    }

    return issues;
  }

  bool _isCollection(RestJsonType type) =>
      type is RestListJsonType || type is RestMapJsonType;
}

/// Generation validator that checks RestModel entries inside a [GenerationUnit].
class RestModelGenerationValidator implements GenerationValidator {
  /// Creates a unit validator.
  const RestModelGenerationValidator({
    this.modelValidator = const DefaultRestModelValidator(),
  });

  /// Per-model validator.
  final RestModelValidator modelValidator;

  @override
  List<ValidationIssue> validate(GenerationUnit unit) {
    return [
      for (final model in unit.models) ...modelValidator.validateModel(model),
    ];
  }
}
