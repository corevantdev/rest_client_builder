import 'dart:async';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'rest_api_generator.dart';
import 'rest_configuration_generator.dart';
import 'rest_export_builder.dart';
import 'rest_model_generator.dart';

/// Default output subfolder for generated files.
const _defaultOutputDir = 'generated';

/// Reads `output_dir` from [BuilderOptions], falling back to [_defaultOutputDir].
String _resolveOutputDir(BuilderOptions options) =>
    options.config['output_dir'] as String? ?? _defaultOutputDir;

/// A custom builder that redirects generated files into `lib/<outputDir>/`.
///
/// The output folder defaults to `generated` and can be overridden per-builder
/// in the consumer's `build.yaml`:
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       rest_client_builder|rest_model:
///         options:
///           output_dir: my_gen   # → lib/my_gen/<path>.g.dart
/// ```
class RestClientOutputBuilder implements Builder {
  /// Creates a [RestClientOutputBuilder].
  ///
  /// [generator] provides the code-generation logic.
  /// [generatedExtension] is appended to the output path (e.g. `.g.dart`).
  /// [outputDir] is the intermediate folder under `lib/` (e.g. `generated`).
  RestClientOutputBuilder(
    Generator generator, {
    required this.generatedExtension,
    required this.outputDir,
  }) : _delegate = LibraryBuilder(generator, generatedExtension: generatedExtension);

  final Builder _delegate;

  /// The generated extension to append to target file paths.
  final String generatedExtension;

  /// Output subfolder under `lib/` (configurable via `output_dir` option).
  final String outputDir;

  @override
  Map<String, List<String>> get buildExtensions => {
        '^lib/{{}}.dart': ['lib/$outputDir/{{}}$generatedExtension'],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) {
    return _delegate.build(buildStep);
  }
}

/// Emits `@RestModel` helpers into `lib/<output_dir>/<dir>/<file>.g.dart`.
Builder restModelBuilder(BuilderOptions options) {
  final outputDir = _resolveOutputDir(options);
  return RestClientOutputBuilder(
    RestModelGenerator(outputDir: outputDir),
    generatedExtension: '.g.dart',
    outputDir: outputDir,
  );
}

/// Emits `@RestApi` client implementations into `lib/<output_dir>/<dir>/<file>.rest.g.dart`.
Builder restApiBuilder(BuilderOptions options) {
  final outputDir = _resolveOutputDir(options);
  return RestClientOutputBuilder(
    RestApiGenerator(outputDir: outputDir),
    generatedExtension: '.rest.g.dart',
    outputDir: outputDir,
  );
}

/// Emits configuration client factories into `lib/<output_dir>/<dir>/<file>.rest.config.g.dart`.
Builder restConfigurationBuilder(BuilderOptions options) {
  final outputDir = _resolveOutputDir(options);
  return RestClientOutputBuilder(
    const RestConfigurationGenerator(),
    generatedExtension: '.rest.config.g.dart',
    outputDir: outputDir,
  );
}

/// Emits a barrel `lib/<output_dir>.g.dart` that re-exports every generated
/// file under `lib/<output_dir>/`. Opt-in — disabled by default.
///
/// Enable in the consumer's `build.yaml`:
/// ```yaml
/// targets:
///   $default:
///     builders:
///       rest_client_builder|rest_export:
///         enabled: true
///         options:
///           output_dir: generated   # must match the other builders
/// ```
Builder restExportBuilder(BuilderOptions options) {
  final outputDir = _resolveOutputDir(options);
  return RestExportBuilder(outputDir: outputDir);
}
