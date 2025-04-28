import "dart:collection";
import "dart:io" hide stdin, stdout;
import "dart:math" as math;

import "package:prompt/src/extensions.dart";
import "package:prompt/src/guard.dart";
import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/exception.dart";
import "package:prompt/src/io/stdio/block/stdout/context.dart";
import "package:prompt/src/io/stdio/block/stdout/hidden_cursor.dart";
import "package:prompt/src/io/stdio/context.dart";
import "package:prompt/src/io/stdio/wrapper/stdin.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdin.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";
import "package:prompt/src/option.dart";
import "package:prompt/src/prompt/base.dart";
import "package:prompt/src/prompt/shared/view.dart";

typedef FSE = FileSystemEntity;

abstract final class FileSystemEntityPromptDefaults {
  static const Color accentColor = Colors.brightBlue;
}

int compareFileSystemEntity(FileSystemEntity a, FileSystemEntity b) => switch ((a, b)) {
      // directories
      (Directory(), File()) => -1,
      // And finally files.
      (File(), Directory()) => 1,
      // If the types are equal, then we compare their name alphabetically.
      (FileSystemEntity(name: String left), FileSystemEntity(name: String right)) =>
        left.compareTo(right),
    };

int index = 0;

Option<FileSystemEntity> fileSystemEntityPrompt(
  String question, {
  Directory? start,
  Guard<FileSystemEntity>? guard,
  String? hint,
  bool displayFullPath = false,
  Color accentColor = FileSystemEntityPromptDefaults.accentColor,
}) {
  start ??= Directory.current;

  int topDisparity = 1;
  int bottomDisparity = 1;
  Directory activeDirectory = start;

  bool hasFailed = false;

  late int activeIndex;
  late int viewIndex;
  late int viewStart;
  late int viewLimit;
  late List<FileSystemEntity> children;

  void displayEntity(int index, int viewIndex, {bool isActive = true}) {
    const displays = (
      top: "-",
      bottom: "-", // "∨"
      active: ">",
      inactive: " ",
    );

    stdout.write("  ");
    late bool isNonFirstTopEdge = viewIndex == 0 && index > 0;
    late bool isNonLastBottomEdge = viewIndex == viewLimit - 1 && index < children.length - 1;
    if (isActive && activeIndex == index) {
      stdout.write(displays.active.brightBlue());
    } else if (isNonFirstTopEdge) {
      stdout.write(displays.top.brightBlack());
    } else if (isNonLastBottomEdge) {
      stdout.write(displays.bottom.brightBlack());
    } else {
      stdout.write(displays.inactive.brightBlack());
    }

    stdout.write(" ");

    if (children[index] case FileSystemEntity entity) {
      if (entity is Directory) {
        stdout.write("${entity.name}/");
      } else {
        stdout.write(entity.name);
        stdout.write(
          " [${entity.statSync().size.toString().replaceAll(RegExp(r"\B(?=(\d{3})+(?!\d))"), ",")} bytes]"
              .brightBlack(),
        );
      }
    }
  }

  void erase() {
    int increment = hasFailed ? 1 : 0;

    stdout.moveUp(viewIndex + 1 + increment);
    stdout.eraselnDown(viewLimit + 1 + increment);
  }

  // ignore: no_leading_underscores_for_local_identifiers
  void update({Directory? previous}) {
    children = activeDirectory.listSync()..sort(compareFileSystemEntity);
    activeIndex = previous == null //
        ? 0
        : children.indexWhere((FileSystemEntity e) => e.path == previous.path);

    int intrinsicViewLimit = <int>{
      children.length,
      8,
      if (stdout.hasTerminal) stdout.terminalLines - 1 /** Question */ - 2,
    }.map((int v) => v - 1).reduce(math.min);

    ViewInfo(
      :viewStart,
      :viewIndex,
      :viewLimit,
    ) = computeViewInfo(
      children.length,
      index: activeIndex,
      topDisparity: topDisparity,
      bottomDisparity: bottomDisparity,
      topDistance: intrinsicViewLimit.fdiv(2),
      bottomDistance: intrinsicViewLimit.cdiv(2),
    );
  }

  void drawTitle({bool isActiveDrawn = true}) {
    if (hasFailed) {
      stdout.write("!".brightRed());
    } else {
      stdout.write("?".color(accentColor));
    }
    stdout.write(" $question ");
    if (hint != null) {
      stdout.write("($hint) ");
    }

    stdout.context(() {
      stdout.foregroundColor = Colors.brightBlack;
      stdout.write(activeDirectory.compactPath);
      stdout.write(Platform.pathSeparator);
      stdout.write(children[activeIndex].name);
    });
  }

  void draw() {
    drawTitle();
    stdout.writeln();

    for (var (int vi, (int i, _)) in children.indexed //
        .skip(viewStart)
        .take(viewLimit)
        .indexed) {
      displayEntity(i, vi);
      stdout.writeln();
    }

    stdout.moveUp(viewLimit - viewIndex);
  }

  void move(void Function() body) {
    stdout.moveUp(viewIndex + 1);
    stdout.eraseln();
    drawTitle(isActiveDrawn: false);
    stdout.moveDown(viewIndex + 1);

    stdout.eraseln();
    displayEntity(activeIndex, viewIndex, isActive: false);

    /// This looks weird, but [body()] is expected to mutate
    ///   [activeIndex] and [viewIndex]
    body();

    stdout.moveUp(viewIndex + 1);
    stdout.eraseln();
    drawTitle();
    stdout.moveDown(viewIndex + 1);

    stdout.eraseln();
    displayEntity(activeIndex, viewIndex);
    stdout.movelnStart();
  }

  void moveUp() {
    if (activeIndex > 0) {
      --activeIndex;

      if ((viewIndex - topDisparity > 0) || (activeIndex - topDisparity < 0)) {
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
        displayEntity(i, vi);
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
        displayEntity(i, vi);
      }

      /// Now that the cursor is at the bottom,
      ///   Move the position up to the viewIndex.
      stdout.moveUp(viewLimit - viewIndex - 1);
      stdout.movelnStart();
    }
  }

  void moveDown() {
    if (activeIndex < children.length - 1) {
      ++activeIndex;

      if ((viewIndex + bottomDisparity < viewLimit - 1) || //
          (activeIndex + bottomDisparity > children.length - 1)) {
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
        displayEntity(i, vi);
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
        displayEntity(i, vi);
      }

      /// Now that the cursor is at the top,
      ///   Move the position down to the viewIndex.
      stdout.moveDown(viewIndex);
      stdout.movelnStart();
    }
  }

  void moveBack() {
    Directory previous = activeDirectory;
    activeDirectory = activeDirectory.parent;
    erase();
    hasFailed = false;
    update(previous: previous);
    draw();
  }

  void moveFront(Directory directory) {
    activeDirectory = directory;
    erase();
    hasFailed = false;
    update();
    draw();
  }

  void moveIntoActive() {
    if (children[activeIndex] case Directory directory) {
      moveFront(directory);
    }
    hasFailed = false;
  }

  try {
    stdout.push();
    stdout.hideCursor();

    update();

    FileSystemEntity chosenEntity;
    for (;;) {
      draw();

      loop:
      for (List<int> key in stdin.sync) {
        switch (key) {
          case <int>[0x03]:
            throw SignalInterruptionException();

          case <int>[0x0d]:
            // enter
            break loop;

          case <int>[0x1b, 0x5b, 0x41]:
            // up
            move(moveUp);

          case <int>[0x1b, 0x5b, 0x42]:
            // down
            move(moveDown);

          case <int>[0x1b, 0x5b, 0x43]:
            // right
            moveIntoActive();

          case <int>[0x1b, 0x5b, 0x44]:
            // left
            moveBack();
        }
      }

      erase();
      chosenEntity = children[activeIndex];

      if (guard?.call(chosenEntity) case False(:String failure)) {
        stdout.writeln("// $failure".brightRed());
        hasFailed = true;

        continue;
      } else {
        break;
      }
    }
    stdout.write("+".color(accentColor));
    stdout.write(" $question ");

    if (displayFullPath) {
      stdout.writeln(chosenEntity.path.color(accentColor));
    } else {
      String separator = Platform.pathSeparator;
      String parentDirectory = chosenEntity.parent.compactPath;
      String name = chosenEntity.path.split(separator).last;

      StringBuffer buffer = StringBuffer()
        ..write(parentDirectory)
        ..write(separator)
        ..write(name);

      stdout.writeln(buffer.toString().color(accentColor));
    }

    return Success<FileSystemEntity>(chosenEntity);
  } on SignalInterruptionException {
    erase();
    stdout.write("!".brightRed());
    stdout.write(" $question ");
    stdout.writeln("^C".brightBlack());

    return const Failure<FileSystemEntity>("^C");
  } finally {
    stdout.pop();
  }
}

