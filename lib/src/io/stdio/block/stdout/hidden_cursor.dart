// ignore_for_file: prefer_void_to_null

import "package:prompt/src/io/stdio/codes.dart";
import "package:prompt/src/io/stdio/context.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";

extension HiddenCursorExtension on WrappedStdout {
  void hideCursor() {
    currentContext.isCursorHidden = true;
    writeEscaped(hideCursorCode);
  }

  void showCursor() {
    currentContext.isCursorHidden = false;
    writeEscaped(showCursorCode);
  }

  void toggleCursor() => (currentContext.isCursorHidden = !currentContext.isCursorHidden) //
      ? showCursor()
      : hideCursor();

  /// Convenience method that allows you to run a block of code with the cursor hidden.
  void hiddenCursor(void Function() callback, {Never? hiddenCursorSignature}) {
    try {
      push();
      hideCursor();
      callback();
    } finally {
      showCursor();
      pop();
    }
  }
}

extension HiddenCursorHelperExtension on void Function(void Function() callback, {Never? hiddenCursorSignature}) {
  /// Convenience method that allows you to run a block of code that returns a value with the cursor hidden.
  T returns<T>(T Function() callback, {Never? hiddenCursorSignature}) {
    try {
      stdout.push();
      stdout.hideCursor();
      return callback();
    } finally {
      stdout.showCursor();
      stdout.pop();
    }
  }
}
