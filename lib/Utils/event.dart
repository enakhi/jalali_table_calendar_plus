import 'package:flutter/material.dart';

/// UserEvent model consumed by JalaliTableCalendar to render user-created events.
/// Use factory constructors to create instances from Unix timestamps.
class UserEvent {
  final String userEventId;
  final String userEventTitle;
  /// Start date of the event (day resolution). Time component is ignored for dot grouping.
  final DateTime userEventDate;
  /// Optional end date (day resolution, inclusive). When null, equals userEventDate.
  final DateTime? userEventEndDate;
  final bool isEntireday;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Color userEventColor;
  final Color userEventBorderColor;

  UserEvent({
    required this.userEventId,
    required this.userEventTitle,
    required this.userEventDate,
    this.userEventEndDate,
    required Color userEventColor,
    Color? userEventBorderColor,
    this.isEntireday = false,
    this.startTime,
    this.endTime,
  })  : userEventColor = userEventColor,
        userEventBorderColor = userEventBorderColor ?? _deriveBorder(userEventColor);

  /// Create from unix timestamp in SECONDS.
  factory UserEvent.fromUnixSeconds({
    required String userEventId,
    required String userEventTitle,
    required int epochSeconds,
    required Color userEventColor,
    Color? userEventBorderColor,
    bool? isEntireday,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000, isUtc: false);
    // Normalize to Y-M-D (local)
    final day = DateTime(dt.year, dt.month, dt.day);
    final bool entire = isEntireday ?? false;
    return UserEvent(
      userEventId: userEventId,
      userEventTitle: userEventTitle,
      userEventDate: day,
      userEventColor: userEventColor,
      userEventBorderColor: userEventBorderColor ?? _deriveBorder(userEventColor),
      isEntireday: entire,
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
    Color? userEventBorderColor,
    bool? isEntireday,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMilliseconds, isUtc: false);
    // Normalize to Y-M-D (local)
    final day = DateTime(dt.year, dt.month, dt.day);
    final bool entire = isEntireday ?? false;
    return UserEvent(
      userEventId: userEventId,
      userEventTitle: userEventTitle,
      userEventDate: day,
      userEventColor: userEventColor,
      userEventBorderColor: userEventBorderColor ?? _deriveBorder(userEventColor),
      isEntireday: entire,
      startTime: startTime,
      endTime: endTime,
    );
  }

  // Derive a border color from the fill color if none is provided.
  static Color _deriveBorder(Color c) {
    final h = HSLColor.fromColor(c);
    final double l = (h.lightness * 0.7).clamp(0.0, 1.0);
    return h.withLightness(l).toColor();
  }

  /// Check if this event occurs on the provided day (local date).
  /// If userEventEndDate is set, treat the event as spanning from userEventDate to end (inclusive).
  bool occursOn(DateTime day) {
    final DateTime d = DateTime(day.year, day.month, day.day);
    final DateTime start = DateTime(userEventDate.year, userEventDate.month, userEventDate.day);
    final DateTime end = userEventEndDate == null
        ? start
        : DateTime(userEventEndDate!.year, userEventEndDate!.month, userEventEndDate!.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}