import 'package:flutter/material.dart';

enum WeekStartDay { saturday, sunday, monday, tuesday, wednesday, thursday, friday }

class JalaliTableCalendarOption {
  final TextStyle? daysOfWeekStyle;
  final bool showHeader;
  final bool showHeaderArrows;
  final TextStyle? headerStyle;
  final TextStyle? daysStyle;
  final Color? currentDayColor;
  final Color? selectedDayShapeColor;
  final Color? selectedDayColor;
  final List<String>? daysOfWeekTitles;
  final EdgeInsets? headerPadding;
  final WeekStartDay weekStartDay;

  JalaliTableCalendarOption({
    this.daysOfWeekStyle,
    this.showHeader = true,
    this.showHeaderArrows = true,
    this.headerStyle,
    this.daysStyle,
    this.currentDayColor,
    this.selectedDayColor,
    this.selectedDayShapeColor,
    this.daysOfWeekTitles,
    this.headerPadding,
    this.weekStartDay = WeekStartDay.saturday,
  }) : assert(daysOfWeekTitles == null || daysOfWeekTitles.length == 7,
            "daysOfWeekTitles length must be 7");
}
