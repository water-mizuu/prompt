// ignore_for_file: deprecated_member_use

// TODO: Do something about this.

import "dart:async";
import "dart:isolate";

import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/stdio/block/stdout/hidden_cursor.dart";
import "package:prompt/src/io/stdio/context.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";

Future<T> process<T>(
  String message,
  FutureOr<T> Function() action, {
  Duration refreshDelay = const Duration(milliseconds: 10),
}) async {
  const List<String> dot = <String>[
    "   ",
    ".  ",
    ".. ",
    "...",
  ];

  Completer<T> completer = Completer<T>();

  DateTime start = DateTime.now();
  unawaited(
    Isolate.run(action).then((T value) {
      completer.complete(value);
    }).catchError((Object error) {
      completer.completeError(error);
    }),
  );

  stdout.writeln(message);

  try {
    stdout.push();
    stdout.hideCursor();
    int i = 0;
    while (!completer.isCompleted) {
      stdout.eraseln();
      stdout.write("Loading${dot[(i ~/ 20) % 4]}");
      stdout.write(" (${DateTime.now().difference(start).inMilliseconds / 1000}s) ".brightBlack());
      i = i + 1;
      await Future<void>.delayed(refreshDelay);
    }
  } finally {
    stdout.pop();
  }

  try {
    T value = await completer.future;
    stdout.eraseln();
    stdout.writeln("Completed");

    return value;
  } on Object catch (e) {
    stdout.eraseln();
    stdout.writeln("Process failed: $e");

    rethrow;
  }
}
