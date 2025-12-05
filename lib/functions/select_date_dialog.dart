import 'package:flutter/material.dart';
import 'package:jalali_table_calendar_plus/jalali_table_calendar_plus.dart';

Future<DateTime?> pickDate({
  required BuildContext context,
  TextDirection direction = TextDirection.rtl,
  Map<DateTime, List>? events,
  MarkerBuilder? marker,
  JalaliTableCalendarOption? option,
  DateTime? initialDate,
  bool useOfficialHolyDays = true,
  List<HolyDay> customHolyDays = const [],
  CalendarType mainCalendar = CalendarType.jalali,
}) async {
  DateTime? selectedDate = await showDialog<DateTime>(
    context: context,
    builder: (_) => _TableCalendarPicker(
      direction,
      events,
      marker,
      useOfficialHolyDays,
      customHolyDays,
      initialDate,
      mainCalendar,
      option,
    ),
  );
  return selectedDate;
}

class _TableCalendarPicker extends StatelessWidget {
  const _TableCalendarPicker(
    this.direction,
    this.events,
    this.marker,
    this.useOfficialHolyDays,
    this.customHolyDays,
    this.initialDate,
    this.mainCalendar,
    this.option
  );

  final TextDirection direction;
  final Map<DateTime, List>? events;
  final DateTime? initialDate;
  final MarkerBuilder? marker;
  final bool useOfficialHolyDays;
  final List<HolyDay> customHolyDays;
  final CalendarType mainCalendar;
  final JalaliTableCalendarOption? option;
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width / 100;
    double height = MediaQuery.of(context).size.height / 100;
    DateTime? selectedDate;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(vertical: height * 2, horizontal: width * 5),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: JalaliTableCalendar(
                initialDate: initialDate,
                direction: direction,
                customHolyDays: customHolyDays,
                events: events,
                useOfficialHolyDays: useOfficialHolyDays,
                marker: marker,
                option: option,
                mainCalendar: mainCalendar,
                viewType: CalendarViewType.schedule,
                onDaySelected: (date) {
                  selectedDate = date;
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, selectedDate);
                  },
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
