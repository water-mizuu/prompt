// ignore_for_file: comment_references
/// TODO: Implement these prompts:
///   [ ] Create a prompt for a `Date`.
///     [x] Make a basic working prompt
///     [ ] Add support for hints
///     [ ] Add support for guards
///   [ ] Create a prompt for a `Time`.
///   [ ] Create a unified prompt for a `DateTime`.
///   [ ] Create a prompt for a `Duration`.
///   [ ] Create a prompt for a passwords.
///   [ ] Create a prompt for a `Directory`.
///   [ ] Create a prompt for a `File`.

library;

export "dart:io" hide sleep, stderr, stdin, stdout;

export "src/extensions.dart";
export "src/guards.dart";
export "src/io.dart";
export "src/prompt.dart";
export "src/result.dart";
export "src/types.dart";
