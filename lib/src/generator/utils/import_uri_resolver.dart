/// Resolves a source `package:` URI to its generated `.g.dart` counterpart
/// under the centralized `rest_client_builder/` output directory.
///
/// For example:
/// ```
/// package:my_app/models/user.dart
///   → package:my_app/rest_client_builder/models/user.g.dart
/// ```
///
/// Non-package URIs are left as-is with the `.dart` → `.g.dart` swap.
String resolveGeneratedImportUri(String uri) {
  if (uri.startsWith('package:')) {
    final slashIndex = uri.indexOf('/');
    final pkg = uri.substring(0, slashIndex);
    final rest = uri.substring(slashIndex + 1);
    return '$pkg/rest_client_builder/${rest.replaceAll('.dart', '.g.dart')}';
  }
  return uri.replaceAll('.dart', '.g.dart');
}
