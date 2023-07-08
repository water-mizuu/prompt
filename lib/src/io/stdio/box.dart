import "dart:math" as math;

import "package:prompt/src/extensions.dart";
import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/stdio/block/stdout/context.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";

extension StdoutBoxExtension on WrappedStdout {
  /// Returns a boxed version of the value, wrapping the value to the [maxColumns]
  ///   or the terminal width.
  String boxify(
    String value, {
    String title = "",
    int? maxColumns,
    Color? textColor,
    Color? color,
  }) {
    if (value.replaceAll("\t", "    ") case String value) {
      // ─ │ ┐ ┘ ┌ └ ├ ┤ ┬ ┴ ┼
      const int boxBorder = 4;
      bool enableColor = textColor != null || color != null;

      StringBuffer buffer = StringBuffer();
      int boundaryColumns = maxColumns ?? terminalColumns;
      int columns = <String>[if (title.isNotEmpty) " $title ", ...value.lines]
          .map((String line) => line.visibleLength + boxBorder) //
          .fold(0, math.max)
          .map((int v) => math.min(v, boundaryColumns));

      int writableColumns = columns - boxBorder;

      String topDisplay = title.isEmpty
          ? "─" * writableColumns
          : title
              .ellipsisVisible(writableColumns - 2)
              .map((String title) => title.isEmpty ? "" : " $title ") //
              .padVisibleRight(writableColumns, "─");

      String topBar = "┌─$topDisplay─┐" //
          .map((String line) => enableColor ? line.color(color ?? Color.reset) : line);

      String content = value
          .wrapVisible(writableColumns) //
          .split("\n")
          .map((String line) => line.padVisibleRight(writableColumns))
          .map(
            (String line) => <String>[
              if (enableColor) "│".color(color ?? Color.reset) else "│",
              if (enableColor) line.color(color ?? Color.reset) else line,
              if (enableColor) "│".color(color ?? Color.reset) else "│",
            ].join(" "),
          )
          .join("\n");
      String bottomBar = "└─${"".padVisibleRight(writableColumns, "─")}─┘"
          .map((String line) => enableColor ? line.color(color ?? Color.reset) : line);

      buffer
        ..writeln(topBar)
        ..writeln(content)
        ..write(bottomBar);

      return buffer.toString();
    }
  }

  void box(
    Object? value, {
    String title = "",
    Color textColor = Color.reset,
    Color color = Color.reset,
  }) {
    context(() {
      String display = boxify(
        value.toString(),
        title: title,
        maxColumns: terminalColumns,
        textColor: textColor,
        color: color,
      );
      writeln(display);
    });
  }
}

extension StdoutBoxShortcutExtension on void Function(Object? value, {String title}) {
  void success(Object? value, {String title = "Success"}) {
    stdout.box(
      value,
      title: title,
      color: Color.brightGreen,
      textColor: Color.green,
    );
  }

  void failure(Object? value, {String title = "Failure"}) {
    stdout.box(
      value,
      title: title,
      color: Color.brightRed,
      textColor: Color.red,
    );
  }

  void log(Object? value, {String title = "Log"}) {
    stdout.box(
      value,
      title: title,
      color: Color.brightBlue,
      textColor: Color.blue,
    );
  }
}
