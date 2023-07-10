import "package:prompt/prompt.dart";

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

    if (guard case (GuardFunction<String> function, String message) when !function(input)) {
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
