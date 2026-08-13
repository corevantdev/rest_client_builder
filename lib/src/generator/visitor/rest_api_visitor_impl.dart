// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import '../../annotations/api/api_annotations.dart';
import '../../annotations/cache/cache_annotation.dart';
import '../../annotations/configuration/configuration_annotations.dart';
import '../../annotations/form/form_annotations.dart';
import '../../annotations/http/http_annotations.dart';
import '../../annotations/http/sse_annotation.dart';
import '../../annotations/http/streaming_annotation.dart';
import '../../annotations/multipart/multipart_annotations.dart';
import '../../annotations/parameters/parameter_annotations.dart';
import '../../annotations/queue/offline_queue_annotation.dart';
import '../../core/result/rest_result.dart';
import '../model/generation_models.dart';
import 'library_model_visitor.dart';

/// Default visitor that builds [RestApiClassModel] from analyzer elements.
class DefaultRestApiVisitor implements RestApiVisitor {
  /// Creates a RestApi visitor.
  const DefaultRestApiVisitor();

  static const _restApi = TypeChecker.typeNamed(
    RestApi,
    inPackage: 'rest_client_builder',
  );
  static const _baseUrl = TypeChecker.typeNamed(
    BaseUrl,
    inPackage: 'rest_client_builder',
  );
  static const _headers = TypeChecker.typeNamed(
    Headers,
    inPackage: 'rest_client_builder',
  );
  static const _retry = TypeChecker.typeNamed(
    Retry,
    inPackage: 'rest_client_builder',
  );
  static const _enableLog = TypeChecker.typeNamed(
    EnableLog,
    inPackage: 'rest_client_builder',
  );
  static const _connectTimeout = TypeChecker.typeNamed(
    ConnectTimeout,
    inPackage: 'rest_client_builder',
  );
  static const _receiveTimeout = TypeChecker.typeNamed(
    ReceiveTimeout,
    inPackage: 'rest_client_builder',
  );
  static const _sendTimeout = TypeChecker.typeNamed(
    SendTimeout,
    inPackage: 'rest_client_builder',
  );
  static const _cache = TypeChecker.typeNamed(
    Cache,
    inPackage: 'rest_client_builder',
  );
  static const _get = TypeChecker.typeNamed(GET, inPackage: 'rest_client_builder');
  static const _post = TypeChecker.typeNamed(
    POST,
    inPackage: 'rest_client_builder',
  );
  static const _put = TypeChecker.typeNamed(PUT, inPackage: 'rest_client_builder');
  static const _patch = TypeChecker.typeNamed(
    PATCH,
    inPackage: 'rest_client_builder',
  );
  static const _delete = TypeChecker.typeNamed(
    DELETE,
    inPackage: 'rest_client_builder',
  );
  static const _head = TypeChecker.typeNamed(
    HEAD,
    inPackage: 'rest_client_builder',
  );
  static const _options = TypeChecker.typeNamed(
    OPTIONS,
    inPackage: 'rest_client_builder',
  );
  static const _http = TypeChecker.typeNamed(
    HTTP,
    inPackage: 'rest_client_builder',
  );
  static const _streaming = TypeChecker.fromUrl(
    'package:rest_client_builder/rest_client_builder.dart#Streaming',
  );
  static const _sse = TypeChecker.fromUrl(
    'package:rest_client_builder/rest_client_builder.dart#SSE',
  );
  static const _offlineQueue = TypeChecker.fromUrl(
    'package:rest_client_builder/rest_client_builder.dart#OfflineQueue',
  );
  static const _resilientQueue = TypeChecker.fromUrl(
    'package:rest_client_builder/rest_client_builder.dart#ResilientQueue',
  );

