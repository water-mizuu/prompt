import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/stdio/box.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";

class CustomError extends Error {
  CustomError(
    this.main, {
    this.invalidValue,
    this.message = "",
    this.title = "Error",
  });
  factory CustomError.invalidArgument(Object? invalidValue, String message) => CustomError(
        "Invalid argument",
        invalidValue: invalidValue,
        message: message,
        title: "InvalidArgumentError",
      );

  final String main;

  /// The invalid value.
  final Object? invalidValue;

  /// Message describing the problem.
  final String message;

  final String title;

  @override
  String toString() => stdout.boxify(
        title: title,
        "$main${invalidValue != null ? " ($invalidValue)" : ""}. $message",
        color: Colors.brightRed,
        textColor: Colors.red,
      );
}

class UnreachableError extends Error {}
