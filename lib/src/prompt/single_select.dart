import "dart:math" as math;

import "package:prompt/prompt.dart";
import "package:prompt/src/io/exception.dart";
import "package:prompt/src/prompt/shared/view.dart";

abstract final class SingleSelectPromptDefaults {
  static const int start = 0;
  static const int view = 6;

  static const Color accentColor = Colors.brightBlue;
}

Option<T> singleSelectPrompt<T>(
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
    topDisparity: 2,
    bottomDisparity: 2,
  );

  void displayItemAt(int index, int viewIndex, {bool colored = true}) {
    const ({String active, String bottom, String inactive, String top}) displays = (
      top: "-",
      bottom: "-", // "∨"
      active: ">",
      inactive: " ",
    );

    T option = choices[index];

    late bool isNonFirstTopEdge = viewIndex == 0 && index > 0;
    late bool isNonLastBottomEdge = viewIndex == viewLimit - 1 && index < choices.length - 1;
    late bool isActive = colored && index == activeIndex;
    if (isActive) {
      stdout.write(accentColor(displays.active));
    } else if (isNonFirstTopEdge) {
      stdout.write(displays.top.brightBlack());
    } else if (isNonLastBottomEdge) {
      stdout.write(displays.bottom.brightBlack());
    } else {
      stdout.write(displays.inactive);
    }

    stdout.write(" ");
    stdout.write("$option".color(accentColor, iff: isActive));
  }

  void move(void Function() body) {
    stdout.eraseln();
    displayItemAt(activeIndex, viewIndex, colored: false);

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
        displayItemAt(i, vi);
        stdout.writeln();
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

      if (guard case (GuardFunction<T> function, String message) when !function(chosen)) {
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
  Option<T> select<T>(
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

typedef SingleSelectPrompt = Option<O> Function<O>(
  String question, {
  required List<O> choices,
  Guard<O>? guard,
  String? hint,
  int start,
  int view,
  Color accentColor,
});
