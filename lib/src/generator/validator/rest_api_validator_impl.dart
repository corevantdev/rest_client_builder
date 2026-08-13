import '../../core/constants/rest_constants.dart';
import '../model/generation_models.dart';
import 'generation_validator.dart';
import 'validation_issue.dart';

/// Validates `@RestApi` generator models at compile time.
///
/// Enforced error rules:
/// - duplicate routes (`METHOD` + path)
/// - `GET` must not declare `@Body`
/// - path placeholders must match `@Path` parameters (both directions)
/// - invalid `@Multipart` / `@Part` combinations
class DefaultRestApiValidator implements RestApiValidator {
  /// Creates a RestApi validator.
  const DefaultRestApiValidator();

  static final RegExp _pathPlaceholder = RegExp(r'\{([^{}]+)\}');

  @override
  List<ValidationIssue> validateApi(RestApiClassModel api) {
    final issues = <ValidationIssue>[];

    if (api.methods.isEmpty) {
      issues.add(
        ValidationIssue(
          message: '`@RestApi` class `${api.name}` has no HTTP methods.',
          severity: ValidationSeverity.warning,
          elementName: api.name,
        ),
      );
    }

    _validateDuplicateRoutes(api, issues);

    for (final method in api.methods) {
      _validateMethod(api, method, issues);
    }

    return issues;
  }

  void _validateDuplicateRoutes(
    RestApiClassModel api,
    List<ValidationIssue> issues,
  ) {
    final seen = <String, String>{};
    for (final method in api.methods) {
      final key = '${method.httpMethod} ${method.path}';
      final previous = seen[key];
      if (previous != null) {
        issues.add(
          ValidationIssue(
            message:
                'Duplicate route `$key` on `${method.name}` '
                '(already declared by `$previous`).',
            severity: ValidationSeverity.error,
            elementName: '${api.name}.${method.name}',
          ),
        );
      } else {
        seen[key] = method.name;
      }
    }
  }

