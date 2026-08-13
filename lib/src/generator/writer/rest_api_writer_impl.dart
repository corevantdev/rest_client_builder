import 'package:dart_style/dart_style.dart';

import '../model/generation_models.dart';
import 'source_writer.dart';

/// Writes `_Api` implementations for `@RestApi` classes into `*.rest.g.dart`.
class DefaultRestApiWriter implements RestApiWriter {
  /// Creates a RestApi writer.
  const DefaultRestApiWriter();

  static final DartFormatter _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  @override
  String writeApi(RestApiClassModel api) {
    final implName = '${api.name}Impl';
    final privateAlias = '_${api.name}';
    final methods = api.methods
        .map((method) => _writeMethod(api, method))
        .join('\n\n');
    final baseUrlFallback = api.baseUrl == null
        ? "''"
        : "'${_escape(api.baseUrl!)}'";
    final defaultHeaders = _mapLiteral(api.defaultHeaders);
    final clientFallback = api.configurationName == null
        ? 'RestApiClientRegistry.defaultClient'
        : 'RestApiClientRegistry.sharedClient(${api.configurationName}())';

    final source =
        '''
${_apiFileDocumentation(api)}
${_apiDocsClass(api)}

typedef $privateAlias = $implName;

${_apiCreateFunction(api, implName)}

class $implName implements ${api.name} {
  $implName({
    RestClient? client,
    this.baseUrl,
    Map<String, String>? headers,
  })  : _client = client ?? $clientFallback,
        _headers = <String, String>{
          ...$defaultHeaders,
          ...?headers,
        };

  final RestClient _client;
  final String? baseUrl;
  final Map<String, String> _headers;

  String get _effectiveBaseUrl => baseUrl ?? $baseUrlFallback;

  $methods
}
''';
    return _formatter.format(source);
  }

  String _apiCreateFunction(RestApiClassModel api, String implName) {
    final camelName = _camelCase(api.name);
    return '''
/// Shared process-wide instance of [${api.name}] using the default client.
${api.name} get $camelName => $implName();

/// Creates a [${api.name}] backed by the generated `$implName` implementation.
${api.name} create${api.name}({
  RestClient? client,
  String? baseUrl,
  Map<String, String>? headers,
}) =>
    $implName(client: client, baseUrl: baseUrl, headers: headers);

/// Extension to cleanly instantiate [${api.name}] directly from a [RestClient].
extension ${api.name}ClientExtension on RestClient {
  /// Returns a new [${api.name}] bound to this client.
  ${api.name} get $camelName => create${api.name}(client: this);
}
''';
  }

  String _camelCase(String name) {
    if (name.isEmpty) return name;
    return name[0].toLowerCase() + name.substring(1);
  }

  String _apiFileDocumentation(RestApiClassModel api) {
    final base = api.baseUrl == null || api.baseUrl!.isEmpty
        ? '(no default base URL)'
        : api.baseUrl!;
    final rows = api.methods
        .map((method) {
          final flags = <String>[
            if (method.isMultipart) 'multipart',
            if (method.isFormUrlEncoded) 'form',
            if (method.isStreaming) 'streaming',
          ];
          final suffix = flags.isEmpty ? '' : ' [${flags.join(', ')}]';
          return '/// | `${method.httpMethod}` | `${_escape(method.path)}` | '
              '[${api.name}.${method.name}]$suffix |';
        })
        .join('\n');

    return '''
/// Generated REST client implementation for [${api.name}].
///
/// **Base URL:** `$base`
///
/// ## Endpoints
///
/// | HTTP | Path | Method |
/// |------|------|--------|
$rows
///
/// Do not edit by hand. Regenerate with `dart run build_runner build`.
''';
  }

  String _apiDocsClass(RestApiClassModel api) {
    final entries = api.methods
        .map((method) {
          final route = '${method.httpMethod} ${_escape(method.path)}';
          return "  '$route => ${method.name}',";
        })
        .join('\n');

    return '''
/// Machine-readable endpoint documentation for [${api.name}].
///
/// Generated next to the private `_${api.name}` implementation.
abstract final class ${api.name}Docs {
  /// `METHOD path => dartMethod` entries for this API.
  static const List<String> endpoints = <String>[
$entries
  ];
}
''';
  }

