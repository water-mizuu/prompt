import "package:prompt/prompt.dart";
import "package:prompt/src/io/exception.dart";

class TimePromptDefaults {
  static const Color accentColor = Colors.brightBlue;
}

enum _FocusMode { hour, minute, meridiem }

enum Meridiem {
  am,
  pm;

  @override
  String toString() => switch (this) { am => "AM", pm => "PM" };

  Meridiem get inverse => switch (this) {
    am => pm,
    pm => am,
  };
}

Option<DateTime> timePrompt(
  String question, {
  DateTime? start,
  Guard<DateTime>? guard,
  Color accentColor = TimePromptDefaults.accentColor,
}) {
  start ??= DateTime.now();
  String formattedQuestion = question.bold();
  const ({int hour, int meridiem, int minute}) paddingSizes = (hour: 2, minute: 2, meridiem: 2);

  try {
    stdout.push();
    stdout.hideCursor();

    _FocusMode focusMode = _FocusMode.hour;
    Meridiem activeMeridiem = switch (start.hour) {
      >= 0 && < 12 => Meridiem.am,
      _ => Meridiem.pm,
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
      buffer.write(hour.inverted(iff: focusMode == _FocusMode.hour));
      buffer.write(" : ");

      /// MM
      buffer.write(minute.inverted(iff: focusMode == _FocusMode.minute));
      buffer.write(" : ");

      /// AM/PM
      buffer.write(meridiem.inverted(iff: focusMode == _FocusMode.meridiem));

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
                  if (activeHour == 11) {
                    activeMeridiem = activeMeridiem.inverse;
                  }

                  activeHour += 1;
                case <int>[0x1b, 0x5b, 0x42]:
                  // down
                  activeHour -= 1;
                  activeHour -= 1;
                  activeHour %= 12;
                  if (activeHour == 10) {
                    activeMeridiem = activeMeridiem.inverse;
                  }

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
                    Meridiem.am => Meridiem.pm,
                    Meridiem.pm => Meridiem.am,
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
          "${"$activeHour".padLeft(2, "0")}:${"$activeMinute".padLeft(2, "0")} $activeMeridiem"
              .color(accentColor),
        );

      stdout.writeln(buffer);
    }

    return Success<DateTime>(
      DateTime(
        start.year,
        start.month,
        start.day,
        switch (activeMeridiem) {
          Meridiem.am when activeHour == 12 => 0,
          Meridiem.am => activeHour,
          Meridiem.pm when activeHour == 12 => 12,
          Meridiem.pm => activeHour + 12,
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
  Option<DateTime> time(
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
