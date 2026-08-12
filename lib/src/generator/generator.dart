/// Code-generation architecture for rest_client_builder.
///
/// Consumed by `build_runner` via `build.yaml`. Not part of the public package
/// API.
///
/// - `@RestModel` → `*.g.dart` (`fromJson` / `toJson`)
/// - `@RestApi` → `*.rest.g.dart` (typed client implementations)
library;

export 'builder.dart';
export 'model/generation_models.dart';
export 'pipeline/generation_pipeline.dart';
export 'rest_api_generator.dart';
export 'rest_model_generator.dart';
export 'validator/generation_validator.dart';
export 'validator/rest_api_validator_impl.dart';
export 'validator/rest_model_validator_impl.dart';
export 'validator/validation_issue.dart';
export 'visitor/library_model_visitor.dart';
export 'visitor/rest_api_visitor_impl.dart';
export 'visitor/rest_model_visitor_impl.dart';
export 'writer/rest_api_writer_impl.dart';
export 'writer/rest_model_writer_impl.dart';
export 'writer/source_writer.dart';
