# Jalali  Table Calendar Plus

A rewritten package of [jalali_table_calendar](https://pub.dev/packages/jalali_table_calendar)

## Jalali Calendar

- Table view of the calendar
- Range selection
- Customizable holidays
- Modal for date selection
- Event list definition for each date
- Custom marker definition for each day

## Setup

### Add this line to the pubspec.yaml file

```yaml
jalali_table_calendar_plus: ^1.1.3
```

```dart
Widget buildCalendar(BuildContext context) {
  DateTime today = DateUtils.dateOnly(DateTime.now());
  Map <DateTime, List<dynamic>>events = {
    today: ['sample event', 26],
    today.add(const Duration(days: 1)): ['all types can use here', {"key": "value"}],
  };
  return JalaliTableCalendar(
    events: events,
    range: range,
    option: JalaliTableCalendarOption(
      daysOfWeekTitles: [
        "شنبه",
        "یکشنبه",
        "دوشنبه",
        "سه شنبه",
        "چهارشنبه",
        "پنجشنبه",
        "جمعه"
      ],
    ),
    customHolyDays: [
      // use jalali month and day for this
      HolyDay(month: 4, day: 10), // For Repeated Days
      HolyDay(year: 1404, month: 1, day: 26), // For Only One Day
    ],
    onRangeSelected: (selectedDates) {
      for (DateTime date in selectedDates) {
        print(date);
      }
    },
    marker: (date, event) {
      if (event.isNotEmpty) {
        return Positioned(
            top: -2,
            left: 1,
            child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.blue),
                child: Text(event.length.toString())));
      }
      return null;
    },
    onDaySelected: (DateTime date) {},
  );
}

```

## HolyDays

HolyDay(year: Jalai_Year , month: Jalai_Month, day: Jalai_Day)

| Parameter | Usage       | Data Type |
 |-----------|-------------|-----------|
| year      | Jalai Year  | Int       |
| month     | Jalai Month | Int       |
| day       | Jalai Day   | Int       |

## Parameters

| Parameter       | Usage                                                | Data Type                                         |
|-----------------|------------------------------------------------------|---------------------------------------------------|
| events          | A map of events for each day                         | Map <DateTime,List<dynamic>>                      |
| range           | Used for range selection                             | bool                                              |
| customHolyDays  | A list of customizable holidays                      | List<HolyDay> HolyDay(year:Int,month:Int,day:Int) |
| onRangeSelected | Method executed after range selection is completed	  | List<DateTime>                                    |
| onDaySelected   | Method executed after single date selection          | DateTime                                          |
| marker          | Method to receive user-designed markers for each day | (DateTime date, List<dynamic> eventsOfDay)        |

## تقویم جلالی

بازنویسی شده پکیج   [jalal_table_calendar](https://pub.dev/packages/jalali_table_calendar)

- نمای جدولی تقویم
- انتخاب به صورت بازه ای
- تعریف تعطیلات به صورت شخصی سازی شده
- مودال برای انتخاب تاریخ
- تعریف لیست رویداد ها برای هر تاریخ
- تعریف مارکر مخصوص برای هر روز

## راه اندازی

### این خط را به فایل  pubspec.yaml اضافه کنید

```yaml
jalali_table_calendar_plus: ^1.1.3
```

```dart
Widget buildCalendar(BuildContext context) {
  DateTime today = DateUtils.dateOnly(DateTime.now());
  Map <DateTime, List<dynamic>>events = {
    today: ['sample event', 26],
    today.add(const Duration(days: 1)): ['all types can use here', {"key": "value"}],
  };
  return JalaliTableCalendar(
    events: events,
    range: range,
    customHolyDays: [
      // use jalali month and day for this
      HolyDay(month: 4, day: 10), // For Repeated Days
      HolyDay(year: 1404, month: 1, day: 26), // For Only One Day
    ],
    onRangeSelected: (selectedDates) {
      for (DateTime date in selectedDates) {
        print(date);
      }
    },
    marker: (date, event) {
      if (event.isNotEmpty) {
        return Positioned(
            top: -2,
            left: 1,
            child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.blue),
                child: Text(event.length.toString())));
      }
      return null;
    },
    onDaySelected: (DateTime date) {},
  );
}

```

## HolyDays

HolyDay(year: Jalai_Year , month: Jalai_Month, day: Jalai_Day)

| پارامتر | کاربرد    | Data Type |
|---------|-----------|-----------|
| year    | سال جلالی | Int       |
| month   | ماه جلالی | Int       |
| day     | روز جلالی | Int       |

## پارامتر ها

| پارامتر         | کاربرد                                                            | نوع داده                                          |
|-----------------|-------------------------------------------------------------------|---------------------------------------------------|
| events          | یک Map از رویداد های هر روز                                       | Map <DateTime,List<dynamic>>                      |
| range           | برای انتخاب بازه ای استفاده میشود                                 | bool                                              |
| customHolyDays  | لیستی از تطیلات شخصی سازی شده                                     | List<HolyDay> HolyDay(year:Int,month:Int,day:Int) |
| onRangeSelected | متدی که بعد از اتمام انتخاب بازه ای اجرا میشود                    | List<DateTime>                                    |
| onDaySelected   | متدی که بعد از انتخاب تاریخ در حالت تکی اجرا میشود                | DateTime                                          |
| marker          | متد ساخت مارکر های طراحی شده کاربر را برای هر روز را دریافت میکند | (DateTime date, List<dynamic> eventsOfDay)        |



## Weekly View (JalaliWeekView) with JalaliTableCalendarOption

JalaliWeekView supports the same JalaliTableCalendarOption you use in the monthly view. You can control:
- showHeader: show/hide the internal header bar
- showHeaderArrows: show/hide the navigation chevrons
- headerPadding: padding around the header
- weekStartDay: starting day of the week (saturday/sunday/monday/…)
- daysOfWeekTitles: custom titles for weekday header (must be length 7)
- weekendDays: customize weekend weekdays by ISO number (1=Mon … 7=Sun)

Minimal example:
```dart
import 'package:flutter/material.dart';
import 'package:jalali_table_calendar_plus/jalali_table_calendar_plus.dart';

class WeeklyDemo extends StatelessWidget {
  const WeeklyDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: JalaliWeekView(
        mainCalendar: CalendarType.jalali,
        initialDate: DateTime.now(),
        // Use JalaliTableCalendarOption to configure header + week start
        option: JalaliTableCalendarOption(
          showHeader: true,
          showHeaderArrows: true,
          headerPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          // Set week start day (e.g., monday, saturday, etc.)
          weekStartDay: WeekStartDay.saturday,
          // Optional: override weekday titles (length must be 7)
          daysOfWeekTitles: const ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'],
          // Optional: customize weekend days by ISO weekday (1=Mon..7=Sun).
          // For Jalali/Hijri typically Friday is weekend => 5
          weekendDays: const [5],
        ),
        // Optional extras:
        selectedDate: DateTime.now(),
        onDaySelected: (DateTime d) {
          debugPrint('Selected day in weekly view: $d');
        },
        // Supply your events list if you use the schedule grid
        calendarEvents: const [],
      ),
    );
  }
}
```

Hide the built-in header:
```dart
JalaliWeekView(
  initialDate: DateTime.now(),
  option: JalaliTableCalendarOption(
    showHeader: false,         // hides the header bar
    // showHeaderArrows is ignored when header is hidden
    weekStartDay: WeekStartDay.monday,
  ),
)
```

Start week on Monday and set custom weekday titles:
```dart
JalaliWeekView(
  initialDate: DateTime.now(),
  option: JalaliTableCalendarOption(
    showHeader: true,
    showHeaderArrows: true,
    weekStartDay: WeekStartDay.monday,
    daysOfWeekTitles: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    // If you use Gregorian and want weekend on Sunday:
    weekendDays: const [7], // 7 = Sunday
  ),
)
```

Notes:
- weekStartDay also affects the page navigation math and the 7-day range the view shows.
- daysOfWeekTitles must be length 7 or an assertion will throw.
- weekendDays controls only weekend highlighting; actual holiday detection still depends on your events/holiday sources.
