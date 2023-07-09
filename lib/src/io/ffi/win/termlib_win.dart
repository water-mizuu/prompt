// termlib-win.dart
//
// Win32-dependent library for interrogating and manipulating the console.
//
// This class provides raw wrappers for the underlying terminal system calls
// that are not available through ANSI mode control sequences, and is not
// designed to be called directly. Package consumers should normally use the
// `Console` class to call these methods.

// ignore_for_file: constant_identifier_names

import "dart:ffi";

import "package:prompt/src/io/ffi/ffi_light.dart";
import "package:prompt/src/io/ffi/termlib.dart";
import "package:prompt/src/io/ffi/win/win32_light.dart";

class TermLibWindows implements TermLib {
  TermLibWindows()
      : _outputHandle = GetStdHandle(STD_OUTPUT_HANDLE),
        _inputHandle = GetStdHandle(STD_INPUT_HANDLE),
        _isRaw = false;

  static const int _savedFlags = 503;

  @override
  bool get isRawModeEnabled => _isRaw;

  bool _isRaw;

  late int _previousFlags;
  final int _inputHandle;
  final int _outputHandle;

  @override
  int setWindowHeight(int height) {
    throw UnsupportedError(
      "Setting window height is not supported for Windows terminals.",
    );
  }

  @override
  int setWindowWidth(int width) {
    throw UnsupportedError(
      "Setting window width is not supported for Windows terminals.",
    );
  }

  void saveConsoleMode() {
    Pointer<Uint32> pointer = calloc<Uint32>();
    GetConsoleMode(_inputHandle, pointer);
    _previousFlags = pointer.value;
    calloc.free(pointer);
  }

  @override
  void enableRawMode() {
    saveConsoleMode();
    _isRaw = true;

    const int dwMode = (~ENABLE_ECHO_INPUT) & //
        (~ENABLE_PROCESSED_INPUT) &
        (~ENABLE_LINE_INPUT) &
        (~ENABLE_WINDOW_INPUT);
    SetConsoleMode(_inputHandle, dwMode);
  }

  @override
  void disableRawMode() {
    _isRaw = false;

    SetConsoleMode(_inputHandle, _previousFlags);

    // const int dwMode = ENABLE_ECHO_INPUT &
    //     ENABLE_EXTENDED_FLAGS &
    //     ENABLE_INSERT_MODE &
    //     ENABLE_LINE_INPUT &
    //     ENABLE_MOUSE_INPUT &
    //     ENABLE_PROCESSED_INPUT &
    //     ENABLE_QUICK_EDIT_MODE &
    //     ENABLE_VIRTUAL_TERMINAL_INPUT;
    // SetConsoleMode(_inputHandle, dwMode);

    SetConsoleMode(_inputHandle, _savedFlags);
  }

  void hideCursor() {
    Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo = calloc<CONSOLE_CURSOR_INFO>()
      ..ref.bVisible = 0;
    try {
      SetConsoleCursorInfo(_outputHandle, lpConsoleCursorInfo);
    } finally {
      calloc.free(lpConsoleCursorInfo);
    }
  }

  void showCursor() {
    Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo = calloc<CONSOLE_CURSOR_INFO>()
      ..ref.bVisible = 1;
    try {
      SetConsoleCursorInfo(_outputHandle, lpConsoleCursorInfo);
    } finally {
      calloc.free(lpConsoleCursorInfo);
    }
  }

  void clearScreen() {
    Pointer<CONSOLE_SCREEN_BUFFER_INFO> pBufferInfo = calloc<CONSOLE_SCREEN_BUFFER_INFO>();
    Pointer<Uint32> pCharsWritten = calloc<Uint32>();
    Pointer<COORD> origin = calloc<COORD>();
    try {
      CONSOLE_SCREEN_BUFFER_INFO bufferInfo = pBufferInfo.ref;
      GetConsoleScreenBufferInfo(_outputHandle, pBufferInfo);

      int consoleSize = bufferInfo.dwSize.X * bufferInfo.dwSize.Y;

      FillConsoleOutputCharacter(
        _outputHandle,
        " ".codeUnitAt(0),
        consoleSize,
        origin.ref,
        pCharsWritten,
      );
      GetConsoleScreenBufferInfo(_outputHandle, pBufferInfo);
      FillConsoleOutputAttribute(
        _outputHandle,
        bufferInfo.wAttributes,
        consoleSize,
        origin.ref,
        pCharsWritten,
      );
      SetConsoleCursorPosition(_outputHandle, origin.ref);
    } finally {
      calloc
        ..free(origin)
        ..free(pCharsWritten)
        ..free(pBufferInfo);
    }
  }

  void setCursorPosition(int x, int y) {
    Pointer<COORD> coord = calloc<COORD>()
      ..ref.X = x
      ..ref.Y = y;
    try {
      SetConsoleCursorPosition(_outputHandle, coord.ref);
    } finally {
      calloc.free(coord);
    }
  }
}
