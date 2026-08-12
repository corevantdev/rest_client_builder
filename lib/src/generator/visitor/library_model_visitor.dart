// source_gen still exposes the classic element APIs; Element2 migration comes later.
// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import '../model/generation_models.dart';

/// Walks analyzer elements and produces generator models.
///
/// Visitors must not emit source code. They only translate the analyzer
/// element model (resolved AST) into [GenerationUnit] data.
abstract interface class LibraryModelVisitor {
  /// Visits an entire library via `source_gen`'s [LibraryReader].
  GenerationUnit visitLibrary(LibraryReader library);
}

/// Visits `@RestApi` / configuration classes.
abstract interface class RestApiVisitor {
  /// Returns a model when [element] is an annotated API class; otherwise `null`.
  RestApiClassModel? visitClass(ClassElement element);

  /// Returns a model when [element] is an annotated HTTP method; otherwise `null`.
  RestMethodModel? visitMethod(MethodElement element);

  /// Returns a model when [element] is a bound parameter; otherwise `null`.
  RestParameterModel? visitParameter(FormalParameterElement element);
}

/// Visits `@RestModel` classes.
abstract interface class RestModelVisitor {
  /// Returns a model when [element] is an annotated model class; otherwise `null`.
  RestModelClassModel? visitClass(ClassElement element);

  /// Returns a field model for [element].
  RestModelFieldModel visitField(FieldElement element);
}

/// No-op visitor scaffold. Real AST walking will be added later.
class NoOpLibraryModelVisitor implements LibraryModelVisitor {
  /// Creates a no-op visitor.
  const NoOpLibraryModelVisitor();

  @override
  GenerationUnit visitLibrary(LibraryReader library) {
    // The analyzer has already resolved this library into an element model.
    // Future visitors will walk [library.classes] / methods / parameters and
    // read annotations via TypeChecker. No traversal yet.
    final uri = library.element.firstFragment.source.uri.toString();
    return GenerationUnit(sourceLibraryName: uri);
  }
}
