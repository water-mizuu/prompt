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
  static const Color accentColor = Color.brightBlue;
}

const List<String> _daysOfTheWeek = <String>["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

enum _Focus {
  year,
  month,
  day,
  calendar;
}

Result<DateTime> datePrompt(
  String question, {
  DateTime? start,
  bool minimal = DatePromptDefaults.minimal,
  Color accentColor = DatePromptDefaults.accentColor,
}) {
  String formattedQuestion = question.bold();
  start ??= DateTime.now();

  // Constants that will be used in the program in building the calendar.
  const int paddingSize = 4;
  const int calendarWidth = 7;

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

    skippedDays = currentMonth.weekday % 7;
    monthIndex = activeMonth - 1;

    previousDaysOfTheMonth = DateTime(previousMonth.year, previousMonth.month + 1, 0).day;
    daysOfTheMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    calendarHeight = ((skippedDays + daysOfTheMonth) / calendarWidth).ceil();

    calendarGrid = List2<int>.generate(
      calendarHeight,
      (int y) => List<int>.generate(
        calendarWidth,
        (int x) => (y * calendarWidth + x) - skippedDays + 1,
      ),
    );

    active = DateTime(activeYear, activeMonth, activeDay);
    activeX = active.weekday % 7;
    activeY = (skippedDays + activeDay - 1) ~/ calendarWidth;
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
    StringBuffer dayOfTheWeekBuffer = StringBuffer("│");
    for (int i = 0; i < 7; ++i) {
      String paddedDisplay = _daysOfTheWeek[i].padVisibleLeft(paddingSize);
      String formattedDisplay = switch (i) {
        0 => paddedDisplay.brightRed(),
        _ => paddedDisplay,
      };

      // If it is sunday, print it red.
      dayOfTheWeekBuffer.write(formattedDisplay);
    }
    dayOfTheWeekBuffer.write("│");
    stdout.write$(dayOfTheWeekBuffer.toString());
  }

  void displayCalendarRow(int y, {bool isActiveColorDisabled = false}) {
    StringBuffer stream = StringBuffer("│");

    for (int x = 0; x < calendarWidth; ++x) {
      int day = calendarGrid[y][x];

      Color color = switch (day) {
        < 1 => Color.brightBlack,
        _ when day > daysOfTheMonth => Color.brightBlack,
        _ when x == 0 => Color.brightRed,
        _ => Color.reset,
      };

      String toDisplay = switch (day) {
        _
            when focus == _Focus.calendar && //
                !isActiveColorDisabled &&
                y == activeY &&
                x == activeX =>
          day.toString().inverted(),
        _ when day < 1 => //
          (previousDaysOfTheMonth + day).toString(),
        _ when day > daysOfTheMonth => //
          (day - daysOfTheMonth).toString(),
        _ => //
          day.toString(),
      } //
          .color(color);

      String paddedDisplay = toDisplay.padVisibleLeft(paddingSize);
      String formattedDisplay = paddedDisplay;

      stream.write(formattedDisplay);
    }

    stream.write("│");
    stdout.write$(stream.toString());
  }

  void displayActiveMonth() {
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
    stdout.movelnUp(activeY + 2);
    stdout.eraselnDown(calendarHeight + 1);

    computeActives();
    displayActiveMonth();

    stdout.movelnUp(calendarHeight - activeY);
  }

  void updateTitleCard() {
    stdout.moveUp(activeY + 2);
    stdout.eraseln();
    displayTitleCard();
    stdout.moveDown(activeY + 2);
  }

  void moveHorizontal(int difference) {
    activeX += difference;

    stdout.eraseln();
    displayCalendarRow(activeY, isActiveColorDisabled: true);

    if (activeX > calendarWidth - 1) {
      activeX %= calendarWidth;
      activeY += 1;
      stdout.moveDown();
    } else if (activeX < 0) {
      activeX %= calendarWidth;
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

    if (activeDay > daysOfTheMonth || activeDay < 1) {
      updateCalendar();
    } else {
      stdout.eraseln();
      displayCalendarRow(activeY);
      updateTitleCard();
    }
  }

  void moveVertical(int difference) {
    stdout.eraseln();
    displayCalendarRow(activeY, isActiveColorDisabled: true);

    activeY += difference;
    stdout.moveVertical(difference);

    if (activeY < 0) {
      activeDay -= 7;
    } else if (activeY > calendarHeight - 1) {
      activeDay += 7;
    } else {
      activeDay += difference * 7;
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
    if (focus case _Focus.calendar) {
      stdout.moveUp(activeY + 2);
    }
    stdout.moveUp();

    stdout.eraselnDown(calendarHeight + 3);
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

    displayActiveMonth();
    stdout.moveUp(calendarHeight - activeY);
  }

  void moveToTitleFromCalendar(_Focus to) {
    /// Remove the focus from the calendar.
    stdout.eraseln();
    displayCalendarRow(activeY, isActiveColorDisabled: true);

    focus = to;

    /// Rerender the title.
    stdout.moveUp(activeY + 2);
    stdout.eraseln();
    displayTitleCard();
  }

  computeActives();

  {
    StringBuffer buffer = StringBuffer()
      ..write("?".color(accentColor))
      ..write(" $formattedQuestion ");

    stdout.write$(buffer);
    stdout.moveDown();
  }

  displayActiveMonth();

  stdout.moveUp(calendarHeight - activeY);
  try {
    stdout.push();
    stdout.hideCursor();

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
        default:
          void titularRefreshCalendar() {
            stdout.eraselnDown(calendarHeight + 2);

            computeActives();
            displayActiveMonth();

            stdout.moveUp(calendarHeight + 2);
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
    stdout.write("+".color(accentColor));
    stdout.write(" $formattedQuestion ");
    stdout.write(active.toDateString().color(accentColor));
    stdout.writeln();

    return Success<DateTime>(active);
  } on SignalInterruptionException {
    clearScreen();

    {
      StringBuffer buffer = StringBuffer()
        ..write("!".brightRed())
        ..write(" $formattedQuestion ")
        ..write("^C".brightBlack());

      stdout.writeln$(buffer);
    }

    return const Failure<DateTime>("^C");
  } finally {
    stdout.pop();
  }
}

extension PromptDateExtension on BasePrompt {
  Result<DateTime> date(
    String question, {
    DateTime? start,
    String? example,
    bool minimal = DatePromptDefaults.minimal,
    Color accentColor = DatePromptDefaults.accentColor,
  }) =>
      datePrompt(question, start: start, accentColor: accentColor);
}
