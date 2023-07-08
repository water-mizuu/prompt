import "package:prompt/src/io/stdio/context.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";

extension ContextStdoutExtension on WrappedStdout {
  /// Runs a block of code with a new standard out context, automatically popped on exit.
  void context(void Function() callback) {
    try {
      stdout.push();
      callback();
    } finally {
      stdout.pop();
    }
  }

  Iterable<void> get contextBlock sync* {
    try {
      stdout.push();
      yield null;
      return;
    } finally {
      stdout.pop();
    }
  }
}

extension ContextStdoutHelperExtension on void Function(void Function() callback) {
  Future<void> async(Future<void> Function() callback) async {
    try {
      stdout.push();
      await callback();
    } finally {
      stdout.pop();
    }
  }

  T returns<T>(T Function() callback) {
    try {
      stdout.push();
      return callback();
    } finally {
      stdout.pop();
    }
  }
}
