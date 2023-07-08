import "package:prompt/src/types.dart";

abstract final class Guards {
  static Guard<num> numGreaterThan(num value) =>
      ((num v) => v.compareTo(value) > 0, "Must be greater than $value!");

  static Guard<num> numLessThan(num value) =>
      ((num v) => v.compareTo(value) < 0, "Must be greater than $value!");

  static Guard<num> numEquals(num value) => //
      ((num v) => v == value, "Must be equal to $value!");

  static Guard<num> numGreaterThanEqual(num value) =>
      ((num v) => v.compareTo(value) >= 0, "Must be greater than $value!");

  static Guard<num> numLessThanEqual(num value) =>
      ((num v) => v.compareTo(value) <= 0, "Must be greater than $value!");

  static Guard<int> intIsOdd() => ((int v) => v.isOdd, "Must be odd!");

  static Guard<int> intIsEven() => ((int v) => v.isEven, "Must be even!");

  static Guard<BigInt> bigIntIsOdd() => ((BigInt v) => v.isOdd, "Must be odd!");

  static Guard<BigInt> bigIntIsEven() => ((BigInt v) => v.isEven, "Must be even!");

  static Guard<C> greaterThan<C extends Comparable<C>>(C value) =>
      ((C v) => v.compareTo(value) > 0, "Must be greater than $value!");

  static Guard<C> lessThan<C extends Comparable<C>>(C value) =>
      ((C v) => v.compareTo(value) < 0, "Must be greater than $value!");

  static Guard<C> greaterThanEquals<C extends Comparable<C>>(C value) =>
      ((C v) => v.compareTo(value) >= 0, "Must be greater than $value!");

  static Guard<C> lessThanEquals<C extends Comparable<C>>(C value) =>
      ((C v) => v.compareTo(value) <= 0, "Must be greater than $value!");

  static Guard<String> stringIsNotEmpty() => ((String v) => v.isNotEmpty, "Must not be empty!");

  static Guard<T> within<T>(Set<T> values) =>
      ((T v) => values.contains(v), "Must be one of $values!");

  static Guard<T> except<T>(Set<T> values) =>
      ((T v) => !values.contains(v), "Must not be one of $values!");

  static Guard<T> equals<T>(T value) => ((T v) => v == value, "Must be $value!");

  static Guard<T> notEquals<T>(T value, [String? name]) =>
      ((T v) => v != value, "Must not be ${name ?? value}!");

  static Guard<Iterable<T>> contains<T>(T value, [String? name]) =>
      ((Iterable<T> v) => v.contains(value), "Must contain ${name ?? value}!");

  static Guard<Iterable<T>> notContains<T>(T value, [String? name]) =>
      ((Iterable<T> v) => !v.contains(value), "Must contain ${name ?? value}!");
}
