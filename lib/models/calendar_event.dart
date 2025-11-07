class CalendarEvent {
  final int month;
  final int day;
  final String title;
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
    return CalendarEvent(
      month: json['month'] as int,
      day: json['day'] as int,
      title: json['title'] as String,
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
}