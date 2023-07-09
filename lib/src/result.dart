import "package:prompt/src/io/error.dart";
import "package:prompt/src/types.dart";

sealed class Result<inout T> {
  const Result();
  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(String failure) = Failure<T>;

  abstract final T value;
  abstract final String failure;

  T orElse(T Function() orElse);
  Result<O> map<O>(O Function(T value) callback);
  Result<O> expand<O>(Result<O> Function(T value) callback);
  Result<T> where(Predicate<T> predicate);

  T unwrap();
  T? nullable();
}

final class Failure<inout T> implements Result<T> {
  const Failure(this.failure);

  @override
  Never get value => throw UnsupportedError("An failure object does not contain a [result].");

  @override
  final String failure;

  @override
  T orElse(T Function() orElse) => orElse();

  @override
  Failure<O> map<O>(O Function(T) callback) => Failure<O>(failure);

  @override
  Failure<O> expand<O>(Result<O> Function(T) callback) => Failure<O>(failure);

  @override
  Failure<T> where(Predicate<T> callback) => this;

  @override
  Null nullable() => null;

  @override
  Never unwrap() => throw CustomError(
        "[.unwrap] called on [Failure]",
        message: failure,
        title: "Unwrap Failure",
      );
}

final class Success<inout T> implements Result<T> {
  const Success(this.value);

  @override
  final T value;

  @override
  String get failure => throw UnsupportedError("A success object does not contain a [failure].");

  @override
  T orElse(T Function() orElse) => value;

  @override
  Success<O> map<O>(O Function(T) callback) => Success<O>(callback(value));

  @override
  Result<O> expand<O>(Result<O> Function(T) callback) => callback(value);

  @override
  Result<T> where(Predicate<T> callback, [String message = "Filter failure"]) =>
      callback(value) ? this : Failure<T>(message);

  @override
  T nullable() => value;

  @override
  T unwrap() => value;
}

extension FutureFailureOrMethods<E> on Future<Result<E>> {
  Future<E> unwrap() => then((Result<E> result) => result.unwrap());
  Future<E?> unwrapNullable() => then((Result<E> result) => result.nullable());
}
