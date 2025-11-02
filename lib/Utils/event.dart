import 'package:flutter/material.dart';

/// Event model consumed by JalaliTableCalendar to render day indicators.
/// Use factory constructors to create instances from Unix timestamps.
class CalendarEvent {
  final String id;
  final String title;
  /// Date of the event (day resolution). Time component is ignored for dot grouping.
  final DateTime date;
  final bool isHoliday;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Color color;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.color,
    this.isHoliday = false,
    this.startTime,
    this.endTime,
  });

  /// Create from unix timestamp in SECONDS.
  factory CalendarEvent.fromUnixSeconds({
    required String id,
    required String title,
    required int epochSeconds,
    required Color color,
    bool isHoliday = false,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000, isUtc: false);
    // Normalize to Y-M-D (local)
    final day = DateTime(dt.year, dt.month, dt.day);
    return CalendarEvent(
      id: id,
      title: title,
      date: day,
      color: color,
      isHoliday: isHoliday,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Create from unix timestamp in MILLISECONDS.
  factory CalendarEvent.fromUnixMilliseconds({
    required String id,
    required String title,
    required int epochMilliseconds,
    required Color color,
    bool isHoliday = false,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMilliseconds, isUtc: false);
    // Normalize to Y-M-D (local)
    final day = DateTime(dt.year, dt.month, dt.day);
    return CalendarEvent(
      id: id,
      title: title,
      date: day,
      color: color,
      isHoliday: isHoliday,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Check if this event occurs on the provided day (local date).
  bool occursOn(DateTime day) =>
      date.year == day.year && date.month == day.month && date.day == day.day;
}