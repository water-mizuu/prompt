import "dart:io";
import "dart:math" as math;

import "package:prompt/src/types.dart";

extension StringExtension on String {
  String padCenter(int count, [String character = " "]) {
    int padCount = (count - length).clamp(0, math.max(length, count));
    int left = (padCount / 2).floor();
    int right = (padCount / 2).ceil();

    return "${character * left}$this${character * right}";
  }

  /// Function that wraps string by words.
  String wrap(int columns) => this //
      .split("\n")
      .map((String line) => line._wrapSingle(columns))
      .join("\n");

  String _wrapSingle(int columns) {
    List<String> words = this.trimRight().split(" ");
    List<String> lines = <String>[];
    List<String> buffer = <String>[];

    for (String word in words) {
      if (buffer.join(" ") case String temp
          when buffer.isNotEmpty && temp.length + word.length >= columns) {
        lines.add(temp);
        buffer.clear();
      }
      buffer.add(word);
    }

    if (buffer.isNotEmpty) {
      lines.add(buffer.join(" "));
      buffer.clear();
    }
    return lines.join("\n");
  }

  String ellipsis(int columns) {
    if (length > columns) {
      return "${substring(0, columns - 3)}...";
    }
    return this;
  }

  List<String> get lines => replaceAll("\r", "").split("\n");
}

extension AnsiEscapeStringExtension on String {
  int get visibleLength => stripEscapeCharacters().length;

  String padVisibleRight(int count, [String character = " "]) {
    int padCount = (count - visibleLength).clamp(0, math.max(visibleLength, count)).ceil();

    return "$this${character * padCount}";
  }

  String padVisibleLeft(int count, [String character = " "]) {
    int padCount = (count - visibleLength).clamp(0, math.max(visibleLength, count)).floor();

    return "${character * padCount}$this";
  }

  String padVisibleCenter(int count, [String character = " "]) {
    num padCount = (count - visibleLength).clamp(0, math.max(visibleLength, count));
    int left = (padCount / 2).floor();
    int right = (padCount / 2).ceil();

    return "${character * left}$this${character * right}";
  }

  /// Function that wraps string by words.
  String wrapVisible(int columns) => this //
      .split("\n")
      .map((String line) => line._wrapVisibleSingle(columns))
      .join("\n");

  String _wrapVisibleSingle(int columns) {
    List<String> words = this.trimRight().split(" ");
    List<String> lines = <String>[];
    List<String> buffer = <String>[];

    for (String word in words) {
      if (buffer.join(" ") case String temp
          when buffer.isNotEmpty && temp.visibleLength + word.visibleLength >= columns) {
        lines.add(temp);
        buffer.clear();
      }
      buffer.add(word);
    }

    if (buffer.isNotEmpty) {
      lines.add(buffer.join(" "));
      buffer.clear();
    }
    return lines.join("\n");
  }

  String ellipsisVisible(int columns) {
    if (visibleLength > columns) {
      return "${substring(0, columns - 3)}...";
    }
    return this;
  }

  String stripEscapeCharacters() => this
      .replaceAll(RegExp(r"\x1b\[[\x30-\x3f]*[\x20-\x2f]*[\x40-\x7e]"), "")
      .replaceAll(RegExp(r"\x1b[PX^_].*?\x1b\\"), "")
      .replaceAll(RegExp(r"\x1b\][^\a]*(?:\a|\x1b\\)"), "")
      .replaceAll(RegExp(r"\x1b[\[\]A-Z\\^_@]"), "");
}

extension AnsiEscapeListStringExtension on List<String> {
  int get visibleLength => this //
      .map((String v) => v.visibleLength)
      .fold(0, (int a, int b) => a + b);
}

extension BooleanExtension on bool {
  /// Postfix not operator. Useful for nullable / futures.
  bool not() => !this;
}

extension SetExtensions<E> on Set<E> {
  Set<E> exclusiveUnion(Set<E> right) => this.union(right).difference(this.intersection(right));

  Set<E> operator -(Set<E> right) => this.difference(right);
  Set<E> operator |(Set<E> right) => this.union(right);
  Set<E> operator &(Set<E> right) => this.intersection(right);
  Set<E> operator ^(Set<E> right) => this.exclusiveUnion(right);
}

extension PredicateExtension<T> on Predicate<T> {
  Predicate<T> not() => (T value) => !this(value);
  Predicate<T> or(Predicate<T> right) => (T value) => this(value) || right(value);
  Predicate<T> and(Predicate<T> right) => (T value) => this(value) && right(value);
  Predicate<T> xor(Predicate<T> right) => (T value) => this(value) ^ right(value);

  Predicate<T> implies(Predicate<T> right) => (T value) => !this(value) || right(value);
  Predicate<T> equivalent(Predicate<T> right) => (T value) => this(value) == right(value);

  Predicate<T> operator ~() => this.not();
  Predicate<T> operator &(Predicate<T> right) => this.and(right);
  Predicate<T> operator |(Predicate<T> right) => this.or(right);
  Predicate<T> operator ^(Predicate<T> right) => this.xor(right);
}

extension NullableFunctionalExtension<T> on T? {
  O? map<O>(O Function(T value) mapper) => switch (this) { T value => mapper(value), _ => null };
  T? where(bool Function(T value) predicate) =>
      switch (this) { T value when predicate(value) => value, _ => null };
}

extension NonNullableFunctionalExtension<T> on T {
  O map<O>(O Function(T value) mapper) => mapper(this);
  T? where(bool Function(T value) predicate) =>
      switch (this) { T value when predicate(value) => value, _ => null };
}

extension ListExtensionMethods<E> on List<E> {
  (List<E>, List<E>) splitAt(int index) => (sublist(0, index), sublist(index));
}

extension DateExtension on DateTime {
  static const List<String> monthNames = <String>[
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  static String _twoDigits(int n) => //
      "${n < 0 ? "-" : ""}${n.abs().toString().padLeft(2, '0')}";

  String toDateString() {
    String y = year.toString();
    String m = monthNames[month - 1];
    String d = _twoDigits(day);

    return "$y $m $d";
  }

  String toTimeString() {
    String h = _twoDigits(hour);
    String m = _twoDigits(minute);
    String s = _twoDigits(second);

    return "$h:$m:$s";
  }

  DateTime minimalDate() => copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );

  int get dayCount => DateTime(year, month + 1, 0).day;
}

extension BigIntExtension<N extends num> on N {
  BigInt get n => BigInt.from(this);

  /// Floor division
  int fdiv(int right) => (this / right).floor();

  /// Ceiling division
  int cdiv(int right) => (this / right).ceil();

  /// Rounding division
  int rdiv(int right) => (this / right).round();
}

extension IntegerExtension on int {
  int max(int right) => this > right ? this : right;
}

extension FileSystemEntityExtension on FileSystemEntity {
  String get name => path.split(Platform.pathSeparator).last;
}
