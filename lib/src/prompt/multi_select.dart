import "dart:math" as math;

import "package:prompt/prompt.dart";
import "package:prompt/src/io/exception.dart";

abstract final class MultiSelectPromptDefaults {
  static const int start = 0;
  static const int view = 6;
  static const int min = 0;

  static const String hint = "";

  static const Color accentColor = Colors.brightBlue;
}

abstract final class MultiSelectPromptSettings {
  static String selectedMarker = "[x]";
  static String unselectedMarker = "[ ]";
}

Result<List<T>> multiSelectPrompt<T>(
  String question, {
  required List<T> choices,
  Guard<List<T>>? guard,
  String hint = MultiSelectPromptDefaults.hint,
  int start = MultiSelectPromptDefaults.start,
  int view = MultiSelectPromptDefaults.view,
  int min = MultiSelectPromptDefaults.min,
  Color accentColor = MultiSelectPromptDefaults.accentColor,
}) {
  assert(choices.isNotEmpty, "Choices must not be empty!");
  assert(0 <= start && start < choices.length, "[start] must be a valid index!");
  assert(view > 0, "view must be greater than 0.");

  int activeIndex = start;

  Set<int> chosenIndices = <int>{};

  int viewLimit = <int>{
    view,
    choices.length,
    if (stdout.hasTerminal) stdout.terminalLines - stdout.cursor.line - 2,
  }.reduce(math.min);
  int disparity = 1;

  /// The actual index where the view starts.
  int viewStart;

  /// The index of the item in the view.
  int viewIndex;

  if (activeIndex - disparity > choices.length - viewLimit) {
    viewStart = choices.length - viewLimit;
    viewIndex = activeIndex - choices.length + viewLimit;
  } else if (activeIndex - disparity >= 0) {
    viewStart = activeIndex - disparity;
    viewIndex = disparity;
  } else {
    viewStart = 0;
    viewIndex = activeIndex;
  }

  String displayItemAt(int index, int viewIndex, {bool isActiveColorDisabled = false}) {
    const ({String active, String bottom, String inactive, String top}) displays = (
      top: "-", // "∧"
      bottom: "-", // "∨"
      active: ">",
      inactive: " ",
    );

    StringBuffer buffer = StringBuffer();
    T option = choices[index];

    late bool isNonFirstTopEdge = viewIndex <= 0 && index > 0;
    late bool isNonLastBottomEdge = viewIndex >= viewLimit - 1 && index < choices.length - 1;
    late bool isActive = !isActiveColorDisabled && index == activeIndex;
    late bool isChosen = chosenIndices.contains(index);

    if (isActive) {
      buffer.write(displays.active.color(accentColor));
    } else if (isNonFirstTopEdge) {
      buffer.write(displays.top.brightBlack());
    } else if (isNonLastBottomEdge) {
      buffer.write(displays.bottom.brightBlack());
    } else {
      buffer.write(displays.inactive);
    }

    buffer.write(" ");

    if (isChosen) {
      buffer.write(MultiSelectPromptSettings.selectedMarker.color(accentColor));
    } else {
      buffer.write(MultiSelectPromptSettings.unselectedMarker);
    }

    buffer.write(" ");

    if (isActive) {
      buffer.write("$option".color(accentColor));
    } else {
      buffer.write(option);
    }

    return buffer.toString();
  }

  void move(void Function() body) {
    stdout.eraseln();
    stdout.write(displayItemAt(activeIndex, viewIndex, isActiveColorDisabled: true));

    /// This looks weird, but [body()] is expected to mutate
    ///   [activeIndex] and [viewIndex]
    body();
    stdout.eraseln();
    stdout.write(displayItemAt(activeIndex, viewIndex));
    stdout.movelnStart();
  }

  void moveUp() {
    if (activeIndex > 0) {
      --activeIndex;

      if ((viewIndex - disparity > 0) || //
          (activeIndex - disparity < 0)) {
        --viewIndex;
        stdout.moveUp();

        return;
      }

      --viewStart;

      /// Scan until the top, and update.
      for (int y = viewIndex - 1; y >= 0; --y) {
        int i = activeIndex - (viewIndex - y);
        int vi = y;

        stdout.moveUp();
        stdout.eraseln();
        stdout.write(displayItemAt(i, vi));
      }

      /// Now that the cursor is at the top,
      ///   Move down the position to the viewIndex.
      stdout.moveDown(viewIndex);

      /// Scan until the bottom, and update.
      for (int y = viewIndex + 1; y < viewLimit; ++y) {
        int i = activeIndex - (viewIndex - y);
        int vi = y;

        stdout.moveDown();
        stdout.eraseln();
        stdout.write(displayItemAt(i, vi));
      }

      /// Now that the cursor is at the bottom,
      ///   Move the position up to the viewIndex.
      stdout.moveUp(viewLimit - viewIndex - 1);
      stdout.movelnStart();
    }
  }

  void moveDown() {
    if (activeIndex < choices.length - 1) {
      ++activeIndex;

      if ((viewIndex + disparity < viewLimit - 1) || //
          (activeIndex + disparity > choices.length - 1)) {
        ++viewIndex;
        stdout.moveDown();
        return;
      }

      ++viewStart;

      /// Scan until the bottom, and update.
      for (int y = viewIndex + 1; y < viewLimit; ++y) {
        int i = activeIndex - (viewIndex - y);
        int vi = y;

        stdout.moveDown();
        stdout.eraseln();
        stdout.write(displayItemAt(i, vi));
      }

      /// Now that the cursor is at the bottom,
      ///   Move up the position to the viewIndex.
      stdout.moveUp(viewLimit - viewIndex - 1);

      /// Scan until the top, and update.
      for (int y = viewIndex - 1; y >= 0; --y) {
        int i = activeIndex - (viewIndex - y);
        int vi = y;

        stdout.moveUp();
        stdout.eraseln();
        stdout.write(displayItemAt(i, vi));
      }

      /// Now that the cursor is at the top,
      ///   Move the position down to the viewIndex.
      stdout.moveDown(viewIndex);
      stdout.movelnStart();
    }
  }

  bool hasFailed = false;

  void clearDrawnScreen() {
    int addend = hasFailed ? 1 : 0;

    stdout.eraselnUp(viewIndex + 1 + addend);
    stdout.eraselnDown(viewLimit - viewIndex);
    stdout.moveUp(viewIndex + 1 + addend);
  }

  try {
    /// Prerequisites
    stdout.push();
    stdout.hideCursor();

    failure_loop:
    for (;;) {
      /// Body
      if (hasFailed) {
        stdout.write("!".brightRed());
      } else {
        stdout.write("?".color(accentColor));
      }
      stdout.space();
      stdout.write(question);
      if (hint.isNotEmpty) {
        stdout.space();
        stdout.write("($hint)".brightBlack());
      }
      stdout.writeln();

      for (var (int vi, (int i, _)) in choices.indexed.skip(viewStart).take(viewLimit).indexed) {
        stdout.writeln(displayItemAt(i, vi));
      }

      /// Choose the active option
      stdout.moveUp(viewLimit - viewIndex);

      key_loop:
      for (List<int> code in stdin.sync) {
        switch (code) {
          case <int>[0x03]:
            throw SignalInterruptionException();

          case <int>[0x20]:
            if (chosenIndices.contains(activeIndex)) {
              chosenIndices.remove(activeIndex);
            } else {
              chosenIndices.add(activeIndex);
            }

            stdout.eraseln();
            stdout.write(displayItemAt(activeIndex, viewIndex));

          case <int>[0x0d]:
            break key_loop;

          case <int>[0x1b, 0x5b, 0x41]:
            move(moveUp);

          case <int>[0x1b, 0x5b, 0x42]:
            move(moveDown);
        }
      }

      /// Clear the previous (including the question)
      clearDrawnScreen();

      /// Check if the number of chosen items is valid.
      if (min > 0 && chosenIndices.length < min) {
        stdout.writeln("// You must select at least $min items.".brightRed());
        hasFailed = true;

        continue failure_loop;
      }

      /// Display the answer.
      List<T> chosen = <T>[for (int index in chosenIndices) choices[index]];

      if (guard case (GuardFunction<List<T>> fn, String msg) when !fn(chosen)) {
        stdout.writeln("// $msg".brightRed());
        hasFailed = true;

        continue failure_loop;
      }

      stdout.write("+".color(accentColor));
      stdout.write(" $question ");
      for (void _ in stdout.contextBlock) {
        stdout.foregroundColor = accentColor;

        if (chosen.length > 5) {
          stdout.writeln("${chosen.length} selected items");
        } else {
          stdout.writeln(chosen.join(", "));
        }
      }

      return Success<List<T>>(chosen);
    }
  } on SignalInterruptionException {
    /// Clear the previous (including the question)
    clearDrawnScreen();

    /// Display the failure
    stdout.write("!".brightRed());
    stdout.write(" $question ");
    stdout.writeln("^C".brightBlack());

    return Failure<List<T>>("^C");
  } finally {
    stdout.pop();
  }
}

