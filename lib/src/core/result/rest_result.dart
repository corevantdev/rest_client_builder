import '../error/rest_error.dart';

/// A discriminated result representing either a [Success] or a [Failure].
///
/// Use [RestResult] at Clean Architecture boundaries to avoid throwing for
/// expected failures. Pattern-match with `switch`, or use [when] / [fold].
sealed class RestResult<T> {
  /// Creates a [RestResult].
  const RestResult();

  /// Creates a successful result carrying [data].
  const factory RestResult.success(T data) = Success<T>;

  /// Creates a failed result carrying [error].
  const factory RestResult.failure(RestError error) = Failure<T>;

  /// Whether this instance is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Whether this instance is a [Failure].
  bool get isFailure => this is Failure<T>;

  /// The success payload, or `null` when this is a [Failure].
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  /// The failure error, or `null` when this is a [Success].
  RestError? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };

  /// Exhaustive callback dispatch for success and failure branches.
  R when<R>({
    required R Function(T data) success,
    required R Function(RestError error) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final error) => failure(error),
    };
  }

  /// Functional fold: [onFailure] then [onSuccess] argument order.
  R fold<R>(
    R Function(RestError error) onFailure,
    R Function(T data) onSuccess,
  ) {
    return when(success: onSuccess, failure: onFailure);
  }

  /// Maps the success value; failures are preserved with a cast type.
  RestResult<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => Success<R>(transform(data)),
      Failure<T>(:final error) => Failure<R>(error),
    };
  }

  /// Chains another [RestResult]-returning operation on success.
  RestResult<R> flatMap<R>(RestResult<R> Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => transform(data),
      Failure<T>(:final error) => Failure<R>(error),
    };
  }

  /// Returns the success value, or [defaultValue] when this is a failure.
  T getOrElse(T Function() defaultValue) {
    return switch (this) {
      Success<T>(:final data) => data,
      Failure<T>() => defaultValue(),
    };
  }

  /// Returns the success value, or throws [RestError] on failure.
  T getOrThrow() {
    return switch (this) {
      Success<T>(:final data) => data,
      Failure<T>(:final error) => throw error,
    };
  }

  /// Transforms the success value with an asynchronous [transform].
  ///
  /// Failures are propagated unchanged without invoking [transform].
  ///
  /// ```dart
  /// final profile = await userResult.mapAsync((user) => profileRepo.get(user.id));
  /// ```
  Future<RestResult<R>> mapAsync<R>(Future<R> Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) =>
        transform(data).then((r) => RestResult.success(r)),
      Failure<T>(:final error) => Future.value(Failure<R>(error)),
    };
  }

  /// Chains an async [RestResult]-returning operation on success.
  ///
  /// Failures are propagated unchanged without invoking [transform].
  ///
  /// ```dart
  /// final order = await cartResult.flatMapAsync((cart) => orderRepo.submit(cart));
  /// ```
  Future<RestResult<R>> flatMapAsync<R>(
    Future<RestResult<R>> Function(T data) transform,
  ) {
    return switch (this) {
      Success<T>(:final data) => transform(data),
      Failure<T>(:final error) => Future.value(Failure<R>(error)),
    };
  }
}

/// Successful [RestResult] carrying [data].
final class Success<T> extends RestResult<T> {
  /// Creates a success result.
  const Success(this.data);

  /// The successful payload.
  final T data;

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is Success<T> && other.data == data);
  }

  @override
  int get hashCode => data.hashCode;
}

/// Failed [RestResult] carrying a [RestError].
final class Failure<T> extends RestResult<T> {
  /// Creates a failure result.
  const Failure(this.error);

  /// The structured error.
  final RestError error;

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Failure<T> && other.error == error);
  }

  @override
  int get hashCode => error.hashCode;
}
