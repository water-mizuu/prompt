import "package:prompt/src/extensions.dart";
import "package:prompt/src/guard.dart";
import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/decoration/style.dart";
import "package:prompt/src/io/exception.dart";
import "package:prompt/src/io/stdio/context.dart";
import "package:prompt/src/io/stdio/wrapper/stdin.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdin.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";
import "package:prompt/src/option.dart";
import "package:prompt/src/prompt/base.dart";

Option<String> linePrompt(
  String question, {
  Guard<String>? guard,
  Color accentColor = Colors.brightBlue,
  bool sameLine = false,
  bool showInput = true,
  String? mask,
}) {
  String formattedQuestion = question.bold();
  int x = 0;
  List<String> content = [];

  void padContent() {
    if (x > content.length - 1) {
      for (int i = content.length - 1; i <= x; ++i) {
        content.add("");
      }
    }
  }

  void tab() {
    x += 2;
  }

  void right() {
    if (x >= content.length - 1) {
      return;
    }

    if (showInput || mask != null) {
      stdout.moveRight();
    }
    x += 1;
  }

  void left() {
    if (x <= 0) {
      return;
    }

    if (showInput || mask != null) {
      stdout.moveLeft();
    }
    x -= 1;
  }

  void backspace() {
    if (x - 1 < 0) return;

    content.removeAt(x - 1);

    if (showInput || mask != null) {
      stdout.moveLeft();

      stdout.eraselnFromCursor();
      stdout.write$(content.skip(x - 1).join());
    }

    x -= 1;
  }

  void delete() {
    if (x >= content.length) return;

    if (showInput || mask != null) {
      stdout.moveRight();
    }
    x += 1;
    backspace();
  }

  void type(int code) {
    padContent();

    stdout.eraselnFromCursor();

    String value = String.fromCharCode(code);
    if (content[x].isEmpty) {
      /// If the current character is uninhabited, then we can write to it.
      content[x] = value;
    } else {
      /// Else, we must insert a new character.
      content.insert(x, value);
    }

    if (showInput) {
      stdout.write$(content.skip(x).join());
      stdout.moveRight();
    } else if (mask != null) {
      stdout.write$(
        content.skip(x).toList().reversed.skipWhile((s) => s.isEmpty).map((s) => mask).join(),
      );
      stdout.moveRight();
    }
    x += 1;
  }

  bool hasFailed = false;
  try {
    stdout.push();
    for (;;) {
      {
        StringBuffer buffer = StringBuffer()
          ..write(hasFailed ? "!".brightRed() : "?".color(accentColor))
          ..write(" $formattedQuestion ");

        stdout.write(buffer);
        if (!sameLine && (showInput || mask != null)) {
          stdout.writeln();
          var cursor = stdout.cursor?.line;
          if (cursor != null && cursor + 1 >= stdout.terminalLines) {
            stdout.scrollUp();
          }
        }
      }

      if (showInput && mask == null) {
        stdout.write(content.join());
      }

      /// A ghetto text editor. Doesn't support scrolling, wrapping, etc.
      loop:
      for (List<int> code in stdin.sync) {
        switch (code) {
          case <int>[0x3]: // ctrl c
            throw SignalInterruptionException();

          case <int>[0x09]: // tab
            tab();

          case <int>[0x1b, 0x5b, 0x43]: // right
            right();
          case <int>[0x1b, 0x5b, 0x44]: // left
            left();
          case <int>[0x7f]: // backspace
            backspace();
          case <int>[0x1b, 0x5b, 0x33, 0x7e]: // delete
            delete();

          case <int>[0xd]: // enter
            break loop;
          case <int>[int code]: // any single character
            type(code);
        }
      }

      String built = content.join();
      int increment = hasFailed ? 1 : 0;

      stdout.moveLeft(x);

      if (sameLine || (!showInput && mask == null)) {
        stdout.moveUp(increment);
        stdout.eraselnDown(increment);
      } else {
        stdout.moveUp(1 + increment);
        stdout.eraselnDown(1 + increment);
      }

      if (guard?.call(built) case False(:String failure)) {
        stdout.eraselnFromCursor();
        stdout.writeln("// $failure".brightRed());
        hasFailed = true;

        continue;
      }

      StringBuffer buffer = StringBuffer()
        ..write("+".color(accentColor))
        ..write(" $formattedQuestion ");

      if (showInput) {
        buffer
            .write(built.trimLeft().split("\n").join(r"\n").ellipsisVisible(30).color(accentColor));
      }

      stdout.writeln(buffer);

      return Success<String>(built);
    }
  } on SignalInterruptionException {
    int increment = hasFailed ? 1 : 0;

    stdout.moveLeft(x);
    stdout.moveUp(1 + increment);
    stdout.eraselnDown(1 + increment);

    StringBuffer buffer = StringBuffer()
      ..write("!".brightRed())
      ..write(" $formattedQuestion ")
      ..write("^C".brightBlack());

    stdout.writeln(buffer);

    return const Failure<String>("^C");
  } finally {
    stdout.pop();
  }
}

extension PromptSingleLineExtension on BasePrompt {
  Option<String> line(
    String question, {
    Guard<String>? guard,
    Color accentColor = Colors.brightBlue,
    bool showInput = true,
    bool sameLine = false,
    String? mask,
  }) =>
      linePrompt(
        question,
        guard: guard,
        accentColor: accentColor,
        showInput: showInput,
        sameLine: sameLine,
        mask: mask,
      );

  Option<String> password(
    String question, {
    Guard<String>? guard,
    Color accentColor = Colors.brightBlue,
    bool showInput = false,
  }) =>
      linePrompt(
        question,
        guard: guard,
        accentColor: accentColor,
        showInput: showInput,
        mask: showInput ? "*" : null,
        sameLine: true,
      );
}
