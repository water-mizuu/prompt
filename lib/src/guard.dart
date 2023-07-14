import "package:prompt/prompt.dart";

typedef True = Success<void>;
typedef False = Failure<void>;

sealed class Guard<T> {
  const factory Guard.unit(Predicate<T> function, String failure) = UnitGuard<T>;

  Option<void> call(T value);
}

final class UnitGuard<T> implements Guard<T> {
  const UnitGuard(this.test, this.message);

  final Predicate<T> test;
  final String message;

  @override
  Option<void> call(T value) => test(value) ? const True(null) : False(message);
}

final class OrGuard<T> implements Guard<T> {
  const OrGuard(this.left, this.right);

  final Guard<T> left;
  final Guard<T> right;

  @override
  Option<void> call(T value) => switch (left.call(value)) {
        True result => result,
        False(failure: String left) => switch (right.call(value)) {
            True result => result,
            False(failure: String right) => False("$left\n$right"),
          },
      };
}

final class AndGuard<T> implements Guard<T> {
  const AndGuard(this.left, this.right);

  final Guard<T> left;
  final Guard<T> right;

  @override
  Option<void> call(T value) => switch (left.call(value)) {
        False failure => failure,
        True _ => switch (right.call(value)) {
            False failure => failure,
            True _ => const True(null),
          },
      };
}

final class ExclusiveOrGuard<T> implements Guard<T> {
  const ExclusiveOrGuard(this.left, this.right);

  final Guard<T> left;
  final Guard<T> right;

  @override
  Option<void> call(T value) => switch ((left.call(value), right.call(value))) {
        (False left, False right) => False("${left.failure}\n${right.failure}"),
        (True _, False _) => const True(null),
        (False _, True _) => const True(null),
        (True _, True _) => const False("Both guards passed!"),
      };
}

extension GuardOverload<T> on Guard<T> {
  Guard<T> operator &(Guard<T> other) => AndGuard<T>(this, other);
  Guard<T> operator |(Guard<T> other) => OrGuard<T>(this, other);
  Guard<T> operator ^(Guard<T> other) => ExclusiveOrGuard<T>(this, other);
}

extension GuardConversionExtension<T> on (Predicate<T> predicate, String message) {
  Guard<T> toGuard() => Guard<T>.unit($1, $2);
}

abstract final class Guards {
  // Number guards
  static Guard<num> numGreaterThan(num value) => (
        (num v) => v.compareTo(value) > 0,
        "Must be greater than $value!",
      ).toGuard();

  static Guard<num> numLessThan(num value) => (
        (num v) => v.compareTo(value) < 0,
        "Must be greater than $value!",
      ).toGuard();

  static Guard<num> numEquals(num value) => (
        (num v) => v == value,
        "Must be equal to $value!",
      ).toGuard();

  static Guard<num> numGreaterThanEqual(num value) => (
        (num v) => v.compareTo(value) >= 0,
        "Must be greater than $value!",
      ).toGuard();

  static Guard<num> numLessThanEqual(num value) => (
        (num v) => v.compareTo(value) <= 0,
        "Must be greater than $value!",
      ).toGuard();

  // Integer guards

  static Guard<int> intIsOdd() => (
        (int v) => v.isOdd,
        "Must be odd!",
      ).toGuard();

  static Guard<int> intIsEven() => (
        (int v) => v.isEven,
        "Must be even!",
      ).toGuard();

  static Guard<BigInt> bigIntIsOdd() => (
        (BigInt v) => v.isOdd,
        "Must be odd!",
      ).toGuard();

  static Guard<BigInt> bigIntIsEven() => (
        (BigInt v) => v.isEven,
        "Must be even!",
      ).toGuard();

  // Comparable guards

  static Guard<C> greaterThan<C extends Comparable<C>>(C value) => (
        (C v) => v.compareTo(value) > 0,
        "Must be greater than $value!",
      ).toGuard();

  static Guard<C> lessThan<C extends Comparable<C>>(C value) => (
        (C v) => v.compareTo(value) < 0,
        "Must be greater than $value!",
      ).toGuard();

  static Guard<C> greaterThanEquals<C extends Comparable<C>>(C value) => (
        (C v) => v.compareTo(value) >= 0,
        "Must be greater than $value!",
      ).toGuard();

  static Guard<C> lessThanEquals<C extends Comparable<C>>(C value) => (
        (C v) => v.compareTo(value) <= 0,
        "Must be greater than $value!",
      ).toGuard();

  // String guards

  static Guard<String> stringIsNotEmpty() => (
        (String v) => v.isNotEmpty,
        "Must not be empty!",
      ).toGuard();

  static Guard<String> stringStartsWith(String other, [int index = 0]) => (
        (String v) => v.startsWith(other, index),
        "Must start with $other!",
      ).toGuard();

  static Guard<String> stringEndsWith(String other) => (
        (String v) => v.endsWith(other),
        "Must end with $other!",
      ).toGuard();

