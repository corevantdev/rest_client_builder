/// Classification of a [RestRequest] body.
///
/// Used by the runtime to select encoding. No HTTP is performed here.
enum RestBodyType {
  /// No request body.
  none,

  /// JSON-encoded body.
  json,

  /// `application/x-www-form-urlencoded` body.
  formUrlEncoded,

  /// `multipart/form-data` body.
  multipart,

  /// Raw bytes body.
  bytes,

  /// Plain text body.
  text,
}
