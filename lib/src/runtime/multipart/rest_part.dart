import 'dart:convert';

import 'rest_multipart_part.dart';

/// Binary multipart part that never depends on `dart:io` File APIs.
///
/// Create parts with [RestPart.fromBytes] or [RestPart.fromBase64].
class RestPart implements RestMultipartPart {
  RestPart._({
    required this.name,
    required List<int> bytes,
    this.fileName,
    this.contentType,
  }) : bytes = List<int>.unmodifiable(bytes);

  /// Creates a part from raw bytes (e.g. image/memory buffers).
  factory RestPart.fromBytes({
    required String name,
    required List<int> bytes,
    String? fileName,
    String? contentType,
  }) {
    return RestPart._(
      name: name,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  /// Creates a part by decoding a Base64 [base64] payload.
  ///
  /// Accepts standard or URL-safe Base64. Whitespace is ignored.
  ///
  /// Throws [ArgumentError] if [base64] is not a valid Base64 string.
  factory RestPart.fromBase64({
    required String name,
    required String base64,
    String? fileName,
    String? contentType,
  }) {
    try {
      final normalized = base64.replaceAll(RegExp(r'\s'), '');
      final bytes = base64Decode(normalized);
      return RestPart.fromBytes(
        name: name,
        bytes: bytes,
        fileName: fileName,
        contentType: contentType,
      );
    } on FormatException catch (e) {
      throw ArgumentError.value(
        base64,
        'base64',
        'Invalid Base64 string: ${e.message}',
      );
    }
  }

  /// Creates a plain text/field part (UTF-8 bytes).
  factory RestPart.field({
    required String name,
    required String value,
    String? contentType,
  }) {
    return RestPart.fromBytes(
      name: name,
      bytes: utf8.encode(value),
      contentType: contentType ?? 'text/plain; charset=utf-8',
    );
  }

  @override
  final String name;

  @override
  final String? fileName;

  @override
  final String? contentType;

  /// Immutable payload bytes.
  final List<int> bytes;

  @override
  Object get value => bytes;

  /// Byte length of the payload.
  int get length => bytes.length;

  /// Returns a copy with a different form field [name].
  RestPart withName(String name) {
    return RestPart._(
      name: name,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  /// Base64 representation of [bytes].
  String toBase64() => base64Encode(bytes);
}
