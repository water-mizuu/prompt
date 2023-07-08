import "package:prompt/prompt.dart";
import "package:prompt/src/io/exception.dart";

class TimePromptDefaults {
  static const Color accentColor = Color.brightBlue;
}

enum _FocusMode { hour, minute, meridiem }

enum _Meridiem {
  am,
  pm;

  @override
  String toString() => switch (this) { am => "AM", pm => "PM" };
}

Result<DateTime> timePrompt(
  String question, {
  DateTime? start,
  Guard<DateTime>? guard,
  Color accentColor = TimePromptDefaults.accentColor,
}) {
  start ??= DateTime.now();
  String formattedQuestion = question.bold();
  const ({int hour, int minute, int meridiem}) paddingSizes = (hour: 2, minute: 2, meridiem: 2);

  try {
    stdout.push();
    stdout.hideCursor();

    _FocusMode focusMode = _FocusMode.hour;
    _Meridiem activeMeridiem = switch (start.hour) {
      >= 0 && < 12 => _Meridiem.am,
      _ => _Meridiem.pm,
    };
    int activeHour = switch (start.hour) {
      0 || 12 => 12,
      > 0 && < 12 => start.hour,
      _ => start.hour - 12,
    };
    int activeMinute = start.minute;

    {
      StringBuffer buffer = StringBuffer() //
        ..write("?".color(accentColor))
        ..write(" $formattedQuestion ");

      stdout.writeln(buffer);
    }

    void displayUpperControl() {
      stdout.eraselnFromCursor();
      StringBuffer buffer = StringBuffer();

      /// Indentation
      buffer.write("  ");

      /// HH
      buffer.write("^".padVisibleLeft(paddingSizes.hour).brightBlack());
      buffer.write("   ");

      /// MM
      buffer.write("^".padVisibleLeft(paddingSizes.minute).brightBlack());
      buffer.write("   ");

      stdout.write$(buffer);
    }

    void displayClock() {
      stdout.eraselnFromCursor();
      StringBuffer buffer = StringBuffer();

      String hour = activeHour.toString().padVisibleLeft(paddingSizes.hour, "0");
      String minute = activeMinute.toString().padVisibleLeft(paddingSizes.minute, "0");
      String meridiem = activeMeridiem.toString().padVisibleLeft(paddingSizes.meridiem, "0");

      /// Indentation
      buffer.write("  ");

      /// HH
      buffer.write(
        switch (focusMode) {
          _FocusMode.hour => hour.inverted(),
          _ => hour,
        },
      );
      buffer.write(" : ");

      /// MM
      buffer.write(
        switch (focusMode) {
          _FocusMode.minute => minute.inverted(),
          _ => minute,
        },
      );
      buffer.write(" : ");

      /// AM/PM
      buffer.write(
        switch (focusMode) {
          _FocusMode.meridiem => meridiem.inverted(),
          _ => meridiem,
        },
      );

      stdout.write$(buffer);
    }

    void displayLowerControl() {
      stdout.eraselnFromCursor();
      StringBuffer buffer = StringBuffer();

      /// Indentation
      buffer.write("  ");

      /// HH
      buffer.write("v".padVisibleLeft(paddingSizes.hour).brightBlack());
      buffer.write("   ");

      /// MM
      buffer.write("v".padVisibleLeft(paddingSizes.minute).brightBlack());
      buffer.write("   ");

      stdout.write$(buffer);
    }

    displayUpperControl();
    stdout.moveDown();
    displayClock();
    stdout.moveDown();
    displayLowerControl();

    stdout.moveUp();

    loop:
    for (List<int> code in stdin.sync) {
      switch (code) {
        case <int>[0x03]:
          throw SignalInterruptionException();
        case <int>[0x0d]:
          break loop;
        case _:
          switch (focusMode) {
            case _FocusMode.hour:
              switch (code) {
                case <int>[0x1b, 0x5b, 0x41]:
                  // up
                  activeHour -= 1;
                  activeHour += 1;
                  activeHour %= 12;
                  activeHour += 1;
                case <int>[0x1b, 0x5b, 0x42]:
                  // down

                  activeHour -= 1;
                  activeHour -= 1;
                  activeHour %= 12;
                  activeHour += 1;
                case <int>[0x1b, 0x5b, 0x43]:
                  // right
                  focusMode = _FocusMode.minute;
                case <int>[0x1b, 0x5b, 0x44]:
                  // left
                  focusMode = _FocusMode.meridiem;
                case _:
                  continue loop;
              }

            case _FocusMode.minute:
              switch (code) {
                case <int>[0x1b, 0x5b, 0x41]:
                  // up
                  activeMinute = (activeMinute + 1) % 60;
                case <int>[0x1b, 0x5b, 0x42]:
                  // down
                  activeMinute = (activeMinute - 1) % 60;
                case <int>[0x1b, 0x5b, 0x43]:
                  // right
                  focusMode = _FocusMode.meridiem;
                case <int>[0x1b, 0x5b, 0x44]:
                  // left
                  focusMode = _FocusMode.hour;
                case _:
                  continue loop;
              }
            case _FocusMode.meridiem:
              switch (code) {
                case <int>[0x20]:
                //space
                case <int>[0x1b, 0x5b, 0x41]:
                // up
                case <int>[0x1b, 0x5b, 0x42]:
                  // down
                  activeMeridiem = switch (activeMeridiem) {
                    _Meridiem.am => _Meridiem.pm,
                    _Meridiem.pm => _Meridiem.am,
                  };
                case <int>[0x1b, 0x5b, 0x43]:
                  // right
                  focusMode = _FocusMode.hour;
                case <int>[0x1b, 0x5b, 0x44]:
                  // left
                  focusMode = _FocusMode.minute;
                case _:
                  continue loop;
              }
          }
      }

      displayClock();
    }

    stdout.moveUp(2);
    stdout.eraselnDown(4);
    {
      StringBuffer buffer = StringBuffer()
        ..write("+".color(accentColor))
        ..write(" $formattedQuestion ")
        ..write(
          ("${"$activeHour".padLeft(2, "0")}:${"$activeMinute".padLeft(2, "0")} $activeMeridiem")
              .color(accentColor),
        );

      stdout.write$(buffer);
      stdout.moveDown();
    }
    return Success<DateTime>(
      DateTime(
        start.year,
        start.month,
        start.day,
        switch (activeMeridiem) {
          _Meridiem.am when activeHour == 12 => 0,
          _Meridiem.am => activeHour,
          _Meridiem.pm when activeHour == 12 => 12,
          _Meridiem.pm => activeHour + 12,
        },
        activeMinute,
      ),
    );
  } on SignalInterruptionException {
    stdout.moveUp(2);
    stdout.eraselnDown(4);
    {
      StringBuffer buffer = StringBuffer() //
        ..write("!".brightRed())
        ..write(" $formattedQuestion ")
        ..write("^C".brightBlack());

      stdout.write$(buffer);
      stdout.moveDown();
    }

    return const Failure<DateTime>("^C");
  } finally {
    stdout.pop();
  }
}

extension PromptTimeExtension on BasePrompt {
  /// Prompt the user to choose from a list of options.
  Result<DateTime> time(
    String question, {
    DateTime? start,
    Guard<DateTime>? guard,
    Color accentColor = TimePromptDefaults.accentColor,
  }) =>
      timePrompt(
        question,
        start: start,
        guard: guard,
        accentColor: accentColor,
      );
}
