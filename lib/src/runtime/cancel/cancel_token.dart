/// Token used to cancel an in-flight request.
///
/// Cooperative cancellation: engines and interceptors should observe
/// [isCancelled] / [whenCancelled]. This interface does not perform networking.
abstract interface class CancelToken {
  /// Whether cancellation has been requested.
  bool get isCancelled;

  /// Reason provided to [cancel], if any.
  String? get cancelReason;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled;

  /// Requests cancellation of the associated call.
  void cancel([String? reason]);
}