  static Guard<String> stringMatches(Pattern pattern, [int startIndex = 0]) => (
        (String v) => pattern.matchAsPrefix(v, startIndex) != null,
        "Must match $pattern!",
      ).toGuard();

  // Set guards

  static Guard<T> within<T>(Set<T> values) => (
        (T v) => values.contains(v),
        "Must be one of $values!",
      ).toGuard();

  static Guard<T> except<T>(Set<T> values) => (
        (T v) => !values.contains(v),
        "Must not be one of $values!",
      ).toGuard();

  // Equality guards

  static Guard<T> equals<T>(T value) => (
        (T v) => v == value,
        "Must be $value!",
      ).toGuard();

  static Guard<T> notEquals<T>(T value, [String? name]) => (
        (T v) => v != value,
        "Must not be ${name ?? value}!",
      ).toGuard();

  // Iterable guards

  static Guard<Iterable<T>> contains<T>(T value, [String? name]) => (
        (Iterable<T> v) => v.contains(value),
        "Must contain ${name ?? value}!",
      ).toGuard();

  static Guard<Iterable<T>> notContains<T>(T value, [String? name]) => (
        (Iterable<T> v) => !v.contains(value),
        "Must contain ${name ?? value}!",
      ).toGuard();

  // DateTime guards
  static Guard<DateTime> before(DateTime value) => (
        (DateTime v) => v.isBefore(value),
        "Must be before $value!",
      ).toGuard();

  static Guard<DateTime> after(DateTime value) => (
        (DateTime v) => v.isAfter(value),
        "Must be after $value!",
      ).toGuard();

  static Guard<DateTime> beforeOrOn(DateTime value) => (
        (DateTime v) => v.isBefore(value.add(const Duration(days: 1))),
        "Must be before or on $value!",
      ).toGuard();

  static Guard<DateTime> afterOrOn(DateTime value) => (
        (DateTime v) => v.isAfter(value.subtract(const Duration(days: 1))),
        "Must be after or on $value!",
      ).toGuard();

  static Guard<DateTime> beforeNow() => (
        (DateTime v) => v.isBefore(DateTime.now().minimalDate().minimalDate()),
        "Must be before today!",
      ).toGuard();

  static Guard<DateTime> afterNow() => (
        (DateTime v) => v.isAfter(DateTime.now().minimalDate()),
        "Must be after today!",
      ).toGuard();

  static Guard<DateTime> beforeOrOnNow() => (
        (DateTime v) => v.isBefore(
              DateTime.now().minimalDate().add(const Duration(days: 1)),
            ),
        "Must be today or before today!",
      ).toGuard();

  static Guard<DateTime> afterOrOnNow() => (
        (DateTime v) => v.isAfter(
              DateTime.now().minimalDate().subtract(const Duration(days: 1)),
            ),
        "Must be today or after today!",
      ).toGuard();

  // FileSystemEntity guards

  static Guard<F> nameStartsWith<F extends FileSystemEntity>(String prefix) => (
        (F v) => v.name.startsWith(prefix),
        "Must start with $prefix!",
      ).toGuard();

  static Guard<F> nameEndsWith<F extends FileSystemEntity>(String suffix) => (
        (F v) => v.name.endsWith(suffix),
        "Must end with $suffix!",
      ).toGuard();

  static Guard<F> nameMatches<F extends FileSystemEntity>(Pattern pattern, [int startIndex = 0]) =>
      (
        (F v) => pattern.matchAsPrefix(v.name, startIndex) != null,
        "Must match $pattern!",
      ).toGuard();

  static Guard<F> pathStartsWith<F extends FileSystemEntity>(String prefix) => (
        (F v) => v.path.startsWith(prefix),
        "Must start with $prefix!",
      ).toGuard();

  static Guard<F> pathEndsWith<F extends FileSystemEntity>(String suffix) => (
        (F v) => v.path.endsWith(suffix),
        "Must end with $suffix!",
      ).toGuard();

  static Guard<F> pathMatches<F extends FileSystemEntity>(Pattern pattern, [int startIndex = 0]) =>
      (
        (F v) => pattern.matchAsPrefix(v.path, startIndex) != null,
        "Must match $pattern!",
      ).toGuard();

  // Directory

  static Guard<Directory> directoryIsEmpty() => (
        (Directory v) => v.listSync().isEmpty,
        "Must be empty!",
      ).toGuard();

  static Guard<Directory> directoryIsNotEmpty() => (
        (Directory v) => v.listSync().isNotEmpty,
        "Must not be empty!",
      ).toGuard();

  // File

  static Guard<File> fileIsEmpty() => (
        (File v) => v.readAsStringSync().isEmpty,
        "Must be empty!",
      ).toGuard();

  static Guard<File> fileIsNotEmpty() => (
        (File v) => v.readAsStringSync().isNotEmpty,
        "Must not be empty!",
      ).toGuard();
}