Option<File> filePrompt(
  String question, {
  Directory? start,
  Guard<File>? guard,
  String? hint,
  bool displayFullPath = false,
  Color accentColor = FileSystemEntityPromptDefaults.accentColor,
}) =>
    fileSystemEntityPrompt(
      question,
      start: start,
      guard: Guard<FSE>.unit((FSE entity) => entity is File, "Must be a file.")
          .map((Guard<FSE> type) => guard != null ? type & guard : type),
      hint: hint,
      displayFullPath: displayFullPath,
      accentColor: accentColor,
    ).map((FSE value) => value as File);

Option<Directory> directoryPrompt(
  String question, {
  Directory? start,
  Guard<Directory>? guard,
  String? hint,
  bool displayFullPath = false,
  Color accentColor = FileSystemEntityPromptDefaults.accentColor,
}) =>
    fileSystemEntityPrompt(
      question,
      start: start,
      guard: Guard<FSE>.unit(
        (FSE entity) => entity is Directory,
        "Must be a directory.",
      ) //
          .map((Guard<FSE> type) => guard != null ? type & guard : type),
      hint: hint,
      displayFullPath: displayFullPath,
      accentColor: accentColor,
    ).map((FSE value) => value as Directory);

Option<Link> linkPrompt(
  String question, {
  Directory? start,
  Guard<Link>? guard,
  String? hint,
  bool displayFullPath = false,
  Color accentColor = FileSystemEntityPromptDefaults.accentColor,
}) =>
    fileSystemEntityPrompt(
      question,
      start: start,
      guard: Guard<FSE>.unit(
        (FSE entity) => entity is Directory,
        "Must be a directory.",
      ) //
          .map((Guard<FSE> type) => guard != null ? type & guard : type),
      hint: hint,
      displayFullPath: displayFullPath,
      accentColor: accentColor,
    ).map((FSE value) => value as Link);