  static const _multipart = TypeChecker.typeNamed(
    Multipart,
    inPackage: 'rest_client_builder',
  );
  static const _form = TypeChecker.typeNamed(
    FormUrlEncoded,
    inPackage: 'rest_client_builder',
  );
  static const _path = TypeChecker.typeNamed(
    Path,
    inPackage: 'rest_client_builder',
  );
  static const _query = TypeChecker.typeNamed(
    Query,
    inPackage: 'rest_client_builder',
  );
  static const _queryMap = TypeChecker.typeNamed(
    QueryMap,
    inPackage: 'rest_client_builder',
  );
  static const _body = TypeChecker.typeNamed(
    Body,
    inPackage: 'rest_client_builder',
  );
  static const _header = TypeChecker.typeNamed(
    Header,
    inPackage: 'rest_client_builder',
  );
  static const _headerMap = TypeChecker.typeNamed(
    HeaderMap,
    inPackage: 'rest_client_builder',
  );
  static const _url = TypeChecker.typeNamed(Url, inPackage: 'rest_client_builder');
  static const _cancel = TypeChecker.typeNamed(
    Cancel,
    inPackage: 'rest_client_builder',
  );
  static const _part = TypeChecker.typeNamed(
    Part,
    inPackage: 'rest_client_builder',
  );
  static const _partMap = TypeChecker.typeNamed(
    PartMap,
    inPackage: 'rest_client_builder',
  );
  static const _field = TypeChecker.typeNamed(
    Field,
    inPackage: 'rest_client_builder',
  );
  static const _fieldMap = TypeChecker.typeNamed(
    FieldMap,
    inPackage: 'rest_client_builder',
  );
  static const _useInterceptor = TypeChecker.typeNamed(
    UseInterceptor,
    inPackage: 'rest_client_builder',
  );
  static const _excludeInterceptor = TypeChecker.typeNamed(
    ExcludeInterceptor,
    inPackage: 'rest_client_builder',
  );
  static const _restResult = TypeChecker.typeNamed(
    RestResult,
    inPackage: 'rest_client_builder',
  );

  @override
  RestApiClassModel? visitClass(ClassElement element) {
    final annotation = _restApi.firstAnnotationOf(
      element,
      throwOnUnresolved: false,
    );
    if (annotation == null) {
      return null;
    }

    final restApi = ConstantReader(annotation);
    final baseUrlFromApi = restApi.peek('baseUrl')?.stringValue;
    final pathPrefix = restApi.peek('path')?.stringValue ?? '';
    final configType = restApi.peek('configuration')?.typeValue;
    final configName = configType?.element?.name;
    final baseUrlFromAnno = _readStringAnnotation(element, _baseUrl, 'value');
    final headers = {..._readHeaders(element)};

    final methods = <RestMethodModel>[
      for (final method in element.methods)
        if (!method.isStatic)
          ?_visitMethod(method, element, pathPrefix),
    ];

    return RestApiClassModel(
      name: element.name ?? '',
      methods: methods,
      baseUrl: baseUrlFromApi ?? baseUrlFromAnno,
      defaultHeaders: headers,
      globalInterceptors: _readInterceptorTypes(element, _useInterceptor),
      excludeInterceptors: _readInterceptorTypes(element, _excludeInterceptor),
      enableLog: _readBoolAnnotation(element, _enableLog, 'enabled'),
      retryMaxAttempts: _readIntAnnotation(element, _retry, 'maxAttempts'),
      retryDelayMs: _readIntAnnotation(element, _retry, 'delayMs'),
      retryStatusCodes: _readIntListAnnotation(
        element,
        _retry,
        'retryStatusCodes',
      ),
      connectTimeoutMs: _readIntAnnotation(
        element,
        _connectTimeout,
        'milliseconds',
      ),
      receiveTimeoutMs: _readIntAnnotation(
        element,
        _receiveTimeout,
        'milliseconds',
      ),
      sendTimeoutMs: _readIntAnnotation(element, _sendTimeout, 'milliseconds'),
      configurationName: configName,
    );
  }

  @override
  RestMethodModel? visitMethod(MethodElement element) {
    final enclosing = (element as dynamic).enclosingElement3 ?? (element as dynamic).enclosingElement;
    final classEl = enclosing is ClassElement ? enclosing : null;
    if (classEl == null) return null;
    return _visitMethod(element, classEl, '');
  }

