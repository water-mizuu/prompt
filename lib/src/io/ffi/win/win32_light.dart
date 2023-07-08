/// A manually tree shaken part of a gigantic library (win32)
library;

// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names

import "dart:ffi";

const int STD_INPUT_HANDLE = -10;
const int STD_OUTPUT_HANDLE = -11;
const int STD_ERROR_HANDLE = -12;
const int ENABLE_ECHO_INPUT = 0x0004;
const int ENABLE_EXTENDED_FLAGS = 0x0080;
const int ENABLE_INSERT_MODE = 0x0020;
const int ENABLE_LINE_INPUT = 0x0002;
const int ENABLE_MOUSE_INPUT = 0x0010;
const int ENABLE_PROCESSED_INPUT = 0x0001;
const int ENABLE_QUICK_EDIT_MODE = 0x0040;
const int ENABLE_WINDOW_INPUT = 0x0008;
const int ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200;

final DynamicLibrary _kernel32 = DynamicLibrary.open("kernel32.dll");

/// Contains information about the console cursor.
///
/// {@category Struct}
base class CONSOLE_CURSOR_INFO extends Struct {
  @Uint32()
  external int dwSize;

  @Int32()
  external int bVisible;
}

/// Defines the coordinates of a character cell in a console screen buffer.
/// The origin of the coordinate system (0,0) is at the top, left cell of
/// the buffer.
///
/// {@category Struct}
base class COORD extends Struct {
  @Int16()
  external int X;

  @Int16()
  external int Y;
}

/// Retrieves a handle to the specified standard device (standard input,
/// standard output, or standard error).
///
/// ```c
/// HANDLE GetStdHandle(
///   _In_ DWORD nStdHandle
/// );
/// ```
/// {@category kernel32}
int GetStdHandle(int nStdHandle) => _GetStdHandle(nStdHandle);

final int Function(int nStdHandle) _GetStdHandle = _kernel32.lookupFunction<
    IntPtr Function(Uint32 nStdHandle), int Function(int nStdHandle)>(
  "GetStdHandle",
);

/// Sets the size and visibility of the cursor for the specified console
/// screen buffer.
///
/// ```c
/// BOOL SetConsoleCursorInfo(
///   _In_       HANDLE              hConsoleOutput,
///   _In_ const CONSOLE_CURSOR_INFO *lpConsoleCursorInfo
/// );
/// ```
/// {@category kernel32}
int SetConsoleCursorInfo(
  int hConsoleOutput,
  Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo,
) =>
    _SetConsoleCursorInfo(hConsoleOutput, lpConsoleCursorInfo);

final int Function(
  int hConsoleOutput,
  Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo,
) _SetConsoleCursorInfo = _kernel32.lookupFunction<
    Int32 Function(
      IntPtr hConsoleOutput,
      Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo,
    ),
    int Function(
      int hConsoleOutput,
      Pointer<CONSOLE_CURSOR_INFO> lpConsoleCursorInfo,
    )>("SetConsoleCursorInfo");

/// Sets the input mode of a console's input buffer or the output mode of a
/// console screen buffer.
///
/// ```c
/// BOOL SetConsoleMode(
///   _In_ HANDLE hConsoleHandle,
///   _In_ DWORD  dwMode
/// );
/// ```
/// {@category kernel32}
int SetConsoleMode(int hConsoleHandle, int dwMode) =>
    _SetConsoleMode(hConsoleHandle, dwMode);

final int Function(int hConsoleHandle, int dwMode) _SetConsoleMode =
    _kernel32.lookupFunction<
        Int32 Function(IntPtr hConsoleHandle, Uint32 dwMode),
        int Function(int hConsoleHandle, int dwMode)>("SetConsoleMode");

/// Retrieves the current input mode of a console's input buffer or the
/// current output mode of a console screen buffer.
///
/// ```c
/// BOOL GetConsoleMode(
///   _In_  HANDLE  hConsoleHandle,
///   _Out_ LPDWORD lpMode
/// );
/// ```
/// {@category kernel32}
int GetConsoleMode(int hConsoleHandle, Pointer<Uint32> lpMode) =>
    _GetConsoleMode(hConsoleHandle, lpMode);

final int Function(int hConsoleHandle, Pointer<Uint32> lpMode) _GetConsoleMode =
    _kernel32.lookupFunction<
        Int32 Function(IntPtr hConsoleHandle, Pointer<Uint32> lpMode),
        int Function(
          int hConsoleHandle,
          Pointer<Uint32> lpMode,
        )>("GetConsoleMode");

/// Sets the cursor position in the specified console screen buffer.
///
/// ```c
/// BOOL SetConsoleCursorPosition(
///   _In_ HANDLE hConsoleOutput,
///   _In_ COORD  dwCursorPosition
/// );
/// ```
/// {@category kernel32}
int SetConsoleCursorPosition(int hConsoleOutput, COORD dwCursorPosition) =>
    _SetConsoleCursorPosition(hConsoleOutput, dwCursorPosition);

final int Function(int hConsoleOutput, COORD dwCursorPosition)
    _SetConsoleCursorPosition = _kernel32.lookupFunction<
        Int32 Function(IntPtr hConsoleOutput, COORD dwCursorPosition),
        int Function(
          int hConsoleOutput,
          COORD dwCursorPosition,
        )>("SetConsoleCursorPosition");

