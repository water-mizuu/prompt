// ignore_for_file: use_late_for_private_fields_and_variables

import "dart:ffi";
import "dart:io";

import "package:prompt/src/io/ffi/ffi_light.dart";
import "package:prompt/src/io/ffi/win32_light.dart";
import "package:termlib/termlib.dart" as og;

class TermLib extends og.TermLib {
  TermLib()
      : _isRaw = false,
        super() {
    if (Platform.isWindows) {
      _inputHandle = GetStdHandle(STD_INPUT_HANDLE);
      // _outputHandle = GetStdHandle(STD_OUTPUT_HANDLE);
    }
  }

  int setWindowHeight(int height) {
    stdout.write("\x1b[8;$height;t");
    return height;
  }

  int setWindowWidth(int width) {
    stdout.write("\x1b[8;;${width}t");
    return width;
  }

  int? _inputHandle;
  // int? _outputHandle;
  int? _previousFlags;
  bool _isRaw;
  bool get isRawModeEnabled => _isRaw;

  @override
  void enableRawMode() {
    _isRaw = true;

    if (Platform.isWindows) {
      Pointer<Uint32> pointer = calloc<Uint32>();
      GetConsoleMode(_inputHandle!, pointer);
      _previousFlags = pointer.value;
      calloc.free(pointer);
    }

    super.enableRawMode();
  }

  @override
  void disableRawMode() {
    super.disableRawMode();

    if (Platform.isWindows) {
      SetConsoleMode(_inputHandle!, _previousFlags!);
    }
  }

  void scrollDown(int n) {
    og.TermLib().scrollDown(n);
  }

  void scrollUp(int n) {
    og.TermLib().scrollUp(n);
  }
}