  RestMethodModel? _visitMethod(
    MethodElement element,
    ClassElement classElement,
    String pathPrefix,
  ) {
    final http = _readHttpMethod(element);
    if (http == null) {
      // Check for @SSE — which needs an HTTP method annotation too.
      if (_sse.hasAnnotationOf(element, throwOnUnresolved: false) ||
          _hasAnnotationNamed(element, 'SSE')) {
        throw InvalidGenerationSourceError(
          '@SSE on `${element.name}` requires a verb annotation '
          '(e.g. @GET, @HTTP).',
          element: element,
        );
      }
      return null;
    }

    final isStreaming = _streaming.hasAnnotationOf(
          element,
          throwOnUnresolved: false,
        ) ||
        _hasAnnotationNamed(element, 'Streaming');

    final isSse = _sse.hasAnnotationOf(
          element,
          throwOnUnresolved: false,
        ) ||
        _hasAnnotationNamed(element, 'SSE');

    // Read @ResilientQueue / @OfflineQueue fields.
    final offlineAnnotationObj = _resilientQueue.firstAnnotationOf(
          element,
          throwOnUnresolved: false,
        ) ??
        _offlineQueue.firstAnnotationOf(
          element,
          throwOnUnresolved: false,
        ) ??
        _findAnnotationNamed(element, 'ResilientQueue')
            ?.computeConstantValue() ??
        _findAnnotationNamed(element, 'OfflineQueue')
            ?.computeConstantValue();
    final isOfflineQueue = offlineAnnotationObj != null;
    final offlineReader = offlineAnnotationObj != null
        ? ConstantReader(offlineAnnotationObj)
        : null;
    final offlineQueueRemoveWhen = offlineReader
            ?.peek('removeWhen')
            ?.listValue
            .map((e) => e.toIntValue() ?? 200)
            .toList() ??
        const <int>[200, 201, 202, 204];
    final enqueueOnConnectionError =
        offlineReader?.peek('enqueueOnConnectionError')?.boolValue ?? true;
    final enqueueOnTimeout =
        offlineReader?.peek('enqueueOnTimeout')?.boolValue ?? true;
    final enqueueOnServerError =
        offlineReader?.peek('enqueueOnServerError')?.boolValue ?? false;
    final enqueueOnStatusCodes = offlineReader
            ?.peek('enqueueOnStatusCodes')
            ?.listValue
            .map((e) => e.toIntValue() ?? 0)
            .where((code) => code > 0)
            .toList() ??
        const <int>[];


    return RestMethodModel(
      name: element.name ?? '',
      httpMethod: http.method,
      path: _joinPaths(pathPrefix, http.path),
      returnType: _parseReturnType(
        element,
        isStreaming: isStreaming,
        isSse: isSse,
      ),
      parameters: [
        for (final parameter in element.formalParameters)
          visitParameter(parameter),
      ].whereType<RestParameterModel>().toList(growable: false),
      headers: _readHeaders(element),
      isMultipart: _multipart.hasAnnotationOf(
        element,
        throwOnUnresolved: false,
      ),
      isFormUrlEncoded: _form.hasAnnotationOf(
        element,
        throwOnUnresolved: false,
      ),
      isStreaming: isStreaming,
      isSse: isSse,
      isOfflineQueue: isOfflineQueue,
      offlineQueueRemoveWhen: offlineQueueRemoveWhen,
      enqueueOnConnectionError: enqueueOnConnectionError,
      enqueueOnTimeout: enqueueOnTimeout,
      enqueueOnServerError: enqueueOnServerError,
      enqueueOnStatusCodes: enqueueOnStatusCodes,
      useInterceptors: _readInterceptorTypes(element, _useInterceptor),
      excludeInterceptors: _readInterceptorTypes(element, _excludeInterceptor),
      enableLog: _readBoolAnnotation(element, _enableLog, 'enabled'),
      retryMaxAttempts: _readIntAnnotation(element, _retry, 'maxAttempts'),
      retryDelayMs: _readIntAnnotation(element, _retry, 'delayMs'),
      retryStatusCodes: _readIntListAnnotation(
        element,
        _retry,
        'retryStatusCodes',
      ),
      connectTimeoutMs: _readIntAnnotation(
        element,
        _connectTimeout,
        'milliseconds',
      ),
      receiveTimeoutMs: _readIntAnnotation(
        element,
        _receiveTimeout,
        'milliseconds',
      ),
      sendTimeoutMs: _readIntAnnotation(element, _sendTimeout, 'milliseconds'),
      cacheDurationMs: _readIntAnnotation(element, _cache, 'durationMs') ??
          _readIntAnnotation(classElement, _cache, 'durationMs'),
    );
  }

