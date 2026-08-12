import 'dart:async';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'rest_api_generator.dart';
import 'rest_configuration_generator.dart';
import 'rest_model_generator.dart';

/// A custom builder that redirects generated files into `lib/rest_client_builder/`.
class RestClientOutputBuilder implements Builder {
  final Builder _delegate;
  final String generatedExtension;

  RestClientOutputBuilder(Generator generator, {required this.generatedExtension})
      : _delegate = LibraryBuilder(generator, generatedExtension: generatedExtension);

  @override
  Map<String, List<String>> get buildExtensions => {
        '^lib/{{}}.dart': ['lib/rest_client_builder/{{}}$generatedExtension']
      };

  @override
  FutureOr<void> build(BuildStep buildStep) {
    return _delegate.build(buildStep);
  }
}

/// Emits `@RestModel` helpers into `lib/rest_client_builder/<dir>/<file>.g.dart`.
Builder restModelBuilder(BuilderOptions options) {
  return RestClientOutputBuilder(
    const RestModelGenerator(),
    generatedExtension: '.g.dart',
  );
}

/// Emits `@RestApi` client implementations into `lib/rest_client_builder/<dir>/<file>.rest.g.dart`.
Builder restApiBuilder(BuilderOptions options) {
  return RestClientOutputBuilder(
    const RestApiGenerator(),
    generatedExtension: '.rest.g.dart',
  );
}

/// Emits configuration client factories into `lib/rest_client_builder/<dir>/<file>.rest.config.g.dart`.
Builder restConfigurationBuilder(BuilderOptions options) {
  return RestClientOutputBuilder(
    const RestConfigurationGenerator(),
    generatedExtension: '.rest.config.g.dart',
  );
}