  String _methodDocumentation(RestApiClassModel api, RestMethodModel method) {
    final lines = <String>[
      '/// `${method.httpMethod} ${_escape(method.path)}`',
      '///',
      '/// Generated implementation of [${api.name}.${method.name}].',
    ];

    if (method.isMultipart) {
      lines.add('///');
      lines.add('/// Content-Type: `multipart/form-data`');
    } else if (method.isFormUrlEncoded) {
      lines.add('///');
      lines.add('/// Content-Type: `application/x-www-form-urlencoded`');
    } else if (method.isStreaming) {
      lines.add('///');
      lines.add('/// Response: raw `Stream<List<int>>` (byte stream — not buffered).');
    }

    final pathParams = method.parameters
        .where((p) => p.kind == RestParameterKind.path)
        .map((p) => p.name)
        .toList();
    final queryParams = method.parameters
        .where(
          (p) =>
              p.kind == RestParameterKind.query ||
              p.kind == RestParameterKind.queryMap,
        )
        .map((p) => p.name)
        .toList();
    final headerParams = method.parameters
        .where(
          (p) =>
              p.kind == RestParameterKind.header ||
              p.kind == RestParameterKind.headerMap,
        )
        .map((p) => p.name)
        .toList();

    if (pathParams.isNotEmpty) {
      lines
        ..add('///')
        ..add('/// Path: ${pathParams.map((n) => '[$n]').join(', ')}');
    }
    if (queryParams.isNotEmpty) {
      lines
        ..add('///')
        ..add('/// Query: ${queryParams.map((n) => '[$n]').join(', ')}');
    }
    if (headerParams.isNotEmpty) {
      lines
        ..add('///')
        ..add('/// Headers: ${headerParams.map((n) => '[$n]').join(', ')}');
    }
    if (method.parameters.any((p) => p.kind == RestParameterKind.cancelToken)) {
      lines
        ..add('///')
        ..add('/// Supports [CancelToken] cancellation.');
    }
    if (method.parameters.any(
      (p) =>
          p.kind == RestParameterKind.uploadProgress ||
          p.kind == RestParameterKind.downloadProgress,
    )) {
      lines
        ..add('///')
        ..add('/// Supports upload/download [RestProgressCallback]s.');
    }

    return lines.join('\n');
  }

  String _writeMethod(RestApiClassModel api, RestMethodModel method) {
    final signature =
        '${_methodDocumentation(api, method)}\n'
        '  @override\n'
        '  ${method.returnTypeName} ${method.name}(${_parameterList(method)}) async';

    final body = StringBuffer()
      ..writeln('final pathParams = <String, String>{')
      ..writeln(_pathEntries(method))
      ..writeln('};')
      ..writeln('final query = <String, String>{')
      ..writeln(_queryEntries(method))
      ..writeln('};')
      ..writeln('final requestHeaders = <String, String>{')
      ..writeln('  ..._headers,')
      ..writeln(_headerStaticEntries(method))
      ..writeln(_headerParamEntries(method))
      ..writeln('};')
      ..writeln(
        "final resolvedPath = resolveRestPath('${_escape(method.path)}', pathParams);",
      )
      ..writeln(_urlOverride(method))
      ..writeln(_bodySetup(method))
      ..writeln('final httpRequest = BasicRestRequest(')
      ..writeln("  method: '${method.httpMethod}',")
      ..writeln('  path: resolvedPath,')
      ..writeln('  url: absoluteUrl,')
      ..writeln('  headers: requestHeaders,')
      ..writeln('  queryParameters: query,')
      ..writeln('  body: body,')
      ..writeln('  bodyType: bodyType,')
      ..writeln('  multipartBody: multipartBody,')
      ..writeln(
        '  connectTimeoutMs: ${_intOption(method.connectTimeoutMs, api.connectTimeoutMs)},',
      )
      ..writeln(
        '  receiveTimeoutMs: ${_intOption(method.receiveTimeoutMs, api.receiveTimeoutMs)},',
      )
      ..writeln(
        '  sendTimeoutMs: ${_intOption(method.sendTimeoutMs, api.sendTimeoutMs)},',
      )
      ..writeln('  cancelToken: ${_cancelTokenExpr(method)},')
      ..writeln('  onSendProgress: ${_uploadProgressExpr(method)},')
      ..writeln('  onReceiveProgress: ${_downloadProgressExpr(method)},')
      ..writeln('  extras: ${_extrasLiteral(api, method)},')
      ..writeln(');')
      ..writeln('final raw = await _client.execute(httpRequest);')
      ..writeln('return ${_mapExpression(method)};');

    return '''
  $signature {
    ${body.toString().split('\n').join('\n    ')}
  }
''';
  }

