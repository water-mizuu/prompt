import "dart:collection";

import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/stdio/codes.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";

final class StdoutContext {
  StdoutContext({
    this.backgroundColor = Color.reset,
    this.foregroundColor = Color.reset,
    this.isCursorHidden = false,
    this.isBold = false,
    this.isFaint = false,
    this.isItalic = false,
    this.isUnderlined = false,
    this.isBlinking = false,
    this.isReversed = false,
    this.isHidden = false,
    this.isStrikeThrough = false,
    this.isGothic = false,
    this.isDoubleUnderlined = false,
    this.isFramed = false,
    this.isEncircled = false,
    this.isOverlined = false,
  });

  StdoutContext.empty()
      : this.foregroundColor = Color.reset,
        this.backgroundColor = Color.reset,
        this.isCursorHidden = false,
        this.isBold = false,
        this.isFaint = false,
        this.isItalic = false,
        this.isUnderlined = false,
        this.isBlinking = false,
        this.isReversed = false,
        this.isHidden = false,
        this.isStrikeThrough = false,
        this.isGothic = false,
        this.isDoubleUnderlined = false,
        this.isFramed = false,
        this.isEncircled = false,
        this.isOverlined = false;

  StdoutContext.inherit(StdoutContext parent)
      : this.foregroundColor = parent.foregroundColor,
        this.backgroundColor = parent.backgroundColor,
        this.isCursorHidden = parent.isCursorHidden,
        this.isBold = parent.isBold,
        this.isFaint = parent.isFaint,
        this.isItalic = parent.isItalic,
        this.isUnderlined = parent.isUnderlined,
        this.isBlinking = parent.isBlinking,
        this.isReversed = parent.isReversed,
        this.isHidden = parent.isHidden,
        this.isStrikeThrough = parent.isStrikeThrough,
        this.isGothic = parent.isGothic,
        this.isDoubleUnderlined = parent.isDoubleUnderlined,
        this.isFramed = parent.isFramed,
        this.isEncircled = parent.isEncircled,
        this.isOverlined = parent.isOverlined;

  bool isBold;
  bool isFaint;
  bool isItalic;
  bool isUnderlined;
  bool isBlinking;
  bool isReversed;
  bool isHidden;
  bool isStrikeThrough;
  bool isGothic;
  bool isDoubleUnderlined;
  bool isFramed;
  bool isEncircled;
  bool isOverlined;

  bool isCursorHidden;

  Color foregroundColor;
  Color backgroundColor;
}

extension ContextExtension on WrappedStdout {
  static final Expando<Queue<StdoutContext>> _savedContextStacks = Expando<Queue<StdoutContext>>();

  Queue<StdoutContext> get contextStack =>
      _savedContextStacks[this] ??= Queue<StdoutContext>()..addLast(StdoutContext.empty());

  StdoutContext get currentContext => contextStack.last;

  void update() {
    var StdoutContext(
      :bool isCursorHidden,
      :Color backgroundColor,
      :Color foregroundColor,
    ) = contextStack.last;

    writeEscaped(isCursorHidden ? hideCursorCode : showCursorCode);
    writeEscaped(backgroundColor.escapeBackground());
    writeEscaped(foregroundColor.escapeForeground());
  }

  /// Pushes a new standard out context onto the stack.
  void push() {
    contextStack.addLast(StdoutContext.inherit(contextStack.last));
    update();
  }

  /// Pops the last standard out context onto the stack.
  void pop() {
    if (contextStack.length <= 1) {
      return;
    }
    contextStack.removeLast();
    update();
  }
}