  @override
  RestParameterModel? visitParameter(FormalParameterElement element) {
    final kind = _parameterKind(element);
    if (kind == null) {
      // Optional named/positional parameters without a binding annotation are
      // silently skipped — they are implementation details, not REST bindings.
      // Positional required parameters must always declare a binding annotation.
      final isOptional =
          !element.isRequiredPositional && !element.isRequiredNamed;
      if (isOptional) return null;
      throw InvalidGenerationSourceError(
        'Parameter `${element.name}` on a REST method must have a binding '
        'annotation (@Path, @Query, @Body, @Header, @Part, @Field, etc.). '
        'Optional named parameters without an annotation are silently skipped.',
        element: element,
      );
    }

    final type = element.type;
    final usesToJson = _usesToJson(type);
    final sourceUri = usesToJson ? type.element?.library?.firstFragment.source.uri.toString() : null;
    return RestParameterModel(
      name: element.name ?? '',
      typeName: type.getDisplayString(),
      kind: kind,
      annotationName: _bindingName(element, kind),
      encoded: _isEncoded(element, kind),
      fileName: _partField(element, 'fileName'),
      contentType: _partField(element, 'contentType'),
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      usesToJson: usesToJson,
      isNamed: element.isNamed,
      isRequired: element.isRequiredNamed || element.isRequiredPositional,
      modelSourceUri: sourceUri,
    );
  }

  ({String method, String path})? _readHttpMethod(MethodElement element) {
    for (final entry in <(TypeChecker, String)>[
      (_get, 'GET'),
      (_post, 'POST'),
      (_put, 'PUT'),
      (_patch, 'PATCH'),
      (_delete, 'DELETE'),
      (_head, 'HEAD'),
      (_options, 'OPTIONS'),
    ]) {
      final annotation = entry.$1.firstAnnotationOf(
        element,
        throwOnUnresolved: false,
      );
      if (annotation != null) {
        final reader = ConstantReader(annotation);
        final path = reader.peek('path')?.stringValue ?? '';
        return (method: entry.$2, path: path);
      }
    }
    // Generic @HTTP annotation — any custom verb.
    final httpAnnotation = _http.firstAnnotationOf(
      element,
      throwOnUnresolved: false,
    );
    if (httpAnnotation != null) {
      final reader = ConstantReader(httpAnnotation);
      // HttpMethod stores the verb in the 'method' field.
      final rawMethod = reader.peek('method')?.stringValue ?? 'GET';
      final path = reader.peek('path')?.stringValue ?? '';
      return (method: rawMethod.toUpperCase(), path: path);
    }
    return null;
  }