/// Writes a character to the console screen buffer a specified number of
/// times, beginning at the specified coordinates.
///
/// ```c
/// BOOL FillConsoleOutputCharacterW(
///   _In_  HANDLE  hConsoleOutput,
///   _In_  WCHAR   cCharacter,
///   _In_  DWORD   nLength,
///   _In_  COORD   dwWriteCoord,
///   _Out_ LPDWORD lpNumberOfCharsWritten
/// );
/// ```
/// {@category kernel32}
int FillConsoleOutputCharacter(
  int hConsoleOutput,
  int cCharacter,
  int nLength,
  COORD dwWriteCoord,
  Pointer<Uint32> lpNumberOfCharsWritten,
) =>
    _FillConsoleOutputCharacter(
      hConsoleOutput,
      cCharacter,
      nLength,
      dwWriteCoord,
      lpNumberOfCharsWritten,
    );

final int Function(
  int hConsoleOutput,
  int cCharacter,
  int nLength,
  COORD dwWriteCoord,
  Pointer<Uint32> lpNumberOfCharsWritten,
) _FillConsoleOutputCharacter = _kernel32.lookupFunction<
    Int32 Function(
      IntPtr hConsoleOutput,
      Uint16 cCharacter,
      Uint32 nLength,
      COORD dwWriteCoord,
      Pointer<Uint32> lpNumberOfCharsWritten,
    ),
    int Function(
      int hConsoleOutput,
      int cCharacter,
      int nLength,
      COORD dwWriteCoord,
      Pointer<Uint32> lpNumberOfCharsWritten,
    )>("FillConsoleOutputCharacterW");

/// Sets the character attributes for a specified number of character cells,
/// beginning at the specified coordinates in a screen buffer.
///
/// ```c
/// BOOL FillConsoleOutputAttribute(
///   _In_  HANDLE  hConsoleOutput,
///   _In_  WORD    wAttribute,
///   _In_  DWORD   nLength,
///   _In_  COORD   dwWriteCoord,
///   _Out_ LPDWORD lpNumberOfAttrsWritten
/// );
/// ```
/// {@category kernel32}
int FillConsoleOutputAttribute(
  int hConsoleOutput,
  int wAttribute,
  int nLength,
  COORD dwWriteCoord,
  Pointer<Uint32> lpNumberOfAttrsWritten,
) =>
    _FillConsoleOutputAttribute(
      hConsoleOutput,
      wAttribute,
      nLength,
      dwWriteCoord,
      lpNumberOfAttrsWritten,
    );

final int Function(
  int hConsoleOutput,
  int wAttribute,
  int nLength,
  COORD dwWriteCoord,
  Pointer<Uint32> lpNumberOfAttrsWritten,
) _FillConsoleOutputAttribute = _kernel32.lookupFunction<
    Int32 Function(
      IntPtr hConsoleOutput,
      Uint16 wAttribute,
      Uint32 nLength,
      COORD dwWriteCoord,
      Pointer<Uint32> lpNumberOfAttrsWritten,
    ),
    int Function(
      int hConsoleOutput,
      int wAttribute,
      int nLength,
      COORD dwWriteCoord,
      Pointer<Uint32> lpNumberOfAttrsWritten,
    )>("FillConsoleOutputAttribute");

/// Defines the coordinates of the upper left and lower right corners of a
/// rectangle.
///
/// {@category Struct}
base class SMALL_RECT extends Struct {
  @Int16()
  external int Left;

  @Int16()
  external int Top;

  @Int16()
  external int Right;

  @Int16()
  external int Bottom;
}

/// Contains information about a console screen buffer.
///
/// {@category Struct}
base class CONSOLE_SCREEN_BUFFER_INFO extends Struct {
  external COORD dwSize;

  external COORD dwCursorPosition;

  @Uint16()
  external int wAttributes;

  external SMALL_RECT srWindow;

  external COORD dwMaximumWindowSize;
}

/// Retrieves information about the specified console screen buffer.
///
/// ```c
/// BOOL GetConsoleScreenBufferInfo(
///   _In_  HANDLE                      hConsoleOutput,
///   _Out_ PCONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo
/// );
/// ```
/// {@category kernel32}
int GetConsoleScreenBufferInfo(
  int hConsoleOutput,
  Pointer<CONSOLE_SCREEN_BUFFER_INFO> lpConsoleScreenBufferInfo,
) =>
    _GetConsoleScreenBufferInfo(hConsoleOutput, lpConsoleScreenBufferInfo);

final int Function(
  int hConsoleOutput,
  Pointer<CONSOLE_SCREEN_BUFFER_INFO> lpConsoleScreenBufferInfo,
) _GetConsoleScreenBufferInfo = _kernel32.lookupFunction<
    Int32 Function(
      IntPtr hConsoleOutput,
      Pointer<CONSOLE_SCREEN_BUFFER_INFO> lpConsoleScreenBufferInfo,
    ),
    int Function(
      int hConsoleOutput,
      Pointer<CONSOLE_SCREEN_BUFFER_INFO> lpConsoleScreenBufferInfo,
    )>("GetConsoleScreenBufferInfo");
