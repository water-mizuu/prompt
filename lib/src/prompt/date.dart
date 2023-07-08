import "package:prompt/src/extensions.dart";
import "package:prompt/src/io/decoration/color.dart";
import "package:prompt/src/io/decoration/style.dart";
import "package:prompt/src/io/exception.dart";
import "package:prompt/src/io/stdio/block/stdout/hidden_cursor.dart";
import "package:prompt/src/io/stdio/context.dart";
import "package:prompt/src/io/stdio/wrapper/stdin.dart";
import "package:prompt/src/io/stdio/wrapper/stdout.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdin.dart";
import "package:prompt/src/io/stdio/wrapper/wrapped_stdout.dart";
import "package:prompt/src/prompt/base.dart";
import "package:prompt/src/result.dart";
import "package:prompt/src/types.dart";

abstract final class DatePromptDefaults {
  static const bool minimal = false;
  static const Color accentColor = Colors.brightBlue;
}

enum _Focus {
  year,
  month,
  day,
  calendar;
}

Result<DateTime> datePrompt(
  String question, {
  DateTime? start,
  Guard<DateTime>? guard,
  String? hint,
  bool minimal = DatePromptDefaults.minimal,
  Color accentColor = DatePromptDefaults.accentColor,
}) {
  start ??= DateTime.now();

  DateTime currentDateTime = DateTime.now();
  bool hasFailed = false;

  // Constants that will be used in the program in building the calendar.
  const List<String> daysOfTheWeek = <String>["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  const int paddingSize = 4;
  // const List<String> daysOfTheWeek = <String>["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
  // const int paddingSize = 3;
  const int horizontalCellCount = 7;

  // A value determining which part of the form is focused.
  _Focus focus = _Focus.calendar;

  // Declaration and initialization of variables that will be used
  // in the program in building the calendar.
  var DateTime(
    year: int activeYear,
    month: int activeMonth,
    day: int activeDay,
  ) = start;

  late DateTime currentMonth;
  late DateTime previousMonth;

  late int skippedDays;
  late int monthIndex;

  late int previousDaysOfTheMonth;
  late int daysOfTheMonth;

  late int calendarHeight;

  late List2<int> calendarGrid;
  late DateTime active;

  late int activeX;
  late int activeY;

  /// This is a hack. I cannot believe this.
  void computeActives() {
    /// The DateTime constructor does magic that corrects incorrect data like
    ///   `2022-(-1)-(-5)` -> `2021-11-25`.
    DateTime(
      year: activeYear,
      month: activeMonth,
      day: activeDay,
    ) = DateTime(activeYear, activeMonth, activeDay);

    previousMonth = DateTime(activeYear, activeMonth - 1);
    currentMonth = DateTime(activeYear, activeMonth);

    skippedDays = currentMonth.weekday % horizontalCellCount;
    monthIndex = activeMonth - 1;

    previousDaysOfTheMonth = previousMonth.dayCount;
    daysOfTheMonth = currentMonth.dayCount;

    calendarHeight = ((skippedDays + daysOfTheMonth) / 7).ceil();

    calendarGrid = List2<int>.generate(
      calendarHeight,
      (int y) => List<int>.generate(
        horizontalCellCount,
        (int x) => (y * horizontalCellCount + x) - skippedDays + 1,
      ),
    );

    active = DateTime(activeYear, activeMonth, activeDay);
    activeX = active.weekday % horizontalCellCount;
    activeY = (skippedDays + activeDay - 1) ~/ horizontalCellCount;
  }

  void displayTitleCard() {
    // A String with the format "<Year Month Day>"
    List<String> buffer = <String>[
      if (activeYear.toString().padLeft(4) case String yearName)
        switch (focus) {
          _Focus.year => yearName.inverted(),
          _ => yearName,
        },
      if (DateExtension.monthNames[monthIndex] case String monthName)
        switch (focus) {
          _Focus.month => monthName.inverted(),
          _ => monthName,
        },
      if (activeDay.toString().padLeft(2, "0") case String text)
        switch (focus) {
          _Focus.day => text.inverted(),
          _ => text,
        },
    ];

    // Print the automatically centered title card
    stdout.write("<${buffer.join(" ")}>");
  }

  void displayDayLabels() {
    // Print the labels for the days of the week
    stdout.write("│");
    for (int i = 0; i < horizontalCellCount; ++i) {
      String paddedDisplay = daysOfTheWeek[i].padVisibleLeft(paddingSize);
      String formattedDisplay = switch (i) {
        0 => paddedDisplay.brightRed(),
        _ => paddedDisplay,
      };

      // If it is sunday, print it red.
      stdout.write(formattedDisplay);
    }
    stdout.write("│");
  }

  void displayCalendarRow(int y, {bool isActiveColorEnabled = true}) {
    stdout.write("│");
    for (int x = 0; x < horizontalCellCount; ++x) {
      int day = calendarGrid[y][x];

      bool isFocused = focus == _Focus.calendar;
      bool isActive = y == activeY && x == activeX;
      bool isToday = activeYear == currentDateTime.year &&
          activeMonth == currentDateTime.month &&
          day == currentDateTime.day;

      Color color = switch (day) {
        < 1 => Colors.brightBlack,
        _ when day > daysOfTheMonth => Colors.brightBlack,
        _ when x == 0 => Colors.brightRed,
        _ => Colors.reset,
      };

      String display = switch (day) {
        _ when day < 1 => previousDaysOfTheMonth + day,
        _ when day > daysOfTheMonth => day - daysOfTheMonth,
        _ => day,
      }
          .toString()
          .padVisibleLeft(2)
          .bold(iff: isToday)
          .color(color)
          .inverted(iff: isFocused && isActiveColorEnabled && isActive)
          .padVisibleLeft(paddingSize);

      stdout.write(display);
    }

    stdout.write("│");
  }

  void displayCalendar() {
    displayTitleCard();
    stdout.writeln();
    displayDayLabels();
    stdout.writeln();

    for (int y = 0; y < calendarHeight; ++y) {
      displayCalendarRow(y);
      stdout.writeln();
    }
  }

  void updateCalendar() {
    stdout.movelnUp(activeY + 1 /** Weekday Label */ + 1 /** Title Card */);
    stdout.eraselnDown(calendarHeight + 1);

    computeActives();
    displayCalendar();

    stdout.movelnUp(calendarHeight - activeY);
  }

  void updateTitleCard() {
    stdout.moveUp(activeY + 1 /** Weekday Label */ + 1 /** Title Card */);
    stdout.eraseln();
    displayTitleCard();
    stdout.moveDown(activeY + 1 /** Weekday Label */ + 1 /** Title Card */);
  }

  void moveHorizontal(int difference) {
    activeX += difference;

    stdout.eraseln();
    displayCalendarRow(activeY);

    if (activeX > horizontalCellCount - 1) {
      activeX %= horizontalCellCount;
      activeY += 1;
      stdout.moveDown();
    } else if (activeX < 0) {
      activeX %= horizontalCellCount;
      activeY -= 1;
      stdout.moveUp();
    }

    if (activeY > calendarHeight - 1) {
      activeDay += 1;
    } else if (activeY < 0) {
      activeDay -= 1;
    } else {
      activeDay += difference;
    }

    if (1 <= activeDay && activeDay <= daysOfTheMonth) {
      stdout.eraseln();
      displayCalendarRow(activeY);
      updateTitleCard();
    } else {
      updateCalendar();
    }
  }

  void moveVertical(int difference) {
    stdout.eraseln();
    displayCalendarRow(activeY, isActiveColorEnabled: false);

    activeY += difference;
    stdout.moveVertical(difference);

    if (activeY < 0) {
      activeDay -= horizontalCellCount;
    } else if (activeY > calendarHeight - 1) {
      activeDay += horizontalCellCount;
    } else {
      activeDay += difference * horizontalCellCount;
    }

    if (activeY < 0 ||
        activeDay < 1 ||
        activeY > calendarHeight - 1 ||
        activeDay > daysOfTheMonth) {
      updateCalendar();
    } else {
      stdout.eraseln();
      displayCalendarRow(activeY);
      updateTitleCard();
    }
  }

  void clearScreen() {
    int increment = hasFailed ? 1 : 0;

    if (focus case _Focus.calendar) {
      stdout.moveUp(activeY + 1 /** Weekday Label */ + 1 /** Title Card */ + increment);
    }
    stdout.moveUp(/** Question */);

    stdout.eraselnDown(
      calendarHeight + //
          1 /** Question */ +
          1 /** Title Card */ +
          1 /** Weekday Label */ +
          increment,
    );
  }

  void moveToTitleFromTitle(_Focus to) {
    stdout.eraseln();
    focus = to;
    displayTitleCard();
  }

  void moveToCalendarFromTitle(_Focus to) {
    /// Reset the title without the focus.
    stdout.eraseln();
    focus = to;

    displayCalendar();
    stdout.moveUp(calendarHeight - activeY);
  }

  void moveToTitleFromCalendar(_Focus to) {
    /// Remove the focus from the calendar.
    stdout.eraseln();
    displayCalendarRow(activeY);

    focus = to;

    /// Rerender the title.
    stdout.moveUp(activeY + 1 /** Weekday Label */ + 1 /** Title Card */);
    stdout.eraseln();
    displayTitleCard();
  }

  try {
    stdout.push();
    stdout.hideCursor();

    for (;;) {
      computeActives();

      stdout.write("?".color(accentColor));
      stdout.write(" $question ");
      if (hint != null) {
        stdout.write("($hint)".brightBlack());
      }
      stdout.writeln();

      displayCalendar();

      stdout.moveUp(calendarHeight - activeY);

      loop:
      for (List<int> code in stdin.sync) {
        switch (code) {
          case <int>[0x3]:
            throw SignalInterruptionException();
          case <int>[0x9]:
            // tab
            switch (focus) {
              case _Focus.calendar:
                moveToTitleFromCalendar(_Focus.year);
              case _Focus.year:
                moveToTitleFromTitle(_Focus.month);
              case _Focus.month:
                moveToTitleFromTitle(_Focus.day);
              case _Focus.day:
                moveToCalendarFromTitle(_Focus.calendar);
            }
          case <int>[0x1b, 0x5b, 0x5a]:
            // shift + tab
            switch (focus) {
              case _Focus.calendar:
                moveToTitleFromCalendar(_Focus.day);
              case _Focus.day:
                moveToTitleFromTitle(_Focus.month);
              case _Focus.month:
                moveToTitleFromTitle(_Focus.year);
              case _Focus.year:
                moveToCalendarFromTitle(_Focus.calendar);
            }
          case <int>[0x0d]:
            // enter
            active = DateTime(activeYear, activeMonth, activeDay);
            break loop;
          case _:
            void titularRefreshCalendar() {
              stdout.eraselnDown(calendarHeight + 1 /** Weekday Label */ + 1 /** Title Card */);

              computeActives();
              displayCalendar();

              stdout.moveUp(calendarHeight + 1 /** Weekday Label */ + 1 /** Title Card */);
            }
            switch (focus) {
              case _Focus.year:
                switch (code) {
                  case <int>[0x1b, 0x5b, 0x41]:
                    // up
                    activeYear -= 1;
                    titularRefreshCalendar();
                  case <int>[0x1b, 0x5b, 0x42]:
                    // down
                    activeYear += 1;
                    titularRefreshCalendar();
                  case <int>[0x1b, 0x5b, 0x43]:
                    // right
                    moveToTitleFromTitle(_Focus.month);
                  case <int>[0x1b, 0x5b, 0x44]:
                    // left
                    moveToTitleFromTitle(_Focus.day);
                }
              case _Focus.month:
                switch (code) {
                  case <int>[0x1b, 0x5b, 0x41]:
                    // up
                    activeMonth -= 1;
                    titularRefreshCalendar();
                  case <int>[0x1b, 0x5b, 0x42]:
                    // down
                    activeMonth += 1;
                    titularRefreshCalendar();
                  case <int>[0x1b, 0x5b, 0x43]:
                    // right
                    moveToTitleFromTitle(_Focus.day);
                  case <int>[0x1b, 0x5b, 0x44]:
                    // left
                    moveToTitleFromTitle(_Focus.year);
                }
              case _Focus.day:
                switch (code) {
                  case <int>[0x1b, 0x5b, 0x41]:
                    // up
                    activeDay -= 1;
                    titularRefreshCalendar();
                  case <int>[0x1b, 0x5b, 0x42]:
                    // down
                    activeDay += 1;
                    titularRefreshCalendar();
                  case <int>[0x1b, 0x5b, 0x43]:
                    // right
                    moveToTitleFromTitle(_Focus.year);
                  case <int>[0x1b, 0x5b, 0x44]:
                    // left
                    moveToTitleFromTitle(_Focus.month);
                }
              case _Focus.calendar:
                switch (code) {
                  case <int>[0x1b, 0x5b, 0x41]:
                    // up
                    moveVertical(-1);
                  case <int>[0x1b, 0x5b, 0x42]:
                    // down
                    moveVertical(1);
                  case <int>[0x1b, 0x5b, 0x43]:
                    // right
                    moveHorizontal(1);
                  case <int>[0x1b, 0x5b, 0x44]:
                    // left
                    moveHorizontal(-1);
                }
            }
        }
      }

      /// When the loop is broken, we move downwards.
      clearScreen();

      if (guard case (GuardFunction<DateTime> fn, String msg) when !fn(active)) {
        hasFailed = true;
        stdout.writeln("// $msg".brightRed());

        continue;
      } else {
        break;
      }
    }

    stdout.write("+".color(accentColor));
    stdout.write(" $question ");
    stdout.writeln(active.toDateString().color(accentColor));

    return Success<DateTime>(active);
  } on SignalInterruptionException {
    clearScreen();

    stdout.write("!".brightRed());
    stdout.write(" $question ");
    stdout.writeln("^C".brightBlack());

    return const Failure<DateTime>("^C");
  } finally {
    stdout.pop();
  }
}

extension PromptDateExtension on BasePrompt {
  Result<DateTime> date(
    String question, {
    DateTime? start,
    Guard<DateTime>? guard,
    String? hint,
    bool minimal = DatePromptDefaults.minimal,
    Color accentColor = DatePromptDefaults.accentColor,
  }) =>
      datePrompt(
        question,
        start: start,
        guard: guard,
        hint: hint,
        minimal: minimal,
        accentColor: accentColor,
      );
}
