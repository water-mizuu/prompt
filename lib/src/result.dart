import "package:prompt/src/io/error.dart";
import "package:prompt/src/types.dart";

sealed class Result<T> {
  const Result();
  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(String failure) = Failure<T>;

  abstract final T result;
  abstract final String failure;

  T orElse(T Function() orElse);
  Result<O> map<O>(O Function(T) callback);
  Result<O> expand<O>(Result<O> Function(T) callback);
  Result<T> where(Predicate<T> predicate);

  T unwrap();
  T? nullable();
}

final class Failure<T> implements Result<T> {
  const Failure(this.failure);

  @override
  Never get result => throw UnsupportedError("An failure object does not contain a [result].");

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

final class Success<T> implements Result<T> {
  const Success(this.result);

  @override
  final T result;

  @override
  String get failure => throw UnsupportedError("A success object does not contain a [failure].");

  @override
  T orElse(T Function() orElse) => result;

  @override
  Success<O> map<O>(O Function(T) callback) => Success<O>(callback(result));

  @override
  Result<O> expand<O>(Result<O> Function(T) callback) => callback(result);

  @override
  Result<T> where(Predicate<T> callback, [String message = "Filter failure"]) =>
      callback(result) ? this : Failure<T>(message);

  @override
  T nullable() => result;

  @override
  T unwrap() => result;
}

extension FutureFailureOrMethods<E> on Future<Result<E>> {
  Future<E> unwrap() => then((Result<E> result) => result.unwrap());
  Future<E?> unwrapNullable() => then((Result<E> result) => result.nullable());
}
