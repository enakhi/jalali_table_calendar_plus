import 'package:jalali_table_calendar_plus/Widget/table_calendar.dart';

class CalendarEvent {
  final int month;
  final int day;
  final Map<String, String> title;
  final bool holiday;
  final String type;
  final String calendar; // 'Persian', 'Hijri', 'Gregorian'
  final int? year; // Optional specific year in the event's calendar system

  CalendarEvent({
    required this.month,
    required this.day,
    required this.title,
    required this.holiday,
    required this.type,
    required this.calendar,
    this.year,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json, String calendar) {
    final titleRaw = json['title'];
    Map<String, String> title;
    if (titleRaw is Map<String, dynamic>) {
      title = titleRaw.cast<String, String>();
    } else if (titleRaw is String) {
      title = {'en': titleRaw};
    } else {
      title = {};
    }
    return CalendarEvent(
      month: json['month'] as int,
      day: json['day'] as int,
      title: title,
      holiday: json['holiday'] as bool? ?? false,
      type: json['type'] as String,
      calendar: calendar,
      year: json['year'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'day': day,
      'title': title,
      'holiday': holiday,
      'type': type,
      'calendar': calendar,
      'year': year,
    };
  }

  String getTitle(String? locale) {
    final lang = locale ?? 'en';
    if (title.containsKey(lang)) {
      final t = title[lang]!;
      if (t.isNotEmpty) return t;
    }
    return title['en'] ?? '';
  }

  /// Returns a formatted string with month name and day number
  /// The month name and number format are based on the calendar type
  /// If [locale] is provided, the month name will be in that language
  /// Examples:
  /// - For Persian calendar with no locale: "۱۰آذر"
  /// - For Gregorian calendar with 'en' locale: "9 dec"
  /// - For Persian calendar with 'en' locale: "10 azar"
  /// - For Gregorian calendar with 'fa' locale: "۹ دسامبر"
  String getFormattedMonthDay({String? locale}) {
    // Determine calendar type
    CalendarType calendarType;
    switch (calendar.toLowerCase()) {
      case 'persian':
      case 'jalali':
        calendarType = CalendarType.jalali;
        break;
      case 'hijri':
        calendarType = CalendarType.hijri;
        break;
      case 'gregorian':
      default:
        calendarType = CalendarType.gregorian;
        break;
    }

    // Get month names based on calendar type and locale
    List<String> monthNames;
    if (locale != null) {
      monthNames = getMonthNamesByLanguage(calendarType, locale);
    } else {
      monthNames = getMonthNames(calendarType);
    }

    // Get month name (adjust for 0-based index)
    String monthName = monthNames[month - 1];

    // Format day number based on calendar type or locale
    String formattedDay;
    if (locale != null) {
      formattedDay = convertNumbersBaseOfLanguge(day, locale);
    } else {
      formattedDay = convertNumbers(day, calendarType);
    }

    // Combine month name and day
    return '$formattedDay $monthName';
  }
}