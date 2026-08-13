import 'package:rest_client_builder/rest_client_builder.dart';
import 'package:rest_client_builder/src/generator/generator.dart';
import 'package:test/test.dart';

void main() {
  group('generator architecture', () {
    test('generation models expose empty unit helpers', () {
      expect(GenerationUnit.empty.isEmpty, isTrue);
      expect(
        const GenerationUnit(apis: [
          RestApiClassModel(name: 'Api', methods: []),
        ]).isNotEmpty,
        isTrue,
      );
    });

    test('no-op writer emits nothing', () {
      const writer = NoOpSourceWriter();
      expect(writer.write(GenerationUnit.empty), isNull);
    });

    test('no-op validator returns no issues', () {
      const validator = NoOpGenerationValidator();
      expect(validator.validate(GenerationUnit.empty), isEmpty);
    });

    test('parameter kinds cover annotation bindings', () {
      expect(RestParameterKind.values, contains(RestParameterKind.path));
      expect(RestParameterKind.values, contains(RestParameterKind.part));
      expect(RestParameterKind.values, contains(RestParameterKind.field));
      expect(RestParameterKind.values, contains(RestParameterKind.cancelToken));
      expect(
        RestParameterKind.values,
        contains(RestParameterKind.uploadProgress),
      );
      expect(
        RestParameterKind.values,
        contains(RestParameterKind.downloadProgress),
      );
      // `@Cancel` annotation binds to cancelToken kind (name avoids clashing
      // with the CancelToken runtime interface).
      expect(const Cancel(), isA<Cancel>());
    });
  });

  group('RestModel writer', () {
    const writer = DefaultRestModelWriter();

    test('generates fromJson/toJson for primitives and JsonKey.name', () {
      const model = RestModelClassModel(
        name: 'User',
        fields: [
          RestModelFieldModel(
            name: 'id',
            typeName: 'String',
            jsonType: RestPrimitiveJsonType(RestPrimitiveKind.string),
            isNullable: false,
          ),
          RestModelFieldModel(
            name: 'name',
            typeName: 'String',
            jsonType: RestPrimitiveJsonType(RestPrimitiveKind.string),
            isNullable: false,
            jsonKeyName: 'user_name',
          ),
        ],
      );

      final source = writer.writeModel(model);
      expect(source, contains('User restUserFromJson(Map<String, dynamic> json)'));
      expect(source, contains("json['user_name'] as String"));
      expect(source, contains('Map<String, dynamic> restUserToJson(User instance)'));
      expect(source, contains("'user_name': instance.name"));
    });

    test('supports DateTime, enum, nested, list, map, defaultValue, ignore', () {
      const model = RestModelClassModel(
        name: 'Profile',
        fields: [
          RestModelFieldModel(
            name: 'createdAt',
            typeName: 'DateTime',
            jsonType: RestDateTimeJsonType(),
            isNullable: false,
          ),
          RestModelFieldModel(
            name: 'role',
            typeName: 'Role',
            jsonType: RestEnumJsonType('Role'),
            isNullable: false,
          ),
          RestModelFieldModel(
            name: 'address',
            typeName: 'Address',
            jsonType: RestNestedJsonType('Address'),
            isNullable: true,
          ),
          RestModelFieldModel(
            name: 'tags',
            typeName: 'List<String>',
            jsonType: RestListJsonType(
              RestJsonTypeRef(
                RestPrimitiveJsonType(RestPrimitiveKind.string),
              ),
            ),
            isNullable: false,
          ),
          RestModelFieldModel(
            name: 'meta',
            typeName: 'Map<String, int>',
            jsonType: RestMapJsonType(
              RestJsonTypeRef(
                RestPrimitiveJsonType(RestPrimitiveKind.int_),
              ),
            ),
            isNullable: false,
          ),
          RestModelFieldModel(
            name: 'nickname',
            typeName: 'String',
            jsonType: RestPrimitiveJsonType(RestPrimitiveKind.string),
            isNullable: false,
            defaultValueCode: "'guest'",
          ),
          RestModelFieldModel(
            name: 'secret',
            typeName: 'String?',
            jsonType: RestPrimitiveJsonType(RestPrimitiveKind.string),
            isNullable: true,
            ignore: true,
          ),
        ],
      );

      final source = writer.writeModel(model);
      expect(source, contains('DateTime.parse(json[\'createdAt\'] as String)'));
      expect(source, contains('Role.values.byName(json[\'role\'] as String)'));
      expect(source, contains('restAddressFromJson(json[\'address\']'));
      expect(source, contains(".map((e) => e as String).toList()"));
      expect(source, contains('MapEntry(k, v as int)'));
      expect(source, contains("?? 'guest'"));
      expect(source, contains('secret: null'));
      expect(source, isNot(contains("'secret':")));
      expect(source, contains('instance.createdAt.toIso8601String()'));
      expect(source, contains('instance.role.name'));
      expect(source, contains('instance.address?.toJson()'));
    });
  });

  group('RestApi writer', () {
    const writer = DefaultRestApiWriter();

    test('generates client with path/query/body and RestResult mapping', () {
      const api = RestApiClassModel(
        name: 'UserApi',
        baseUrl: 'https://api.example.com',
        defaultHeaders: {'Accept': 'application/json'},
        methods: [
          RestMethodModel(
            name: 'getUser',
            httpMethod: 'GET',
            path: '/users/{id}',
            returnType: RestReturnTypeModel(
              rawTypeName: 'Future<RestResult<User>>',
              isFuture: true,
              isRestResult: true,
              isModel: true,
              resultTypeName: 'User',
            ),
            parameters: [
              RestParameterModel(
                name: 'id',
                typeName: 'String',
                kind: RestParameterKind.path,
                annotationName: 'id',
              ),
              RestParameterModel(
                name: 'expand',
                typeName: 'String?',
                kind: RestParameterKind.query,
                annotationName: 'expand',
                isNullable: true,
                isNamed: true,
                isRequired: false,
              ),
            ],
          ),
          RestMethodModel(
            name: 'createUser',
            httpMethod: 'POST',
            path: '/users',
            returnType: RestReturnTypeModel(
              rawTypeName: 'Future<RestResult<User>>',
              isFuture: true,
              isRestResult: true,
              isModel: true,
              resultTypeName: 'User',
            ),
            parameters: [
              RestParameterModel(
                name: 'user',
                typeName: 'User',
                kind: RestParameterKind.body,
                usesToJson: true,
              ),
            ],
          ),
        ],
      );

      final source = writer.writeApi(api);
      expect(source, contains('class UserApiImpl implements UserApi'));
      expect(source, contains('UserApi createUserApi('));
      expect(source, contains('UserApiImpl(client: client, baseUrl: baseUrl, headers: headers)'));
      expect(source, contains("method: 'GET'"));
      expect(source, contains('resolveRestPath'));
      expect(source, contains("if (expand != null) 'expand'"));
      expect(source, contains('restUserToJson(user)'));
      expect(
        source,
        contains('RestResponseMapper.mapModel<User>(raw, restUserFromJson)'),
      );
    });

    test('generates multipart RestPart, cancel, progress, interceptor extras', () {
      const api = RestApiClassModel(
        name: 'UploadApi',
        globalInterceptors: ['AuthInterceptor'],
        methods: [
          RestMethodModel(
            name: 'upload',
            httpMethod: 'POST',
            path: '/avatar',
            isMultipart: true,
            useInterceptors: ['UploadInterceptor'],
            excludeInterceptors: ['OtherInterceptor'],
            returnType: RestReturnTypeModel(
              rawTypeName: 'Future<RestResult<User>>',
              isFuture: true,
              isRestResult: true,
              isModel: true,
              resultTypeName: 'User',
            ),
            parameters: [
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
                isRequired: false,
              ),
              RestParameterModel(
                name: 'onSendProgress',
                typeName: 'RestProgressCallback?',
                kind: RestParameterKind.uploadProgress,
                isNullable: true,
                isNamed: true,
                isRequired: false,
              ),
              RestParameterModel(
                name: 'onReceiveProgress',
                typeName: 'RestProgressCallback?',
                kind: RestParameterKind.downloadProgress,
                isNullable: true,
                isNamed: true,
                isRequired: false,
              ),
            ],
          ),
        ],
      );

      final source = writer.writeApi(api);
      expect(source, contains("file.withName('file')"));
      expect(source, contains('cancelToken: cancelToken'));
      expect(source, contains('onSendProgress: onSendProgress'));
      expect(source, contains('onReceiveProgress: onReceiveProgress'));
      expect(source, contains('RestInterceptorExtras.useInterceptors'));
      expect(source, contains("'AuthInterceptor'"));
      expect(source, contains("'UploadInterceptor'"));
      expect(source, contains('RestInterceptorExtras.excludeInterceptors'));
      expect(source, contains("'OtherInterceptor'"));
      expect(source, contains('const bodyType = RestBodyType.multipart'));
      expect(source, contains('BasicMultipartBody'));
      expect(source, contains('abstract final class UploadApiDocs'));
      expect(source, contains('## Endpoints'));
      expect(source, contains('`POST /avatar`'));
    });
  });
}
