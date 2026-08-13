import 'rest_json_type.dart';

export 'rest_json_type.dart';

/// How a method parameter is bound onto an HTTP request.
enum RestParameterKind {
  /// Path placeholder (`@Path`).
  path,

  /// Single query parameter (`@Query`).
  query,

  /// Query map (`@QueryMap`).
  queryMap,

  /// Request body (`@Body`).
  body,

  /// Single header (`@Header`).
  header,

  /// Header map (`@HeaderMap`).
  headerMap,

  /// Full URL override (`@Url`).
  url,

  /// Multipart part (`@Part`).
  part,

  /// Multipart part map (`@PartMap`).
  partMap,

  /// Form field (`@Field`).
  field,

  /// Form field map (`@FieldMap`).
  fieldMap,

  /// Request cancellation token (`CancelToken`).
  cancelToken,

  /// Upload progress callback (`RestProgressCallback` / `onSendProgress`).
  uploadProgress,

  /// Download progress callback (`RestProgressCallback` / `onReceiveProgress`).
  downloadProgress,
}

/// Generator model for a single API method parameter.
class RestParameterModel {
  /// Creates a parameter model.
  const RestParameterModel({
    required this.name,
    required this.typeName,
    required this.kind,
    this.annotationName,
    this.encoded = false,
    this.fileName,
    this.contentType,
    this.isNullable = false,
    this.usesToJson = false,
    this.isNamed = false,
    this.isRequired = true,
    this.modelSourceUri,
  });

  /// Dart parameter name.
  final String name;

  /// Dart type display name.
  final String typeName;

  /// Binding kind derived from annotations.
  final RestParameterKind kind;

  /// Name supplied by the annotation when different from [name].
  final String? annotationName;

  /// Whether the value is pre-encoded (query/queryMap).
  final bool encoded;

  /// Optional multipart file name.
  final String? fileName;

  /// Optional multipart content type.
  final String? contentType;

  /// Whether the parameter type is nullable.
  final bool isNullable;

  /// Whether the value should be sent via `.toJson()`.
  final bool usesToJson;

  /// Whether the parameter is named.
  final bool isNamed;

  /// Whether the parameter is required.
  final bool isRequired;

  /// Optional URI of the model's source file (for importing generated model logic).
  final String? modelSourceUri;

  /// Effective path/query/field/part name.
  String get bindingName => annotationName ?? name;
}

/// Parsed return type for a generated API method.
class RestReturnTypeModel {
  /// Creates a return type model.
  const RestReturnTypeModel({
    required this.rawTypeName,
    required this.isFuture,
    required this.isRestResult,
    this.resultTypeName,
    this.isList = false,
    this.isVoid = false,
    this.isMap = false,
    this.isDynamic = false,
    this.isModel = false,
    this.isStreaming = false,
    this.modelSourceUri,
  });

  /// Full Dart return type display string.
  final String rawTypeName;

  /// Whether the method returns a `Future`.
  final bool isFuture;

  /// Whether the (future) value is a `RestResult`.
  final bool isRestResult;

  /// Inner type name (`User` for `RestResult<User>` / `RestResult<List<User>>`).
  final String? resultTypeName;

  /// Whether the RestResult value is a `List`.
  final bool isList;

  /// Whether the RestResult value is `void` / `Null`.
  final bool isVoid;

  /// Whether the RestResult value is a `Map`.
  final bool isMap;

  /// Whether the RestResult value is `dynamic` / `Object`.
  final bool isDynamic;

  /// Whether [resultTypeName] should be decoded via `Type.fromJson`.
  final bool isModel;

  /// Whether this method streams the raw response bytes (`@Streaming`).
  final bool isStreaming;

  /// Optional URI of the model's source file (for importing generated model logic).
  final String? modelSourceUri;
}

/// Generator model for a single HTTP API method.
class RestMethodModel {
  /// Creates a method model.
  const RestMethodModel({
    required this.name,
    required this.httpMethod,
    required this.path,
    required this.returnType,
    required this.parameters,
    this.headers = const <String, String>{},
    this.tags = const <String>[],
    this.isMultipart = false,
    this.isFormUrlEncoded = false,
    this.isStreaming = false,
    this.enableLog,
    this.retryMaxAttempts,
    this.retryDelayMs,
    this.retryStatusCodes,
    this.connectTimeoutMs,
    this.receiveTimeoutMs,
    this.sendTimeoutMs,
    this.cacheDurationMs,
    this.useInterceptors = const <String>[],
    this.excludeInterceptors = const <String>[],
  });

  /// Dart method name.
  final String name;

  /// HTTP verb (e.g. `GET`).
  final String httpMethod;

  /// Relative path, possibly with `{placeholders}`.
  final String path;

  /// Parsed return type.
  final RestReturnTypeModel returnType;

  /// Dart return type display name.
  String get returnTypeName => returnType.rawTypeName;

  /// Ordered parameters.
  final List<RestParameterModel> parameters;

  /// Method-level static headers.
  final Map<String, String> headers;

  /// Method-level tags.
  final List<String> tags;

  /// Whether `@Multipart` is present.
  final bool isMultipart;

  /// Whether `@FormUrlEncoded` is present.
  final bool isFormUrlEncoded;

  /// Whether `@Streaming` is present (raw byte-stream response).
  final bool isStreaming;

