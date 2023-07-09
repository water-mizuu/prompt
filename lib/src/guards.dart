import "package:prompt/prompt.dart";

abstract final class Guards {
  // Number guards
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

  // Integer guards

  static Guard<int> intIsOdd() => ((int v) => v.isOdd, "Must be odd!");

  static Guard<int> intIsEven() => ((int v) => v.isEven, "Must be even!");

  static Guard<BigInt> bigIntIsOdd() => ((BigInt v) => v.isOdd, "Must be odd!");

  static Guard<BigInt> bigIntIsEven() => ((BigInt v) => v.isEven, "Must be even!");

  // Comparable guards

  static Guard<C> greaterThan<C extends Comparable<C>>(C value) =>
      ((C v) => v.compareTo(value) > 0, "Must be greater than $value!");

  static Guard<C> lessThan<C extends Comparable<C>>(C value) =>
      ((C v) => v.compareTo(value) < 0, "Must be greater than $value!");

  static Guard<C> greaterThanEquals<C extends Comparable<C>>(C value) =>
      ((C v) => v.compareTo(value) >= 0, "Must be greater than $value!");

  static Guard<C> lessThanEquals<C extends Comparable<C>>(C value) =>
      ((C v) => v.compareTo(value) <= 0, "Must be greater than $value!");

  // String guards

  static Guard<String> stringIsNotEmpty() => ((String v) => v.isNotEmpty, "Must not be empty!");

  // Set guards

  static Guard<T> within<T>(Set<T> values) =>
      ((T v) => values.contains(v), "Must be one of $values!");

  static Guard<T> except<T>(Set<T> values) =>
      ((T v) => !values.contains(v), "Must not be one of $values!");

  // Equality guards

  static Guard<T> equals<T>(T value) => ((T v) => v == value, "Must be $value!");

  static Guard<T> notEquals<T>(T value, [String? name]) =>
      ((T v) => v != value, "Must not be ${name ?? value}!");

  // Iterable guards

  static Guard<Iterable<T>> contains<T>(T value, [String? name]) =>
      ((Iterable<T> v) => v.contains(value), "Must contain ${name ?? value}!");

  static Guard<Iterable<T>> notContains<T>(T value, [String? name]) =>
      ((Iterable<T> v) => !v.contains(value), "Must contain ${name ?? value}!");

  // DateTime guards
  static Guard<DateTime> before(DateTime value) =>
      ((DateTime v) => v.isBefore(value), "Must be before $value!");

  static Guard<DateTime> after(DateTime value) =>
      ((DateTime v) => v.isAfter(value), "Must be after $value!");

  static Guard<DateTime> beforeOrOn(DateTime value) => (
        (DateTime v) => v.isBefore(value.add(const Duration(days: 1))),
        "Must be before or on $value!",
      );

  static Guard<DateTime> afterOrOn(DateTime value) => (
        (DateTime v) => v.isAfter(value.subtract(const Duration(days: 1))),
        "Must be after or on $value!",
      );

  static Guard<DateTime> beforeNow() => (
        (DateTime v) => v.isBefore(DateTime.now().minimalDate().minimalDate()),
        "Must be before today!"
      );

  static Guard<DateTime> afterNow() =>
      ((DateTime v) => v.isAfter(DateTime.now().minimalDate()), "Must be after today!");

  static Guard<DateTime> beforeOrOnNow() => (
        (DateTime v) => v.isBefore(DateTime.now().minimalDate().add(const Duration(days: 1))),
        "Must be today or before today!"
      );

  static Guard<DateTime> afterOrOnNow() => (
        (DateTime v) => v.isAfter(DateTime.now().minimalDate().subtract(const Duration(days: 1))),
        "Must be today or after today!"
      );
}
