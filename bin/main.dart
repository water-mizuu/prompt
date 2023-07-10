import "package:prompt/prompt.dart";
import "package:prompt/src/prompt/filesystem_entity.dart";
import "package:prompt/src/prompt/shared/view.dart";

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

void testView(
  int length, {
  required int index,
  int topDisparity = 1,
  int bottomDisparity = 1,
  int topDistance = 2,
  int bottomDistance = 2,
}) {
  var ViewInfo(
    :int viewLimit,
    :int endOverflow,
    :int viewStart,
    :int viewEnd,
    :int viewIndex,
  ) = computeViewInfo(
    length,
    index: index,
    topDistance: topDistance,
    bottomDistance: bottomDistance,
  );

  for (int ind in List<int>.generate(length, (int i) => i)) {
    stdout.write(
      "#"
          .brightBlue(iff: index == ind)
          .brightCyan(iff: index - topDisparity <= ind && ind <= index + bottomDisparity)
          .italic(iff: viewStart <= ind && ind < viewEnd)
          .brightBlack(iff: viewStart > ind || ind >= viewEnd),
    );
  }
  stdout.writeln();

  for (int i = 0; i < viewStart; ++i) {
    stdout.write(" ");
  }
  stdout.write("+");
  for (int i = viewStart + 1; i < viewEnd - 1; ++i) {
    stdout.write("-");
  }
  stdout.write("+");
  stdout.writeln();

  stdout.writeln(
    (
      index: index,
      viewLimit: viewLimit,
      endOverflow: endOverflow,
      viewIndex: viewIndex,
      viewStart: viewStart,
      viewEnd: viewEnd,
    ).toString().brightBlack(),
  );
}

void main() async {
  prompt.directory(
    "Select a directory to create the project in.",
    guard: Guard<Directory>.unit(
      (Directory dir) => dir.name.endsWith("_test"),
      "The name must end in _test!",
    ),
  );
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
  // prompt.int("An odd integer.", guard: Guards.intIsOdd());
  // var birthday = prompt
  //     .date(
  //       "When is your birthday?",
  //       hint: "The year will be ignored.",
  //       guard: Guards.beforeNow(),
  //       minimal: true,
  //     )
  //     .map((value) => value.copyWith(year: 0))
  //     .orElse(() => DateTime.now());

  // stdout.box(birthday);
  // prompt("A nonempty string", guard: Guards.stringIsNotEmpty());
}
