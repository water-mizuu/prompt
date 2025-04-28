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
    var [_, String name] = super.toString().split(".");
    var [String first, ...List<String> rest] = name.split("");

    return first.toUpperCase() + rest.join();
  }
}

void main() async {
  for (List<int> key in stdin.syncInterrupt) {
    stdout.box(key.map((int v) => v.map((int c) => c.toRadixString(16).padLeft(2, "0"))).toList());
  }
  // prompt("What's your name?");
  // prompt.time("Said I'm fine but it wasn't true,");
  // prompt.dateTime(
  //   "Hello there!",
  //   guard: Guard.unit((DateTime v) => v.isAfter(DateTime.now()), "Must be after today!"),
  //   minimal: true,
  // );
  // prompt.dateTime(
  //   "Hello there!",
  //   guard: Guard.unit((DateTime v) => v.isAfter(DateTime.now()), "Must be after today!"),
  // );

  // prompt
  //     .line(
  //       "Tell us about yourself",
  //       guard: Guards.stringIsNotEmpty(),
  //     )
  //     .nullable();
  // prompt.range("An even multiple of 3", step: 3, min: -128, guard: Guards.intIsEven());
  // prompt.double("A double greater than pi.", guard: Guards.doubleGreaterThan(3.14));
  // prompt.bigInt("A large integer", guard: Guards.greaterThan(200.n));
  // prompt.bool("Do you agree?".doubleUnderlined());
  // prompt.select(
  //   "Which is your most favorite?",
  //   choices: Month.values,
  //   guard: Guards.notEquals(Month.march),
  // );
  // prompt.select.multi(
  //   "What are your favorite months?",
  //   choices: Month.values,
  //   guard: Guards.listContains(Month.march),
  // );
  prompt.int("An odd integer.", guard: Guards.intIsOdd());
  prompt
      .date(
        "When is your birthday?",
        hint: "The year will be ignored.",
        guard: Guards.beforeNow(),
      )
      .orElse(() => DateTime.now());
  prompt
      .date(
        "When is your birthday?",
        hint: "The year will be ignored.",
        guard: Guards.beforeNow(),
        minimal: true,
      )
      .orElse(() => DateTime.now());
  prompt.file("Select your file.");
  // stdout.box(birthday);
}
