import '../model/generation_models.dart';

/// Emits Dart source from validated generator models.
///
/// Writers format with `dart_style`. They must not parse AST themselves —
/// input is always a [GenerationUnit] / model.
abstract interface class SourceWriter {
  /// Returns generated source, or `null` when there is nothing to emit.
  String? write(GenerationUnit unit);
}

/// Writes `@RestApi` client implementations (`*.rest.g.dart`).
abstract interface class RestApiWriter {
  /// Emits source for a single API class model.
  String writeApi(RestApiClassModel api);
}

/// Writes `@RestModel` `fromJson` / `toJson` helpers (`*.g.dart`).
abstract interface class RestModelWriter {
  /// Emits source for a single model class.
  String writeModel(RestModelClassModel model);
}

/// Writer that emits nothing (tests / disabled pipelines).
class NoOpSourceWriter implements SourceWriter {
  /// Creates a no-op writer.
  const NoOpSourceWriter();

  @override
  String? write(GenerationUnit unit) => null;
}