  RestReturnTypeModel _parseReturnType(
    MethodElement element, {
    bool isStreaming = false,
    bool isSse = false,
  }) {
    final raw = element.returnType.getDisplayString();
    var type = element.returnType;
    var isFuture = false;

    // SSE methods return Stream<SSEEvent> directly — no Future or RestResult wrap.
    if (isSse) {
      final isStream = type is InterfaceType &&
          type.isDartAsyncStream;
      if (!isStream) {
        throw InvalidGenerationSourceError(
          '@SSE methods must return `Stream<SSEEvent>` '
          '(found `$raw` on `${element.name}`).',
          element: element,
        );
      }
      return RestReturnTypeModel(
        rawTypeName: raw,
        isFuture: false,
        isRestResult: false,
        isSse: true,
        resultTypeName: 'SSEEvent',
      );
    }

    if (type.isDartAsyncFuture || type.isDartAsyncFutureOr) {
      isFuture = true;
      type = (type as InterfaceType).typeArguments.first;
    }

    // Streaming methods must return Future<RestResult<Stream<List<int>>>>.
    if (isStreaming) {
      final isRestResult = _restResult.isAssignableFromType(type);
      if (!isRestResult) {
        throw InvalidGenerationSourceError(
          '@Streaming methods must return `Future<RestResult<Stream<List<int>>>>` '
          '(found `$raw` on `${element.name}`).',
          element: element,
        );
      }
      return RestReturnTypeModel(
        rawTypeName: raw,
        isFuture: isFuture,
        isRestResult: true,
        isStreaming: true,
        resultTypeName: 'Stream<List<int>>',
      );
    }

    final isRestResult = _restResult.isAssignableFromType(type);
    if (!isRestResult) {
      throw InvalidGenerationSourceError(
        'REST methods must return `Future<RestResult<T>>` '
        '(found `$raw` on `${element.name}`).',
        element: element,
      );
    }

    final resultType = (type as InterfaceType).typeArguments.first;
    return _parseResultInner(raw, isFuture: isFuture, resultType: resultType);
  }

  RestReturnTypeModel _parseResultInner(
    String raw, {
    required bool isFuture,
    required DartType resultType,
  }) {
    if (resultType is VoidType ||
        resultType.isDartCoreNull ||
        resultType.getDisplayString() == 'void') {
      return RestReturnTypeModel(
        rawTypeName: raw,
        isFuture: isFuture,
        isRestResult: true,
        isVoid: true,
      );
    }
    if (resultType is DynamicType || resultType.isDartCoreObject) {
      return RestReturnTypeModel(
        rawTypeName: raw,
        isFuture: isFuture,
        isRestResult: true,
        isDynamic: true,
        resultTypeName: resultType.getDisplayString(),
      );
    }
    if (resultType.isDartCoreMap) {
      return RestReturnTypeModel(
        rawTypeName: raw,
        isFuture: isFuture,
        isRestResult: true,
        isMap: true,
        resultTypeName: resultType.getDisplayString(),
      );
    }
    if (resultType.isDartCoreList) {
      final item = (resultType as InterfaceType).typeArguments.first;
      final itemIsModel = _usesToJson(item);
      final sourceUri = itemIsModel ? item.element?.library?.firstFragment.source.uri.toString() : null;
      return RestReturnTypeModel(
        rawTypeName: raw,
        isFuture: isFuture,
        isRestResult: true,
        isList: true,
        isModel: itemIsModel,
        resultTypeName: item.getDisplayString().replaceAll('?', ''),
        modelSourceUri: sourceUri,
      );
    }
    if (_usesToJson(resultType)) {
      final sourceUri = resultType.element?.library?.firstFragment.source.uri.toString();
      return RestReturnTypeModel(
        rawTypeName: raw,
        isFuture: isFuture,
        isRestResult: true,
        isModel: true,
        resultTypeName: resultType.getDisplayString().replaceAll('?', ''),
        modelSourceUri: sourceUri,
      );
    }

    return RestReturnTypeModel(
      rawTypeName: raw,
      isFuture: isFuture,
      isRestResult: true,
      resultTypeName: resultType.getDisplayString().replaceAll('?', ''),
      isDynamic: true,
    );
  }

