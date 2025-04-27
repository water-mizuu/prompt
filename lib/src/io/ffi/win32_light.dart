/// A manually tree shaken part of a gigantic library (win32)
library;

// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names

import "dart:ffi";

const int STD_INPUT_HANDLE = -10;
const int STD_OUTPUT_HANDLE = -11;

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
