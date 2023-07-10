import "dart:math" as math;

import "package:prompt/src/extensions.dart";
import "package:prompt/src/guard.dart";
import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/exception.dart";
import "package:prompt/src/io/stdio/block/stdout/hidden_cursor.dart";
import "package:prompt/src/io/stdio/context.dart";
import "package:prompt/src/io/stdio/wrapper/stdin.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdin.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";
import "package:prompt/src/option.dart";
import "package:prompt/src/prompt/base.dart";
import "package:prompt/src/prompt/shared/view.dart";
import "package:prompt/src/prompt/single_select.dart";

abstract final class MultiSelectPromptDefaults {
  static const int start = 0;
  static const int view = 6;
  static const int min = 0;

  static const Color accentColor = Colors.brightBlue;
}

abstract final class MultiSelectPromptSettings {
  static String selectedMarker = "[x]";
  static String unselectedMarker = "[ ]";
}

Option<List<T>> multiSelectPrompt<T>(
  String question, {
  required List<T> choices,
  Guard<List<T>>? guard,
  String? hint,
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
  int intrinsicViewLimit = <int>{
    view,
    choices.length,
    if (stdout.hasTerminal) stdout.terminalLines - 1 /** Question */ - 2,
  }.map((int v) => v - 1).reduce(math.min);

  var ViewInfo(
    /// The actual index where the view starts.
    :int viewStart,

    /// The index of the item in the view.
    :int viewIndex,

    /// The *preferred* distance of the active item from the top of the view.
    :int topDisparity,

    /// The *preferred* distance of the active item from the bottom of the view.
    :int bottomDisparity,

    /// The size of the view.
    :int viewLimit,
  ) = computeViewInfo(
    choices.length,
    index: activeIndex,
    topDistance: intrinsicViewLimit.fdiv(2),
    bottomDistance: intrinsicViewLimit.cdiv(2),
  );

  void displayItemAt(int index, int viewIndex, {bool isActiveColorDisabled = false}) {
    const ({String active, String bottom, String inactive, String top}) displays = (
      top: "-", // "∧"
      bottom: "-", // "∨"
      active: ">",
      inactive: " ",
    );

    T option = choices[index];

    late bool isNonFirstTopEdge = viewIndex <= 0 && index > 0;
    late bool isNonLastBottomEdge = viewIndex >= viewLimit - 1 && index < choices.length - 1;
    late bool isActive = !isActiveColorDisabled && index == activeIndex;
    late bool isChosen = chosenIndices.contains(index);

    if (isActive) {
      stdout.write(displays.active.color(accentColor));
    } else if (isNonFirstTopEdge) {
      stdout.write(displays.top.brightBlack());
    } else if (isNonLastBottomEdge) {
      stdout.write(displays.bottom.brightBlack());
    } else {
      stdout.write(displays.inactive);
    }

    stdout.write(" ");

    if (isChosen) {
      stdout.write(MultiSelectPromptSettings.selectedMarker.color(accentColor));
    } else {
      stdout.write(MultiSelectPromptSettings.unselectedMarker);
    }

    stdout.write(" ");

    if (isActive) {
      stdout.write("$option".color(accentColor));
    } else {
      stdout.write(option);
    }
  }

  void move(void Function() body) {
    stdout.eraseln();
    displayItemAt(activeIndex, viewIndex, isActiveColorDisabled: true);

    /// This looks weird, but [body()] is expected to mutate
    ///   [activeIndex] and [viewIndex]
    body();
    stdout.eraseln();
    displayItemAt(activeIndex, viewIndex);
    stdout.movelnStart();
  }

  void moveUp() {
    if (activeIndex > 0) {
      --activeIndex;

      if ((viewIndex - topDisparity > 0) || //
          (activeIndex - topDisparity < 0)) {
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
        displayItemAt(i, vi);
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
        displayItemAt(i, vi);
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

      if ((viewIndex + bottomDisparity < viewLimit - 1) || //
          (activeIndex + bottomDisparity > choices.length - 1)) {
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
        displayItemAt(i, vi);
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
        displayItemAt(i, vi);
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
      if (hint != null) {
        stdout.space();
        stdout.write("($hint)".brightBlack());
      }
      stdout.writeln();

      for (var (int vi, (int i, _)) in choices //
          .indexed
          .skip(viewStart)
          .take(viewLimit)
          .indexed) {
        displayItemAt(i, vi);
        stdout.writeln();
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
            displayItemAt(activeIndex, viewIndex);

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

      if (guard?.call(chosen) case False(:String failure)) {
        stdout.writeln("// $failure".brightRed());
        hasFailed = true;

        continue failure_loop;
      }

      stdout.write("+".color(accentColor));
      stdout.write(" $question ");
      try {
        stdout.push();
        stdout.foregroundColor = accentColor;

        if (chosen.length > 5) {
          stdout.writeln("${chosen.length} selected items");
        } else {
          stdout.writeln(chosen.join(", "));
        }
      } finally {
        stdout.pop();
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
  Option<List<T>> selectMulti<T>(
    String question, {
    required List<T> choices,
    Guard<List<T>>? guard,
    String? hint,
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
  Option<List<T>> multi<T>(
    String question, {
    required List<T> choices,
    Guard<List<T>>? guard,
    String? hint,
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

typedef MultiSelectPrompt<T> = Option<List<T>> Function(
  String question, {
  required List<T> choices,
  Guard<T>? guard,
  String? hint,
  int start,
  int view,
  Color accentColor,
});