  String _cancelTokenExpr(RestMethodModel method) {
    final param = method.parameters
        .where((parameter) => parameter.kind == RestParameterKind.cancelToken)
        .firstOrNull;
    return param?.name ?? 'null';
  }

  String _uploadProgressExpr(RestMethodModel method) {
    final param = method.parameters
        .where(
          (parameter) => parameter.kind == RestParameterKind.uploadProgress,
        )
        .firstOrNull;
    return param?.name ?? 'null';
  }

  String _downloadProgressExpr(RestMethodModel method) {
    final param = method.parameters
        .where(
          (parameter) => parameter.kind == RestParameterKind.downloadProgress,
        )
        .firstOrNull;
    return param?.name ?? 'null';
  }

  String _extrasLiteral(RestApiClassModel api, RestMethodModel method) {
    final use = <String>{
      ...api.globalInterceptors,
      ...method.useInterceptors,
    }.toList(growable: false);
    final exclude = <String>{
      ...api.excludeInterceptors,
      ...method.excludeInterceptors,
    }.toList(growable: false);
    final retryMaxAttempts = method.retryMaxAttempts ?? api.retryMaxAttempts;
    final retryDelayMs = method.retryDelayMs ?? api.retryDelayMs;
    final retryStatusCodes = method.retryStatusCodes ?? api.retryStatusCodes;
    final enableLog = method.enableLog ?? api.enableLog;
    if (use.isEmpty &&
        exclude.isEmpty &&
        retryMaxAttempts == null &&
        retryDelayMs == null &&
        retryStatusCodes == null &&
        enableLog == null &&
        !method.isStreaming) {
      return 'const <String, Object?>{}';
    }
    final buffer = StringBuffer('<String, Object?>{');
    if (method.isStreaming) {
      buffer.write("'responseType': 'stream',");
    }
    if (use.isNotEmpty) {
      final names = use.map((name) => "'${_escape(name)}'").join(', ');
      buffer.write('RestInterceptorExtras.useInterceptors: <String>[$names],');
    }
    if (exclude.isNotEmpty) {
      final names = exclude.map((name) => "'${_escape(name)}'").join(', ');
      buffer.write(
        'RestInterceptorExtras.excludeInterceptors: <String>[$names],',
      );
    }
    if (retryMaxAttempts != null) {
      buffer.write('RestExecutionExtras.retryMaxAttempts: $retryMaxAttempts,');
    }
    if (retryDelayMs != null) {
      buffer.write('RestExecutionExtras.retryDelayMs: $retryDelayMs,');
    }
    if (retryStatusCodes != null) {
      buffer.write(
        'RestExecutionExtras.retryStatusCodes: <int>[${retryStatusCodes.join(', ')}],',
      );
    }
    if (enableLog != null) {
      buffer.write('RestExecutionExtras.enableLog: $enableLog,');
    }
    if (method.cacheDurationMs != null) {
      buffer.write("'cacheDurationMs': ${method.cacheDurationMs},");
    }
    buffer.write('}');
    return buffer.toString();
  }

  String _intOption(int? methodValue, int? apiValue) =>
      (methodValue ?? apiValue)?.toString() ?? 'null';

  String _parameterList(RestMethodModel method) {
    final positional = method.parameters.where((p) => !p.isNamed).toList();
    final named = method.parameters.where((p) => p.isNamed).toList();
    final parts = <String>[
      for (final parameter in positional) _parameterDecl(parameter),
    ];
    if (named.isNotEmpty) {
      final namedDecls = named.map(_parameterDecl).join(', ');
      parts.add('{$namedDecls}');
    }
    return parts.join(', ');
  }

  String _parameterDecl(RestParameterModel parameter) {
    final prefix = parameter.isNamed && parameter.isRequired ? 'required ' : '';
    return '$prefix${parameter.typeName} ${parameter.name}';
  }

