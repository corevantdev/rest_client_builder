// ignore_for_file: deprecated_member_use

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';


/// Generates a Dio client factory from plain global-configuration fields.
class RestConfigurationGenerator extends Generator {
  /// Creates a [RestConfigurationGenerator].
  const RestConfigurationGenerator();

  static const _configChecker = TypeChecker.fromUrl(
    'package:rest_client_builder/src/runtime/config/rest_api_global_configuration.dart#RestApiGlobalConfiguration',
  );

  static const _annotationChecker = TypeChecker.fromUrl(
    'package:rest_client_builder/src/annotations/configuration/configuration_annotations.dart#RestConfiguration',
  );

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final elements = library.classes.where((element) =>
        _annotationChecker.hasAnnotationOf(element, throwOnUnresolved: false));

    if (elements.isEmpty) return '';

    final sourceUri = library.element.firstFragment.source.uri.toString();
    final importBuffer = StringBuffer();
    importBuffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    importBuffer.writeln('// ignore_for_file: type=lint');
    importBuffer.writeln("import 'package:rest_client_builder/rest_client_builder.dart';");
    importBuffer.writeln("import '$sourceUri';");

    final codeBuffer = StringBuffer();
    for (final element in elements) {
      if (!_configChecker.isAssignableFromType(element.thisType)) {
        throw InvalidGenerationSourceError(
          '`@RestConfiguration` classes must implement '
          '`RestApiGlobalConfiguration`.',
          element: element,
        );
      }
      final name = element.name;
      codeBuffer.writeln('''
/// Generated runtime factory for [$name].
///
/// Do not edit by hand. Regenerate with `dart run build_runner build`.
extension ${name}RestClientFactory on $name {
  RestGlobalConfig get restClientConfig => RestGlobalConfig(
        baseUrl: baseUrl,
        defaultHeaders: headers,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        enableLog: enableLog,
        retryMaxAttempts: retryMaxAttempts,
        retryDelay: retryDelay,
        retryStatusCodes: retryStatusCodes,
        interceptors: List<RestInterceptor>.unmodifiable(interceptors),
      );

  /// Shared client for this configuration type (reuses Dio connection pool).
  RestClient createRestClient() => RestApiClientRegistry.sharedClient(this);

  /// New uncached client — prefer [createRestClient] in app code.
  RestClient createFreshRestClient() => RestApiClientRegistry.freshClient(this);
}
''');
    }

    return '${importBuffer.toString()}\n${codeBuffer.toString()}';
  }
}
