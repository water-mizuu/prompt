// ignore_for_file: prefer_void_to_null

import "package:prompt/src/io/stdio/wrapper/stdin.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdin.dart";

extension RawBlockExtension on WrappedStdin {
  /// A code block that manages turning rawMode on and off automatically.
  void raw(void Function() callback, {Never? rawSignature}) {
    try {
      enableRawMode();
      callback();
    } finally {
      disableRawMode();
    }
  }

  /// A code block that manages turning rawMode on and off automatically.
  Iterable<T Function<T>(T value)> get rawBlock sync* {
    try {
      enableRawMode();
      yield <T>(T object) {
        disableRawMode();
        return object;
      };
    } finally {
      disableRawMode();
    }
  }
}

extension RawBlockHelperExtension on void Function(
  void Function() callback, {
  Never? rawSignature,
}) {
  /// Convenience method that allows you to run a block of code that returns a value with raw mode enabled.
  T returns<T>(T Function() callback, {Never? rawSignature}) {
    try {
      stdin.enableRawMode();
      return callback();
    } finally {
      stdin.disableRawMode();
    }
  }
}