  /// Optional method-level log override.
  final bool? enableLog;

  /// Optional method-level retry override.
  final int? retryMaxAttempts;

  /// Method-level retry delay override.
  final int? retryDelayMs;

  /// Method-level retry status-code override.
  final List<int>? retryStatusCodes;

  /// Optional method-level timeouts.
  final int? connectTimeoutMs;

  /// Optional method-level receive timeout.
  final int? receiveTimeoutMs;

  /// Optional method-level send timeout.
  final int? sendTimeoutMs;

  /// Optional cache TTL in milliseconds (@Cache).
  final int? cacheDurationMs;

  /// Interceptor type names from `@UseInterceptor`.
  final List<String> useInterceptors;

  /// Interceptor type names from `@ExcludeInterceptor`.
  final List<String> excludeInterceptors;
}

/// Generator model for an `@RestApi` / configuration class.
class RestApiClassModel {
  /// Creates an API class model.
  const RestApiClassModel({
    required this.name,
    required this.methods,
    this.baseUrl,
    this.defaultHeaders = const <String, String>{},
    this.tags = const <String>[],
    this.globalInterceptors = const <String>[],
    this.excludeInterceptors = const <String>[],
    this.enableLog,
    this.retryMaxAttempts,
    this.retryDelayMs,
    this.retryStatusCodes,
    this.connectTimeoutMs,
    this.receiveTimeoutMs,
    this.sendTimeoutMs,
    this.configurationName,
  });

  /// Dart class name.
  final String name;

  /// Declared methods.
  final List<RestMethodModel> methods;

  /// Base URL from `@RestApi` / `@BaseUrl`.
  final String? baseUrl;

  /// Class-level headers.
  final Map<String, String> defaultHeaders;

  /// Class-level tags.
  final List<String> tags;

  /// Class-level `@UseInterceptor` type names.
  final List<String> globalInterceptors;

  /// Class-level `@ExcludeInterceptor` type names.
  final List<String> excludeInterceptors;

  /// Logging flag from `@EnableLog`.
  final bool? enableLog;

  /// Retry settings.
  final int? retryMaxAttempts;

  /// Retry delay in milliseconds.
  final int? retryDelayMs;

  /// Retry status codes.
  final List<int>? retryStatusCodes;

  /// Timeouts in milliseconds.
  final int? connectTimeoutMs;

  /// Receive timeout in milliseconds.
  final int? receiveTimeoutMs;

  /// Send timeout in milliseconds.
  final int? sendTimeoutMs;

  /// Optional `@RestConfiguration` name.
  final String? configurationName;
}

/// Generator model for an `@RestModel` data class.
class RestModelClassModel {
  /// Creates a REST model class model.
  const RestModelClassModel({
    required this.name,
    this.createFactory = true,
    this.createToJson = true,
    this.explicitToJson = true,
    this.fields = const <RestModelFieldModel>[],
  });

  /// Dart class name.
  final String name;

  /// Whether `fromJson` helpers should be generated.
  final bool createFactory;

  /// Whether `toJson` helpers should be generated.
  final bool createToJson;

  /// Whether nested models should call `toJson` explicitly.
  final bool explicitToJson;

  /// Constructor parameters / fields used for (de)serialization.
  final List<RestModelFieldModel> fields;

  /// Fields that participate in JSON (not ignored).
  List<RestModelFieldModel> get serializableFields =>
      fields.where((field) => !field.ignore).toList(growable: false);
}

/// Generator model for a field on an `@RestModel` class.
class RestModelFieldModel {
  /// Creates a model field.
  const RestModelFieldModel({
    required this.name,
    required this.typeName,
    required this.jsonType,
    required this.isNullable,
    this.jsonKeyName,
    this.ignore = false,
    this.defaultValueCode,
  });

  /// Dart field / constructor parameter name.
  final String name;

  /// Full Dart type display name (including `?`).
  final String typeName;

  /// Resolved JSON type graph.
  final RestJsonType jsonType;

  /// Whether the Dart type is nullable.
  final bool isNullable;

  /// JSON key from `@JsonKey(name)`; defaults to [name] when null.
  final String? jsonKeyName;

  /// Whether `@JsonKey(ignore: true)` was set.
  final bool ignore;

  /// Dart source expression for `@JsonKey(defaultValue)`, when present.
  final String? defaultValueCode;

  /// Effective JSON object key.
  String get jsonName => jsonKeyName ?? name;
}

/// Aggregate output of visitors for a single library.
class GenerationUnit {
  /// Creates a generation unit.
  const GenerationUnit({
    this.apis = const <RestApiClassModel>[],
    this.models = const <RestModelClassModel>[],
    this.sourceLibraryName,
  });

  /// Empty unit.
  static const GenerationUnit empty = GenerationUnit();

  /// API client classes discovered in the library.
  final List<RestApiClassModel> apis;

  /// `@RestModel` classes discovered in the library.
  final List<RestModelClassModel> models;

  /// Optional library identifier for diagnostics.
  final String? sourceLibraryName;

  /// Whether any generatable declarations were found.
  bool get isEmpty => apis.isEmpty && models.isEmpty;

  /// Whether any generatable declarations were found.
  bool get isNotEmpty => !isEmpty;
}
