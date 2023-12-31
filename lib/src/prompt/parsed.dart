import "dart:core" as core show BigInt, bool, double, int;
import "dart:core";

import "package:prompt/src/guard.dart";
import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdin.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";
import "package:prompt/src/option.dart";
import "package:prompt/src/prompt/base.dart";
import "package:prompt/src/types.dart";

abstract final class ParsedPromptDefaults {
  static const bool repeat = true;
  static const Color accentColor = Colors.brightBlue;
}

Option<T> parsedPrompt<T>(
  String question, {
  required Parser<T> parser,
  Guard<T>? guard,
  String? hint,
  Color accentColor = BasePromptDefaults.accentColor,
}) {
  bool hasFailed = false;

  void displaySuccess(T answer) {
    stdout.write("+".color(accentColor));
    stdout.write(" $question ");
    stdout.writeln("$answer".color(accentColor));
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

    String rawInput = stdin.readLineSync()?.trim() ?? "";
    stdout.movelnUp(); // Move back to the question line.

    var (ParseFunction<T> parserFunction, String message) = parser;

    T? parsed = parserFunction(rawInput);
    if (parsed is! T) {
      resetDisplay();
      displayFailure(rawInput, message);
      hasFailed = true;

      continue;
    }
    if (guard?.call(parsed) case False(:String failure)) {
      resetDisplay();
      displayFailure(rawInput, failure);
      hasFailed = true;

      continue;
    }

    resetDisplay();
    displaySuccess(parsed);

    return Success<T>(parsed);
  }
}

extension PromptParsedExtension on BasePrompt {
  Option<O> parsed<O>(
    String question, {
    required Parser<O> parser,
    Guard<O>? guard,
    String? example,
    Color accentColor = ParsedPromptDefaults.accentColor,
  }) =>
      parsedPrompt(
        question,
        parser: parser,
        guard: guard,
        hint: example,
        accentColor: accentColor,
      );

  Option<String> string(
    String question, {
    Guard<String>? guard,
    String? example,
    Color accentColor = ParsedPromptDefaults.accentColor,
  }) =>
      parsedPrompt(
        question,
        parser: ((String source) => source, "Never"),
        guard: guard,
        hint: example,
        accentColor: accentColor,
      );

  Option<core.int> int(
    String question, {
    Guard<core.int>? guard,
    String? example,
    Color accentColor = ParsedPromptDefaults.accentColor,
  }) =>
      parsedPrompt(
        question,
        parser: (core.int.tryParse, "Failed to parse input as integer"),
        guard: guard,
        hint: example,
        accentColor: accentColor,
      );

  Option<core.double> double(
    String question, {
    Guard<core.double>? guard,
    String? example,
    Color accentColor = ParsedPromptDefaults.accentColor,
  }) =>
      parsedPrompt(
        question,
        parser: (core.double.tryParse, "Failed to parse input as double"),
        guard: guard,
        hint: example,
        accentColor: accentColor,
      );

  Option<core.BigInt> bigInt(
    String question, {
    Guard<core.BigInt>? guard,
    String? example,
    Color accentColor = ParsedPromptDefaults.accentColor,
  }) =>
      parsedPrompt(
        question,
        parser: (core.BigInt.tryParse, "Failed to parse input as BigInt"),
        guard: guard,
        hint: example,
        accentColor: accentColor,
      );

  Option<core.bool> bool(
    String question, {
    Guard<core.bool>? guard,
    core.bool defaultValue = true,
    String? example,
    Color accentColor = ParsedPromptDefaults.accentColor,
  }) => //
      parsedPrompt(
        question,
        parser: (
          (String source) => switch (source.toLowerCase()) {
                "y" || "yes" || "true" => true,
                "n" || "no" || "false" => false,
                "" => defaultValue,
                _ => null,
              },
          "Failed to convert value to boolean",
        ),
        guard: guard,
        hint: example ?? (defaultValue ? "Y/n" : "y/N"),
        accentColor: accentColor,
      );
}