  String _pathEntries(RestMethodModel method) {
    final entries = method.parameters
        .where((parameter) => parameter.kind == RestParameterKind.path)
        .map((parameter) {
          final value = 'stringifyRestValue(${parameter.name})';
          return "  '${_escape(parameter.bindingName)}': $value,";
        });
    return entries.join('\n');
  }

  String _queryEntries(RestMethodModel method) {
    final buffer = StringBuffer();
    for (final parameter in method.parameters) {
      switch (parameter.kind) {
        case RestParameterKind.query:
          final key = _escape(parameter.bindingName);
          final value = 'stringifyRestValue(${parameter.name})';
          if (parameter.isNullable) {
            buffer.writeln("  if (${parameter.name} != null) '$key': $value,");
          } else {
            buffer.writeln("  '$key': $value,");
          }
        case RestParameterKind.queryMap:
          if (parameter.isNullable) {
            buffer.writeln(
              '  if (${parameter.name} != null) '
              '...${parameter.name}.map((k, v) => MapEntry(k, stringifyRestValue(v))),',
            );
          } else {
            buffer.writeln(
              '  ...${parameter.name}.map((k, v) => MapEntry(k, stringifyRestValue(v))),',
            );
          }
        default:
          break;
      }
    }
    return buffer.toString();
  }

  String _headerStaticEntries(RestMethodModel method) {
    return method.headers.entries
        .map((entry) => "  '${_escape(entry.key)}': '${_escape(entry.value)}',")
        .join('\n');
  }

  String _headerParamEntries(RestMethodModel method) {
    final buffer = StringBuffer();
    for (final parameter in method.parameters) {
      switch (parameter.kind) {
        case RestParameterKind.header:
          final key = _escape(parameter.bindingName);
          final value = 'stringifyRestValue(${parameter.name})';
          if (parameter.isNullable) {
            buffer.writeln("  if (${parameter.name} != null) '$key': $value,");
          } else {
            buffer.writeln("  '$key': $value,");
          }
        case RestParameterKind.headerMap:
          if (parameter.isNullable) {
            buffer.writeln(
              '  if (${parameter.name} != null) ...${parameter.name},',
            );
          } else {
            buffer.writeln('  ...${parameter.name},');
          }
        default:
          break;
      }
    }
    return buffer.toString();
  }

  String _urlOverride(RestMethodModel method) {
    final urlParam = method.parameters
        .where((parameter) => parameter.kind == RestParameterKind.url)
        .firstOrNull;
    if (urlParam != null) {
      return 'final String? absoluteUrl = ${urlParam.name};';
    }
    return 'final String? absoluteUrl = _effectiveBaseUrl.isEmpty '
        '? null '
        ': joinRestUrl(_effectiveBaseUrl, resolvedPath);';
  }

  String _bodySetup(RestMethodModel method) {
    if (method.isMultipart) {
      return '''
final multipartBody = BasicMultipartBody(parts: [
${_multipartParts(method)}
]);
const Object? body = null;
const bodyType = RestBodyType.multipart;
''';
    }
    if (method.isFormUrlEncoded) {
      return '''
final body = <String, String>{
${_formFields(method)}
};
const multipartBody = null;
const bodyType = RestBodyType.formUrlEncoded;
''';
    }

    final bodyParam = method.parameters
        .where((parameter) => parameter.kind == RestParameterKind.body)
        .firstOrNull;
    if (bodyParam == null) {
      return '''
const Object? body = null;
const multipartBody = null;
const bodyType = RestBodyType.none;
''';
    }

    final encoded = bodyParam.usesToJson
        ? (bodyParam.isNullable
            ? '${bodyParam.name} == null ? null : rest${bodyParam.typeName.replaceAll('?', '')}ToJson(${bodyParam.name})'
            : 'rest${bodyParam.typeName}ToJson(${bodyParam.name})')
        : bodyParam.name;

    return '''
final Object? body = $encoded;
const multipartBody = null;
const bodyType = RestBodyType.json;
''';
  }

