// ignore_for_file: prefer_void_to_null

import "package:prompt/src/io/ffi/termlib.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdin.dart";

final TermLib _lib = TermLib();

extension StdinExtension on WrappedStdin {
  int get cr => 0xd;
  int get lf => 0xa;

  void enableRawMode() => _lib.enableRawMode();
  void disableRawMode() => _lib.disableRawMode();

  bool get rawMode => _lib.isRawModeEnabled;
  set rawMode(bool value) => value ? enableRawMode() : disableRawMode();

  /// Synchronously iterates over the input stream.
  ///
  /// Escape codes such as SIGINT (Ctrl+C; code `[0x03]`) must
  /// be handled by the receiver.
  Iterable<List<int>> get sync sync* {
    while (true) {
      yield readSync();
    }
  }

  /// Synchronously iterates over the input stream.
  ///
  /// Escape code SIGINT `0x03` cuts the [Iterable].
  Iterable<List<int>> get syncInterrupt sync* {
    while (true) {
      List<int> read = readSync();
      if (read case <int>[0x03]) {
        return;
      }
      yield read;
    }
  }

  /// Reads a key sequence from the standard input synchronously.
  List<int> readSync() {
    List<int> sequence = <int>[];

    try {
      stdin.enableRawMode();

      int charCode = stdin.readByteSync();
      if (charCode >= 0) {
        sequence.add(charCode);
      }

      switch (sequence) {
        case <int>[0x1b]:
          charCode = stdin.readByteSync();
          if (charCode >= 0) {
            sequence.add(charCode);
          }
      }

      switch (sequence) {
        case <int>[_, 0x5b]:
          charCode = stdin.readByteSync();
          if (charCode >= 0) {
            sequence.add(charCode);
          }
        case <int>[_, 0x4f]:
          charCode = stdin.readByteSync();
          if (charCode >= 0) {
            sequence.add(charCode);
          }
      }

      switch (sequence) {
        case <int>[_, _, 0x31]:
          for (int i = 0; i < 3; ++i) {
            charCode = stdin.readByteSync();
            if (charCode >= 0) {
              sequence.add(charCode);
            }
          }
        case <int>[_, _, 0x32]:
          for (; charCode != 0x7e;) {
            charCode = stdin.readByteSync();
            if (charCode >= 0) {
              sequence.add(charCode);
            }
          }
        case <int>[_, _, >= 0x32 && <= 0x39]:
          charCode = stdin.readByteSync();
          if (charCode >= 0) {
            sequence.add(charCode);
          }
      }
      return sequence;
    } finally {
      stdin.disableRawMode();
    }
  }
}
