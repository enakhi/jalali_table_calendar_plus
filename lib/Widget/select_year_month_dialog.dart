part of 'package:jalali_table_calendar_plus/Widget/table_calendar.dart';

/// Wrapper widget to use SelectYearMonth as a dialog
class SelectYearMonthDialog extends StatelessWidget {
  const SelectYearMonthDialog({
    super.key,
    required this.year,
    required this.month,
    required this.direction,
    required this.mainCalendar,
    required this.dayTitleBasedOn,
    required this.monthTitleBasedOn,
    required this.yearTitleBasedOn,
    required this.language,
  });

  final int year;
  final int month;
  final TextDirection direction;
  final CalendarType mainCalendar;
  final DayTitleBasedOn dayTitleBasedOn;
  final DayTitleBasedOn monthTitleBasedOn;
  final DayTitleBasedOn yearTitleBasedOn;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SelectYearMonth(
        year: year,
        month: month,
        direction: direction,
        mainCalendar: mainCalendar,
        dayTitleBasedOn: dayTitleBasedOn,
        monthTitleBasedOn: monthTitleBasedOn,
        yearTitleBasedOn: yearTitleBasedOn,
        language: language,
      ),
    );
  }
}