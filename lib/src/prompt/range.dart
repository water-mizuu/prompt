import "dart:core";
import "dart:math" as math;

import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/decoration/style.dart";
import "package:prompt/src/io/exception.dart";
import "package:prompt/src/io/stdio/block/stdout/hidden_cursor.dart";
import "package:prompt/src/io/stdio/wrapper/stdin.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdin.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";
import "package:prompt/src/prompt/base.dart";
import "package:prompt/src/result.dart";
import "package:prompt/src/types.dart";

abstract final class RangePromptDefaults {
  static const int min = 0;
  static const int max = 128;
  static const int step = 1;
  static const int value = 0;

  static const Color accentColor = Color.brightBlue;
}

Result<int> rangePrompt(
  String question, {
  Guard<int>? guard,
  int min = RangePromptDefaults.min,
  int max = RangePromptDefaults.max,
  int step = RangePromptDefaults.step,
  int value = RangePromptDefaults.value,
  Color accentColor = RangePromptDefaults.accentColor,
}) {
  String formattedQuestion = question.bold();
  int activeValue = value.clamp(min, max);

  bool hasFailed = false;

  void flagFailure(String message) {
    hasFailed = true;

    stdout.eraseln();
    stdout.write("// $message".brightRed());
    stdout.write(" ($activeValue)".brightBlack());
    stdout.writeln();
  }

  void displayQuestion() {
    stdout.eraseln();
    if (hasFailed) {
      stdout.write("!".brightRed());
    } else {
      stdout.write("?".color(accentColor));
    }
    stdout.write(" $formattedQuestion ");
    stdout.write("[$min, $max]".brightBlack());
    stdout.write(" $activeValue ".color(accentColor));
  }

  Success<int> success(int result) {
    /// Display the answer
    stdout.eraseln();
    if (hasFailed) {
      stdout.eraselnUp();
      stdout.movelnUp();
    }
    stdout.write("+".color(accentColor));
    stdout.write(" $formattedQuestion ");
    stdout.writeln("$result".color(accentColor));

    return Success<int>(result);
  }

  Failure<int> failure(String message) {
    /// Display the failure
    stdout.eraseln();
    stdout.write("!".brightRed());
    stdout.write(" $formattedQuestion ");
    stdout.writeln(message.brightBlack());

    return Failure<int>(message);
  }

  try {
    stdout.hideCursor();
    stdout.write("?".color(accentColor));
    stdout.write(" $formattedQuestion ");
    stdout.write("[$min, $max]".brightBlack());
    stdout.write(" $activeValue ".color(accentColor));
    stdout.write("// Arrow keys to change".brightBlack());

    loop:
    for (List<int> code in stdin.sync) {
      if (hasFailed) {
        stdout.eraseln();
        stdout.movelnUp();
      }

      switch (code) {
        case <int>[0x03]:
          throw SignalInterruptionException();

        case <int>[0x0d]:
          if (guard case (GuardFunction<int> fn, String message) when !fn(activeValue)) {
            flagFailure(message);
          } else {
            break loop;
          }

        case <int>[0x1b, 0x5b, 0x41]:
          hasFailed = false;
          activeValue = math.min(max, activeValue + step);

        case <int>[0x1b, 0x5b, 0x42]:
          hasFailed = false;
          activeValue = math.max(min, activeValue - step);
      }

      displayQuestion();
    }

    return success(activeValue);
  } on SignalInterruptionException {
    /// Display the failure
    return failure("^C");
  } finally {
    stdout.showCursor();
  }
}

extension PromptRangeExtension on BasePrompt {
  Result<int> range(
    String question, {
    Guard<int>? guard,
    int min = RangePromptDefaults.min,
    int max = RangePromptDefaults.max,
    int step = RangePromptDefaults.step,
    int value = RangePromptDefaults.value,
    Color accentColor = RangePromptDefaults.accentColor,
  }) =>
      rangePrompt(
        question,
        guard: guard,
        min: min,
        max: max,
        step: step,
        value: value,
        accentColor: accentColor,
      );
}
