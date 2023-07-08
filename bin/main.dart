// ignore_for_file: always_specify_types

import "package:prompt/prompt.dart";

enum Month {
  january,
  february,
  march,
  april,
  may,
  june,
  july,
  august,
  september,
  october,
  november,
  december;

  @override
  String toString() {
    var [String first, ...List<String> rest] = super.toString().split(".").last.split("");

    return first.toUpperCase() + rest.join();
  }
}

void main() async {
  // for (List<int> key in stdin.syncInterrupt) {
  //   stdout.box(key.map((v) => v.map((c) => c.toRadixString(16).padLeft(2, "0"))));
  // }
  // prompt
  //     .lines(
  //       "Tell us about yourself",
  //       guard: Guards.stringIsNotEmpty(),
  //     )
  //     .nullable();
  // prompt.range("An even multiple of 3", step: 3, min: -128, guard: Guards.intIsEven());
  // prompt.int("An odd integer.", guard: Guards.intIsOdd());
  // prompt.double("A double greater than pi.", guard: Guards.numGreaterThan(3.14));
  // prompt.bigInt("A large integer", guard: Guards.greaterThan(200.n));
  // prompt.bool("Do you agree?".doubleUnderline());
  // prompt.select(
  //   "Which is your most favorite?",
  //   choices: Month.values,
  //   guard: Guards.notEquals(Month.march),
  // );
  // prompt.select.multi(
  //   "What are your favorite months?",
  //   choices: Month.values,
  //   guard: Guards.contains(Month.march),
  // );
  var birthday = prompt
      .date("When is your birthday?", hint: "The year will be ignored.", guard: Guards.afterNow())
      .map((value) => value.copyWith(year: 0))
      .orElse(() => DateTime.now());

  stdout.box(birthday);
  // prompt("A nonempty string", guard: Guards.stringIsNotEmpty());
}
