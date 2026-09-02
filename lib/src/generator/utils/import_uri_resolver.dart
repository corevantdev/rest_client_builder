/// Resolves a source `package:` URI to its generated `.g.dart` counterpart
/// under the centralized output directory.
///
/// [outputDir] controls the intermediate folder name (default: `generated`).
///
/// For example (with default `outputDir`):
/// ```
/// package:my_app/models/user.dart
///   → package:my_app/generated/models/user.g.dart
/// ```
///
/// Non-package URIs are left as-is with the `.dart` → `.g.dart` swap.
String resolveGeneratedImportUri(
  String uri, {
  String outputDir = 'generated',
}) {
  if (uri.startsWith('package:')) {
    final slashIndex = uri.indexOf('/');
    final pkg = uri.substring(0, slashIndex);
    final rest = uri.substring(slashIndex + 1);
    return '$pkg/$outputDir/${rest.replaceAll('.dart', '.g.dart')}';
  }
  return uri.replaceAll('.dart', '.g.dart');
}
