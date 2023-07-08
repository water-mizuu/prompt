// termlib.dart
//
// Platform-independent library for interrogating and manipulating the console.
//
// This class provides raw wrappers for the underlying terminal system calls
// that are not available through ANSI mode control sequences, and is not
// designed to be called directly. Package consumers should normally use the
// `Console` class to call these methods.

import "dart:io";

import "package:prompt/src/io/ffi/unix/termlib_unix.dart";
import "package:prompt/src/io/ffi/win/termlib_win.dart";

abstract class TermLib {
  factory TermLib() {
    if (Platform.isWindows) {
      return TermLibWindows();
    } else {
      return TermLibUnix();
    }
  }
  int setWindowHeight(int height);
  int setWindowWidth(int width);

  bool get isRawModeEnabled;
  void enableRawMode();
  void disableRawMode();
}
