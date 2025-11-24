import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
    // New: empty slot tap listener for creating events
    this.onEmptySlotTap,
    // New: callback to open event creation screen
    this.onCreateEvent,
    // New: text for new event placeholder
    this.newEventText = '+ New Event',
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
  
  /// Callback when an empty time slot is tapped. Provides (date, time, dayIndex).
  final void Function(DateTime date, TimeOfDay time, int dayIndex)? onEmptySlotTap;
  
  /// Callback to open event creation screen with pre-filled date/time.
  final void Function(DateTime start, DateTime end)? onCreateEvent;

  /// Text to display in the new event placeholder
  final String newEventText;

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
  late ScrollController _scrollController;

  // Repository for official holiday lookup
  late final EventRepository _eventRepository;
  bool _eventsLoaded = false;
  
  // Event placeholder state
  DateTime? _placeholderStart;
  DateTime? _placeholderEnd;
  int? _placeholderDayIndex; // 0-6 for day of week
  bool _isDraggingPlaceholder = false; // Track if placeholder is being dragged
  bool _isDraggingInsidePlaceholder = false; // Track if drag is inside placeholder bounds

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
    _scrollController = ScrollController();
   
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

  // Helper method to clamp a DateTime to the allowed time range
  DateTime _clampTimeToDayBounds(DateTime dateTime) {
    final int dayStartMinutes = (widget.dayStartTime?.hour ?? 8) * 60 + (widget.dayStartTime?.minute ?? 0);
    final int dayEndMinutes = (widget.dayEndTime?.hour ?? 20) * 60 + (widget.dayEndTime?.minute ?? 0);
    final int currentMinutes = dateTime.hour * 60 + dateTime.minute;
    
    // Clamp to the allowed range
    final int clampedMinutes = currentMinutes.clamp(dayStartMinutes, dayEndMinutes);
    
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      clampedMinutes ~/ 60,
      clampedMinutes % 60,
    );
  }

  // Helper method to ensure both start and end times are within bounds
  (DateTime, DateTime) _clampEventTimesToDayBounds(DateTime start, DateTime end) {
    DateTime clampedStart = _clampTimeToDayBounds(start);
    DateTime clampedEnd = _clampTimeToDayBounds(end);
    
    // Ensure minimum duration of 30 minutes
    if (clampedEnd.difference(clampedStart).inMinutes < 30) {
      if (start.isAfter(end)) {
        // If start was after end (can happen with top resize), swap them
        final temp = clampedStart;
        clampedStart = clampedEnd;
        clampedEnd = temp;
      }
      
      // Adjust end to ensure minimum duration
      if (clampedEnd.difference(clampedStart).inMinutes < 30) {
        clampedEnd = clampedStart.add(const Duration(minutes: 30));
        // If this goes beyond bounds, adjust start instead
        if (_clampTimeToDayBounds(clampedEnd).hour != clampedEnd.hour ||
            _clampTimeToDayBounds(clampedEnd).minute != clampedEnd.minute) {
          clampedEnd = _clampTimeToDayBounds(clampedEnd);
          clampedStart = clampedEnd.subtract(const Duration(minutes: 30));
        }
      }
    }
    
    return (clampedStart, clampedEnd);
  }

  // Methods to handle event placeholder
  void _showEventPlaceholder(DateTime date, TimeOfDay time, int dayIndex) {
    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final end = start.add(const Duration(hours: 1));
    
    // Clamp times to day bounds
    final (clampedStart, clampedEnd) = _clampEventTimesToDayBounds(start, end);
    
    // Log for debugging: Check if initial times are within bounds
    final int startMinutes = start.hour * 60 + start.minute;
    final int endMinutes = end.hour * 60 + end.minute;
    final int clampedStartMinutes = clampedStart.hour * 60 + clampedStart.minute;
    final int clampedEndMinutes = clampedEnd.hour * 60 + clampedEnd.minute;
    final int dayStartMinutes = (widget.dayStartTime?.hour ?? 8) * 60 + (widget.dayStartTime?.minute ?? 0);
    final int dayEndMinutes = (widget.dayEndTime?.hour ?? 20) * 60 + (widget.dayEndTime?.minute ?? 0);
    
    print('DEBUG: _showEventPlaceholder called');
    print('  Initial start: ${start.hour}:${start.minute.toString().padLeft(2, '0')} (minutes: $startMinutes)');
    print('  Initial end: ${end.hour}:${end.minute.toString().padLeft(2, '0')} (minutes: $endMinutes)');
    print('  Clamped start: ${clampedStart.hour}:${clampedStart.minute.toString().padLeft(2, '0')} (minutes: $clampedStartMinutes)');
    print('  Clamped end: ${clampedEnd.hour}:${clampedEnd.minute.toString().padLeft(2, '0')} (minutes: $clampedEndMinutes)');
    print('  Day start: ${widget.dayStartTime?.hour ?? 8}:${(widget.dayStartTime?.minute ?? 0).toString().padLeft(2, '0')} (minutes: $dayStartMinutes)');
    print('  Day end: ${widget.dayEndTime?.hour ?? 20}:${(widget.dayEndTime?.minute ?? 0).toString().padLeft(2, '0')} (minutes: $dayEndMinutes)');
    print('  Start within bounds: ${clampedStartMinutes >= dayStartMinutes}');
    print('  End within bounds: ${clampedEndMinutes <= dayEndMinutes}');
    
    if (_placeholderStart != null) {
      _hideEventPlaceholder();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentDragPosition = null;
          _isDraggingPlaceholder = false;
          _isDraggingInsidePlaceholder = false;
          _placeholderStart = clampedStart;
          _placeholderEnd = clampedEnd;
          _placeholderDayIndex = dayIndex;
        });
      });
    } else {
      setState(() {
        _currentDragPosition = null;
        _isDraggingPlaceholder = false;
        _isDraggingInsidePlaceholder = false;
        _placeholderStart = clampedStart;
        _placeholderEnd = clampedEnd;
        _placeholderDayIndex = dayIndex;
      });
    }
  }

  void _hideEventPlaceholder() {
    setState(() {
      _currentDragPosition = null;
      _isDraggingPlaceholder = false;
      _isDraggingInsidePlaceholder = false;
      _placeholderStart = null;
      _placeholderEnd = null;
      _placeholderDayIndex = null;
    });
  }

  void _updatePlaceholder(DateTime newStart, DateTime newEnd) {
    // Clamp times to day bounds
    final (clampedStart, clampedEnd) = _clampEventTimesToDayBounds(newStart, newEnd);
    
    // Log for debugging: Check if new times are within bounds
    final int startMinutes = newStart.hour * 60 + newStart.minute;
    final int endMinutes = newEnd.hour * 60 + newEnd.minute;
    final int clampedStartMinutes = clampedStart.hour * 60 + clampedStart.minute;
    final int clampedEndMinutes = clampedEnd.hour * 60 + clampedEnd.minute;
    final int dayStartMinutes = (widget.dayStartTime?.hour ?? 8) * 60 + (widget.dayStartTime?.minute ?? 0);
    final int dayEndMinutes = (widget.dayEndTime?.hour ?? 20) * 60 + (widget.dayEndTime?.minute ?? 0);
    
    print('DEBUG: _updatePlaceholder called');
    print('  Requested start: ${newStart.hour}:${newStart.minute.toString().padLeft(2, '0')} (minutes: $startMinutes)');
    print('  Requested end: ${newEnd.hour}:${newEnd.minute.toString().padLeft(2, '0')} (minutes: $endMinutes)');
    print('  Clamped start: ${clampedStart.hour}:${clampedStart.minute.toString().padLeft(2, '0')} (minutes: $clampedStartMinutes)');
    print('  Clamped end: ${clampedEnd.hour}:${clampedEnd.minute.toString().padLeft(2, '0')} (minutes: $clampedEndMinutes)');
    print('  Day start: ${widget.dayStartTime?.hour ?? 8}:${(widget.dayStartTime?.minute ?? 0).toString().padLeft(2, '0')} (minutes: $dayStartMinutes)');
    print('  Day end: ${widget.dayEndTime?.hour ?? 20}:${(widget.dayEndTime?.minute ?? 0).toString().padLeft(2, '0')} (minutes: $dayEndMinutes)');
    print('  Start within bounds: ${clampedStartMinutes >= dayStartMinutes}');
    print('  End within bounds: ${clampedEndMinutes <= dayEndMinutes}');
    
    setState(() {
      _placeholderStart = clampedStart;
      _placeholderEnd = clampedEnd;
    });
  }

  void _setPlaceholderDragging(bool isDragging) {
    setState(() {
      _isDraggingPlaceholder = isDragging;
      if (!isDragging) {
        _isDraggingInsidePlaceholder = false;
      }
    });
    
    // Start or stop auto-scroll based on dragging state
    if (isDragging) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }
  
  void _setDraggingInsidePlaceholder(bool isInside) {
    setState(() {
      _isDraggingInsidePlaceholder = isInside;
    });
  }
  
  Timer? _autoScrollTimer;
  Offset? _currentDragPosition;
  
  void _handleDragUpdate(Offset globalPosition) {
    _currentDragPosition = globalPosition;
  }
  
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isDraggingPlaceholder || !_scrollController.hasClients) {
        timer.cancel();
        return;
      }
      
      // Check if we need to auto-scroll based on drag position
      if (_currentDragPosition == null) return;
      
      final RenderBox? scrollableBox = _scrollController.position.context.storageContext?.findRenderObject() as RenderBox?;
      if (scrollableBox == null) return;
      
      final Offset localPosition = scrollableBox.globalToLocal(_currentDragPosition!);
      final double viewportHeight = scrollableBox.size.height;
      final double scrollOffset = _scrollController.offset;
      final double maxScrollOffset = _scrollController.position.maxScrollExtent;
      
      const double edgeThreshold = 50.0;
      const double scrollSpeed = 8.0;
      
      double scrollAmount = 0.0;
      
      if (localPosition.dy < edgeThreshold && scrollOffset > 0) {
        final double proximityFactor = 1.0 - (localPosition.dy / edgeThreshold);
        scrollAmount = -scrollSpeed * proximityFactor;
      } else if (localPosition.dy > viewportHeight - edgeThreshold && scrollOffset < maxScrollOffset) {
        final double proximityFactor = (localPosition.dy - (viewportHeight - edgeThreshold)) / edgeThreshold;
        scrollAmount = scrollSpeed * proximityFactor;
      }
      
      if (scrollAmount != 0.0) {
        final double newOffset = (scrollOffset + scrollAmount).clamp(0.0, maxScrollOffset);
        _scrollController.jumpTo(newOffset);
      }
    });
  }
  
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _onPlaceholderTap() {
    if (_placeholderStart != null && _placeholderEnd != null) {
      widget.onCreateEvent?.call(_placeholderStart!, _placeholderEnd!);
      _hideEventPlaceholder();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
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
              // Disable page changes only when dragging placeholder
              physics: _isDraggingPlaceholder ? const NeverScrollableScrollPhysics() : null,
              onPageChanged: (page) {
                // Calculate new week start based on page offset
                final int weekOffset = page - 1000;
                final DateTime base = _startOfWeek(widget.initialDate ?? DateTime.now(), _effectiveWeekStart);
                final DateTime weekStart = base.add(Duration(days: weekOffset * 7));
                setState(() {
                  _currentWeekStart = weekStart;
                  if (_placeholderStart != null) {
                    final dayOfWeek = _placeholderStart!.weekday;
                    final int newDayIndex = (dayOfWeek - _isoWeekdayForStart(_effectiveWeekStart) + 7) % 7;
                    _placeholderDayIndex = newDayIndex;
                  }
                });
                final DateTime endExclusive = weekStart.add(const Duration(days: 7));
                if (widget.onPageRangeChanged != null) {
                  widget.onPageRangeChanged!(weekStart, endExclusive);
                }
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
                      option: widget.option,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                     fit: FlexFit.loose,
                     child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: _isDraggingPlaceholder && _placeholderDayIndex != null ? const NeverScrollableScrollPhysics() : null,
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
                           onEmptySlotTap: _showEventPlaceholder,
                           placeholderStart: _placeholderStart,
                           placeholderEnd: _placeholderEnd,
                           placeholderDayIndex: _placeholderDayIndex,
                           onPlaceholderUpdate: _updatePlaceholder,
                           onPlaceholderTap: _onPlaceholderTap,
                           onPlaceholderHide: _hideEventPlaceholder,
                           onPlaceholderDragStart: () => _setPlaceholderDragging(true),
                           onPlaceholderDragEnd: () => _setPlaceholderDragging(false),
                           onPlaceholderDragUpdate: _handleDragUpdate,
                           onPlaceholderDragInsideChange: _setDraggingInsidePlaceholder,
                           newEventText: widget.newEventText,
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
    this.option,
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
  final JalaliTableCalendarOption? option;

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
              final isToday = _isToday(d);
              final dayNum = switch (mainCalendar) {
                CalendarType.jalali => convertNumbers(Jalali.fromDateTime(d).day, mainCalendar),
                CalendarType.hijri => convertNumbers(HijriCalendar.fromDate(d).hDay, mainCalendar),
                CalendarType.gregorian => d.day.toString(),
              };
              final String? leftText = subCalendarLeft == null ? null : _secondaryDay(d, subCalendarLeft!);
              final String? rightText = subCalendarRight == null ? null : _secondaryDay(d, subCalendarRight!);
              final styleColor = isWeekend || isHoliday ? theme.colorScheme.primary : null;
              return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onDaySelected != null ? () => onDaySelected!(d) : null,
                    child:Container(
                width: dayColumnWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child:  Column(
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
                          ) : (isToday && option?.todayBackgroundColor != null) ? BoxDecoration(
                            shape: BoxShape.circle,
                            color: option!.todayBackgroundColor,
                          ) : null,
                          child: Center(
                            child: Text(
                              dayNum,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isToday && option?.todayOnColor != null && !isSelected
                                    ? option!.todayOnColor
                                    : styleColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(padding: const EdgeInsets.only(left:7,right: 7,top: 0,bottom: 0),child:
                        Row(
                          children: [
                            if (leftText != null)
                              Text(leftText, style: TextStyle(fontSize: 11,fontWeight: FontWeight.w600, color: styleColor)),
                            const Spacer(),
                            if (rightText != null)
                              Text(rightText, style: TextStyle(fontSize: 11,fontWeight: FontWeight.w600, color: styleColor)),
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

  // Check if a date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

}

class _WeekTimeGrid extends StatefulWidget {
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
    this.onEmptySlotTap,
    this.placeholderStart,
    this.placeholderEnd,
    this.placeholderDayIndex,
    this.onPlaceholderUpdate,
    this.onPlaceholderTap,
    this.onPlaceholderHide,
    this.onPlaceholderDragStart,
    this.onPlaceholderDragEnd,
    this.onPlaceholderDragUpdate,
    this.onPlaceholderDragInsideChange,
    this.newEventText = '+ New Event',
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
  final void Function(DateTime date, TimeOfDay time, int dayIndex)? onEmptySlotTap;
  final DateTime? placeholderStart;
  final DateTime? placeholderEnd;
  final int? placeholderDayIndex;
  final Function(DateTime newStart, DateTime newEnd)? onPlaceholderUpdate;
  final VoidCallback? onPlaceholderTap;
  final VoidCallback? onPlaceholderHide;
  final VoidCallback? onPlaceholderDragStart;
  final VoidCallback? onPlaceholderDragEnd;
  final Function(Offset globalPosition)? onPlaceholderDragUpdate;
  final Function(bool isInside)? onPlaceholderDragInsideChange;
  final String newEventText;

  @override
  State<_WeekTimeGrid> createState() => _WeekTimeGridState();
}

class _WeekTimeGridState extends State<_WeekTimeGrid> {
  final GlobalKey<_EventPlaceholderState> _placeholderKey = GlobalKey<_EventPlaceholderState>();
  
  @override
  void didUpdateWidget(_WeekTimeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placeholderStart != null && widget.placeholderStart == null) {
      _placeholderKey.currentState?.hidePlaceholder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int startMinutes = _toMinutes(widget.dayStartTime);
    int endMinutes = _toMinutes(widget.dayEndTime);
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
      final d = widget.days[di];
      final dayEvents = widget.calendarEvents.where((e) => e.occursOn(d)).toList();

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

    final double totalHeight = widget.allDayRowHeight + hours * widget.hourRowHeight;

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time labels column (left side)
          SizedBox(
            width: widget.timeColumnWidth * 0.8, // Make time column smaller
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // All-day label row
                  SizedBox(
                    height: widget.allDayRowHeight,
                    child: Center(
                      child: Text(
                        widget.allDayLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
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
                      height: widget.hourRowHeight,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
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
                      final double top = widget.allDayRowHeight + (s / 60.0) * widget.hourRowHeight;
                      final double height = math.max((dur / 60.0) * widget.hourRowHeight, widget.eventMinHeight);

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
                          widget.direction == TextDirection.rtl ? (6 - di) * dayColumnWidth : di * dayColumnWidth;
                      final double left = dayOffset + leftInDay;

                      positioned.add(Positioned(
                        left: left,
                        top: top,
                        width: width,
                        height: height,
                        child: _EventCard(e: e, onEventTap: widget.onEventTap),
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
                          height: widget.allDayRowHeight,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.06),
                            border: Border(
                              bottom: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.08)),
                              left: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.08)),
                              top: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.08)),
                              right: di < 6 ? BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.08)) : BorderSide.none,
                            ),
                          ),
                        );
                      }
                      final UserEvent primary = items.first;
                      final int extraCount = items.length - 1;
                      final String extraLabel = extraCount > 0 ? '+${convertNumbers(extraCount, widget.mainCalendar)}' : '';
                      return Container(
                        width: dayColumnWidth,
                        height: widget.allDayRowHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.08)),
                            left: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.08)),
                            top: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.08)),
                            right: di < 6 ? BorderSide(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.08)) : BorderSide.none,
                          ),
                        ),
                        child: Stack(
                          children: [
                            _AllDayChip(e: primary, onEventTap: widget.onEventTap),
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

                  // Add invisible tap detectors for empty slots
                  final List<Widget> emptySlotDetectors = [];
                  for (int di = 0; di < 7; di++) {
                    for (int hi = 0; hi < hours; hi++) {
                      final hourStart = startMinutes + hi * 60;
                      final hourEnd = hourStart + 60;
                      final timeOfDay = TimeOfDay(hour: hourStart ~/ 60, minute: hourStart % 60);
                       
                      // Check if this slot overlaps with any existing event
                      bool hasEvent = false;
                      for (final segment in timedSegmentsByDay[di]) {
                        final segStart = _toMinutes(segment.start);
                        final segEnd = _toMinutes(segment.end);
                        if ((hourStart >= segStart && hourStart < segEnd) ||
                            (hourEnd > segStart && hourEnd <= segEnd) ||
                            (hourStart <= segStart && hourEnd >= segEnd)) {
                          hasEvent = true;
                          break;
                        }
                      }
                       
                      if (!hasEvent) {
                        final double top = widget.allDayRowHeight + (hi * widget.hourRowHeight);
                        final double left = widget.direction == TextDirection.rtl ?
                            (6 - di) * dayColumnWidth : di * dayColumnWidth;
                         
                        emptySlotDetectors.add(Positioned(
                          left: left,
                          top: top,
                          width: dayColumnWidth,
                          height: widget.hourRowHeight,
                          child: GestureDetector(
                            onTap: () => widget.onEmptySlotTap?.call(widget.days[di], timeOfDay, di),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ));
                      }
                    }
                   
                  }

                  return Stack(
                    children: [
                      // Grid
                      Column(
                        children: [
                          Row(children: allDayRow),
                          SizedBox(
                            height: hours * widget.hourRowHeight,
                            width: gridWidth,
                            child: CustomPaint(
                              ///hours grid
                              painter: _GridPainter(
                                hours: hours,
                                dayCount: 7,
                                hourRowHeight: widget.hourRowHeight,
                                lineColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                                boldLineColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Empty slot detectors
                      ...emptySlotDetectors,
                      // Timed events
                      ...positioned,
                      // Event placeholder
                      if (widget.placeholderStart != null && widget.placeholderEnd != null)
                        _buildPlaceholder(
                          widget.placeholderStart!,
                          widget.placeholderEnd!,
                          dayColumnWidth,
                          widget.days,
                          widget.allDayRowHeight,
                          startMinutes,
                          widget.hourRowHeight,
                          widget.direction,
                        ),
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
    final String hh = convertNumbers(h, widget.mainCalendar).padLeft(2, convertNumbers(0, widget.mainCalendar));
    final String mm = convertNumbers(m, widget.mainCalendar).padLeft(2, convertNumbers(0, widget.mainCalendar));
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

  Widget _buildPlaceholder(
    DateTime start,
    DateTime end,
    double dayColumnWidth,
    List<DateTime> weekDays,
    double allDayRowHeight,
    int startMinutes,
    double hourRowHeight,
    TextDirection direction,
  ) {
    // Find day indices for start and end
    int startDayIndex = weekDays.indexWhere((d) => d.year == start.year && d.month == start.month && d.day == start.day);
    int endDayIndex = weekDays.indexWhere((d) => d.year == end.year && d.month == end.month && d.day == end.day);

    // If not found in current week or invalid span, don't show
    if (startDayIndex == -1 || endDayIndex == -1 || startDayIndex > endDayIndex) {
      return Container();
    }

    int span = endDayIndex - startDayIndex + 1;

    // Calculate position and size
    final int startMinutesFromMidnight = start.hour * 60 + start.minute;
    final int endMinutesFromMidnight = end.hour * 60 + end.minute;

    final double top = allDayRowHeight + ((startMinutesFromMidnight - startMinutes) / 60.0) * hourRowHeight;
    final double height = ((endMinutesFromMidnight - startMinutesFromMidnight) / 60.0) * hourRowHeight;

    final double dayOffset = direction == TextDirection.rtl ?
        (6 - endDayIndex) * dayColumnWidth : startDayIndex * dayColumnWidth;
    final double width = span * dayColumnWidth - 4;

    return Positioned(
      left: dayOffset + 2,
      top: top,
      width: width,
      height: height,
      child: _EventPlaceholder(
        startDate: start,
        endDate: end,
        dayColumnWidth: dayColumnWidth,
        weekDays: weekDays,
        hourRowHeight: hourRowHeight,
        newEventText: widget.newEventText,
        onTap: widget.onPlaceholderTap ?? () {},
        onResize: (newStart, newEnd) => widget.onPlaceholderUpdate?.call(newStart, newEnd),
        onDragStart: widget.onPlaceholderDragStart ?? () {},
        onDragEnd: widget.onPlaceholderDragEnd ?? () {},
        onDragUpdate: widget.onPlaceholderDragUpdate,
        onDragInsideChange: widget.onPlaceholderDragInsideChange,
        direction: direction,
      ),
    );
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
        height: double.infinity,
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

// Event placeholder widget for creating new events
class _EventPlaceholder extends StatefulWidget {
  const _EventPlaceholder({
    required this.startDate,
    required this.endDate,
    required this.dayColumnWidth,
    required this.weekDays,
    required this.hourRowHeight,
    required this.newEventText,
    required this.onTap,
    required this.onResize,
    required this.direction,
    this.onDragStart,
    this.onDragEnd,
    this.onDragUpdate,
    this.onDragInsideChange,
    this.onHide,
  });

  final DateTime startDate;
  final DateTime endDate;
  final double dayColumnWidth;
  final List<DateTime> weekDays;
  final double hourRowHeight;
  final String newEventText;
  final VoidCallback onTap;
  final Function(DateTime newStart, DateTime newEnd) onResize;
  final TextDirection direction;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final Function(Offset globalPosition)? onDragUpdate;
  final Function(bool isInside)? onDragInsideChange;
  final VoidCallback? onHide;

  @override
  State<_EventPlaceholder> createState() => _EventPlaceholderState();
}

class _EventPlaceholderState extends State<_EventPlaceholder> {
  bool _isDraggingTop = false;
  bool _isDraggingBottom = false;
  bool _isDraggingLeft = false;
  bool _isDraggingRight = false;
  bool _isDraggingMove = false;
  late DateTime _dragStart;
  late DateTime _dragEnd;
  final GlobalKey _placeholderKey = GlobalKey();

  Offset? _lastPointerPosition;
  bool _isDraggingWithPointer = false;

  // Accumulate drag deltas for more responsive movement
  double _accumulatedDeltaX = 0.0;
  double _accumulatedDeltaY = 0.0;
  
  void _resetPointerPositions() {
    _lastPointerPosition = null;
    _accumulatedDeltaX = 0.0;
    _accumulatedDeltaY = 0.0;
  }
  
  @override
  void didUpdateWidget(_EventPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) {
      setState(() {
        _dragStart = widget.startDate;
        _dragEnd = widget.endDate;
      });
      _resetPointerPositions();
    }
  }
  
  void hidePlaceholder() {
    _resetPointerPositions();
    setState(() {
      _isDraggingTop = false;
      _isDraggingBottom = false;
      _isDraggingMove = false;
      _isDraggingWithPointer = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _dragStart = widget.startDate;
    _dragEnd = widget.endDate;
  }
  
  bool _isInsidePlaceholder(Offset globalPosition) {
    final RenderBox? renderBox = _placeholderKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;
    
    final Size placeholderSize = renderBox.size;
    final Offset localPosition = renderBox.globalToLocal(globalPosition);
    
    const double padding = 8.0;
    return localPosition.dx >= -padding &&
           localPosition.dx <= placeholderSize.width + padding &&
           localPosition.dy >= -padding &&
           localPosition.dy <= placeholderSize.height + padding;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Listener(
      key: _placeholderKey,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.2),
            border: Border.all(color: colorScheme.primary, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _isDraggingMove ? colorScheme.primary.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(padding: EdgeInsetsGeometry.all(5),child:  Center(
                  child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.newEventText,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  ),
                ),
                ),
              ),
              // Top resize handle
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isDraggingTop ? colorScheme.primary.withOpacity(0.4) : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 30,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom resize handle
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isDraggingBottom ? colorScheme.primary.withOpacity(0.4) : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 30,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              // Left resize handle for start day
              Positioned(
                left: widget.direction == TextDirection.rtl ? null : 0,
                right: widget.direction == TextDirection.rtl ? 0 : null,
                top: 12,
                bottom: 12,
                width: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isDraggingLeft ? colorScheme.primary.withOpacity(0.4) : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: Align(
                    alignment: widget.direction == TextDirection.rtl ? Alignment.centerRight :Alignment.centerLeft,
                    child: Container(
                      width: 3,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              // Right resize handle for end day
              Positioned(
                left: widget.direction == TextDirection.rtl ? 0 : null,
                right: widget.direction == TextDirection.rtl ? null : 0,
                top: 12,
                bottom: 12,
                width: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isDraggingRight ? colorScheme.primary.withOpacity(0.4) : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Align(
                    alignment: widget.direction == TextDirection.rtl ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      width: 3,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _lastPointerPosition = event.localPosition;

    final RenderBox? renderBox = _placeholderKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final localY = event.localPosition.dy;
    final localX = event.localPosition.dx;

    // Log for debugging RTL dragging issue
    print('DEBUG: _handlePointerDown called');
    print('  Text direction: ${widget.direction}');
    print('  Local X: $localX, Local Y: $localY');
    print('  Width: ${size.width}, Height: ${size.height}');

    if (localY < 12) {
      print('  Dragging: TOP');
      setState(() {
        _isDraggingTop = true;
        _isDraggingWithPointer = true;
      });
      widget.onDragStart?.call();
    } else if (localY > size.height - 12) {
      print('  Dragging: BOTTOM');
      setState(() {
        _isDraggingBottom = true;
        _isDraggingWithPointer = true;
      });
      widget.onDragStart?.call();
    } else if (localX < 12) {
      print('  Dragging: LEFT side');
      setState(() {
        if(widget.direction == TextDirection.rtl){
          _isDraggingRight = true;
          print('  RTL: Interpreted as RIGHT drag');
        }else{
        _isDraggingLeft = true;
          print('  LTR: Interpreted as LEFT drag');
        }
        _isDraggingWithPointer = true;
      });
      widget.onDragStart?.call();
    } else if (localX > size.width - 12) {
      print('  Dragging: RIGHT side');
      setState(() {
        if(widget.direction == TextDirection.rtl){
          _isDraggingLeft = true;
          print('  RTL: Interpreted as LEFT drag');
        }else{
        _isDraggingRight = true;
          print('  LTR: Interpreted as RIGHT drag');
        }
        _isDraggingWithPointer = true;
      });
      widget.onDragStart?.call();
    } else {
      print('  Dragging: MOVE');
      setState(() {
        _isDraggingMove = true;
        _isDraggingWithPointer = true;
      });
      widget.onDragStart?.call();
    }
  }
  
  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isDraggingWithPointer) return;
    if (_lastPointerPosition == null) {
      _lastPointerPosition = event.localPosition;
    }
    final delta = event.localPosition - _lastPointerPosition!;
    _lastPointerPosition = event.localPosition;

    // Accumulate deltas for more responsive movement
    _accumulatedDeltaX += delta.dx;
    _accumulatedDeltaY += delta.dy;

    final isInside = _isInsidePlaceholder(event.position);
    widget.onDragInsideChange?.call(isInside);
    widget.onDragUpdate?.call(event.position);

    if (_isDraggingLeft || _isDraggingRight) {
      // Process accumulated horizontal deltas for day changes
      const double threshold = 20.0; // Minimum accumulated pixels before processing
      if (_accumulatedDeltaX.abs() >= threshold) {
        final deltaToProcess = _accumulatedDeltaX;
        _accumulatedDeltaX = 0.0; // Reset accumulator

        if (_isDraggingLeft) {
          _handleDayResizeByDelta(deltaToProcess, true);
        } else if (_isDraggingRight) {
          _handleDayResizeByDelta(deltaToProcess, false);
        }
      }
    } else if (_isDraggingMove) {
      if (_accumulatedDeltaX.abs() > _accumulatedDeltaY.abs()) {
        // Horizontal movement - handle day changes
        const double threshold = 25.0;
        if (_accumulatedDeltaX.abs() >= threshold) {
          final deltaToProcess = _accumulatedDeltaX;
          _accumulatedDeltaX = 0.0;
          _handleMoveDaysByDelta(deltaToProcess);
        }
      } else {
        // Vertical movement - handle time changes
        const double threshold = 10.0;
        if (_accumulatedDeltaY.abs() >= threshold) {
          final deltaToProcess = _accumulatedDeltaY;
          _accumulatedDeltaY = 0.0;
          _handleMoveByDelta(deltaToProcess);
        }
      }
    } else if (_isDraggingTop || _isDraggingBottom) {
      // Process accumulated vertical deltas for time resizing
      const double threshold = 15.0;
      if (_accumulatedDeltaY.abs() >= threshold) {
        final deltaToProcess = _accumulatedDeltaY;
        _accumulatedDeltaY = 0.0;

        if (_isDraggingTop) {
          _handleResizeByDelta(deltaToProcess, true);
        } else if (_isDraggingBottom) {
          _handleResizeByDelta(deltaToProcess, false);
        }
      }
    }
  }
  
  void _handlePointerUp(PointerUpEvent event) {
    if (!_isDraggingWithPointer) return;

    setState(() {
      _isDraggingMove = false;
      _isDraggingTop = false;
      _isDraggingBottom = false;
      _isDraggingLeft = false;
      _isDraggingRight = false;
      _isDraggingWithPointer = false;
    });

    widget.onDragEnd?.call();
    widget.onDragInsideChange?.call(false);
    _lastPointerPosition = null;
  }
  
  void _handlePointerCancel(PointerCancelEvent event) {
    _handlePointerUp(PointerUpEvent(
      timeStamp: event.timeStamp,
      pointer: event.pointer,
      position: event.position,
    ));
  }
  
  void _handleMoveByDelta(double deltaY) {
    // Get the parent widget to access dayStartTime/dayEndTime
    final parentWidget = context.findAncestorWidgetOfExactType<_WeekTimeGrid>();
    if (parentWidget != null) {
    const double hourRowHeight = 35.0;
    final double minutesChange = (deltaY / hourRowHeight) * 60.0;
    final int roundedMinutesChange = (minutesChange / 15).round() * 15;
    
    final int oldStartMinutes = _dragStart.hour * 60 + _dragStart.minute;
    final int oldEndMinutes = _dragEnd.hour * 60 + _dragEnd.minute;
    final dif=oldEndMinutes-oldStartMinutes;

    if (roundedMinutesChange == 0) return;
    
    final duration = Duration(minutes: roundedMinutesChange);
    

    // Log before move
    print('DEBUG: _handleMoveByDelta called');
    print('  Before move - Start: ${_dragStart.hour}:${_dragStart.minute.toString().padLeft(2, '0')}, End: ${_dragEnd.hour}:${_dragEnd.minute.toString().padLeft(2, '0')}');
    print('  Minutes change: $roundedMinutesChange');
    
    if (mounted) {
      setState(() {
        _dragStart = _dragStart.add(duration);
        _dragEnd = _dragEnd.add(duration);

        if (_dragEnd.difference(_dragStart).inMinutes < 30) {
          _dragEnd = _dragStart.add(const Duration(minutes: 30));
        }
      });
    }

    
    
      // Clamp times to day bounds using the parent's bounds
      final dayStartMinutes = (parentWidget.dayStartTime.hour) * 60 + (parentWidget.dayStartTime.minute);
      final dayEndMinutes = (parentWidget.dayEndTime.hour) * 60 + (parentWidget.dayEndTime.minute);

      final int startMinutes = _dragStart.hour * 60 + _dragStart.minute;
      final int endMinutes = _dragEnd.hour * 60 + _dragEnd.minute;

      // Apply bounds
      int clampedStartMinutes = startMinutes.clamp(dayStartMinutes, dayEndMinutes);
      int clampedEndMinutes = endMinutes.clamp(dayStartMinutes, dayEndMinutes);
      if(duration.inMinutes > 0 && clampedEndMinutes - clampedStartMinutes < dif) {
        clampedStartMinutes = clampedEndMinutes - dif;
      }else
      if(duration.inMinutes < 0 && clampedEndMinutes - clampedStartMinutes < dif) {
        clampedEndMinutes = clampedStartMinutes + dif;
      }
      if (mounted) {
        setState(() {
          _dragStart = DateTime(
            _dragStart.year,
            _dragStart.month,
            _dragStart.day,
            clampedStartMinutes ~/ 60,
            clampedStartMinutes % 60,
          );
          _dragEnd = DateTime(
            _dragEnd.year,
            _dragEnd.month,
            _dragEnd.day,
            clampedEndMinutes ~/ 60,
            clampedEndMinutes % 60,
          );

          // Ensure minimum duration
          if (_dragEnd.difference(_dragStart).inMinutes < 30) {
            _dragEnd = _dragStart.add(const Duration(minutes: 30));
            // If this goes beyond bounds, adjust start instead
            final int endMinutesAfter = _dragEnd.hour * 60 + _dragEnd.minute;
            if (endMinutesAfter > dayEndMinutes) {
              _dragEnd = DateTime(
                _dragEnd.year,
                _dragEnd.month,
                _dragEnd.day,
                dayEndMinutes ~/ 60,
                dayEndMinutes % 60,
              );
              _dragStart = _dragEnd.subtract(const Duration(minutes: 30));
            }
          }
        });
      }
    }
    
    // Log after move
    print('  After move - Start: ${_dragStart.hour}:${_dragStart.minute.toString().padLeft(2, '0')}, End: ${_dragEnd.hour}:${_dragEnd.minute.toString().padLeft(2, '0')}');
    
    widget.onResize(_dragStart, _dragEnd);
  }
  
  void _handleResizeByDelta(double deltaY, bool isTop) {
    const double hourRowHeight = 35.0;
    final double minutesChange = (deltaY / hourRowHeight) * 60.0;
    final int roundedMinutesChange = (minutesChange / 15).round() * 15;
    
    if (roundedMinutesChange == 0) return;
    
    final duration = Duration(minutes: roundedMinutesChange);
    
    // Log before resize
    print('DEBUG: _handleResizeByDelta called');
    print('  Before resize - Start: ${_dragStart.hour}:${_dragStart.minute.toString().padLeft(2, '0')}, End: ${_dragEnd.hour}:${_dragEnd.minute.toString().padLeft(2, '0')}');
    print('  Resizing: ${isTop ? "TOP" : "BOTTOM"}, Minutes change: $roundedMinutesChange');
    
    if (mounted) {
      setState(() {
        if (isTop) {
          _dragStart = _dragStart.add(duration);
        } else {
          _dragEnd = _dragEnd.add(duration);
        }

        if (_dragEnd.difference(_dragStart).inMinutes < 30) {
          if (isTop) {
            _dragStart = _dragEnd.subtract(const Duration(minutes: 30));
          } else {
            _dragEnd = _dragStart.add(const Duration(minutes: 30));
          }
        }
      });
    }
    
    // Get the parent widget to access dayStartTime/dayEndTime
    final parentWidget = context.findAncestorWidgetOfExactType<_WeekTimeGrid>();
    if (parentWidget != null) {
      // Clamp times to day bounds using the parent's bounds
      final dayStartMinutes = (parentWidget.dayStartTime.hour) * 60 + (parentWidget.dayStartTime.minute);
      final dayEndMinutes = (parentWidget.dayEndTime.hour) * 60 + (parentWidget.dayEndTime.minute);
      
      final int startMinutes = _dragStart.hour * 60 + _dragStart.minute;
      final int endMinutes = _dragEnd.hour * 60 + _dragEnd.minute;
      
      // Apply bounds
      final int clampedStartMinutes = startMinutes.clamp(dayStartMinutes, dayEndMinutes);
      final int clampedEndMinutes = endMinutes.clamp(dayStartMinutes, dayEndMinutes);
      
      setState(() {
        _dragStart = DateTime(
          _dragStart.year,
          _dragStart.month,
          _dragStart.day,
          clampedStartMinutes ~/ 60,
          clampedStartMinutes % 60,
        );
        _dragEnd = DateTime(
          _dragEnd.year,
          _dragEnd.month,
          _dragEnd.day,
          clampedEndMinutes ~/ 60,
          clampedEndMinutes % 60,
        );
        
        // Ensure minimum duration
        if (_dragEnd.difference(_dragStart).inMinutes < 30) {
          if (isTop) {
            _dragStart = _dragEnd.subtract(const Duration(minutes: 30));
          } else {
            _dragEnd = _dragStart.add(const Duration(minutes: 30));
          }
          
          // If this goes beyond bounds, adjust the other side instead
          final int finalStartMinutes = _dragStart.hour * 60 + _dragStart.minute;
          final int finalEndMinutes = _dragEnd.hour * 60 + _dragEnd.minute;
          
          if (finalStartMinutes < dayStartMinutes) {
            _dragStart = DateTime(
              _dragStart.year,
              _dragStart.month,
              _dragStart.day,
              dayStartMinutes ~/ 60,
              dayStartMinutes % 60,
            );
            _dragEnd = _dragStart.add(const Duration(minutes: 30));
          } else if (finalEndMinutes > dayEndMinutes) {
            _dragEnd = DateTime(
              _dragEnd.year,
              _dragEnd.month,
              _dragEnd.day,
              dayEndMinutes ~/ 60,
              dayEndMinutes % 60,
            );
            _dragStart = _dragEnd.subtract(const Duration(minutes: 30));
          }
        }
      });
    }
    
    // Log after resize
    print('  After resize - Start: ${_dragStart.hour}:${_dragStart.minute.toString().padLeft(2, '0')}, End: ${_dragEnd.hour}:${_dragEnd.minute.toString().padLeft(2, '0')}');

    widget.onResize(_dragStart, _dragEnd);
  }

  void _handleDayResizeByDelta(double deltaX, bool isStart) {
    // Log for debugging RTL dragging issue
    print('DEBUG: _handleDayResizeByDelta called');
    print('  Text direction: ${widget.direction}');
    print('  Delta X: $deltaX');
    print('  Is start: $isStart');
    
    // More responsive day changes - accumulate smaller deltas but require clear intent
    if (deltaX.abs() < 15.0) return; // Minimum drag threshold

    final dayPixels = widget.dayColumnWidth*2;
    // Use a smaller divisor for more responsive movement
    var daysChange = (deltaX / (dayPixels / 4)).round(); // More sensitive scaling
    
    // For RTL, invert the horizontal direction
    if (widget.direction == TextDirection.rtl) {
      daysChange = -daysChange;
      print('  RTL: Inverted days change to: $daysChange');
    }
    
    final clampedDaysChange = daysChange.clamp(-1, 1); // Limit to single day moves
    
    print('  Days change: $daysChange, Clamped: $clampedDaysChange');

    if (clampedDaysChange == 0) return;

    // Get week boundaries
    final DateTime weekStart = widget.weekDays.first;
    final DateTime weekEnd = widget.weekDays.last;

    DateTime newDate;

    if (isStart) {
      newDate = widget.startDate.add(Duration(days: daysChange));
      // Clamp to ensure minimum 1 day duration and within week bounds
      if (newDate.isAfter(widget.endDate.subtract(Duration(days: 1)))) {
        newDate = widget.endDate;
      }
      if (newDate.isBefore(weekStart)) {
        newDate = weekStart;
      }
      if (mounted) {
        setState(() {
          _dragStart = DateTime(newDate.year, newDate.month, newDate.day, widget.startDate.hour, widget.startDate.minute);
        });
      }
    } else {
      newDate = widget.endDate.add(Duration(days: daysChange));
      // Clamp to ensure minimum 1 day duration and within week bounds
      if (newDate.isBefore(widget.startDate.add(Duration(days: 1)))) {
        newDate = widget.startDate;
      }
      if (newDate.isAfter(weekEnd)) {
        newDate = weekEnd;
      }
      if (mounted) {
        setState(() {
          _dragEnd = DateTime(newDate.year, newDate.month, newDate.day, widget.endDate.hour, widget.endDate.minute);
        });
      }
    }

    widget.onResize(_dragStart, _dragEnd);
  }

  void _handleMoveDaysByDelta(double deltaX) {
    // Log for debugging RTL dragging issue
    print('DEBUG: _handleMoveDaysByDelta called');
    print('  Text direction: ${widget.direction}');
    print('  Delta X: $deltaX');
    
    final dayPixels = widget.dayColumnWidth;
    var daysChange = (deltaX / dayPixels).round();
    
    // For RTL, invert the horizontal direction
    if (widget.direction == TextDirection.rtl) {
      daysChange = -daysChange;
      print('  RTL: Inverted days change to: $daysChange');
    }
    
    print('  Days change: $daysChange');

    if (daysChange == 0) return;

    // Get week boundaries
    final DateTime weekStart = widget.weekDays.first;
    final DateTime weekEnd = widget.weekDays.last;

    final duration = Duration(days: daysChange);
    final dif=(widget.endDate.millisecondsSinceEpoch/ (1000 * 60 * 60 * 24)).toInt()-(widget.startDate.millisecondsSinceEpoch/ (1000 * 60 * 60 * 24)).toInt(); // Force read to avoid lint
    DateTime newStart = widget.startDate.add(duration);
    DateTime newEnd = widget.endDate.add(duration);

    // Clamp start date to week bounds
    if (newStart.isBefore(weekStart)) {
      newStart = weekStart; 
      newEnd = newStart.add(Duration(days: dif));
    } else if (newEnd.isAfter(weekEnd)) {
      newEnd = weekEnd;
      newStart = newEnd.subtract(Duration(days: dif));
    }

    setState(() {
      _dragStart = DateTime(newStart.year, newStart.month, newStart.day, widget.startDate.hour, widget.startDate.minute);
      _dragEnd = DateTime(newEnd.year, newEnd.month, newEnd.day, widget.endDate.hour, widget.endDate.minute);
    });

    widget.onResize(_dragStart, _dragEnd);
  }

}
