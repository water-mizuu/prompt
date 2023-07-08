import "package:prompt/src/io/decoration/decoration.dart";
import "package:prompt/src/io/stdio/context.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";

final class Style implements TextDecoration {
  const Style({required this.code, required this.condition, int? resetCode})
      : resetCode = resetCode ?? (code + 20);

  static final Style bold = Style(
    code: 1,
    condition: (StdoutContext context) => context.isBold,
    resetCode: 22,
  );
  static final Style faint = Style(
    code: 2,
    condition: (StdoutContext context) => context.isFaint,
  );
  static final Style italic = Style(
    code: 3,
    condition: (StdoutContext context) => context.isItalic,
  );
  static final Style underlined = Style(
    code: 4,
    condition: (StdoutContext context) => context.isUnderlined,
  );
  static final Style blinking = Style(
    code: 5,
    condition: (StdoutContext context) => context.isBlinking,
  );
  static final Style blinkingFast = Style(
    code: 6,
    condition: (StdoutContext context) => context.isBlinking,
    resetCode: 25,
  );
  static final Style reverse = Style(
    code: 7,
    condition: (StdoutContext context) => context.isReversed,
  );
  static final Style inverted = reverse;
  static final Style hidden = Style(
    code: 8,
    condition: (StdoutContext context) => context.isHidden,
  );
  static final Style strikeThrough = Style(
    code: 9,
    condition: (StdoutContext context) => context.isStrikeThrough,
  );

  static final Style gothic = Style(
    code: 20,
    condition: (StdoutContext context) => context.isGothic,
  );

  static final Style doubleUnderline = Style(
    code: 21,
    condition: (StdoutContext context) => context.isDoubleUnderlined,
    resetCode: 24,
  );

  static final Style framed = Style(
    code: 51,
    condition: (StdoutContext context) => context.isFramed,
    resetCode: 54,
  );

  static final Style encircled = Style(
    code: 52,
    condition: (StdoutContext context) => context.isEncircled,
    resetCode: 54,
  );

  static final Style overlined = Style(
    code: 53,
    condition: (StdoutContext context) => context.isOverlined,
    resetCode: 55,
  );

  final bool Function(StdoutContext) condition;
  final int code;
  final int resetCode;

  @override
  String call(String content) => "${stdout.escape("${code}m")}"
      "$content"
      // If the latest says it's not hidden, then we reset.
      "${condition(stdout.contextStack.last) ? "" : stdout.escape("${resetCode}m")}";
}

extension StringStyleExtension on String {
  String decorate(TextDecoration decoration) => decoration(this);

  String bold() => this.decorate(Style.bold);
  String faint() => this.decorate(Style.faint);
  String italic() => this.decorate(Style.italic);
  String underlined() => this.decorate(Style.underlined);
  String blinking() => this.decorate(Style.blinking);
  String blinkingFast() => this.decorate(Style.blinkingFast);
  String reverse() => this.decorate(Style.reverse);
  String inverted() => this.decorate(Style.inverted);
  String hidden() => this.decorate(Style.hidden);
  String strikeThrough() => this.decorate(Style.strikeThrough);
  String gothic() => this.decorate(Style.gothic);
  String doubleUnderline() => this.decorate(Style.doubleUnderline);
  String framed() => this.decorate(Style.framed);
  String encircled() => this.decorate(Style.encircled);
  String overlined() => this.decorate(Style.overlined);
}
