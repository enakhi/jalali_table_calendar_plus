import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:jalali_table_calendar_plus/Widget/table_calendar.dart' show CalendarType, convertNumbers, getMonthNames, getWeekdayNames, OnPageRangeChanged;
import 'package:jalali_table_calendar_plus/Utils/event.dart';
import 'package:jalali_table_calendar_plus/Utils/options.dart';

import 'package:jalali_table_calendar_plus/repositories/event_repository.dart';
/// Weekly time-grid view (Jalali friendly)
/// - Top row: All-day container (shows events with isEntireDay == true or events with no time)
/// - Left column: time labels
/// - 7 day columns: time grid from dayStartTime to dayEndTime
/// - Timed events are positioned by start/end within their day's column
///
/// Note: Provide dayStartTime/dayEndTime from your app settings.
/// If end <= start, the widget extends end to start + 12 hours.
class JalaliWeekView extends StatefulWidget {
  const JalaliWeekView({
    super.key,
    this.direction = TextDirection.rtl,
    this.initialDate,
    this.mainCalendar = CalendarType.jalali,
    this.weekStartDay = WeekStartDay.saturday,
    this.showHeader = true,
    this.showHeaderArrows = true,
    this.headerPadding = const EdgeInsets.all(16),
    this.option,
    this.calendarEvents,
    this.dayStartTime,
    this.dayEndTime,
    this.allDayRowHeight = 56,
    this.hourRowHeight = 64,
    this.timeColumnWidth = 68,
    this.eventMinHeight = 26,
    this.subCalendarLeft,
    this.subCalendarRight,
    this.allDayLabel = 'All Day',
    this.selectedDate,
    this.onDaySelected,
    // New: page range change listener (start, endExclusive)
    this.onPageRangeChanged,
    // New: header text change listener
    this.onHeaderTextChanged,
    // New: event tap listener
    this.onEventTap,
  });

  final TextDirection direction;
  final DateTime? initialDate;
  final CalendarType mainCalendar;
  final WeekStartDay weekStartDay;
  final bool showHeader;
  final bool showHeaderArrows;
  final EdgeInsets headerPadding;
  final JalaliTableCalendarOption? option;
  final List<UserEvent>? calendarEvents;
  final CalendarType? subCalendarLeft;
  final CalendarType? subCalendarRight;
  
  /// Work day bounds (from app settings). Defaults to 08:00 - 18:00 if not provided.
  final TimeOfDay? dayStartTime;
  final TimeOfDay? dayEndTime;
 
  /// Layout tuning
  final double allDayRowHeight;
  final double hourRowHeight;
  final double timeColumnWidth;
  final double eventMinHeight;
 
  /// Localized labels
  final String allDayLabel;
 
  /// Selected date for highlighting
  final DateTime? selectedDate;
 
  /// Callback when a day is selected
  final void Function(DateTime)? onDaySelected;
 
  /// Callback when visible week page changes (start..endExclusive)
  final OnPageRangeChanged? onPageRangeChanged;
 
  /// Callback for header text (month title) changes. Provides (title, year, month) in mainCalendar.
  final void Function(String title, int year, int month)? onHeaderTextChanged;
  
  /// Callback when an event is tapped. Provides the event ID.
  final void Function(String eventId)? onEventTap;

  @override
  JalaliWeekViewState createState() => JalaliWeekViewState();
}

extension JalaliWeekViewStateExtension on JalaliWeekViewState {
  void jumpToToday() {
    final now = DateTime.now();
    jumpToDate(now);
  }
 
  void jumpToDate(DateTime date) {
    final weekStart = _startOfWeek(date, _effectiveWeekStart);
    final initialWeekStart = _startOfWeek(widget.initialDate ?? DateTime.now(), _effectiveWeekStart);
    final weeksDiff = weekStart.difference(initialWeekStart).inDays ~/ 7;
    final page = 1000 + weeksDiff;
    _pageController.jumpToPage(page);
    // Update current week start
    setState(() {
      _currentWeekStart = weekStart;
    });
    // Emit range and header for programmatic jumps
    final DateTime endExclusive = weekStart.add(const Duration(days: 7));
    if (widget.onPageRangeChanged != null) {
      widget.onPageRangeChanged!(weekStart, endExclusive);
    }
    _emitHeaderChange(weekStart);
  }
}

class JalaliWeekViewState extends State<JalaliWeekView> {
  late DateTime _currentWeekStart;
  late PageController _pageController;