  RestParameterKind? _parameterKind(FormalParameterElement element) {
    if (_cancel.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.cancelToken;
    }
    // Backward-compatible: bare `CancelToken` / `CancelToken?` params.
    if (_isCancelToken(element.type)) {
      return RestParameterKind.cancelToken;
    }
    if (_isProgressCallback(element.type)) {
      final name = element.name;
      if (name == 'onReceiveProgress' ||
          name == 'onDownloadProgress' ||
          name == 'downloadProgress') {
        return RestParameterKind.downloadProgress;
      }
      return RestParameterKind.uploadProgress;
    }
    if (_path.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.path;
    }
    if (_query.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.query;
    }
    if (_queryMap.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.queryMap;
    }
    if (_body.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.body;
    }
    if (_header.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.header;
    }
    if (_headerMap.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.headerMap;
    }
    if (_url.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.url;
    }
    if (_part.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.part;
    }
    if (_partMap.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.partMap;
    }
    if (_field.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.field;
    }
    if (_fieldMap.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return RestParameterKind.fieldMap;
    }
    return null;
  }

  String? _bindingName(FormalParameterElement element, RestParameterKind kind) {
    switch (kind) {
      case RestParameterKind.path:
        return _readOptionalName(element, _path);
      case RestParameterKind.query:
        return _readOptionalName(element, _query);
      case RestParameterKind.header:
        return ConstantReader(
          _header.firstAnnotationOf(element)!,
        ).read('name').stringValue;
      case RestParameterKind.part:
        final reader = ConstantReader(_part.firstAnnotationOf(element)!);
        return reader.peek('name')?.stringValue;
      case RestParameterKind.field:
        return _readOptionalName(element, _field);
      case RestParameterKind.queryMap:
      case RestParameterKind.body:
      case RestParameterKind.headerMap:
      case RestParameterKind.url:
      case RestParameterKind.partMap:
      case RestParameterKind.fieldMap:
      case RestParameterKind.cancelToken:
      case RestParameterKind.uploadProgress:
      case RestParameterKind.downloadProgress:
        return null;
    }
  }

  String? _readOptionalName(
    FormalParameterElement element,
    TypeChecker checker,
  ) {
    final annotation = checker.firstAnnotationOf(element);
    if (annotation == null) {
      return null;
    }
    final peek = ConstantReader(annotation).peek('name');
    if (peek == null || peek.isNull) {
      return null;
    }
    return peek.stringValue;
  }

  bool _isEncoded(FormalParameterElement element, RestParameterKind kind) {
    if (kind == RestParameterKind.query) {
      return ConstantReader(
        _query.firstAnnotationOf(element)!,
      ).read('encoded').boolValue;
    }
    if (kind == RestParameterKind.queryMap) {
      return ConstantReader(
        _queryMap.firstAnnotationOf(element)!,
      ).read('encoded').boolValue;
    }
    return false;
  }

  String? _partField(FormalParameterElement element, String field) {
    final annotation = _part.firstAnnotationOf(
      element,
      throwOnUnresolved: false,
    );
    if (annotation == null) {
      return null;
    }
    final peek = ConstantReader(annotation).peek(field);
    if (peek == null || peek.isNull) {
      return null;
    }
    return peek.stringValue;
  }

  static const _modelChecker = TypeChecker.fromUrl(
    'package:rest_client_builder/src/annotations/models/rest_model.dart#RestModel',
  );

  bool _usesToJson(DartType type) {
    final element = type.element;
    if (element is! ClassElement) {
      return false;
    }
    if (element.name == 'RestPart') {
      return false;
    }
    
    if (_modelChecker.hasAnnotationOf(element, throwOnUnresolved: false)) {
      return true;
    }

    return element.lookUpMethod(name: 'toJson', library: element.library) !=
            null ||
        element.methods.any((method) => method.name == 'toJson');
  }

  bool _isCancelToken(DartType type) {
    final element = type.element;
    return element != null && element.name == 'CancelToken';
  }

  bool _isProgressCallback(DartType type) {
    final aliasName = type.alias?.element.name;
    if (aliasName == 'RestProgressCallback') {
      return true;
    }
    final display = type.getDisplayString();
    return display.startsWith('RestProgressCallback') ||
        display.startsWith('void Function(int, int)') ||
        display.startsWith('void Function(int count, int total)');
  }