  void _validateMethod(
    RestApiClassModel api,
    RestMethodModel method,
    List<ValidationIssue> issues,
  ) {
    final elementName = '${api.name}.${method.name}';

    if (!method.returnType.isRestResult) {
      issues.add(
        ValidationIssue(
          message:
              'Method `${method.name}` must return `Future<RestResult<T>>`.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }

    final bodies = method.parameters
        .where((parameter) => parameter.kind == RestParameterKind.body)
        .toList(growable: false);
    if (bodies.length > 1) {
      issues.add(
        ValidationIssue(
          message: 'Method `${method.name}` has more than one `@Body`.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }

    if (method.httpMethod == HttpMethodNames.get && bodies.isNotEmpty) {
      issues.add(
        ValidationIssue(
          message:
              'GET method `${method.name}` cannot contain `@Body`. '
              'Use query parameters or switch to POST/PUT/PATCH.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }

    if (method.httpMethod == HttpMethodNames.head && bodies.isNotEmpty) {
      issues.add(
        ValidationIssue(
          message: 'HEAD method `${method.name}` cannot contain `@Body`.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }

    if (method.httpMethod == HttpMethodNames.options && bodies.isNotEmpty) {
      issues.add(
        ValidationIssue(
          message: 'OPTIONS method `${method.name}` cannot contain `@Body`.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }

    if (method.isMultipart && method.isFormUrlEncoded) {
      issues.add(
        ValidationIssue(
          message:
              'Method `${method.name}` cannot be both `@Multipart` and '
              '`@FormUrlEncoded` at the same time.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }

    if (method.isStreaming && method.isMultipart) {
      issues.add(
        ValidationIssue(
          message:
              '`@Streaming` method `${method.name}` cannot also be `@Multipart`. '
              'Streaming is for downloads; use a separate upload method.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }

    if (method.isStreaming && method.isFormUrlEncoded) {
      issues.add(
        ValidationIssue(
          message:
              '`@Streaming` method `${method.name}` cannot also be `@FormUrlEncoded`. '
              'Streaming is for downloads; use a separate upload method.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }

    _validatePathBindings(api, method, issues);
    _validateCancelToken(api, method, issues);
    _validateMultipart(api, method, issues);
    _validateFormUrlEncoded(api, method, issues);
  }

  void _validateCancelToken(
    RestApiClassModel api,
    RestMethodModel method,
    List<ValidationIssue> issues,
  ) {
    final elementName = '${api.name}.${method.name}';
    final cancelTokens = method.parameters
        .where((parameter) => parameter.kind == RestParameterKind.cancelToken)
        .toList(growable: false);

    if (cancelTokens.length > 1) {
      issues.add(
        ValidationIssue(
          message:
              'Method `${method.name}` has more than one `@Cancel` / '
              '`CancelToken` parameter.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }

    for (final parameter in cancelTokens) {
      final type = parameter.typeName.replaceAll('?', '');
      if (type != 'CancelToken') {
        issues.add(
          ValidationIssue(
            message:
                'Parameter `${parameter.name}` is annotated with `@Cancel` '
                'but its type is `${parameter.typeName}`. '
                'Expected `CancelToken` or `CancelToken?`.',
            severity: ValidationSeverity.error,
            elementName: elementName,
          ),
        );
      }
    }
  }

  void _validatePathBindings(
    RestApiClassModel api,
    RestMethodModel method,
    List<ValidationIssue> issues,
  ) {
    final elementName = '${api.name}.${method.name}';
    final placeholders = _pathPlaceholder
        .allMatches(method.path)
        .map((match) => match.group(1)!)
        .toSet();

    final pathParams = method.parameters
        .where((parameter) => parameter.kind == RestParameterKind.path)
        .toList(growable: false);

    for (final parameter in pathParams) {
      final token = parameter.bindingName;
      if (!placeholders.contains(token)) {
        issues.add(
          ValidationIssue(
            message:
                'Path parameter `$token` is not present in path '
                '`${method.path}`. Expected `{$token}`.',
            severity: ValidationSeverity.error,
            elementName: elementName,
          ),
        );
      }
    }

    final boundNames = pathParams.map((p) => p.bindingName).toSet();
    for (final placeholder in placeholders) {
      if (!boundNames.contains(placeholder)) {
        issues.add(
          ValidationIssue(
            message:
                'Missing `@Path(\'$placeholder\')` for placeholder '
                '`{$placeholder}` in `${method.path}` '
                '(method `${method.name}`).',
            severity: ValidationSeverity.error,
            elementName: elementName,
          ),
        );
      }
    }
  }

  void _validateMultipart(
    RestApiClassModel api,
    RestMethodModel method,
    List<ValidationIssue> issues,
  ) {
    final elementName = '${api.name}.${method.name}';
    final parts = method.parameters
        .where(
          (parameter) =>
              parameter.kind == RestParameterKind.part ||
              parameter.kind == RestParameterKind.partMap,
        )
        .toList(growable: false);
    final bodies = method.parameters.where(
      (parameter) => parameter.kind == RestParameterKind.body,
    );
    final fields = method.parameters.where(
      (parameter) =>
          parameter.kind == RestParameterKind.field ||
          parameter.kind == RestParameterKind.fieldMap,
    );

    if (method.isMultipart) {
      if (parts.isEmpty) {
        issues.add(
          ValidationIssue(
            message:
                'Invalid multipart: `${method.name}` is `@Multipart` but has '
                'no `@Part` / `@PartMap` parameters.',
            severity: ValidationSeverity.error,
            elementName: elementName,
          ),
        );
      }
      if (bodies.isNotEmpty) {
        issues.add(
          ValidationIssue(
            message:
                'Invalid multipart: `${method.name}` cannot combine '
                '`@Multipart` with `@Body`. Use `@Part` / `RestPart` instead.',
            severity: ValidationSeverity.error,
            elementName: elementName,
          ),
        );
      }
      if (fields.isNotEmpty) {
        issues.add(
          ValidationIssue(
            message:
                'Invalid multipart: `${method.name}` uses `@Field` / '
                '`@FieldMap`. Use `@Part` / `@PartMap` for multipart fields.',
            severity: ValidationSeverity.error,
            elementName: elementName,
          ),
        );
      }
    } else if (parts.isNotEmpty) {
      issues.add(
        ValidationIssue(
          message:
              'Invalid multipart: `${method.name}` has `@Part` / `@PartMap` '
              'but is missing `@Multipart`.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }

    for (final parameter in method.parameters) {
      final type = parameter.typeName.replaceAll('?', '');
      if (type == 'RestPart' && parameter.kind != RestParameterKind.part) {
        issues.add(
          ValidationIssue(
            message:
                'Invalid multipart: parameter `${parameter.name}` is '
                '`RestPart` but is not annotated with `@Part`.',
            severity: ValidationSeverity.error,
            elementName: elementName,
          ),
        );
      }
    }
  }

  void _validateFormUrlEncoded(
    RestApiClassModel api,
    RestMethodModel method,
    List<ValidationIssue> issues,
  ) {
    if (!method.isFormUrlEncoded) {
      return;
    }
    final elementName = '${api.name}.${method.name}';
    final fields = method.parameters.where(
      (parameter) =>
          parameter.kind == RestParameterKind.field ||
          parameter.kind == RestParameterKind.fieldMap,
    );
    final bodies = method.parameters.where(
      (parameter) => parameter.kind == RestParameterKind.body,
    );
    if (fields.isEmpty) {
      issues.add(
        ValidationIssue(
          message:
              'Method `${method.name}` is `@FormUrlEncoded` but has no '
              '`@Field` / `@FieldMap` parameters.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }
    if (bodies.isNotEmpty) {
      issues.add(
        ValidationIssue(
          message:
              'Method `${method.name}` cannot combine `@FormUrlEncoded` with '
              '`@Body`.',
          severity: ValidationSeverity.error,
          elementName: elementName,
        ),
      );
    }
  }
}

/// Validates all `@RestApi` models inside a [GenerationUnit].
class RestApiUnitValidator implements GenerationValidator {
  /// Creates a unit validator.
  const RestApiUnitValidator({
    this.apiValidator = const DefaultRestApiValidator(),
  });

  /// Per-API validator.
  final RestApiValidator apiValidator;

  @override
  List<ValidationIssue> validate(GenerationUnit unit) {
    return [for (final api in unit.apis) ...apiValidator.validateApi(api)];
  }
}
