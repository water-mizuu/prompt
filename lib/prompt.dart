// ignore_for_file: comment_references
/// TODO: Implement these prompts:
///   [x] Create a prompt for a `Date`.
///     [x] Make a basic working prompt
///     [x] Add support for hints
///     [x] Add support for guards
///   [x] Create a prompt for a `Time`.
///   [x] Create a unified prompt for a `DateTime`.
///   [ ] Create a prompt for a `Duration`.
///   [x] Create a prompt for a passwords.
///   [x] Create a prompt for a `Directory`.
///   [x] Create a prompt for a `File`.

library;

export "dart:io" hide sleep, stderr, stdin, stdout;

export "src/extensions.dart";
export "src/guard.dart" hide False, True;
export "src/io.dart";
export "src/option.dart";
export "src/prompt.dart";
export "src/types.dart";
