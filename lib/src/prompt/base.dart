import "package:prompt/src/guard.dart";
import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdin.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";
import "package:prompt/src/option.dart";

abstract final class BasePromptDefaults {
  static const Color accentColor = Colors.brightBlue;
}

Option<String> basePrompt(
  String question, {
  Guard<String>? guard,
  String? hint,
  Color accentColor = BasePromptDefaults.accentColor,
}) {
  bool hasFailed = false;

  void displaySuccess(String answer) {
    stdout.write("+".color(accentColor));
    stdout.write(" $question ");
    stdout.writeln(answer.color(accentColor));
  }

  void displayFailure(String answer, [String? error]) {
    if (error != null) {
      stdout.write("// $error".brightRed());

      if (answer.isNotEmpty) {
        stdout.write(" ($answer)".brightBlack());
      }
      stdout.writeln();
    }

    stdout.eraseln();
    stdout.write("!".brightRed());
  }

  void resetDisplay() {
    stdout.eraseln();
    if (hasFailed) {
      stdout.movelnUp();
      stdout.eraseln();
    }
  }

  stdout.write("?".color(accentColor));

  for (;;) {
    stdout.write(" $question ");
    if (hint != null) {
      stdout.write("($hint) ".brightBlack());
    }

    String input = stdin.readLineSync()?.trim() ?? "";
    stdout.movelnUp(); // Move back to the question line.

    if (guard?.call(input) case False(:String failure)) {
      resetDisplay();
      displayFailure(input, failure);
      hasFailed = true;

      continue;
    }

    resetDisplay();
    displaySuccess(input);

    return Success<String>(input);
  }
}

Option<String> prompt(
  String question, {
  Guard<String>? guard,
  String? hint,
  Color accentColor = BasePromptDefaults.accentColor,
}) =>
    basePrompt(
      question,
      guard: guard,
      hint: hint,
      accentColor: accentColor,
    );

extension PromptExtension on WrappedStdin {
  Option<String> prompt(
    String question, {
    Guard<String>? guard,
    String? hint,
    Color accentColor = BasePromptDefaults.accentColor,
  }) =>
      basePrompt(
        question,
        guard: guard,
        hint: hint,
        accentColor: accentColor,
      );
}

typedef BasePrompt = Option<String> Function(
  String question, {
  Guard<String>? guard,
  String hint,
  Color accentColor,
});