  List<String> _readInterceptorTypes(Element element, TypeChecker checker) {
    final annotation = checker.firstAnnotationOf(
      element,
      throwOnUnresolved: false,
    );
    if (annotation == null) {
      return const <String>[];
    }
    final values =
        ConstantReader(annotation).peek('interceptors')?.listValue ?? const [];
    return [
      for (final value in values)
        ?value.toTypeValue()?.element?.name,
    ];
  }

  Map<String, String> _readHeaders(Element element) {
    final annotation = _headers.firstAnnotationOf(
      element,
      throwOnUnresolved: false,
    );
    if (annotation == null) {
      return const {};
    }
    final map = ConstantReader(annotation).read('value').mapValue;
    return {
      for (final entry in map.entries)
        ?entry.key?.toStringValue(): ?entry.value?.toStringValue(),
    };
  }

  String? _readStringAnnotation(
    Element element,
    TypeChecker checker,
    String field,
  ) {
    final annotation = checker.firstAnnotationOf(
      element,
      throwOnUnresolved: false,
    );
    if (annotation == null) {
      return null;
    }
    final value = ConstantReader(annotation).peek(field);
    if (value == null || value.isNull) {
      return null;
    }
    return value.stringValue;
  }

  int? _readIntAnnotation(Element element, TypeChecker checker, String field) {
    final annotation = checker.firstAnnotationOf(
      element,
      throwOnUnresolved: false,
    );
    return annotation == null
        ? null
        : ConstantReader(annotation).read(field).intValue;
  }

  bool? _readBoolAnnotation(
    Element element,
    TypeChecker checker,
    String field,
  ) {
    final annotation = checker.firstAnnotationOf(
      element,
      throwOnUnresolved: false,
    );
    return annotation == null
        ? null
        : ConstantReader(annotation).read(field).boolValue;
  }

  List<int>? _readIntListAnnotation(
    Element element,
    TypeChecker checker,
    String field,
  ) {
    final annotation = checker.firstAnnotationOf(
      element,
      throwOnUnresolved: false,
    );
    if (annotation == null) return null;
    final value = ConstantReader(annotation).peek(field);
    if (value == null || value.isNull) return null;
    return value.listValue
        .map((element) => element.toIntValue() ?? 0)
        .toList(growable: false);
  }

  bool _hasAnnotationNamed(Element element, String name) {
    // ignore: avoid_dynamic_calls
    final dynamic metaList =
        (element.metadata as dynamic).annotations ?? element.metadata;
    for (final dynamic annotation in (metaList as Iterable<dynamic>)) {
      final source = annotation.toSource() as String;
      if (source == '@$name' || source.startsWith('@$name(')) {
        return true;
      }
      final el = annotation.element;
      final enclosingName = el is ConstructorElement
          ? (el as dynamic).enclosingElement?.name
          : el?.name;
      if (enclosingName == name) return true;
    }
    return false;
  }

  ElementAnnotation? _findAnnotationNamed(Element element, String name) {
    // ignore: avoid_dynamic_calls
    final dynamic metaList =
        (element.metadata as dynamic).annotations ?? element.metadata;
    for (final dynamic annotation in (metaList as Iterable<dynamic>)) {
      final source = annotation.toSource() as String;
      if (source == '@$name' || source.startsWith('@$name(')) {
        return annotation as ElementAnnotation;
      }
      final el = annotation.element;
      final enclosingName = el is ConstructorElement
          ? (el as dynamic).enclosingElement?.name
          : el?.name;
      if (enclosingName == name) return annotation as ElementAnnotation;
    }
    return null;
  }

  String _joinPaths(String prefix, String path) {
    if (prefix.isEmpty) return path;
    if (path.isEmpty) return prefix;
    return '${prefix.endsWith('/') ? prefix.substring(0, prefix.length - 1) : prefix}'
        '${path.startsWith('/') ? path : '/$path'}';
  }
}
