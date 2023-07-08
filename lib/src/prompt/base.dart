import "package:prompt/prompt.dart";

abstract final class BasePromptDefaults {
  static const Color accentColor = Color.brightBlue;
}

Result<String> basePrompt(
  String question, {
  Guard<String>? guard,
  String? hint,
  Color accentColor = BasePromptDefaults.accentColor,
}) {
  String formattedQuestion = question.bold();
  bool hasFailed = false;

  void displaySuccess(String answer) {
    stdout.write("+".color(accentColor));
    stdout.write(" $formattedQuestion ");
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
    stdout.write(" $formattedQuestion ");
    if (hint != null) {
      stdout.write("($hint) ".brightBlack());
    }

    String input = stdin.readLineSync()?.trim() ?? "";
    stdout.movelnUp(); // Move back to the question line.

    if (guard case (GuardFunction<String> fn, String message) when !fn(input)) {
      resetDisplay();
      displayFailure(input, message);
      hasFailed = true;

      continue;
    }

    resetDisplay();
    displaySuccess(input);

    return Success<String>(input);
  }
}

Result<String> prompt(
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
  Result<String> prompt(
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

typedef BasePrompt = Result<String> Function(
  String question, {
  Guard<String>? guard,
  String hint,
  Color accentColor,
});
