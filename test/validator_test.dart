import 'package:rest_client_builder/src/generator/generator.dart';
import 'package:test/test.dart';

RestMethodModel _method({
  required String name,
  required String httpMethod,
  required String path,
  List<RestParameterModel> parameters = const [],
  bool isMultipart = false,
  bool isFormUrlEncoded = false,
}) {
  return RestMethodModel(
    name: name,
    httpMethod: httpMethod,
    path: path,
    isMultipart: isMultipart,
    isFormUrlEncoded: isFormUrlEncoded,
    returnType: const RestReturnTypeModel(
      rawTypeName: 'Future<RestResult<void>>',
      isFuture: true,
      isRestResult: true,
      isVoid: true,
    ),
    parameters: parameters,
  );
}

void main() {
  const validator = DefaultRestApiValidator();

  group('DefaultRestApiValidator', () {
    test('detects duplicate routes', () {
      final api = RestApiClassModel(
        name: 'Api',
        methods: [
          _method(name: 'a', httpMethod: 'GET', path: '/users/{id}', parameters: [
            const RestParameterModel(
              name: 'id',
              typeName: 'String',
              kind: RestParameterKind.path,
              annotationName: 'id',
            ),
          ]),
          _method(name: 'b', httpMethod: 'GET', path: '/users/{id}', parameters: [
            const RestParameterModel(
              name: 'id',
              typeName: 'String',
              kind: RestParameterKind.path,
              annotationName: 'id',
            ),
          ]),
        ],
      );

      final issues = validator.validateApi(api);
      expect(
        issues.where((i) => i.message.contains('Duplicate route')),
        isNotEmpty,
      );
    });

    test('rejects GET with Body', () {
      final api = RestApiClassModel(
        name: 'Api',
        methods: [
          _method(
            name: 'badGet',
            httpMethod: 'GET',
            path: '/users',
            parameters: const [
              RestParameterModel(
                name: 'user',
                typeName: 'User',
                kind: RestParameterKind.body,
              ),
            ],
          ),
        ],
      );

      final issues = validator.validateApi(api);
      expect(
        issues.any((i) => i.message.contains('GET') && i.message.contains('@Body')),
        isTrue,
      );
    });

    test('detects missing Path for placeholder', () {
      final api = RestApiClassModel(
        name: 'Api',
        methods: [
          _method(name: 'getUser', httpMethod: 'GET', path: '/users/{id}'),
        ],
      );

      final issues = validator.validateApi(api);
      expect(
        issues.any((i) => i.message.contains("Missing `@Path('id')`")),
        isTrue,
      );
    });

    test('detects Path parameter not in template', () {
      final api = RestApiClassModel(
        name: 'Api',
        methods: [
          _method(
            name: 'getUser',
            httpMethod: 'GET',
            path: '/users',
            parameters: const [
              RestParameterModel(
                name: 'id',
                typeName: 'String',
                kind: RestParameterKind.path,
                annotationName: 'id',
              ),
            ],
          ),
        ],
      );

      final issues = validator.validateApi(api);
      expect(
        issues.any((i) => i.message.contains('not present in path')),
        isTrue,
      );
    });

    test('rejects invalid multipart combinations', () {
      final missingParts = RestApiClassModel(
        name: 'Api',
        methods: [
          _method(
            name: 'upload',
            httpMethod: 'POST',
            path: '/avatar',
            isMultipart: true,
          ),
        ],
      );
      expect(
        validator.validateApi(missingParts).any(
          (i) => i.message.contains('no `@Part`'),
        ),
        isTrue,
      );

      final partWithoutMultipart = RestApiClassModel(
        name: 'Api',
        methods: [
          _method(
            name: 'upload',
            httpMethod: 'POST',
            path: '/avatar',
            parameters: const [
              RestParameterModel(
                name: 'file',
                typeName: 'RestPart',
                kind: RestParameterKind.part,
                annotationName: 'file',
              ),
            ],
          ),
        ],
      );
      expect(
        validator.validateApi(partWithoutMultipart).any(
          (i) => i.message.contains('missing `@Multipart`'),
        ),
        isTrue,
      );

      final bodyWithMultipart = RestApiClassModel(
        name: 'Api',
        methods: [
          _method(
            name: 'upload',
            httpMethod: 'POST',
            path: '/avatar',
            isMultipart: true,
            parameters: const [
              RestParameterModel(
                name: 'file',
                typeName: 'RestPart',
                kind: RestParameterKind.part,
                annotationName: 'file',
              ),
              RestParameterModel(
                name: 'user',
                typeName: 'User',
                kind: RestParameterKind.body,
              ),
            ],
          ),
        ],
      );
      expect(
        validator.validateApi(bodyWithMultipart).any(
          (i) => i.message.contains('cannot combine') && i.message.contains('@Body'),
        ),
        isTrue,
      );
    });

    test('accepts a valid CRUD + multipart API', () {
      final api = RestApiClassModel(
        name: 'UserApi',
        methods: [
          _method(
            name: 'getUser',
            httpMethod: 'GET',
            path: '/users/{id}',
            parameters: const [
              RestParameterModel(
                name: 'id',
                typeName: 'String',
                kind: RestParameterKind.path,
                annotationName: 'id',
              ),
            ],
          ),
          _method(
            name: 'createUser',
            httpMethod: 'POST',
            path: '/users',
            parameters: const [
              RestParameterModel(
                name: 'user',
                typeName: 'User',
                kind: RestParameterKind.body,
              ),
            ],
          ),
          _method(
            name: 'upload',
            httpMethod: 'POST',
            path: '/avatar',
            isMultipart: true,
            parameters: const [
              RestParameterModel(
                name: 'file',
                typeName: 'RestPart',
                kind: RestParameterKind.part,
                annotationName: 'file',
              ),
              RestParameterModel(
                name: 'cancelToken',
                typeName: 'CancelToken?',
                kind: RestParameterKind.cancelToken,
                isNullable: true,
                isNamed: true,
              ),
            ],
          ),
        ],
      );

      final errors = validator
          .validateApi(api)
          .where((i) => i.severity == ValidationSeverity.error);
      expect(errors, isEmpty);
    });

    test('rejects more than one CancelToken parameter', () {
      final api = RestApiClassModel(
        name: 'Api',
        methods: [
          _method(
            name: 'list',
            httpMethod: 'GET',
            path: '/items',
            parameters: const [
              RestParameterModel(
                name: 'a',
                typeName: 'CancelToken?',
                kind: RestParameterKind.cancelToken,
                isNullable: true,
                isNamed: true,
              ),
              RestParameterModel(
                name: 'b',
                typeName: 'CancelToken?',
                kind: RestParameterKind.cancelToken,
                isNullable: true,
                isNamed: true,
              ),
            ],
          ),
        ],
      );

      expect(
        validator.validateApi(api).any(
          (i) => i.message.contains('more than one `@Cancel`'),
        ),
        isTrue,
      );
    });

    test('rejects @Cancel on a non-CancelToken type', () {
      final api = RestApiClassModel(
        name: 'Api',
        methods: [
          _method(
            name: 'list',
            httpMethod: 'GET',
            path: '/items',
            parameters: const [
              RestParameterModel(
                name: 'token',
                typeName: 'String',
                kind: RestParameterKind.cancelToken,
                isNamed: true,
              ),
            ],
          ),
        ],
      );

      expect(
        validator.validateApi(api).any(
          (i) =>
              i.message.contains('annotated with `@Cancel`') &&
              i.message.contains('Expected `CancelToken`'),
        ),
        isTrue,
      );
    });
  });
}
