import 'package:flutter/material.dart';

enum WeekStartDay { saturday, sunday, monday, tuesday, wednesday, thursday, friday }

enum DayTitleBasedOn { language, calendar }

class JalaliTableCalendarOption {
  final TextStyle? daysOfWeekStyle;
  final bool showHeader;
  final bool showHeaderArrows;
  final TextStyle? headerStyle;
  final TextStyle? daysStyle;
  final Color? currentDayColor;
  final Color? selectedDayShapeColor;
  final Color? selectedDayColor;
  final Color? todayBackgroundColor;
  final Color? todayOnColor;
  final Color? selectedBackgroundColor;
  final Color? selectedOnColor;
  final List<String>? daysOfWeekTitles;
  final EdgeInsets? headerPadding;
  final WeekStartDay weekStartDay;
  final List<int>? weekendDays;
  final DayTitleBasedOn dayTitleBasedOn;
  final DayTitleBasedOn monthTitleBasedOn;
  final DayTitleBasedOn yearTitleBasedOn;
  final String language;

  JalaliTableCalendarOption({
    this.daysOfWeekStyle,
    this.showHeader = true,
    this.showHeaderArrows = true,
    this.headerStyle,
    this.daysStyle,
    this.currentDayColor,
    this.selectedDayColor,
    this.selectedDayShapeColor,
    this.todayBackgroundColor,
    this.todayOnColor,
    this.selectedBackgroundColor,
    this.selectedOnColor,
    this.daysOfWeekTitles,
    this.headerPadding,
    this.weekStartDay = WeekStartDay.saturday,
    this.weekendDays,
    this.dayTitleBasedOn = DayTitleBasedOn.calendar,
    this.monthTitleBasedOn = DayTitleBasedOn.calendar,
    this.yearTitleBasedOn = DayTitleBasedOn.calendar,
    this.language = 'en',
  }) : assert(daysOfWeekTitles == null || daysOfWeekTitles.length == 7,
            "daysOfWeekTitles length must be 7");
}
