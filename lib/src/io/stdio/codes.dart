import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";

extension StdoutAnsiCodeExtension on WrappedStdout {
  // Credits: https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797#file-ansi-md

  // ## Sequences

  // - `ESC` - sequence starting with `ESC` (`\x1B`)
  // - `CSI` - Control Sequence Introducer: sequence starting with `ESC [` or CSI (`\x9B`)
  // - `DCS` - Device Control String: sequence starting with `ESC P` or DCS (`\x90`)
  // - `OSC` - Operating System Command: sequence starting with `ESC ]` or OSC (`\x9D`)

  String get esc => "\u{1b}";
  String get csi => "\u{9b}";
  String get dcs => "\u{90}";
  String get osc => "\u{9d}";

  // ## Erase Functions

  // | ESC Code Sequence | Description                               |
  // | :---------------- | :---------------------------------------- |
  // | `ESC[J`           | erase in display (same as ESC\[0J)        |
  // | `ESC[0J`          | erase from cursor until end of screen     |
  // | `ESC[1J`          | erase from cursor to beginning of screen  |
  // | `ESC[2J`          | erase entire screen                       |
  // | `ESC[3J`          | erase saved lines                         |
  // | `ESC[K`           | erase in line (same as ESC\[0K)           |
  // | `ESC[0K`          | erase from cursor to end of line          |
  // | `ESC[1K`          | erase start of line to the cursor         |
  // | `ESC[2K`          | erase the entire line                     |
  String get eraseCode => "\u{1b}\u{63}\u{1b}\u{5b}\u{33}\u{4a}";
  String get eraseLineFromCursorCode => "0K";
  String get eraseLineToCursorCode => "1K";
  String get eraseLineCode => "2K";

  String get bellCode => "\u{7}";
  String get escapeCode => "$esc[";
  String get hideCursorCode => "?25l";
  String get showCursorCode => "?25h";

  // ## Cursor Controls

  // | ESC Code Sequence               | Description                                            |
  // | :------------------------------ | :----------------------------------------------------- |
  // | `ESC[H`                         | moves cursor to home position (0, 0)                   |
  // | `ESC[{l};{c}H` / `ESC[{l};{c}f` | moves cursor to line #, column #                       |
  // | `ESC[#A`                        | moves cursor up # lines                                |
  // | `ESC[#B`                        | moves cursor down # lines                              |
  // | `ESC[#C`                        | moves cursor right # columns                           |
  // | `ESC[#D`                        | moves cursor left # columns                            |
  // | `ESC[#E`                        | moves cursor to beginning of next line, # lines down   |
  // | `ESC[#F`                        | moves cursor to beginning of previous line, # lines up |
  // | `ESC[#G`                        | moves cursor to column #                               |
  // | `ESC[6n`                        | request cursor position (reports as `ESC[#;#R`)        |
  // | `ESC M`                         | moves cursor one line up, scrolling if needed          |
  // | `ESC 7`                         | save cursor position (DEC)                             |
  // | `ESC 8`                         | restores the cursor to the last saved position (DEC)   |
  // | `ESC[s`                         | save cursor position (SCO)                             |
  // | `ESC[u`                         | restores the cursor to the last saved position (SCO)   |

  String get moveToStartCode => "H";
  String get moveUpCode => "A";
  String get moveDownCode => "B";
  String get moveRightCode => "C";
  String get moveLeftCode => "D";
  String get moveDownLineCode => "E";
  String get moveUpLineCode => "F";
  String get moveToColumnCode => "G";

  // const String ansiDeviceStatusReportCursorPosition = "\x1b[6n";
  // const String ansiEraseInDisplayAll = "\x1b[2J";
  // const String ansiEraseInLineAll = "\x1b[2K";
  // const String ansiEraseCursorToEnd = "\x1b[K";

  // const String ansiHideCursor = "\x1b[?25l";
  // const String ansiShowCursor = "\x1b[?25h";

  // const String ansiCursorLeft = "\x1b[D";
  // const String ansiCursorRight = "\x1b[C";
  // const String ansiCursorUp = "\x1b[A";
  // const String ansiCursorDown = "\x1b[B";

  String get foregroundCode => "38";
  String get backgroundCode => "48";
  String get resetForegroundCode => "39m";
  String get resetBackgroundCode => "49m";
}
