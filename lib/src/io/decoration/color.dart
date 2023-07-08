import "package:prompt/src/io/decoration/decoration.dart";
import "package:prompt/src/io/stdio/codes.dart";
import "package:prompt/src/io/stdio/context.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";

abstract base class Color implements TextDecoration {
  const Color();
  const factory Color.rgb({required int r, required int g, required int b}) = RgbColor;
  const factory Color.ansi({required int code}) = AnsiColor;

  static const Color black = Color.ansi(code: 30);
  static const Color red = Color.ansi(code: 31);
  static const Color green = Color.ansi(code: 32);
  static const Color yellow = Color.ansi(code: 33);
  static const Color blue = Color.ansi(code: 34);
  static const Color magenta = Color.ansi(code: 35);
  static const Color cyan = Color.ansi(code: 36);
  static const Color white = Color.ansi(code: 37);
  static const Color reset = Color.ansi(code: 39);

  static const Color brightBlack = Color.ansi(code: 90);
  static const Color brightRed = Color.ansi(code: 91);
  static const Color brightGreen = Color.ansi(code: 92);
  static const Color brightYellow = Color.ansi(code: 93);
  static const Color brightBlue = Color.ansi(code: 94);
  static const Color brightMagenta = Color.ansi(code: 95);
  static const Color brightCyan = Color.ansi(code: 96);
  static const Color brightWhite = Color.ansi(code: 97);

  String get ansi;
  String escapeForeground();
  String escapeBackground();

  @override
  String call(String content) => "${stdout.escape(this.escapeForeground())}"
      "$content"
      "${stdout.escape(stdout.currentContext.foregroundColor.escapeForeground())}";
}

final class RgbColor extends Color {
  const RgbColor({required this.r, required this.g, required this.b});

  final int r;
  final int g;
  final int b;

  @override
  String get ansi => "$r;$g;$b";

  @override
  String escapeForeground() => "${stdout.foregroundCode};2;${ansi}m";

  @override
  String escapeBackground() => "${stdout.backgroundCode};2;${ansi}m";
}

final class AnsiColor extends Color {
  const AnsiColor({required this.code});

  final int code;

  @override
  String get ansi => "${this.code}";

  @override
  String escapeForeground() => "${code}m";

  @override
  String escapeBackground() => "${code + 10}m";
}

extension StringColorExtension on String {
  String color(Color color, {bool iff = true}) => iff ? color(this) : this;

  String black({bool iff = true}) => this.color(Color.black, iff: iff);
  String red({bool iff = true}) => this.color(Color.red, iff: iff);
  String green({bool iff = true}) => this.color(Color.green, iff: iff);
  String yellow({bool iff = true}) => this.color(Color.yellow, iff: iff);
  String blue({bool iff = true}) => this.color(Color.blue, iff: iff);
  String magenta({bool iff = true}) => this.color(Color.magenta, iff: iff);
  String cyan({bool iff = true}) => this.color(Color.cyan, iff: iff);
  String white({bool iff = true}) => this.color(Color.white, iff: iff);
  String reset({bool iff = true}) => this.color(Color.reset, iff: iff);
  String brightBlack({bool iff = true}) => this.color(Color.brightBlack, iff: iff);
  String brightRed({bool iff = true}) => this.color(Color.brightRed, iff: iff);
  String brightGreen({bool iff = true}) => this.color(Color.brightGreen, iff: iff);
  String brightYellow({bool iff = true}) => this.color(Color.brightYellow, iff: iff);
  String brightBlue({bool iff = true}) => this.color(Color.brightBlue, iff: iff);
  String brightMagenta({bool iff = true}) => this.color(Color.brightMagenta, iff: iff);
  String brightCyan({bool iff = true}) => this.color(Color.brightCyan, iff: iff);
  String brightWhite({bool iff = true}) => this.color(Color.brightWhite, iff: iff);
}