  // Repository for official holiday lookup
  late final EventRepository _eventRepository;
  bool _eventsLoaded = false;

  // Effective values resolved from JalaliTableCalendarOption when provided
  WeekStartDay get _effectiveWeekStart => widget.option?.weekStartDay ?? widget.weekStartDay;
  bool get _effectiveShowHeader => widget.option?.showHeader ?? widget.showHeader;
  bool get _effectiveShowHeaderArrows => widget.option?.showHeaderArrows ?? widget.showHeaderArrows;
  EdgeInsets get _effectiveHeaderPadding => widget.option?.headerPadding ?? widget.headerPadding;
  List<String>? get _customWeekTitles => widget.option?.daysOfWeekTitles;
  List<int>? get _customWeekendDays => widget.option?.weekendDays;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _startOfWeek(widget.initialDate ?? DateTime.now(), _effectiveWeekStart);
    _pageController = PageController(initialPage: 1000); // Start at a large page number for infinite scrolling
   
    _eventRepository = EventRepository();
    _eventRepository.loadEvents().then((_) {
      if (mounted) {
        setState(() {
          _eventsLoaded = true;
        });
      }
    });
 
    // Emit initial header and range after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitHeaderChange(_currentWeekStart);
      final DateTime endExclusive = _currentWeekStart.add(const Duration(days: 7));
      if (widget.onPageRangeChanged != null) {
        widget.onPageRangeChanged!(_currentWeekStart, endExclusive);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _startOfWeek(DateTime date, WeekStartDay start) {
    final int isoStart = _isoWeekdayForStart(start);
    final int iso = date.weekday;
    final int diff = (iso - isoStart + 7) % 7;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: diff));
  }

  int _isoWeekdayForStart(WeekStartDay start) {
    switch (start) {
      case WeekStartDay.monday: return 1;
      case WeekStartDay.tuesday: return 2;
      case WeekStartDay.wednesday: return 3;
      case WeekStartDay.thursday: return 4;
      case WeekStartDay.friday: return 5;
      case WeekStartDay.saturday: return 6;
      case WeekStartDay.sunday: return 7;
    }
  }

  // Repository-backed holiday resolver used by header
  bool _isHolidayFromRepoOrFallback(DateTime date) {
    try {
      if (_eventsLoaded) {
        final events = _eventRepository.getEventsForDate(date: date);
        if (events.any((e) => e.holiday)) return true;
      }
      const List<Map<String, int>> holyDays = [
        {'month': 1, 'day': 1},
        {'month': 1, 'day': 2},
        {'month': 1, 'day': 3},
        {'month': 1, 'day': 4},
        {'month': 1, 'day': 12},
        {'month': 1, 'day': 13},
        {'month': 3, 'day': 14},
        {'month': 3, 'day': 15},
      ];
      for (final hd in holyDays) {
        if (hd['month'] == date.month && hd['day'] == date.day) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
 
  void _emitHeaderChange(DateTime weekStart) {
    try {
      final monthNames = getMonthNames(widget.mainCalendar);
      final DateTime weekEnd = weekStart.add(const Duration(days: 6));

      late final int startYear;
      late final int startMonth;
      late final int endYear;
      late final int endMonth;

      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          final js = Jalali.fromDateTime(weekStart);
          final je = Jalali.fromDateTime(weekEnd);
          startYear = js.year;
          startMonth = js.month;
          endYear = je.year;
          endMonth = je.month;
          break;
        case CalendarType.hijri:
          final hs = HijriCalendar.fromDate(weekStart);
          final he = HijriCalendar.fromDate(weekEnd);
          startYear = hs.hYear;
          startMonth = hs.hMonth;
          endYear = he.hYear;
          endMonth = he.hMonth;
          break;
        case CalendarType.gregorian:
          startYear = weekStart.year;
          startMonth = weekStart.month;
          endYear = weekEnd.year;
          endMonth = weekEnd.month;
          break;
      }

      // Build a composite title when the visible week spans two months (or years)
      String title;
      if (startYear == endYear) {
        if (startMonth == endMonth) {
          title = '${monthNames[startMonth - 1]} ${convertNumbers(startYear, widget.mainCalendar)}';
        } else {
          title = '${monthNames[startMonth - 1]} – ${monthNames[endMonth - 1]} ${convertNumbers(startYear, widget.mainCalendar)}';
        }
      } else {
        title =
            '${monthNames[startMonth - 1]} ${convertNumbers(startYear, widget.mainCalendar)} – ${monthNames[endMonth - 1]} ${convertNumbers(endYear, widget.mainCalendar)}';
      }

      // Keep year/month payload based on the week start to preserve navigation semantics
      widget.onHeaderTextChanged?.call(title, startYear, startMonth);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Directionality(
      textDirection: widget.direction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_effectiveShowHeader)
            Padding(
              padding: _effectiveHeaderPadding,
              child: Row(
                mainAxisAlignment: _effectiveShowHeaderArrows
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (_effectiveShowHeaderArrows)
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      },
                    ),
                  Text(
                    _getHeaderText(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  if (_effectiveShowHeaderArrows)
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                // Calculate new week start based on page offset
                final int weekOffset = page - 1000;
                final DateTime base = _startOfWeek(widget.initialDate ?? DateTime.now(), _effectiveWeekStart);
                final DateTime weekStart = base.add(Duration(days: weekOffset * 7));
                setState(() {
                  _currentWeekStart = weekStart;
                });
                // Notify listener with week range (start..endExclusive)
                final DateTime endExclusive = weekStart.add(const Duration(days: 7));
                if (widget.onPageRangeChanged != null) {
                  widget.onPageRangeChanged!(weekStart, endExclusive);
                }
                // Emit header month/year for outer header
                _emitHeaderChange(weekStart);
              },
              itemBuilder: (context, pageIndex) {
                final int weekOffset = pageIndex - 1000;
                final DateTime weekStart = _startOfWeek(widget.initialDate ?? DateTime.now(), _effectiveWeekStart)
                    .add(Duration(days: weekOffset * 7));
                final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

                return Column(
                  children: [
                    _WeekDaysHeader(
                      mainCalendar: widget.mainCalendar,
                      direction: widget.direction,
                      weekStartDay: _effectiveWeekStart,
                      days: days,
                      timeColumnWidth: widget.timeColumnWidth,
                      theme: theme,
                      subCalendarLeft: widget.subCalendarLeft,
                      subCalendarRight: widget.subCalendarRight,
                      customTitles: _customWeekTitles,
                      customWeekendDays: _customWeekendDays,
                      selectedDate: widget.selectedDate,
                      onDaySelected: widget.onDaySelected,
                      isHolidayFn: _isHolidayFromRepoOrFallback,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        child: _WeekTimeGrid(
                          theme: theme,
                          mainCalendar: widget.mainCalendar,
                          days: days,
                          calendarEvents: widget.calendarEvents ?? const [],
                          dayStartTime: widget.dayStartTime ?? const TimeOfDay(hour: 8, minute: 0),
                          dayEndTime: widget.dayEndTime ?? const TimeOfDay(hour: 20, minute: 0),
                          allDayRowHeight: widget.allDayRowHeight,
                          hourRowHeight: widget.hourRowHeight,
                          timeColumnWidth: widget.timeColumnWidth,
                          eventMinHeight: widget.eventMinHeight,
                          direction: widget.direction,
                          allDayLabel: widget.allDayLabel,
                          onEventTap: widget.onEventTap,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderText() {
    final monthNames = getMonthNames(widget.mainCalendar);

    final DateTime start = _currentWeekStart;
    final DateTime end = _currentWeekStart.add(const Duration(days: 6));

    late final int startYear;
    late final int startMonth;
    late final int endYear;
    late final int endMonth;

    switch (widget.mainCalendar) {
      case CalendarType.jalali:
        final js = Jalali.fromDateTime(start);
        final je = Jalali.fromDateTime(end);
        startYear = js.year;
        startMonth = js.month;
        endYear = je.year;
        endMonth = je.month;
        break;
      case CalendarType.hijri:
        final hs = HijriCalendar.fromDate(start);
        final he = HijriCalendar.fromDate(end);
        startYear = hs.hYear;
        startMonth = hs.hMonth;
        endYear = he.hYear;
        endMonth = he.hMonth;
        break;
      case CalendarType.gregorian:
        startYear = start.year;
        startMonth = start.month;
        endYear = end.year;
        endMonth = end.month;
        break;
    }

    if (startYear == endYear) {
      if (startMonth == endMonth) {
        return '${monthNames[startMonth - 1]} ${convertNumbers(startYear, widget.mainCalendar)}';
      } else {
        return '${monthNames[startMonth - 1]} – ${monthNames[endMonth - 1]} ${convertNumbers(startYear, widget.mainCalendar)}';
      }
    } else {
      return '${monthNames[startMonth - 1]} ${convertNumbers(startYear, widget.mainCalendar)} – ${monthNames[endMonth - 1]} ${convertNumbers(endYear, widget.mainCalendar)}';
    }
  }

}

class _WeekDaysHeader extends StatelessWidget {
  const _WeekDaysHeader({
    required this.mainCalendar,
    required this.direction,
    required this.weekStartDay,
    required this.days,
    required this.timeColumnWidth,
    required this.theme,
    this.subCalendarLeft,
    this.subCalendarRight,
    this.customTitles,
    this.customWeekendDays,
    this.selectedDate,
    this.onDaySelected,
    required this.isHolidayFn,
  });

  final CalendarType mainCalendar;
  final TextDirection direction;
  final WeekStartDay weekStartDay;
  final List<DateTime> days;
  final double timeColumnWidth;
  final ThemeData theme;
  final CalendarType? subCalendarLeft;
  final CalendarType? subCalendarRight;
  final List<String>? customTitles;
  final List<int>? customWeekendDays;
  final DateTime? selectedDate;
  final void Function(DateTime)? onDaySelected;
  final bool Function(DateTime) isHolidayFn;

  @override
  Widget build(BuildContext context) {
    final titles = customTitles ?? getWeekdayNames(mainCalendar, direction); // Base Saturday-first
    final rotated = _rotateWeekdayTitles(titles, weekStartDay);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double gridWidth = constraints.maxWidth - (timeColumnWidth * 0.8);
        final double dayColumnWidth = gridWidth / 7;
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: timeColumnWidth * 0.8),
            ...List.generate(7, (i) {
              final d = days[i];
              final isSelected = selectedDate != null &&
                  d.year == selectedDate!.year &&
                  d.month == selectedDate!.month &&
                  d.day == selectedDate!.day;
              final isWeekend = _isWeekend(d);
              final isHoliday = isHolidayFn(d);
              final dayNum = switch (mainCalendar) {
                CalendarType.jalali => convertNumbers(Jalali.fromDateTime(d).day, mainCalendar),
                CalendarType.hijri => convertNumbers(HijriCalendar.fromDate(d).hDay, mainCalendar),
                CalendarType.gregorian => d.day.toString(),
              };
              final String? leftText = subCalendarLeft == null ? null : _secondaryDay(d, subCalendarLeft!);
              final String? rightText = subCalendarRight == null ? null : _secondaryDay(d, subCalendarRight!);
              final styleColor = isWeekend || isHoliday ? theme.colorScheme.primary : null;
              return Container(
                width: dayColumnWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: GestureDetector(
                    onTap: onDaySelected != null ? () => onDaySelected!(d) : null,
                    child: Column(
                      children: [
                        Text(
                          rotated[i],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: styleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: isSelected ? BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.05),
                                Colors.white.withOpacity(0.08),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.05),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                              ),
                            ],
                          ) : null,
                          child: Center(
                            child: Text(
                              dayNum,
                              style: TextStyle(
                                fontSize: 12,
                                color: styleColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(padding: const EdgeInsets.only(left:7,right: 7,top: 0,bottom: 0),child:
                        Row(
                          children: [
                            if (leftText != null)
                              Text(leftText, style: TextStyle(fontSize: 11, color: styleColor)),
                            const Spacer(),
                            if (rightText != null)
                              Text(rightText, style: TextStyle(fontSize: 11, color: styleColor)),
                          ],
                        )),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // Helper: base index for week start in a Saturday-first array (0..6)
  int _baseIndexForWeekStart(WeekStartDay start) {
    switch (start) {
      case WeekStartDay.saturday:
        return 0;
      case WeekStartDay.sunday:
        return 1;
      case WeekStartDay.monday:
        return 2;
      case WeekStartDay.tuesday:
        return 3;
      case WeekStartDay.wednesday:
        return 4;
      case WeekStartDay.thursday:
        return 5;
      case WeekStartDay.friday:
        return 6;
    }
  }

  // Rotate 7 weekday titles by the configured week start
  List<String> _rotateWeekdayTitles(List<String> titles, WeekStartDay start) {
    final int shift = _baseIndexForWeekStart(start);
    return List<String>.generate(7, (i) => titles[(shift + i) % 7]);
  }

  // Day number for a given secondary calendar type
  String _secondaryDay(DateTime d, CalendarType cal) {
    switch (cal) {
      case CalendarType.jalali:
        return convertNumbers(Jalali.fromDateTime(d).day, cal);
      case CalendarType.hijri:
        return convertNumbers(HijriCalendar.fromDate(d).hDay, cal);
      case CalendarType.gregorian:
        return d.day.toString();
    }
  }

  // Check if a date is a weekend
  bool _isWeekend(DateTime date) {
    // Weekend days can be customized via option; otherwise use defaults per calendar
    List<int> weekendDays = customWeekendDays ??
        (mainCalendar == CalendarType.gregorian ? [7] : [5]); // Jalali/Hijri: Friday (5), Gregorian: Sunday (7)
    return weekendDays.contains(date.weekday);
  }

}

class _WeekTimeGrid extends StatelessWidget {
  const _WeekTimeGrid({
    required this.theme,
    required this.mainCalendar,
    required this.days,
    required this.calendarEvents,
    required this.dayStartTime,
    required this.dayEndTime,
    required this.allDayRowHeight,
    required this.hourRowHeight,
    required this.timeColumnWidth,
    required this.eventMinHeight,
    required this.direction,
    required this.allDayLabel,
    this.onEventTap,
  });

  final ThemeData theme;
  final CalendarType mainCalendar;
  final List<DateTime> days;
  final List<UserEvent> calendarEvents;
  final TimeOfDay dayStartTime;
  final TimeOfDay dayEndTime;
  final double allDayRowHeight;
  final double hourRowHeight;
  final double timeColumnWidth;
  final double eventMinHeight;
  final TextDirection direction;
  final String allDayLabel;
  final void Function(String eventId)? onEventTap;

  @override
  Widget build(BuildContext context) {
    final int startMinutes = _toMinutes(dayStartTime);
    int endMinutes = _toMinutes(dayEndTime);
    if (endMinutes <= startMinutes) {
      endMinutes = startMinutes + 12 * 60; // ensure visible range
    }
    final int totalMinutes = endMinutes - startMinutes;
    final int hours = (totalMinutes / 60).ceil();

    // Split events: all-day vs timed, with support for multi-day spans
    final List<List<UserEvent>> allDayByDay = List.generate(7, (_) => []);
    final List<List<_Timed>> timedSegmentsByDay = List.generate(7, (_) => []);
    bool _sameYMD(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

    for (int di = 0; di < 7; di++) {
      final d = days[di];
      final dayEvents = calendarEvents.where((e) => e.occursOn(d)).toList();

      for (final e in dayEvents) {
        // Entire day or missing times -> treat as all-day for rendering
        if (e.isEntireday || e.startTime == null || e.endTime == null) {
          allDayByDay[di].add(e);
          continue;
        }

        final bool hasEndDate = e.userEventEndDate != null && !_sameYMD(e.userEventDate, e.userEventEndDate!);
        if (!hasEndDate) {
          // Single-day timed event
          timedSegmentsByDay[di].add(_Timed(e, e.startTime!, e.endTime!));
          continue;
        }

        // Multi-day timed event: split per-day segment
        final bool isStartDay = _sameYMD(d, e.userEventDate);
        final bool isEndDay = _sameYMD(d, e.userEventEndDate!);

        if (isStartDay && isEndDay) {
          // Shouldn't happen due to hasEndDate, but safe-guard
          timedSegmentsByDay[di].add(_Timed(e, e.startTime!, e.endTime!));
        } else if (isStartDay) {
          // From event start until end of day
          timedSegmentsByDay[di].add(_Timed(e, e.startTime!, const TimeOfDay(hour: 23, minute: 59)));
        } else if (isEndDay) {
          // From beginning of day until event end
          timedSegmentsByDay[di].add(_Timed(e, const TimeOfDay(hour: 0, minute: 0), e.endTime!));
        } else {
          // Middle days: render as all-day chip in the all-day row
          allDayByDay[di].add(e);
        }
      }

      // Sort timed segments by their per-day segment start time
      timedSegmentsByDay[di].sort((a, b) => _toMinutes(a.start).compareTo(_toMinutes(b.start)));
    }

    final double totalHeight = allDayRowHeight + hours * hourRowHeight;

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time labels column (left side)
          SizedBox(
            width: timeColumnWidth * 0.8, // Make time column smaller
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // All-day label row
                  SizedBox(
                    height: allDayRowHeight,
                    child: Center(
                      child: Text(
                        allDayLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Hour labels
                  ...List.generate(hours , (i) {
                    final m = startMinutes + i * 60;
                    final String label = _formatTimeLabel(m);
                    return SizedBox(
                      height: hourRowHeight,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Main grid and events
          Expanded(
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double gridWidth = constraints.maxWidth;
                  final double dayColumnWidth = gridWidth / 7;

                  // Build positioned timed events
                  final List<Widget> positioned = <Widget>[];

                  for (int di = 0; di < 7; di++) {
                    final daySegments = timedSegmentsByDay[di];
                    final lanes = _computeLanes(daySegments);
                    for (final laneItem in lanes) {
                      final e = laneItem.event;
                      final int s = (_toMinutes(laneItem.start) - startMinutes).clamp(0, totalMinutes);
                      final int t = (_toMinutes(laneItem.end) - startMinutes).clamp(0, totalMinutes);
                      final int dur = math.max(t - s, 1);
                      final double top = allDayRowHeight + (s / 60.0) * hourRowHeight;
                      final double height = math.max((dur / 60.0) * hourRowHeight, eventMinHeight);

                      // Column compute for overlaps
                      final int lane = laneItem.lane;
                      final int laneCount = laneItem.lanesInGroup;
                      final double laneWidth = dayColumnWidth / laneCount;
                      final double leftInDay = lane * laneWidth + 2;
                      final double width = laneWidth - 4;

                      // Respect text direction for horizontal positioning:
                      // - LTR:  di-th column from the left
                      // - RTL:  di-th column from the right (i.e., (6 - di) from the left)
                      final double dayOffset =
                          direction == TextDirection.rtl ? (6 - di) * dayColumnWidth : di * dayColumnWidth;
                      final double left = dayOffset + leftInDay;

                      positioned.add(Positioned(
                        left: left,
                        top: top,
                        width: width,
                        height: height,
                        child: _EventCard(e: e, onEventTap: onEventTap),
                      ));
                    }
                  }

                  // All-day row: entireDay events fill the day column as a rectangular block;
                  // non-entireDay all-day events remain as chips below.
                  final List<Widget> allDayRow = List.generate(7, (di) {
                    final items = allDayByDay[di];
                      if (items.isEmpty) {
                        return Container(
                          width: dayColumnWidth,
                          height: allDayRowHeight,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.06),
                            border: Border(
                              bottom: BorderSide(color: theme.colorScheme.onPrimary.withOpacity(0.08)),
                              left: BorderSide(color: theme.colorScheme.onPrimary.withOpacity(0.08)),
                              top: BorderSide(color: theme.colorScheme.onPrimary.withOpacity(0.08)),
                              right: di < 6 ? BorderSide(color: theme.colorScheme.onPrimary.withOpacity(0.08)) : BorderSide.none,
                            ),
                          ),
                        );
                      }
                      final UserEvent primary = items.first;
                      final int extraCount = items.length - 1;
                      final String extraLabel = extraCount > 0 ? '+${convertNumbers(extraCount, mainCalendar)}' : '';
                      return Container(
                        width: dayColumnWidth,
                        height: allDayRowHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: theme.colorScheme.onPrimary.withOpacity(0.08)),
                            left: BorderSide(color: theme.colorScheme.onPrimary.withOpacity(0.08)),
                            top: BorderSide(color: theme.colorScheme.onPrimary.withOpacity(0.08)),
                            right: di < 6 ? BorderSide(color: theme.colorScheme.onPrimary.withOpacity(0.08)) : BorderSide.none,
                          ),
                        ),
                        child: Stack(
                          children: [
                            _AllDayChip(e: primary, onEventTap: onEventTap),
                            if (extraCount > 0)
                              Positioned(
                                top: 2,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    extraLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                  });

                  return Stack(
                    children: [
                      // Grid
                      Column(
                        children: [
                          Row(children: allDayRow),
                          SizedBox(
                            height: hours * hourRowHeight,
                            width: gridWidth,
                            child: CustomPaint(
                              ///hours grid
                              painter: _GridPainter(
                                hours: hours,
                                dayCount: 7,
                                hourRowHeight: hourRowHeight,
                                lineColor: theme.colorScheme.onSurface.withOpacity(0.08),
                                boldLineColor: theme.colorScheme.onSurface.withOpacity(0.12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Timed events
                      ...positioned,
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _formatTimeLabel(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    final String hh = convertNumbers(h, mainCalendar).padLeft(2, convertNumbers(0, mainCalendar));
    final String mm = convertNumbers(m, mainCalendar).padLeft(2, convertNumbers(0, mainCalendar));
    return '$hh:$mm';
  }

  // Compute lane assignment for overlapping events within a day.
  // Greedy sweep-line: sort by start, keep active intervals, assign smallest free lane.
  List<_LaneItem> _computeLanes(List<_Timed> items) {
    if (items.isEmpty) return const [];
    final List<_LaneItem> out = [];
    final List<_ActiveItem> active = [];

    final List<_Timed> sorted = List<_Timed>.from(items)
      ..sort((a, b) => _toMinutes(a.start).compareTo(_toMinutes(b.start)));

    for (final item in sorted) {
      final int start = _toMinutes(item.start);
      // Remove finished
      active.removeWhere((a) => _toMinutes(a.end) <= start);

      // Find first free lane
      int lane = 0;
      final used = active.map((a) => a.lane).toSet();
      while (used.contains(lane)) lane++;

      // Add active
      active.add(_ActiveItem(lane: lane, end: item.end));

      // Lanes in current overlapping group is max(active lanes)+1
      final int lanesInGroup = (active.map((a) => a.lane).fold<int>(0, (p, c) => math.max(p, c))) + 1;

      out.add(_LaneItem(event: item.event, start: item.start, end: item.end, lane: lane, lanesInGroup: lanesInGroup));
    }
    return out;
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.e, this.onEventTap});

  final UserEvent e;
  final void Function(String eventId)? onEventTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = e.userEventColor;
    final Color fg = Colors.white;
    final String title = e.userEventTitle;

    return GestureDetector(
      onTap: () {
        if (onEventTap != null) {
          onEventTap!(e.userEventId);
        }
      },
      child: Container(
        height: double.infinity, // Fill the Positioned height
        padding: const EdgeInsets.only(top: 4,bottom: 4,left: 1,right: 1),
        decoration: BoxDecoration(
          border: Border.all(color: e.userEventBorderColor, width: 1.0),
          color: bg,
          boxShadow: [
            BoxShadow(color: bg.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: SingleChildScrollView(
          child: DefaultTextStyle(
            style: TextStyle(color: fg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _AllDayChip extends StatelessWidget {
  const _AllDayChip({required this.e, this.onEventTap});
  final UserEvent e;
  final void Function(String eventId)? onEventTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = e.userEventColor;
    return SizedBox.expand(
      child: GestureDetector(
        onTap: () {
          if (onEventTap != null) {
            onEventTap!(e.userEventId);
          }
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: e.userEventBorderColor, width: 1.0),
          ),
          child: Text(
            e.userEventTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.hours,
    required this.dayCount,
    required this.hourRowHeight,
    required this.lineColor,
    required this.boldLineColor,
  });

  final int hours;
  final int dayCount;
  final double hourRowHeight;
  final Color lineColor;
  final Color boldLineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    final Paint pb = Paint()
      ..color = boldLineColor
      ..strokeWidth = 1.2;

    // Horizontal lines (each hour)
    for (int i = 0; i <= hours; i++) {
      final double y = i * hourRowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i % 3 == 0 ? pb : p);
    }

    // Vertical day separators
    final double colW = size.width / dayCount;
    for (int i = 0; i <= dayCount; i++) {
      final double x = i * colW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), pb);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return hours != oldDelegate.hours ||
        dayCount != oldDelegate.dayCount ||
        hourRowHeight != oldDelegate.hourRowHeight ||
        lineColor != oldDelegate.lineColor ||
        boldLineColor != oldDelegate.boldLineColor;
    }
}

class _Timed {
  _Timed(this.event, this.start, this.end);
  final UserEvent event;
  final TimeOfDay start;
  final TimeOfDay end;
}

class _ActiveItem {
  _ActiveItem({required this.lane, required this.end});
  final int lane;
  final TimeOfDay end;
}

class _LaneItem {
  const _LaneItem({required this.event, required this.start, required this.end, required this.lane, required this.lanesInGroup});
  final UserEvent event;
  final TimeOfDay start;
  final TimeOfDay end;
  final int lane;
  final int lanesInGroup;
}