extension PromptFileSystemEntityExtension on BasePrompt {
  Option<FileSystemEntity> fileSystemEntity(
    String question, {
    Directory? start,
    Guard<FileSystemEntity>? guard,
    String? hint,
    bool displayFullPath = false,
    Color accentColor = FileSystemEntityPromptDefaults.accentColor,
  }) =>
      fileSystemEntityPrompt(
        question,
        start: start,
        guard: guard,
        hint: hint,
        displayFullPath: displayFullPath,
        accentColor: accentColor,
      );

  Option<Directory> directory(
    String question, {
    Directory? start,
    Guard<Directory>? guard,
    String? hint,
    bool displayFullPath = false,
    Color accentColor = FileSystemEntityPromptDefaults.accentColor,
  }) =>
      directoryPrompt(
        question,
        start: start,
        guard: guard,
        hint: hint,
        displayFullPath: displayFullPath,
        accentColor: accentColor,
      );

  Option<File> file(
    String question, {
    Directory? start,
    Guard<File>? guard,
    String? hint,
    bool displayFullPath = false,
    Color accentColor = FileSystemEntityPromptDefaults.accentColor,
  }) =>
      filePrompt(
        question,
        start: start,
        guard: guard,
        hint: hint,
        displayFullPath: displayFullPath,
        accentColor: accentColor,
      );

  Option<Link> link(
    String question, {
    Directory? start,
    Guard<Link>? guard,
    String? hint,
    bool displayFullPath = false,
    Color accentColor = FileSystemEntityPromptDefaults.accentColor,
  }) =>
      linkPrompt(
        question,
        start: start,
        guard: guard,
        hint: hint,
        displayFullPath: displayFullPath,
        accentColor: accentColor,
      );
}