  String _multipartParts(RestMethodModel method) {
    final buffer = StringBuffer();
    for (final parameter in method.parameters) {
      if (parameter.kind == RestParameterKind.part) {
        buffer.write(_multipartPartEntry(parameter));
      } else if (parameter.kind == RestParameterKind.partMap) {
        if (parameter.isNullable) {
          buffer.writeln(
            '  if (${parameter.name} != null) '
            '...${parameter.name}.entries.map((e) => e.value is RestMultipartPart '
            '? (e.value as RestMultipartPart) '
            ': BasicMultipartPart(name: e.key, value: e.value)),',
          );
        } else {
          buffer.writeln(
            '  ...${parameter.name}.entries.map((e) => e.value is RestMultipartPart '
            '? (e.value as RestMultipartPart) '
            ': BasicMultipartPart(name: e.key, value: e.value)),',
          );
        }
      }
    }
    return buffer.toString();
  }

  String _multipartPartEntry(RestParameterModel parameter) {
    final name = _escape(parameter.bindingName);
    final isRestPart = parameter.typeName.replaceAll('?', '') == 'RestPart';
    if (isRestPart) {
      final expr = "${parameter.name}.withName('$name')";
      if (parameter.isNullable) {
        return '  if (${parameter.name} != null) $expr,\n';
      }
      return '  $expr,\n';
    }

    final value = parameter.usesToJson
        ? '${parameter.name}.toJson()'
        : parameter.name;
    final fileName = parameter.fileName == null
        ? 'null'
        : "'${_escape(parameter.fileName!)}'";
    final contentType = parameter.contentType == null
        ? 'null'
        : "'${_escape(parameter.contentType!)}'";
    final part =
        'BasicMultipartPart('
        "name: '$name', value: $value, fileName: $fileName, "
        'contentType: $contentType)';
    if (parameter.isNullable) {
      return '  if (${parameter.name} != null) $part,\n';
    }
    return '  $part,\n';
  }

  String _formFields(RestMethodModel method) {
    final buffer = StringBuffer();
    for (final parameter in method.parameters) {
      switch (parameter.kind) {
        case RestParameterKind.field:
          final key = _escape(parameter.bindingName);
          final value = 'stringifyRestValue(${parameter.name})';
          if (parameter.isNullable) {
            buffer.writeln("  if (${parameter.name} != null) '$key': $value,");
          } else {
            buffer.writeln("  '$key': $value,");
          }
        case RestParameterKind.fieldMap:
          if (parameter.isNullable) {
            buffer.writeln(
              '  if (${parameter.name} != null) '
              '...${parameter.name}.map((k, v) => MapEntry(k, stringifyRestValue(v))),',
            );
          } else {
            buffer.writeln(
              '  ...${parameter.name}.map((k, v) => MapEntry(k, stringifyRestValue(v))),',
            );
          }
        default:
          break;
      }
    }
    return buffer.toString();
  }

  String _mapExpression(RestMethodModel method) {
    final returnType = method.returnType;
    if (returnType.isStreaming) {
      return 'RestResponseMapper.mapStream(raw)';
    }
    if (returnType.isVoid) {
      return 'RestResponseMapper.mapVoid(raw)';
    }
    if (returnType.isList && returnType.isModel) {
      final type = returnType.resultTypeName!;
      return 'RestResponseMapper.mapModelList<$type>(raw, rest${type}FromJson)';
    }
    if (returnType.isModel) {
      final type = returnType.resultTypeName!;
      return 'RestResponseMapper.mapModel<$type>(raw, rest${type}FromJson)';
    }
    if (returnType.isList) {
      final type = returnType.resultTypeName!;
      return 'RestResponseMapper.mapCustom<List<$type>>(raw, (data) => '
          '(data as List<dynamic>).map((e) => e as $type).toList())';
    }
    if (returnType.isMap) {
      return 'RestResponseMapper.mapCustom<${returnType.resultTypeName}>('
          'raw, (data) => Map<String, dynamic>.from(data as Map))';
    }
    final type = returnType.resultTypeName ?? 'dynamic';
    return 'RestResponseMapper.mapCustom<$type>(raw, (data) => data as $type)';
  }

  String _mapLiteral(Map<String, String> values) {
    if (values.isEmpty) {
      return '<String, String>{}';
    }
    final entries = values.entries
        .map((entry) => "'${_escape(entry.key)}': '${_escape(entry.value)}'")
        .join(', ');
    return '<String, String>{$entries}';
  }

  String _escape(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n');
  }
}
