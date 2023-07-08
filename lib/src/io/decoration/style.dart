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
  String decorate(TextDecoration decoration, {bool iff = true}) => iff ? decoration(this) : this;

  String bold({bool iff = true}) => this.decorate(Style.bold, iff: iff);
  String faint({bool iff = true}) => this.decorate(Style.faint, iff: iff);
  String italic({bool iff = true}) => this.decorate(Style.italic, iff: iff);
  String underlined({bool iff = true}) => this.decorate(Style.underlined, iff: iff);
  String blinking({bool iff = true}) => this.decorate(Style.blinking, iff: iff);
  String blinkingFast({bool iff = true}) => this.decorate(Style.blinkingFast, iff: iff);
  String reverse({bool iff = true}) => this.decorate(Style.reverse, iff: iff);
  String inverted({bool iff = true}) => this.decorate(Style.inverted, iff: iff);
  String hidden({bool iff = true}) => this.decorate(Style.hidden, iff: iff);
  String strikeThrough({bool iff = true}) => this.decorate(Style.strikeThrough, iff: iff);
  String gothic({bool iff = true}) => this.decorate(Style.gothic, iff: iff);
  String doubleUnderlined({bool iff = true}) => this.decorate(Style.doubleUnderline, iff: iff);
  String framed({bool iff = true}) => this.decorate(Style.framed, iff: iff);
  String encircled({bool iff = true}) => this.decorate(Style.encircled, iff: iff);
  String overlined({bool iff = true}) => this.decorate(Style.overlined, iff: iff);
}
