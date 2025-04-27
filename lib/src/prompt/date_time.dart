import "package:prompt/prompt.dart";
import "package:prompt/src/guard.dart";
import "package:prompt/src/io/exception.dart";

abstract final class DateTimePromptDefaults {
  static const bool minimal = false;
  static const Color accentColor = Colors.brightBlue;
}

enum _Focus {
  year,
  month,
  day,
  calendarBody,
  hour,
  minute,
  meridiem;
}

Option<DateTime> dateTimePrompt(
  String question, {
  DateTime? start,
  Guard<DateTime>? guard,
  String? hint,
  bool minimal = DateTimePromptDefaults.minimal,
  Color accentColor = DateTimePromptDefaults.accentColor,
}) {
  start ??= DateTime.now();

  DateTime currentDateTime = DateTime.now();
  bool hasFailed = false;

  // Declaration and initialization of variables that will be used
  // in the program in building the calendar.
  var DateTime(
    year: int activeYear,
    month: int activeMonth,
    day: int activeDay,
  ) = start;

  int activeHour = switch (start.hour) {
    0 || 12 => 12,
    > 0 && < 12 => start.hour,
    _ => start.hour - 12,
  };
  int activeMinute = start.minute;
  Meridiem activeMeridiem = switch (start.hour) {
    >= 0 && < 12 => Meridiem.am,
    _ => Meridiem.pm,
  };

  DateTime computeActiveDateTime() => DateTime(
        activeYear,
        activeMonth,
        activeDay,
        (activeHour - 1 + (activeMeridiem == Meridiem.pm ? 12 : 0)) % 24,
        activeMinute,
      );

  if (minimal) {
    // A value determining which part of the form is focused.
    _Focus focus = _Focus.year;

    void drawQuestion() {
      if (!hasFailed) {
        stdout.write("?".color(accentColor));
      } else {
        stdout.write("!".color(Colors.brightRed));
      }

      stdout.write(" $question ");
      if (hint != null) {
        stdout.write("($hint) ".brightBlack());
      }

      // A String with the format "<Year Month Day>"
      List<String> buffer = <String>[
        "$activeYear".padLeft(4).inverted(iff: focus == _Focus.year),
        DateExtension.monthNames[activeMonth - 1].inverted(iff: focus == _Focus.month),
        "$activeDay".padLeft(2, "0").inverted(iff: focus == _Focus.day),
        ", ",
        "$activeHour".padLeft(2, "0").inverted(iff: focus == _Focus.hour),
        ":",
        "$activeMinute".padLeft(2, "0").inverted(iff: focus == _Focus.minute),
        "$activeMeridiem".padLeft(2, "0").inverted(iff: focus == _Focus.meridiem),
      ];

      // Print the automatically centered title card
      stdout.write(buffer.join(" "));
    }

    void redraw() {
      stdout.eraseln();

      drawQuestion();
    }

    void moveFocus(_Focus to) {
      focus = to;

      redraw();
    }

    DateTime active = DateTime(activeYear, activeMonth, activeDay);
    try {
      stdout.push();
      stdout.hideCursor();

      for (;;) {
        /// The DateTime constructor does magic that corrects incorrect data like
        ///   `2022-(-1)-(-5)` -> `2021-11-25`.
        DateTime(year: activeYear, month: activeMonth, day: activeDay) =
            DateTime(activeYear, activeMonth, activeDay);

        drawQuestion();

        loop:
        for (List<int> code in stdin.sync) {
          switch (code) {
            case <int>[0x3]:
              throw SignalInterruptionException();

            case <int>[0x9]:
              // tab
              switch (focus) {
                case _Focus.calendarBody:
                  continue;
                case _Focus.year:
                  moveFocus(_Focus.month);
                case _Focus.month:
                  moveFocus(_Focus.day);
                case _Focus.day:
                  moveFocus(_Focus.hour);
                case _Focus.hour:
                  moveFocus(_Focus.minute);
                case _Focus.minute:
                  moveFocus(_Focus.meridiem);
                case _Focus.meridiem:
                  moveFocus(_Focus.year);
              }
            case <int>[0x1b, 0x5b, 0x5a]:
              // shift + tab
              switch (focus) {
                case _Focus.calendarBody:
                  continue;
                case _Focus.year:
                  moveFocus(_Focus.meridiem);
                case _Focus.month:
                  moveFocus(_Focus.year);
                case _Focus.day:
                  moveFocus(_Focus.month);
                case _Focus.hour:
                  moveFocus(_Focus.day);
                case _Focus.minute:
                  moveFocus(_Focus.hour);
                case _Focus.meridiem:
                  moveFocus(_Focus.minute);
              }
            case <int>[0x0d]:
              // enter
              break loop;

            case <int>[0x1b, 0x5b, 0x41]:
            case <int>[0x1b, 0x5b, 0x42]:
              if (hasFailed) {
                stdout.eraseln();
                stdout.moveUp();
                stdout.eraseln();
                hasFailed = false;
                redraw();
              }
              continue continuation;

            continuation:
            case _:
              switch (focus) {
                case _Focus.calendarBody:
                  continue;
                case _Focus.year:
                  switch (code) {
                    case <int>[0x1b, 0x5b, 0x41]:
                      // up
                      activeYear -= 1;
                      redraw();
                    case <int>[0x1b, 0x5b, 0x42]:
                      // down
                      activeYear += 1;
                      redraw();
                    case <int>[0x1b, 0x5b, 0x43]:
                      // right
                      moveFocus(_Focus.month);

                    case <int>[0x1b, 0x5b, 0x44]:
                      // left
                      moveFocus(_Focus.meridiem);
                  }
                case _Focus.month:
                  switch (code) {
                    case <int>[0x1b, 0x5b, 0x41]:
                      // up
                      activeMonth -= 1;
                      redraw();
                    case <int>[0x1b, 0x5b, 0x42]:
                      // down
                      activeMonth += 1;
                      redraw();
                    case <int>[0x1b, 0x5b, 0x43]:
                      // right
                      moveFocus(_Focus.day);
                    case <int>[0x1b, 0x5b, 0x44]:
                      // left
                      moveFocus(_Focus.year);
                  }
                case _Focus.day:
                  switch (code) {
                    case <int>[0x1b, 0x5b, 0x41]:
                      // up
                      activeDay -= 1;
                      redraw();
                    case <int>[0x1b, 0x5b, 0x42]:
                      // down
                      activeDay += 1;
                      redraw();
                    case <int>[0x1b, 0x5b, 0x43]:
                      // right
                      moveFocus(_Focus.hour);
                    case <int>[0x1b, 0x5b, 0x44]:
                      // left
                      moveFocus(_Focus.month);
                  }
                case _Focus.hour:
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
                      redraw();
                    case <int>[0x1b, 0x5b, 0x42]:
                      // down
                      activeHour -= 1;
                      activeHour -= 1;

                      activeHour %= 12;
                      if (activeHour == 10) {
                        activeMeridiem = activeMeridiem.inverse;
                      }

                      activeHour += 1;
                      redraw();
                    case <int>[0x1b, 0x5b, 0x43]:
                      // right
                      moveFocus(_Focus.minute);
                    case <int>[0x1b, 0x5b, 0x44]:
                      // left
                      moveFocus(_Focus.day);
                  }
                case _Focus.minute:
                  switch (code) {
                    case <int>[0x1b, 0x5b, 0x41]:
                      // up
                      activeMinute += 1;
                      activeMinute %= 60;
                      redraw();
                    case <int>[0x1b, 0x5b, 0x42]:
                      // down
                      activeMinute -= 1;
                      activeMinute %= 60;
                      redraw();
                    case <int>[0x1b, 0x5b, 0x43]:
                      // right
                      moveFocus(_Focus.meridiem);
                    case <int>[0x1b, 0x5b, 0x44]:
                      // left
                      moveFocus(_Focus.hour);
                  }
                case _Focus.meridiem:
                  switch (code) {
                    case <int>[0x1b, 0x5b, 0x41]:
                    case <int>[0x1b, 0x5b, 0x42]:
                      activeMeridiem = activeMeridiem.inverse;
                      redraw();
                    case <int>[0x1b, 0x5b, 0x43]:
                      // right
                      moveFocus(_Focus.year);
                    case <int>[0x1b, 0x5b, 0x44]:
                      // left
                      moveFocus(_Focus.minute);
                  }
              }
          }
        }

        if (hasFailed) {
          stdout.eraselnUp();
          stdout.moveUp();
        }
        stdout.eraseln();
        active = computeActiveDateTime();

        if (guard?.call(active) case False(:String failure)) {
          hasFailed = true;

          stdout.writeln("// $failure".brightRed());

          continue;
        } else {
          break;
        }
      }
    } on SignalInterruptionException {
      if (hasFailed) {
        stdout.eraselnUp();
        stdout.moveUp();
      }
      stdout.eraseln();

      stdout.write("!".brightRed());
      stdout.write(" $question ");
      stdout.writeln("^C".brightBlack());

      return const Failure<DateTime>("^C");
    } finally {
      stdout.pop();
    }

    stdout.write("+".color(accentColor));
    stdout.write(" $question ");
    stdout.writeln(active.toAMPMDateTimeString().color(accentColor));

    return Success<DateTime>(active);
  } else {
    // A value determining which part of the form is focused.
    _Focus focus = _Focus.calendarBody;

    // ignore: always_specify_types
    const timePaddingSizes = (hour: 2, minute: 2, meridiem: 2);
    const int timePadding = 2;

    // Constants that will be used in the program in building the calendar.
    const List<String> daysOfTheWeek = <String>["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    const int paddingSize = 4;
    // const List<String> daysOfTheWeek = <String>["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
    // const int paddingSize = 3;
    const int daysInAWeek = 7;

    late DateTime currentMonth;
    late DateTime previousMonth;

    late int skippedDays;

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
        hour: activeHour,
        minute: activeMinute,
      ) = DateTime(activeYear, activeMonth, activeDay, activeHour, activeMinute);

      previousMonth = DateTime(activeYear, activeMonth - 1);
      currentMonth = DateTime(activeYear, activeMonth);

      skippedDays = currentMonth.weekday % daysInAWeek;

      previousDaysOfTheMonth = previousMonth.dayCount;
      daysOfTheMonth = currentMonth.dayCount;

      calendarHeight = ((skippedDays + daysOfTheMonth) / 7).ceil();

      calendarGrid = List2<int>.generate(
        calendarHeight,
        (int y) => List<int>.generate(
          daysInAWeek,
          (int x) => (y * daysInAWeek + x) - skippedDays + 1,
        ),
      );

      active = computeActiveDateTime();
      activeX = active.weekday % daysInAWeek;
      activeY = (skippedDays + activeDay - 1) ~/ daysInAWeek;
    }

    void displayUpperControl() {
      stdout.eraselnFromCursor();
      StringBuffer buffer = StringBuffer();

      /// Indentation
      buffer.write(" " * timePadding);
      buffer.write("│");

      /// HH
      buffer.write("^".padVisibleLeft(timePaddingSizes.hour).brightBlack());
      buffer.write("   ");

      /// MM
      buffer.write("^".padVisibleLeft(timePaddingSizes.minute).brightBlack());
      buffer.write("   ");

      /// AM/PM
      buffer.write(" ".padVisibleLeft(timePaddingSizes.meridiem).brightBlack());
      buffer.write("│");

      stdout.write$(buffer);
    }

    void displayClock() {
      stdout.eraselnFromCursor();
      StringBuffer buffer = StringBuffer();

      String hour = activeHour.toString().padVisibleLeft(timePaddingSizes.hour, "0");
      String minute = activeMinute.toString().padVisibleLeft(timePaddingSizes.minute, "0");
      String meridiem = activeMeridiem.toString().padVisibleLeft(timePaddingSizes.meridiem, "0");

      /// Indentation
      buffer.write(" " * timePadding);
      buffer.write("│");

      /// HH
      buffer.write(hour.inverted(iff: focus == _Focus.hour));
      buffer.write(" : ");

      /// MM
      buffer.write(minute.inverted(iff: focus == _Focus.minute));
      buffer.write(" : ");

      /// AM/PM
      buffer.write(meridiem.inverted(iff: focus == _Focus.meridiem));
      buffer.write("│");

      stdout.write$(buffer);
    }

    void displayLowerControl() {
      stdout.eraselnFromCursor();
      StringBuffer buffer = StringBuffer();

      /// Indentation
      buffer.write(" " * timePadding);
      buffer.write("│");

      /// HH
      buffer.write("v".padVisibleLeft(timePaddingSizes.hour).brightBlack());
      buffer.write("   ");

      /// MM
      buffer.write("v".padVisibleLeft(timePaddingSizes.minute).brightBlack());
      buffer.write("   ");

      /// AM/PM
      buffer.write(" ".padVisibleLeft(timePaddingSizes.meridiem).brightBlack());
      buffer.write("│");

      stdout.write$(buffer);
    }

    String displayTitleCard({bool iff = true}) {
      // A String with the format "<Year Month Day>"

      StringBuffer buffer = StringBuffer();
      buffer.write("<");
      buffer.write("$activeYear".padLeft(4).inverted(iff: focus == _Focus.year));
      buffer.write(" ");
      buffer.write(DateExtension.monthNames[activeMonth - 1].inverted(iff: focus == _Focus.month));
      buffer.write(" ");
      buffer.write("$activeDay".padLeft(2, "0").inverted(iff: focus == _Focus.day));
      buffer.write(">");

      if (iff) {
        stdout.write(buffer);
      }
      return buffer.toString();
    }

    String displayDayLabels({bool iff = true}) {
      // Print the labels for the days of the week
      StringBuffer buffer = StringBuffer();
      buffer.write("│");
      for (int i = 0; i < daysInAWeek; ++i) {
        String paddedDisplay = daysOfTheWeek[i].padVisibleLeft(paddingSize);
        String formattedDisplay = switch (i) {
          0 => paddedDisplay.brightRed(),
          _ => paddedDisplay,
        };

        // If it is sunday, print it red.
        buffer.write(formattedDisplay);
      }
      buffer.write("│");

      if (iff) {
        stdout.write(buffer);
      }

      return buffer.toString();
    }

    void displayCalendarRow(int y, {bool isActiveColorEnabled = true}) {
      StringBuffer buffer = StringBuffer();
      buffer.write("│");
      for (int x = 0; x < daysInAWeek; ++x) {
        int day = calendarGrid[y][x];

        bool isFocused = focus == _Focus.calendarBody;
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

        buffer.write(display);
      }

      buffer.write("│");
      int move = stdout.write$(buffer);
      stdout.moveRight(move);
      if (y == 0) {
        displayUpperControl();
      } else if (y == 1) {
        displayClock();

        /// Display the bottom bar.
      } else if (y == 2) {
        displayLowerControl();
      }
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

    void goToTitle() {
      stdout.movelnUp(activeY + 1 /** Weekday Label */ + 1 /** Title Card */);
    }

    void updateCalendar() {
      goToTitle();
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

      if (activeX > daysInAWeek - 1) {
        activeX %= daysInAWeek;
        activeY += 1;
        stdout.moveDown();
      } else if (activeX < 0) {
        activeX %= daysInAWeek;
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
        activeDay -= daysInAWeek;
      } else if (activeY > calendarHeight - 1) {
        activeDay += daysInAWeek;
      } else {
        activeDay += difference * daysInAWeek;
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

    void eraseScreen() {
      int increment = hasFailed ? 1 : 0;

      if (focus case _Focus.hour || _Focus.minute || _Focus.meridiem) {
        stdout.moveLeft(displayDayLabels(iff: false).visibleLength);
        stdout
            .moveUp(1 /* Second Row */ + 1 /** Weekday Label */ + 1 /** Title Card */ + increment);
      }
      if (focus case _Focus.calendarBody) {
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
      focus = to;
      displayCalendarRow(activeY);

      /// Rerender the title.
      stdout.moveUp(activeY + 1 /** Weekday Label */ + 1 /** Title Card */);
      stdout.eraseln();
      displayTitleCard();
    }

    void moveToTimeFromCalendar(_Focus to) {
      stdout.eraseln();
      focus = to;
      displayCalendarRow(activeY);

      goToTitle();
      stdout.moveDown(1 /* Date card */ + 1 /* Labels */ + 1 /* The top controls */);
      stdout.moveRight(displayDayLabels(iff: false).visibleLength);

      displayClock();
    }

    void moveToTimeFromTime(_Focus to) {
      stdout.eraselnFromCursor();
      focus = to;
      displayClock();
    }

    void moveToTitleFromTime(_Focus to) {
      stdout.eraselnFromCursor();
      focus = to;
      displayClock();

      stdout.moveLeft(displayDayLabels(iff: false).visibleLength);
      stdout.moveUp(1 /* First row */ + 1 /* Labels */ + 1 /* Title */);

      stdout.eraselnFromCursor();
      displayTitleCard();
    }

    void moveToCalendarFromTime(_Focus to) {
      stdout.eraselnFromCursor();
      focus = to;
      displayClock();

      stdout.moveLeft(displayDayLabels(iff: false).visibleLength);
      stdout.moveUp(1 /* First row */ + 1 /* Labels */ + 1 /* Title */);
      stdout.moveDown(activeY + 1 /* First Row */ + 1 /* Labels */);

      stdout.eraselnFromCursor();
      displayCalendarRow(activeY);
    }

    void moveToTimeFromTitle(_Focus to) {
      stdout.eraseln();
      focus = to;
      String displayed = displayTitleCard();

      stdout.moveLeft(displayed.visibleLength);
      stdout.moveDown(1 /* Date card */ + 1 /* Labels */ + 1 /* The top controls */);
      stdout.moveRight(displayDayLabels(iff: false).visibleLength);
      stdout.eraselnFromCursor();
      displayClock();
    }

    try {
      stdout.push();
      stdout.hideCursor();
      List<int>? deferredInput;

      outer:
      for (;;) {
        computeActives();

        if (!hasFailed) {
          stdout.write("?".color(accentColor));
        } else {
          stdout.write("!".color(Colors.brightRed));
        }
        stdout.write(" $question ");
        if (hint != null) {
          stdout.write("($hint)".brightBlack());
        }
        stdout.writeln();

        displayCalendar();

        switch (focus) {
          case _Focus.year:
          case _Focus.month:
          case _Focus.day:
            stdout.moveUp(calendarHeight);
          case _Focus.calendarBody:
            stdout.moveUp(calendarHeight - activeY);
          case _Focus.hour:
          case _Focus.minute:
          case _Focus.meridiem:
            stdout.moveUp(4);
            stdout.moveRight(displayDayLabels(iff: false).visibleLength);
        }

        loop:
        for (List<int> code
            in <List<int>?>[deferredInput].whereType<List<int>>().followedBy(stdin.sync)) {
          deferredInput = null;

          switch (code) {
            case <int>[0x3]:
              throw SignalInterruptionException();
            case <int>[0x9]:
              // tab
              switch (focus) {
                case _Focus.calendarBody:
                  moveToTimeFromCalendar(_Focus.hour);
                case _Focus.year:
                  moveToTitleFromTitle(_Focus.month);
                case _Focus.month:
                  moveToTitleFromTitle(_Focus.day);
                case _Focus.day:
                  moveToCalendarFromTitle(_Focus.calendarBody);
                case _Focus.hour:
                  moveToTimeFromTime(_Focus.minute);
                case _Focus.minute:
                  moveToTimeFromTime(_Focus.meridiem);
                case _Focus.meridiem:
                  moveToTitleFromTime(_Focus.year);
              }
            case <int>[0x1b, 0x5b, 0x5a]:
              // shift + tab
              switch (focus) {
                case _Focus.calendarBody:
                  moveToTitleFromCalendar(_Focus.day);
                case _Focus.day:
                  moveToTitleFromTitle(_Focus.month);
                case _Focus.month:
                  moveToTitleFromTitle(_Focus.year);
                case _Focus.year:
                  moveToTimeFromTitle(_Focus.meridiem);
                case _Focus.hour:
                  moveToCalendarFromTime(_Focus.calendarBody);
                case _Focus.minute:
                  moveToTimeFromTime(_Focus.hour);
                case _Focus.meridiem:
                  moveToTimeFromTime(_Focus.minute);
              }
            case <int>[0x0d]:
              // enter
              break loop;

            case <int>[0x1b, 0x5b, 0x41]:
            case <int>[0x1b, 0x5b, 0x42]:
            case <int>[0x1b, 0x5b, 0x43]:
            case <int>[0x1b, 0x5b, 0x44]:
              if (hasFailed) {
                eraseScreen();
                hasFailed = false;
                deferredInput = code;
                continue outer;
              }
              continue continuation;

            continuation:
            case _:
              void titularRefreshCalendar() {
                stdout.eraselnDown(calendarHeight + 1 /** Weekday Label */ + 1 /** Title Card */);

                computeActives();
                displayCalendar();

                stdout.moveUp(calendarHeight + 1 /** Weekday Label */ + 1 /** Title Card */);
              }

              void refreshTime() {
                stdout.eraselnFromCursor();

                displayClock();
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
                case _Focus.calendarBody:
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
                case _Focus.hour:
                  switch (code) {
                    case <int>[0x1b, 0x5b, 0x41]:
                      // up

                      /// An increment operation is done by (mod 12) + 1.
                      activeHour -= 1;
                      activeHour += 1;
                      activeHour %= 12;
                      if (activeHour == 11) {
                        activeMeridiem = activeMeridiem.inverse;
                      }

                      activeHour += 1;
                      refreshTime();
                    case <int>[0x1b, 0x5b, 0x42]:
                      // down

                      activeHour -= 1;
                      activeHour -= 1;
                      activeHour %= 12;
                      if (activeHour == 10) {
                        activeMeridiem = activeMeridiem.inverse;
                      }

                      activeHour += 1;
                      refreshTime();
                    case <int>[0x1b, 0x5b, 0x43]:
                      // right
                      moveToTimeFromTime(_Focus.minute);
                    case <int>[0x1b, 0x5b, 0x44]:
                      // left
                      moveToTimeFromTime(_Focus.meridiem);
                  }
                case _Focus.minute:
                  switch (code) {
                    case <int>[0x1b, 0x5b, 0x41]:
                      // up
                      activeMinute -= 1;
                      refreshTime();
                    case <int>[0x1b, 0x5b, 0x42]:
                      // down
                      activeMinute += 1;
                      refreshTime();
                    case <int>[0x1b, 0x5b, 0x43]:
                      // right
                      moveToTimeFromTime(_Focus.meridiem);
                    case <int>[0x1b, 0x5b, 0x44]:
                      // left
                      moveToTimeFromTime(_Focus.hour);
                  }
                case _Focus.meridiem:
                  switch (code) {
                    case <int>[0x1b, 0x5b, 0x41]:
                      // up
                      activeMeridiem = activeMeridiem.inverse;
                      refreshTime();
                    case <int>[0x1b, 0x5b, 0x42]:
                      // down
                      activeMeridiem = activeMeridiem.inverse;
                      refreshTime();
                    case <int>[0x1b, 0x5b, 0x43]:
                      // right
                      moveToTimeFromTime(_Focus.hour);
                    case <int>[0x1b, 0x5b, 0x44]:
                      // left
                      moveToTimeFromTime(_Focus.minute);
                  }
              }
          }
        }

        /// When the loop is broken, we move downwards.
        eraseScreen();
        active = computeActiveDateTime();

        if (guard?.call(active) case False(:String failure)) {
          hasFailed = true;
          stdout.writeln("// $failure".brightRed());

          continue;
        } else {
          break;
        }
      }

      stdout.write("+".color(accentColor));
      stdout.write(" $question ");
      stdout.writeln(active.toAMPMDateTimeString().color(accentColor));

      return Success<DateTime>(active);
    } on SignalInterruptionException {
      eraseScreen();

      stdout.write("!".brightRed());
      stdout.write(" $question ");
      stdout.writeln("^C".brightBlack());

      return const Failure<DateTime>("^C");
    } finally {
      stdout.pop();
    }
  }
}

extension PromptDateTimeExtension on BasePrompt {
  Option<DateTime> dateTime(
    String question, {
    DateTime? start,
    Guard<DateTime>? guard,
    String? hint,
    bool minimal = DateTimePromptDefaults.minimal,
    Color accentColor = DateTimePromptDefaults.accentColor,
  }) =>
      dateTimePrompt(
        question,
        start: start,
        guard: guard,
        hint: hint,
        minimal: minimal,
        accentColor: accentColor,
      );
}
