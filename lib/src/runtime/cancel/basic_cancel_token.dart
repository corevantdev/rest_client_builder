import 'dart:async';

import 'package:dio/dio.dart' as dio;

import 'cancel_token.dart';

/// Concrete [CancelToken] backed by Dio's cancel token.
class BasicCancelToken implements CancelToken {
  /// Creates a cancel token.
  BasicCancelToken();

  final dio.CancelToken _dioToken = dio.CancelToken();
  final Completer<void> _completer = Completer<void>();
  String? _reason;

  /// Underlying Dio cancel token used by [DioRestHttpEngine].
  dio.CancelToken get dioToken => _dioToken;

  @override
  bool get isCancelled => _dioToken.isCancelled;

  @override
  String? get cancelReason => _reason;

  @override
  Future<void> get whenCancelled => _completer.future;

  @override
  void cancel([String? reason]) {
    if (isCancelled) {
      return;
    }
    _reason = reason;
    _dioToken.cancel(reason);
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}
