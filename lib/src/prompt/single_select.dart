import "dart:math" as math;

import "package:prompt/prompt.dart";
import "package:prompt/src/io/exception.dart";

abstract final class SingleSelectPromptDefaults {
  static const int start = 0;
  static const int view = 6;

  static const Color accentColor = Colors.brightBlue;
}

Result<T> singleSelectPrompt<T>(
  String question, {
  required List<T> choices,
  Guard<T>? guard,
  String? hint,
  int start = SingleSelectPromptDefaults.start,
  int view = SingleSelectPromptDefaults.view,
  Color accentColor = SingleSelectPromptDefaults.accentColor,
}) {
  assert(choices.isNotEmpty, "Choices must not be empty!");
  assert(0 <= start && start < choices.length, "[start] must be a valid index!");
  assert(view > 0, "view must be greater than 0.");

  int activeIndex = start;
  T chosen = choices[activeIndex];

  int viewLimit = <int>{
    view,
    choices.length,
    if (stdout.hasTerminal) stdout.terminalLines - stdout.cursor.line - 2,
  }.reduce(math.min);
  int disparity = 1;

  bool viewStartingAtActiveIndexExceedsLength =
      activeIndex - disparity + viewLimit > choices.length;

  bool viewExceedsZero = activeIndex - disparity >= 0;

  /// The actual index where the view starts.
  int viewStart;

  /// The index of the item in the view.
  int viewIndex;

  if (viewStartingAtActiveIndexExceedsLength) {
    viewStart = choices.length - viewLimit;
    viewIndex = activeIndex - choices.length + viewLimit;
  } else if (viewExceedsZero) {
    viewStart = activeIndex - disparity;
    viewIndex = disparity;
  } else {
    viewStart = 0;
    viewIndex = activeIndex;
  }

  String displayItemAt(int index, int viewIndex, {bool colored = true}) {
    const ({String active, String bottom, String inactive, String top}) displays = (
      top: "-",
      bottom: "-", // "∨"
      active: ">",
      inactive: " ",
    );

    StringBuffer buffer = StringBuffer();
    T option = choices[index];

    late bool isNonFirstTopEdge = viewIndex == 0 && index > 0;
    late bool isNonLastBottomEdge = viewIndex == viewLimit - 1 && index < choices.length - 1;
    late bool isActive = colored && index == activeIndex;
    if (isActive) {
      buffer.write(accentColor(displays.active));
    } else if (isNonFirstTopEdge) {
      buffer.write(displays.top.brightBlack());
    } else if (isNonLastBottomEdge) {
      buffer.write(displays.bottom.brightBlack());
    } else {
      buffer.write(displays.inactive);
    }

    buffer.write(" ");
    buffer.write("$option".color(accentColor, iff: isActive));

    return buffer.toString();
  }

  void move(void Function() body) {
    stdout.eraseln();
    stdout.write(displayItemAt(activeIndex, viewIndex, colored: false));

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
    int increment = hasFailed ? 1 : 0;

    stdout.eraselnUp(viewIndex + 1 + increment);
    stdout.eraselnDown(viewLimit - viewIndex);
    stdout.moveUp(viewIndex + 1 + increment);
  }

  try {
    /// Prerequisites
    stdout.hideCursor();

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

      for (var (int vi, (int i, _)) in choices.indexed.skip(viewStart).take(viewLimit).indexed) {
        stdout.writeln(displayItemAt(i, vi));
      }

      /// Choose the active option
      stdout.moveUp(viewLimit - viewIndex);

      loop:
      for (List<int> code in stdin.sync) {
        switch (code) {
          case <int>[0x03]:
            throw SignalInterruptionException();

          case <int>[0x0d]:
            chosen = choices[activeIndex];
            break loop;

          case <int>[0x1b, 0x5b, 0x41]:
            move(moveUp);

          case <int>[0x1b, 0x5b, 0x42]:
            move(moveDown);
        }
      }

      /// Clear the previous (including the question)
      clearDrawnScreen();

      if (guard case (GuardFunction<T> guardFunction, String message) //
          when !guardFunction(chosen)) {
        hasFailed = true;

        stdout.writeln("// $message".brightRed());
      } else {
        /// Display the answer.
        stdout.write("+".color(accentColor));
        stdout.write(" $question ");
        stdout.writeln("$chosen".color(accentColor));

        return Success<T>(chosen);
      }
    }
  } on SignalInterruptionException {
    /// Clear the previous (including the question)
    clearDrawnScreen();

    /// Display the failure
    stdout.write("!".brightRed());
    stdout.write(" $question ");
    stdout.writeln("^C".brightBlack());

    return Failure<T>("^C");
  } finally {
    stdout.showCursor();
  }
}

extension PromptSingleSelectionExtension on BasePrompt {
  /// Prompt the user to choose from a list of options.
  Result<T> select<T>(
    String question, {
    required List<T> choices,
    Guard<T>? guard,
    String? hint,
    int start = SingleSelectPromptDefaults.start,
    int view = SingleSelectPromptDefaults.view,
    Color accentColor = SingleSelectPromptDefaults.accentColor,
  }) =>
      singleSelectPrompt(
        question,
        choices: choices,
        guard: guard,
        hint: hint,
        start: start,
        accentColor: accentColor,
        view: view,
      );
}

typedef SingleSelectPrompt = Result<O> Function<O>(
  String question, {
  required List<O> choices,
  Guard<O>? guard,
  String? hint,
  int start,
  int view,
  Color accentColor,
});
