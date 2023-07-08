import "package:prompt/prompt.dart";
import "package:prompt/src/io/exception.dart";

Result<String> linesPrompt(
  String question, {
  Guard<String>? guard,
  String? example,
  Color accentColor = Color.brightBlue,
}) {
  String formattedQuestion = question.bold();
  int y = 0;
  int x = 0;
  List2<String> content = "".trimRight().split("\n").map((String line) => line.split("")).toList();

  void padContent() {
    if (y > content.length - 1) {
      for (int i = content.length - 1; i <= y; ++i) {
        content.add(<String>[]);
      }
    }
    if (x > content[y].length - 1) {
      for (int i = content[y].length - 1; i <= x; ++i) {
        content[y].add("");
      }
    }
  }

  void tab() {
    late int previousIndent = content[y - 1].takeWhile((String c) => c == " ").length - x;

    if (y <= 0 || previousIndent <= 0) {
      // Just indent.
      stdout.moveRight(2);
      content[y].insertAll(x, List<String>.filled(2, " "));

      x += 2;
    } else {
      stdout.moveRight(previousIndent);
      content[y].insertAll(x, List<String>.filled(previousIndent, " "));
      x += previousIndent;
    }
  }

  void up() {
    if (y <= 0) {
      return;
    }

    stdout.moveUp();

    if (y > 0) {
      if (content[y - 1].visibleLength case int bottomRowLength when bottomRowLength < x) {
        int topRowLength = bottomRowLength;

        stdout.moveLeft(x - topRowLength);
        x = topRowLength;
      }
    }
    y -= 1;
  }

  void down() {
    if (y > content.length - 1) {
      return;
    }

    stdout.moveDown();

    if (y < content.length - 1) {
      if (content[y + 1].visibleLength case int topRowLength when topRowLength < x) {
        stdout.moveLeft(x - topRowLength);
        x = topRowLength;
      }
    }

    y += 1;
  }

  void right() {
    if (content[y].visibleLength case int distance when x >= distance) {
      if (y >= content.length - 1) {
        return;
      }

      // Move down.
      stdout.moveLeft(distance);
      stdout.moveDown();

      x = 0;
      y += 1;
    } else {
      stdout.moveRight();
      x += 1;
    }
  }

  void left() {
    if (x <= 0) {
      if (y <= 0) {
        return;
      }

      int offset = content[y - 1].visibleLength;
      // Move up.
      stdout.moveUp();

      // Move to the end of the previous line.
      stdout.moveRight(offset);

      x = offset;
      y -= 1;
    } else {
      stdout.moveLeft();
      x -= 1;
    }
  }

  void backspace() {
    if (x <= 0) {
      if (y <= 0) {
        return;
      }

      /// Cut the current line.
      List<String> remaining = content.removeAt(y);
      List<String> left = content[y - 1];

      stdout.eraselnFromCursor();
      stdout.moveUp();
      stdout.moveRight(left.visibleLength);
      stdout.write$(remaining.join());
      stdout.moveLeft(left.visibleLength);

      for (List<String> line in content.skip(y)) {
        stdout.moveDown();
        stdout.eraselnFromCursor();
        stdout.write$(line.join());
      }

      stdout.moveDown();
      stdout.eraselnFromCursor();
      stdout.moveUp(content.length - y + 1);
      stdout.moveRight(left.visibleLength);

      y -= 1;
      x = content[y].visibleLength;
      content[y].addAll(remaining);
    } else {
      content[y].removeAt(x - 1);
      stdout.moveLeft();

      stdout.eraselnFromCursor();
      stdout.write$(content[y].skip(x - 1).join());

      x -= 1;
    }
  }

  void delete() {
    stdout.moveRight();
    x += 1;
    backspace();
  }

  void enter() {
    int indentation = content[y].takeWhile((String c) => c == " ").length;

    /// Cut the content from the cursor onward.
    stdout.eraselnFromCursor();

    /// Move to next line.
    stdout.moveLeft(x);
    stdout.moveDown();

    var (List<String> left, List<String> right) = content[y].splitAt(x);

    /// Split the lines
    content.insert(y, left);
    content[y + 1] = List<String>.filled(indentation, " ") + right;

    /// Update the content.
    for (List<String> line in content.skip(y + 1)) {
      /// Erase the current line
      stdout.eraselnFromCursor();

      /// Write without updating the cursor, and move down.
      stdout.writeln(line.join());
    }

    /// We move back up to the line we were on.
    stdout.moveUp(content.length - y - 1);
    stdout.moveRight(indentation);

    x = indentation;
    y += 1;
  }

  void type(int code) {
    padContent();

    stdout.eraselnFromCursor();

    String value = String.fromCharCode(code);
    if (content[y][x].isEmpty) {
      /// If the current character is uninhabited, then we can write to it.
      content[y][x] = value;
    } else {
      /// Else, we must insert a new character.
      content[y].insert(x, value);
    }
    stdout.write$(content[y].skip(x).join());
    stdout.moveRight();

    x += 1;
  }

  bool hasFailed = false;
  try {
    for (;;) {
      {
        StringBuffer buffer = StringBuffer()
          ..write(hasFailed ? "!".brightRed() : "?".color(accentColor))
          ..write(" $formattedQuestion ")
          ..write("// CTRL+D to confirm".brightBlack());

        stdout.writeln$(buffer);
      }

      for (List<String> line in content) {
        stdout.write$(line.join());
        stdout.moveDown();
      }

      /// Guarantee: We are at the end of the last line.
      ///            Our column is at zero.
      stdout.moveUp(content.length - y);
      stdout.moveRight(x);

      /// A ghetto text editor. Doesn't support scrolling, wrapping, etc.
      loop:
      for (List<int> code in stdin.sync) {
        switch (code) {
          case <int>[0x4]: // ctrl d
            break loop;
          case <int>[0x3]: // ctrl c
            throw SignalInterruptionException();

          case <int>[0x09]: // tab
            tab();

          case <int>[0x1b, 0x5b, 0x41]: // up
            up();
          case <int>[0x1b, 0x5b, 0x42]: // down
            down();
          case <int>[0x1b, 0x5b, 0x43]: // right
            right();
          case <int>[0x1b, 0x5b, 0x44]: // left
            left();
          case <int>[0x7f]: // backspace
            backspace();
          case <int>[0x1b, 0x5b, 0x33, 0x7e]: // delete
            delete();

          case <int>[0xd]: // enter
            // if (y < content.length && content.length > 3) {
            //   if (content case <List<String>>[..., [], []]) {
            //     stdout.moveUp(3);
            //     content.removeRange(content.length - 3, content.length);
            //     break loop;
            //   }
            // }
            enter();
          case <int>[int code]: // any single character
            type(code);
        }
      }

      String built = content.map((List<String> l) => l.join()).join("\n");
      int increment = hasFailed ? 1 : 0;

      stdout.moveLeft(x);
      stdout.moveUp(y + 1 + increment);
      for (int i = 0; i < content.length + 1 + increment; ++i) {
        stdout.eraselnFromCursor();
        stdout.moveDown();
      }
      stdout.moveUp(content.length + 1 + increment);

      if (guard case (GuardFunction<String> guard, String message) when !guard(built)) {
        stdout.eraselnFromCursor();
        stdout.writeln("// $message".brightRed());
        hasFailed = true;

        continue;
      }

      StringBuffer buffer = StringBuffer()
        ..write("+".color(accentColor))
        ..write(" $formattedQuestion ")
        ..write(built.split("\n").join(r"\n").ellipsisVisible(30).color(accentColor));

      stdout.writeln(buffer);

      return Success<String>(built);
    }
  } on SignalInterruptionException {
    int increment = hasFailed ? 1 : 0;

    stdout.moveLeft(x);
    stdout.moveUp(y + 1 + increment);
    for (int i = 0; i < content.length + 1 + increment; ++i) {
      stdout.eraselnFromCursor();
      stdout.moveDown();
    }
    stdout.moveUp(content.length + 1 + increment);

    StringBuffer buffer = StringBuffer()
      ..write("!".brightRed())
      ..write(" $formattedQuestion ")
      ..write("^C".brightBlack());

    stdout.writeln(buffer);

    return const Failure<String>("^C");
  } finally {}
}

extension PromptMultiLineExtension on BasePrompt {
  Result<String> lines(
    String question, {
    Guard<String>? guard,
    String? example,
    Color accentColor = Color.brightBlue,
  }) =>
      linesPrompt(
        question,
        guard: guard,
        example: example,
        accentColor: accentColor,
      );
}
