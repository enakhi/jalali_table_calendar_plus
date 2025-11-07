import 'package:flutter/material.dart';

/// UserEvent model consumed by JalaliTableCalendar to render day indicators.
/// Use factory constructors to create instances from Unix timestamps.
class UserEvent {
  final String userEventId;
  final String userEventTitle;
  /// Date of the event (day resolution). Time component is ignored for dot grouping.
  final DateTime userEventDate;
  final bool isHoliday;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Color userEventColor;

  const UserEvent({
    required this.userEventId,
    required this.userEventTitle,
    required this.userEventDate,
    required this.userEventColor,
    this.isHoliday = false,
    this.startTime,
    this.endTime,
  });

  /// Create from unix timestamp in SECONDS.
  factory UserEvent.fromUnixSeconds({
    required String userEventId,
    required String userEventTitle,
    required int epochSeconds,
    required Color userEventColor,
    bool isHoliday = false,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000, isUtc: false);
    // Normalize to Y-M-D (local)
    final day = DateTime(dt.year, dt.month, dt.day);
    return UserEvent(
      userEventId: userEventId,
      userEventTitle: userEventTitle,
      userEventDate: day,
      userEventColor: userEventColor,
      isHoliday: isHoliday,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Create from unix timestamp in MILLISECONDS.
  factory UserEvent.fromUnixMilliseconds({
    required String userEventId,
    required String userEventTitle,
    required int epochMilliseconds,
    required Color userEventColor,
    bool isHoliday = false,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMilliseconds, isUtc: false);
    // Normalize to Y-M-D (local)
    final day = DateTime(dt.year, dt.month, dt.day);
    return UserEvent(
      userEventId: userEventId,
      userEventTitle: userEventTitle,
      userEventDate: day,
      userEventColor: userEventColor,
      isHoliday: isHoliday,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Check if this event occurs on the provided day (local date).
  bool occursOn(DateTime day) =>
      userEventDate.year == day.year && userEventDate.month == day.month && userEventDate.day == day.day;
}