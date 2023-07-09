import "dart:collection";
import "dart:io" hide stdin, stdout;
import "dart:math" as math;

import "package:prompt/src/extensions.dart";
import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/exception.dart";
import "package:prompt/src/io/stdio/context.dart";
import "package:prompt/src/io/stdio/wrapper/stdin.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdin.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";
import "package:prompt/src/prompt/shared/view.dart";
import "package:prompt/src/result.dart";
import "package:prompt/src/types.dart";

abstract final class FileSystemEntityPromptDefaults {
  static const Color accentColor = Colors.brightBlue;
}

Result<FileSystemEntity> fileSystemEntityPrompt(
  String question, {
  Directory? start,
  Guard<FileSystemEntity>? guard,
  String? hint,
  Color accentColor = FileSystemEntityPromptDefaults.accentColor,
}) {
  start ??= Directory.current;

  int topDisparity = 2;
  int bottomDisparity = 2;
  Directory activeDirectory = start;

  Queue<int> indexHistory = Queue<int>()..addLast(0);
  bool hasFailed = false;

  late int activeIndex;
  late int viewIndex;
  late int viewStart;
  late int viewLimit;
  late List<FileSystemEntity> children;

  void displayEntity(int index, int viewIndex, {bool isActive = true}) {
    stdout.write("  ");

    if (isActive && activeIndex == index) {
      stdout.write("> ".brightBlue());
    } else {
      stdout.write("  ");
    }

    if (children[index] case FileSystemEntity entity) {
      if (entity is Directory) {
        stdout.write("${entity.name}/");
      } else {
        stdout.write(entity.name);
      }
    }
  }

  void erase() {
    int increment = hasFailed ? 1 : 0;

    stdout.moveUp(viewIndex + 1 + increment);
    stdout.eraselnDown(viewLimit + 1 + increment);
  }

  // ignore: no_leading_underscores_for_local_identifiers
  void update([int _activeIndex = 0]) {
    activeIndex = _activeIndex;
    children = <FileSystemEntity>[const GhostDirectory(".."), ...activeDirectory.listSync()] //
      ..sort(
        (FileSystemEntity a, FileSystemEntity b) => switch ((a, b)) {
          (GhostDirectory(), _) => -1,
          (_, GhostDirectory()) => 1,
          (Directory(), File()) => -1,
          (File(), Directory()) => 1,
          (FileSystemEntity(path: String leftPath), FileSystemEntity(path: String rightPath)) =>
            leftPath.compareTo(rightPath),
        },
      );

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

    stdout.push();
    stdout.foregroundColor = Colors.brightBlack;
    switch (children[activeIndex]) {
      case GhostDirectory _:
        stdout.write(activeDirectory.parent.path);
        stdout.write(Platform.pathSeparator);
      case FileSystemEntity _:
        stdout.write(activeDirectory.path);
        stdout.write(Platform.pathSeparator);
        stdout.write(children[activeIndex].name);
    }
    stdout.pop();
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
    activeDirectory = activeDirectory.parent;
    erase();
    update(indexHistory.removeLast());
    draw();
  }

  void moveFront(Directory directory) {
    indexHistory.addLast(activeIndex);
    activeDirectory = directory;
    erase();
    update();
    draw();
  }

  void moveIntoActive() {
    switch (children[activeIndex]) {
      case GhostDirectory _:
        moveBack();
      case Directory directory:
        moveFront(directory);
    }
    hasFailed = false;
  }

  try {
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
      if (guard case (GuardFunction<FileSystemEntity> function, String message)
          when !function(chosenEntity)) {
        stdout.writeln("// $message".brightRed());

        hasFailed = true;

        continue;
      } else {
        break;
      }
    }
    stdout.write("+".color(accentColor));
    stdout.write(" $question ");
    stdout.write(chosenEntity.path.color(accentColor));
    stdout.writeln();

    return Success<FileSystemEntity>(chosenEntity);
  } finally {}
}

Result<File> filePrompt(
  String question, {
  Directory? start,
  Guard<File>? guard,
  String? hint,
  Color accentColor = FileSystemEntityPromptDefaults.accentColor,
}) =>
    fileSystemEntityPrompt(
      question,
      start: start,
      guard: (
        (FileSystemEntity entity) => entity is File && (guard?.$1(entity) ?? true),
        guard?.$2 ?? "Must be a file."
      ),
      hint: hint,
      accentColor: accentColor,
    ).map((FileSystemEntity value) {
      print(value);
      return value as File;
    });

Result<Directory> directoryPrompt(
  String question, {
  Directory? start,
  Guard<Directory>? guard,
  String? hint,
  Color accentColor = FileSystemEntityPromptDefaults.accentColor,
}) =>
    fileSystemEntityPrompt(
      question,
      start: start,
      guard: (
        (FileSystemEntity entity) => entity is Directory && (guard?.$1(entity) ?? true),
        guard?.$2 ?? "Must be a file."
      ),
      hint: hint,
      accentColor: accentColor,
    ).map((FileSystemEntity value) => value as Directory);

final class GhostDirectory implements Directory {
  const GhostDirectory(this.path);

  @override
  final String path;

  @override
  Directory get absolute => this;

  @override
  Future<Directory> create({bool recursive = false}) {
    throw UnsupportedError("Cannot create a ghost directory.");
  }

  @override
  void createSync({bool recursive = false}) {
    throw UnsupportedError("Cannot create a ghost directory.");
  }

  @override
  Future<Directory> createTemp([String? prefix]) {
    throw UnsupportedError("Cannot create a ghost directory.");
  }

  @override
  Directory createTempSync([String? prefix]) {
    throw UnsupportedError("Cannot create a ghost directory.");
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) {
    throw UnsupportedError("Cannot delete a ghost directory.");
  }

  @override
  void deleteSync({bool recursive = false}) {
    throw UnsupportedError("Cannot delete a ghost directory.");
  }

  @override
  Future<bool> exists() async => false;

  @override
  bool existsSync() => false;

  @override
  bool get isAbsolute => false;

  @override
  Stream<FileSystemEntity> list({bool recursive = false, bool followLinks = true}) async* {}

  @override
  List<FileSystemEntity> listSync({bool recursive = false, bool followLinks = true}) =>
      <FileSystemEntity>[];

  @override
  Directory get parent {
    throw UnsupportedError("Cannot get the parent of a ghost directory.");
  }

  @override
  Future<Directory> rename(String newPath) {
    throw UnsupportedError("Cannot rename a ghost directory.");
  }

  @override
  Directory renameSync(String newPath) {
    throw UnsupportedError("Cannot rename a ghost directory.");
  }

  @override
  Future<String> resolveSymbolicLinks() {
    throw UnsupportedError("Cannot resolve a ghost directory.");
  }

  @override
  String resolveSymbolicLinksSync() {
    throw UnsupportedError("Cannot resolve a ghost directory.");
  }

  @override
  Future<FileStat> stat() {
    throw UnsupportedError("Cannot find stat of ghost directory.");
  }

  @override
  FileStat statSync() {
    throw UnsupportedError("Cannot find stat of ghost directory.");
  }

  @override
  Uri get uri => Uri(path: path);

  @override
  Stream<FileSystemEvent> watch({int events = FileSystemEvent.all, bool recursive = false}) {
    throw UnsupportedError("Cannot watch a ghost directory.");
  }
}
