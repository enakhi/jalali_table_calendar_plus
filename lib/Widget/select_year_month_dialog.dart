part of 'package:jalali_table_calendar_plus/Widget/table_calendar.dart';

/// Wrapper widget to use SelectYearMonth as a dialog
class SelectYearMonthDialog extends StatelessWidget {
  const SelectYearMonthDialog({
    super.key,
    required this.year,
    required this.month,
    required this.direction,
    required this.mainCalendar,
  });

  final int year;
  final int month;
  final TextDirection direction;
  final CalendarType mainCalendar;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SelectYearMonth(
        year: year,
        month: month,
        direction: direction,
        mainCalendar: mainCalendar,
      ),
    );
  }
}