extension PromptMultiSelectExtension on BasePrompt {
  /// Prompt the user to choose from a list of options.
  Result<List<T>> selectMulti<T>(
    String question, {
    required List<T> choices,
    Guard<List<T>>? guard,
    String hint = MultiSelectPromptDefaults.hint,
    int start = MultiSelectPromptDefaults.start,
    int view = MultiSelectPromptDefaults.view,
    int min = MultiSelectPromptDefaults.min,
    Color accentColor = MultiSelectPromptDefaults.accentColor,
  }) =>
      multiSelectPrompt(
        question,
        choices: choices,
        guard: guard,
        hint: hint,
        start: start,
        view: view,
        min: min,
        accentColor: accentColor,
      );
}

extension SingleSelectPromptMultiSelectExtension on SingleSelectPrompt {
  /// Prompt the user to choose from a list of options.
  Result<List<T>> multi<T>(
    String question, {
    required List<T> choices,
    Guard<List<T>>? guard,
    String hint = MultiSelectPromptDefaults.hint,
    int start = MultiSelectPromptDefaults.start,
    int view = MultiSelectPromptDefaults.view,
    int min = MultiSelectPromptDefaults.min,
    Color accentColor = MultiSelectPromptDefaults.accentColor,
  }) =>
      multiSelectPrompt(
        question,
        choices: choices,
        guard: guard,
        hint: hint,
        start: start,
        view: view,
        min: min,
        accentColor: accentColor,
      );
}

typedef MultiSelectPrompt<T> = Result<List<T>> Function(
  String question, {
  required List<T> choices,
  Guard<T>? guard,
  String? hint,
  int start,
  int view,
  Color accentColor,
});
