import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:jalali_table_calendar_plus/Utils/holy_day.dart';
import 'package:jalali_table_calendar_plus/Utils/options.dart';
import 'package:jalali_table_calendar_plus/Utils/event.dart';
import 'package:shamsi_date/shamsi_date.dart';

part 'package:jalali_table_calendar_plus/Utils/select_year_month.dart';

typedef OnDaySelected = void Function(DateTime day);
typedef MarkerBuilder = Widget? Function(DateTime date, List<dynamic> events);
typedef RangeDates = void Function(List<DateTime> dates);

enum CalendarType { jalali, gregorian, hijri }

String _convertToPersianNumbers(int number) {
  const Map<String, String> englishToPersian = {
    '0': '۰',
    '1': '۱',
    '2': '۲',
    '3': '۳',
    '4': '۴',
    '5': '۵',
    '6': '۶',
    '7': '۷',
    '8': '۸',
    '9': '۹',
  };
  
  return number.toString().split('').map((digit) =>
    englishToPersian[digit] ?? digit
  ).join('');
}

String _convertToPersianNumbersFromString(String number) {
  const Map<String, String> englishToPersian = {
    '0': '۰',
    '1': '۱',
    '2': '۲',
    '3': '۳',
    '4': '۴',
    '5': '۵',
    '6': '۶',
    '7': '۷',
    '8': '۸',
    '9': '۹',
  };
  
  return number.split('').map((digit) =>
    englishToPersian[digit] ?? digit
  ).join('');
}

String _convertToArabicNumbers(int number) {
  const Map<String, String> englishToArabic = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };
  
  return number.toString().split('').map((digit) =>
    englishToArabic[digit] ?? digit
  ).join('');
}

String convertNumbers(int number, CalendarType calendarType) {
  switch (calendarType) {
    case CalendarType.jalali:
      return _convertToPersianNumbers(number);
    case CalendarType.hijri:
      return _convertToArabicNumbers(number);
    case CalendarType.gregorian:
      return number.toString();
  }
}


List<String> getMonthNames(CalendarType calendarType) {
  switch (calendarType) {
    case CalendarType.jalali:
      return [
        'فروردین',
        'اردیبهشت',
        'خرداد',
        'تیر',
        'مرداد',
        'شهریور',
        'مهر',
        'آبان',
        'آذر',
        'دی',
        'بهمن',
        'اسفند',
      ];
    case CalendarType.hijri:
      return [
        'محرم',
        'صفر',
        'ربیع‌الاول',
        'ربیع‌الثانی',
        'جمادی‌الاول',
        'جمادی‌الثانی',
        'رجب',
        'شعبان',
        'رمضان',
        'شوال',
        'ذی‌قعده',
        'ذی‌حجه',
      ];
    case CalendarType.gregorian:
      return [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
  }
}

List<String> getWeekdayNames(CalendarType calendarType, TextDirection direction) {
  switch (calendarType) {
    case CalendarType.jalali:
      return ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    case CalendarType.hijri:
      return ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    case CalendarType.gregorian:
      return ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  }
}

DateTime convertDate(DateTime date, CalendarType fromType, CalendarType toType) {
  if (fromType == toType) return date;
  
  // Convert to DateTime first if needed
  DateTime baseDate = date;
  
  switch (fromType) {
    case CalendarType.jalali:
      baseDate = Jalali.fromDateTime(date).toDateTime();
      break;
    case CalendarType.hijri:
      var hijri = HijriCalendar.fromDate(date);
      baseDate = HijriCalendar().hijriToGregorian(hijri.hYear, hijri.hMonth, hijri.hDay);
      break;
    case CalendarType.gregorian:
      // Already in gregorian format
      break;
  }

  switch (toType) {
    case CalendarType.jalali:
      return Jalali.fromDateTime(baseDate).toDateTime();
    case CalendarType.hijri:
      var hijri = HijriCalendar.fromDate(baseDate);
      return HijriCalendar().hijriToGregorian(hijri.hYear, hijri.hMonth, hijri.hDay);
    case CalendarType.gregorian:
      return baseDate;
  }
}

String getDateString(DateTime date, CalendarType calendarType) {
  switch (calendarType) {
    case CalendarType.jalali:
      Jalali jalali = Jalali.fromDateTime(date);
      return '${convertNumbers(jalali.year, calendarType)}/${convertNumbers(jalali.month, calendarType)}/${convertNumbers(jalali.day, calendarType)}';
    case CalendarType.hijri:
      HijriCalendar hijri = HijriCalendar.fromDate(date);
      hijri.hYear -= 53; // Adjust for hijri package bug
      return '${convertNumbers(hijri.hYear, calendarType)}/${convertNumbers(hijri.hMonth, calendarType)}/${convertNumbers(hijri.hDay, calendarType)}';
    case CalendarType.gregorian:
      return '${date.year}/${date.month}/${date.day}';
  }
}

class JalaliTableCalendar extends StatefulWidget {
  const JalaliTableCalendar({
    super.key,
    this.direction = TextDirection.rtl,
    this.onDaySelected,
    this.marker,
    this.events,
    this.calendarEvents,
    this.onRangeSelected,
    this.range = false,
    this.useOfficialHolyDays = true,
    this.customHolyDays = const [],
    this.option,
    this.initialDate,
    this.mainCalendar = CalendarType.jalali,
    this.subCalendarLeft,
    this.subCalendarRight,
    this.showHeader = true,
  });

  final TextDirection direction;
  final MarkerBuilder? marker;
  final OnDaySelected? onDaySelected;
  final RangeDates? onRangeSelected;
  final Map<DateTime, List>? events;
  // New: list-based events with colors, id, times, isHoliday, etc.
  final List<CalendarEvent>? calendarEvents;
  final bool range;
  final bool useOfficialHolyDays;
  final List<HolyDay> customHolyDays;
  final JalaliTableCalendarOption? option;
  final DateTime? initialDate;
  final CalendarType mainCalendar;
  final CalendarType? subCalendarLeft;
  final CalendarType? subCalendarRight;
  final bool showHeader;

  @override
  JalaliTableCalendarState createState() => JalaliTableCalendarState();
}

class JalaliTableCalendarState extends State<JalaliTableCalendar> {
  dynamic _startSelectDate;

  dynamic _endSelectDate;

  late dynamic _selectedDate;

  late dynamic _selectedPage;

  late PageController _pageController;
  late ThemeData themeData;

  @override
  void initState() {
    debugPrint('DEBUG: JalaliTableCalendar initState - mainCalendar: ${widget.mainCalendar.name}');
    debugPrint('DEBUG: subCalendarLeft: ${widget.subCalendarLeft?.name ?? 'null'}');
    debugPrint('DEBUG: subCalendarRight: ${widget.subCalendarRight?.name ?? 'null'}');
    
    if (widget.initialDate != null) {
      _selectedDate = _convertToMainCalendar(widget.initialDate!);
      _selectedPage = _selectedDate;
    } else {
      var now = DateTime.now();
      _selectedDate = _convertToMainCalendar(now);
      _selectedPage = _selectedDate;
    }
    _pageController =
        PageController(initialPage: _calculateInitialPage(_selectedDate));
    super.initState();
  }

  @override
  void didUpdateWidget(covariant JalaliTableCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mainCalendar != oldWidget.mainCalendar) {
      try {
        // Preserve the currently visible date and convert to new main calendar
        final DateTime currentDateTime = _getDateTimeFromCalendar(_selectedPage);
        final dynamic newSelected = _convertToMainCalendar(currentDateTime);
        final int newPage = _calculateInitialPage(newSelected);
        setState(() {
          _selectedDate = newSelected;
          _selectedPage = newSelected;
        });
        // Jump after rebuild to ensure controller is attached
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pageController.jumpToPage(newPage);
          }
        });
      } catch (e) {
        debugPrint('ERROR: didUpdateWidget(mainCalendar) failed: $e');
      }
    }
  }

  dynamic _convertToMainCalendar(DateTime date) {
    debugPrint('DEBUG: _convertToMainCalendar called with date: $date, type: ${widget.mainCalendar.name}');
    dynamic result;
    try {
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          result = Jalali.fromDateTime(date);
          break;
        case CalendarType.hijri:
          result = HijriCalendar.fromDate(date);
          // Removed hYear adjustment for internal calculations
          break;
        case CalendarType.gregorian:
          result = date;
          break;
      }
    } catch (e) {
      debugPrint('ERROR: _convertToMainCalendar failed: $e');
      // Fallback to current date in the appropriate calendar type
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          result = Jalali.now();
          break;
        case CalendarType.hijri:
          result = HijriCalendar.fromDate(DateTime.now());
          break;
        case CalendarType.gregorian:
          result = DateTime.now();
          break;
      }
    }
    debugPrint('DEBUG: _convertToMainCalendar result type: ${result.runtimeType}, value: $result');
    return result;
  }

  int _calculateInitialPage(dynamic date) {
    debugPrint('DEBUG: _calculateInitialPage called with date: $date, type: ${date.runtimeType}, calendar: ${widget.mainCalendar.name}');
    try {
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          return (date.year - 1304) * 12 + date.month - 1;
        case CalendarType.hijri:
          return (date.hYear - 1400) * 12 + date.hMonth - 1;
        case CalendarType.gregorian:
          return (date.year - 2000) * 12 + date.month - 1;
      }
    } catch (e) {
      debugPrint('ERROR: _calculateInitialPage failed: $e');
      // Fallback to current date
      DateTime now = DateTime.now();
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          Jalali jalali = Jalali.fromDateTime(now);
          return (jalali.year - 1304) * 12 + jalali.month - 1;
        case CalendarType.hijri:
          HijriCalendar hijri = HijriCalendar.fromDate(now);
          return (hijri.hYear - 1400) * 12 + hijri.hMonth - 1;
        case CalendarType.gregorian:
          return (now.year - 2000) * 12 + now.month - 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    debugPrint('DEBUG: JalaliTableCalendar build - mainCalendar: ${widget.mainCalendar.name}, selectedPage: $_selectedPage');
    if (!widget.range) {
      _startSelectDate = null;
      _endSelectDate = null;
    }
    return Directionality(
      textDirection: widget.direction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (widget.showHeader)
            _buildHeader(),
          _buildDaysOfWeek(),
          _buildCalendarPageView()
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final List<String> monthNames = getMonthNames(widget.mainCalendar);
    bool showHeaderArrows = widget.option?.showHeaderArrows ?? true;

    debugPrint('DEBUG: _buildHeader - selectedPage: $_selectedPage, type: ${_selectedPage.runtimeType}');

    // Always derive header year/month from a DateTime to avoid stale _selectedPage type
    DateTime currentDate = _getDateTimeFromCalendar(_selectedPage);
    int calendarYear, calendarMonth;

    try {
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          final j = Jalali.fromDateTime(currentDate);
          calendarYear = j.year;
          calendarMonth = j.month;
          break;
        case CalendarType.hijri:
          final h = HijriCalendar.fromDate(currentDate);
          calendarYear = h.hYear;
          calendarMonth = h.hMonth;
          break;
        case CalendarType.gregorian:
          calendarYear = currentDate.year;
          calendarMonth = currentDate.month;
          break;
      }
      debugPrint('DEBUG: _buildHeader - calendarYear: $calendarYear, calendarMonth: $calendarMonth');
    } catch (e) {
      debugPrint('ERROR: _buildHeader failed to get year/month: $e');
      // Fallback to current date
      DateTime now = DateTime.now();
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          final jNow = Jalali.fromDateTime(now);
          calendarYear = jNow.year;
          calendarMonth = jNow.month;
          break;
        case CalendarType.hijri:
          final hNow = HijriCalendar.fromDate(now);
          calendarYear = hNow.hYear;
          calendarMonth = hNow.hMonth;
          break;
        case CalendarType.gregorian:
          calendarYear = now.year;
          calendarMonth = now.month;
          break;
      }
    }
    
    return Container(
      padding: widget.option?.headerPadding ?? const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: showHeaderArrows
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.center,
        children: [
          if (showHeaderArrows)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease);
              },
            ),
          GestureDetector(
            onTap: () async {
              int? newPage = await showDialog(
                context: context,
                builder: (_) => _SelectYearMonth(
                  year: calendarYear,
                  month: calendarMonth,
                  direction: widget.direction,
                  mainCalendar: widget.mainCalendar,
                ),
              );
              if (newPage != null) {
                _pageController.jumpToPage(newPage);
              }
            },
            child: Text(
              '${monthNames[calendarMonth - 1]} ${convertNumbers(calendarYear, widget.mainCalendar)}',
              style:
                  widget.option?.headerStyle ?? const TextStyle(fontSize: 20.0),
            ),
          ),
          if (showHeaderArrows)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    // Base names are Saturday-first for all calendar types
    final List<String> base = getWeekdayNames(widget.mainCalendar, widget.direction);
    // Allow custom titles; still rotate them according to selected start day
    final List<String> titles = widget.option?.daysOfWeekTitles ?? base;
    final WeekStartDay start = widget.option?.weekStartDay ?? WeekStartDay.saturday;

    // Rotate titles so the header starts at the configured weekday
    final List<String> rotated = _rotateWeekdayTitles(titles, start);

    // Friday is base index 6 in Saturday-first arrays; compute its index after rotation
    final int fridayIndex = (6 - _baseIndexForWeekStart(start) + 7) % 7;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final Color? fridayColor = index == fridayIndex ? themeData.primaryColor : null;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Center(
            child: Text(
              rotated[index],
              style: widget.option?.daysOfWeekStyle?.copyWith(color: fridayColor) ??
                  TextStyle(color: fridayColor),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCalendarPageView() {
    return SizedBox(
      height: 350,
      child: PageView.builder(
        itemCount: _getPageCount(),
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            var date = _getDateFromPage(page);
            _selectedPage = date;
            debugPrint('DEBUG: onPageChanged - page: $page, new date: $date, type: ${date.runtimeType}');
          });
        },
        itemBuilder: (context, index) {
          debugPrint('DEBUG: PageView itemBuilder - index: $index');
          var date = _getDateFromPage(index);
          debugPrint('DEBUG: PageView itemBuilder - date: $date, type: ${date.runtimeType}');
          int daysInMonth = _getDaysInMonth(date);
          int startingWeekday = _getStartingWeekday(date, widget.mainCalendar);
          debugPrint('DEBUG: PageView itemBuilder - daysInMonth: $daysInMonth, startingWeekday: $startingWeekday');

          // Extract correct year and month based on calendar type
          int calendarYear, calendarMonth;
          switch (widget.mainCalendar) {
            case CalendarType.jalali:
              calendarYear = date.year;
              calendarMonth = date.month;
              break;
            case CalendarType.hijri:
              calendarYear = date.hYear;
              calendarMonth = date.hMonth;
              break;
            case CalendarType.gregorian:
              calendarYear = date.year;
              calendarMonth = date.month;
              break;
          }

          debugPrint('DEBUG: PageView itemBuilder - calendarYear: $calendarYear, calendarMonth: $calendarMonth');
          return _buildGridView(calendarYear, calendarMonth, daysInMonth, startingWeekday);
        },
      ),
    );
  }
  
  int _getPageCount() {
    switch (widget.mainCalendar) {
      case CalendarType.jalali:
        return 2400; // 200 years * 12 months
      case CalendarType.hijri:
        return 2400; // Same range for simplicity
      case CalendarType.gregorian:
        return 4000; // Extended range for Gregorian
    }
  }
  
  dynamic _getDateFromPage(int page) {
    debugPrint('DEBUG: _getDateFromPage called with page: $page, calendar: ${widget.mainCalendar.name}');
    dynamic result;
    try {
      // Add bounds checking to prevent extreme year values
      int maxPage = _getPageCount();
      if (page < 0) page = 0;
      if (page >= maxPage) page = maxPage - 1;
      
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          int year = 1304 + (page ~/ 12);
          int month = (page % 12) + 1;
          // Add reasonable bounds checking for Jalali calendar
          if (year < 1300) year = 1300;
          if (year > 1500) year = 1500;
          result = Jalali(year, month, 1);
          break;
        case CalendarType.hijri:
          int year = 1400 + (page ~/ 12);
          int month = (page % 12) + 1;
          // Add reasonable bounds checking for Hijri calendar
          if (year < 1300) year = 1300;
          if (year > 1600) year = 1600;
          result = HijriCalendar()..hYear = year..hMonth = month..hDay = 1;
          // Removed hYear adjustment for internal calculations
          break;
        case CalendarType.gregorian:
          int year = 2000 + (page ~/ 12);
          int month = (page % 12) + 1;
          // Add reasonable bounds checking for Gregorian calendar
          if (year < 1900) year = 1900;
          if (year > 2100) year = 2100;
          result = DateTime(year, month, 1);
          break;
      }
    } catch (e) {
      debugPrint('ERROR: _getDateFromPage failed: $e');
      // Fallback to current date in the appropriate calendar type
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          result = Jalali.now();
          break;
        case CalendarType.hijri:
          result = HijriCalendar.fromDate(DateTime.now());
          break;
        case CalendarType.gregorian:
          result = DateTime.now();
          break;
      }
    }
    debugPrint('DEBUG: _getDateFromPage result: $result, type: ${result.runtimeType}');
    return result;
  }
  
  int _getDaysInMonth(dynamic date) {
    debugPrint('DEBUG: _getDaysInMonth called with date: $date, type: ${date.runtimeType}, calendar: ${widget.mainCalendar.name}');
    try {
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          return date.monthLength;
        case CalendarType.hijri:
          return 30; // Approximate, Hijri months are 29-30 days
        case CalendarType.gregorian:
          return DateTime(date.year, date.month + 1, 0).day;
      }
    } catch (e) {
      debugPrint('ERROR: _getDaysInMonth failed: $e');
      // Fallback to current month
      DateTime now = DateTime.now();
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          return Jalali.fromDateTime(now).monthLength;
        case CalendarType.hijri:
          return 30; // Approximate, Hijri months are 29-30 days
        case CalendarType.gregorian:
          return DateTime(now.year, now.month + 1, 0).day;
      }
    }
  }
  
  // Helper: base index for week start in a Saturday-first array (0..6)
  int _baseIndexForWeekStart(WeekStartDay start) {
    switch (start) {
      case WeekStartDay.saturday: return 0;
      case WeekStartDay.sunday: return 1;
      case WeekStartDay.monday: return 2;
      case WeekStartDay.tuesday: return 3;
      case WeekStartDay.wednesday: return 4;
      case WeekStartDay.thursday: return 5;
      case WeekStartDay.friday: return 6;
    }
  }

  // Helper: rotate 7 weekday titles by the configured week start
  List<String> _rotateWeekdayTitles(List<String> titles, WeekStartDay start) {
    final int shift = _baseIndexForWeekStart(start);
    return List<String>.generate(7, (i) => titles[(shift + i) % 7]);
  }

  // Helper: ISO weekday (1=Mon..7=Sun) value for the configured week start
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

  int _getStartingWeekday(dynamic date, CalendarType calendarType) {
    try {
      final DateTime dateTime = _getDateTimeFromCalendar(date);
      final WeekStartDay start = widget.option?.weekStartDay ?? WeekStartDay.saturday;

      // Grid position 1..7 relative to configured start day
      final int isoWeekday = dateTime.weekday; // 1=Mon..7=Sun
      final int isoStart = _isoWeekdayForStart(start);
      return ((isoWeekday - isoStart + 7) % 7) + 1;
    } catch (e) {
      debugPrint('ERROR: _getStartingWeekday failed: $e');
      return 1; // Default to first column when error occurs
    }
  }
  
  int _getWeekdayForDate(dynamic date) {
    try {
      DateTime dateTime = _getDateTimeFromCalendar(date);
      return dateTime.weekday;
    } catch (e) {
      debugPrint('ERROR: _getWeekdayForDate failed: $e');
      return 1; // Default to Monday if there's an error
    }
  }

  Widget _buildGridView(
      int year, int month, int daysInMonth, int startingWeekday) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, mainAxisSpacing: 5, mainAxisExtent: 64),
      itemCount: daysInMonth + (startingWeekday - 1),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        if (index < startingWeekday - 1) {
          return Container(
            height: 100,
          ); // Empty cell
        } else {
          int day = index - (startingWeekday - 2);
          if (day > daysInMonth) {
            day = daysInMonth;
          }
          dynamic date;
          try {
            date = _createDateFromMainCalendar(year, month, day);
          } catch (e) {
            debugPrint('ERROR: _buildGridView failed to create date: $e');
            // Fallback to current date
            date = _convertToMainCalendar(DateTime.now());
          }
          
          bool isSelected = _isSelectedDay(date);
          bool isToday = _isToday(date);
          bool isHolyDay = _isHolyDay(date);
          DateTime dateTime;
          try {
            dateTime = _getDateTimeFromCalendar(date);
          } catch (e) {
            debugPrint('ERROR: _buildGridView failed to get DateTime: $e');
            dateTime = DateTime.now();
          }
          
          Widget? marker = widget.marker != null
              ? widget.marker!(dateTime, dayEvents(dateTime))
              : null;
          // Build default event dots only when no custom marker provided
          Widget? eventDots = marker == null ? _buildEventDots(dateTime) : null;

          final styleColor = isToday && !isSelected
              ? widget.option?.currentDayColor ?? themeData.primaryColorDark
              : isSelected
                  ? widget.option?.selectedDayColor ??
                      null
                  : _isFriday(date) || isHolyDay
                      ? themeData.primaryColor
                      : null;
          return Stack(
            children: [
              if (marker == null && eventDots != null) eventDots,
              GestureDetector(
                onTap: () {
                  if (widget.range) {
                    setRange(date);
                  }
                  if (widget.onDaySelected != null) {
                    widget.onDaySelected!(dateTime);
                  }
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: isSelected
                    ? _buildLiquidGlassSelectedDay(date, styleColor)
                    : _buildDayCellWithSecondaryCalendars(date, styleColor),
              ),
              if (marker != null) marker,
            ],
          );
        }
      },
    );
  }
  
  dynamic _createDateFromMainCalendar(int year, int month, int day) {
    debugPrint('DEBUG: _createDateFromMainCalendar called with year: $year, month: $month, day: $day, calendar: ${widget.mainCalendar.name}');
    dynamic result;
    try {
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          result = Jalali(year, month, day);
          break;
        case CalendarType.hijri:
          result = HijriCalendar()..hYear = year..hMonth = month..hDay = day;
          // Removed hYear adjustment for internal calculations
          break;
        case CalendarType.gregorian:
          result = DateTime(year, month, day);
          break;
      }
    } catch (e) {
      debugPrint('ERROR: _createDateFromMainCalendar failed: $e');
      // Fallback to current date in the appropriate calendar type
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          result = Jalali.now();
          break;
        case CalendarType.hijri:
          result = HijriCalendar.fromDate(DateTime.now());
          break;
        case CalendarType.gregorian:
          result = DateTime.now();
          break;
      }
    }
    debugPrint('DEBUG: _createDateFromMainCalendar result: $result, type: ${result.runtimeType}');
    return result;
  }
  
  DateTime _getDateTimeFromCalendar(dynamic date) {
    debugPrint('DEBUG: _getDateTimeFromCalendar called with date: $date, type: ${date.runtimeType}, calendar: ${widget.mainCalendar.name}');
    DateTime result;
    
    try {
      // First check if it's already a DateTime regardless of calendar type
      if (date is DateTime) {
        result = date;
      } else {
        // Convert based on the actual type of the date object
        switch (widget.mainCalendar) {
          case CalendarType.jalali:
            if (date is Jalali) {
              result = date.toDateTime();
            } else if (date is HijriCalendar) {
              result = HijriCalendar().hijriToGregorian(date.hYear, date.hMonth, date.hDay);
            } else {
              // Fallback for unexpected types
              result = DateTime.now();
            }
            break;
          case CalendarType.hijri:
            if (date is HijriCalendar) {
              result = HijriCalendar().hijriToGregorian(date.hYear, date.hMonth, date.hDay);
            } else if (date is Jalali) {
              result = date.toDateTime();
            } else {
              // Fallback for unexpected types
              result = DateTime.now();
            }
            break;
          case CalendarType.gregorian:
            if (date is DateTime) {
              result = date;
            } else if (date is Jalali) {
              result = date.toDateTime();
            } else if (date is HijriCalendar) {
              result = HijriCalendar().hijriToGregorian(date.hYear, date.hMonth, date.hDay);
            } else {
              // Fallback for unexpected types
              result = DateTime.now();
            }
            break;
        }
      }
    } catch (e) {
      debugPrint('ERROR: _getDateTimeFromCalendar failed: $e');
      result = DateTime.now(); // Fallback to current date on any error
    }
    
    debugPrint('DEBUG: _getDateTimeFromCalendar result: $result');
    return result;
  }
  
  bool _isFriday(dynamic date) {
    try {
      DateTime dateTime = _getDateTimeFromCalendar(date);
      // In Dart, Friday is weekday 5 (1=Monday, 7=Sunday)
      return dateTime.weekday == 5;
    } catch (e) {
      debugPrint('ERROR: _isFriday failed: $e');
      return false; // Default to not Friday if there's an error
    }
  }

  List<dynamic> dayEvents(DateTime date) {
    List events = [];
    widget.events?.forEach(
      (key, value) {
        if (key == date) {
          events.add({key, value});
        }
      },
    );
    return events;
  }

  // New: collect events for a specific local DateTime day
  List<CalendarEvent> _eventsOnDay(DateTime date) {
    try {
      if (widget.calendarEvents == null || widget.calendarEvents!.isEmpty) {
        return const <CalendarEvent>[];
      }
      final day = DateTime(date.year, date.month, date.day);
      return widget.calendarEvents!.where((e) => e.occursOn(day)).toList();
    } catch (e) {
      debugPrint('ERROR: _eventsOnDay failed: $e');
      return const <CalendarEvent>[];
    }
  }

  // New: default marker showing up to 6 small colored dots centered at the bottom
  Widget? _buildEventDots(DateTime date) {
    final events = _eventsOnDay(date);
    if (events.isEmpty) return null;

    // Limit dots to avoid overflow; show first 6
    final visible = events.take(6).toList();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(visible.length, (i) {
          final color = visible[i].color;
          return Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 2,
                  spreadRadius: 0.3,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  bool _isSelectedDay(dynamic date) {
    try {
      if (widget.range && _startSelectDate != null && _endSelectDate != null) {
        DateTime dateTime = _getDateTimeFromCalendar(date);
        DateTime startRange = _getDateTimeFromCalendar(_startSelectDate!).subtract(const Duration(days: 1));
        DateTime endRange = _getDateTimeFromCalendar(_endSelectDate!).add(const Duration(days: 1));
        if (dateTime.isAfter(startRange) && dateTime.isBefore(endRange)) {
          return true;
        }
        return false;
      }

      return (!widget.range || _startSelectDate != null) &&
          _getDayFromCalendar(_selectedDate) == _getDayFromCalendar(date) &&
          _getMonthFromCalendar(_selectedDate) == _getMonthFromCalendar(date) &&
          _getYearFromCalendar(_selectedDate) == _getYearFromCalendar(date);
    } catch (e) {
      debugPrint('ERROR: _isSelectedDay failed: $e');
      return false; // Default to not selected if there's an error
    }
  }

  bool _isToday(dynamic date) {
    try {
      var toDay = _convertToMainCalendar(DateTime.now());
      return _getDayFromCalendar(date) == _getDayFromCalendar(toDay) &&
          _getMonthFromCalendar(date) == _getMonthFromCalendar(toDay) &&
          _getYearFromCalendar(date) == _getYearFromCalendar(toDay);
    } catch (e) {
      debugPrint('ERROR: _isToday failed: $e');
      return false; // Default to not today if there's an error
    }
  }

  void setRange(dynamic date) {
    try {
      if (_startSelectDate != null && _endSelectDate != null) {
        _startSelectDate = null;
        _endSelectDate = null;
      }
      if (_startSelectDate == null) {
        _startSelectDate = date;
        return;
      }
      if (_endSelectDate == null) {
        _endSelectDate = date;
        DateTime startDateTime = _getDateTimeFromCalendar(_startSelectDate!);
        DateTime endDateTime = _getDateTimeFromCalendar(date);
        if (endDateTime.isBefore(startDateTime)) {
          _endSelectDate = _startSelectDate;
          _startSelectDate = date;
        }
        DateTime day = _getDateTimeFromCalendar(_startSelectDate!);
        List<DateTime> days = [];
        while (day.isBefore(_getDateTimeFromCalendar(_endSelectDate!).add(const Duration(days: 1)))) {
          days.add(day);
          day = day.add(const Duration(days: 1));
        }
        if (widget.onRangeSelected != null) {
          widget.onRangeSelected!(days);
        }
        return;
      }
      setState(() {});
    } catch (e) {
      debugPrint('ERROR: setRange failed: $e');
      // Reset range on error
      _startSelectDate = null;
      _endSelectDate = null;
      setState(() {});
    }
  }

  bool _isHolyDay(dynamic date) {
    try {
      List<HolyDay> holyDays = [
        HolyDay(month: 01, day: 1),
        HolyDay(month: 01, day: 2),
        HolyDay(month: 01, day: 3),
        HolyDay(month: 01, day: 4),
        HolyDay(month: 01, day: 12),
        HolyDay(month: 01, day: 13),
        HolyDay(month: 03, day: 14),
        HolyDay(month: 03, day: 15),
      ];
      holyDays.addAll(widget.customHolyDays);
      for (HolyDay holyDay in holyDays) {
        if ((holyDay.year == 0 || holyDay.year == _getYearFromCalendar(date)) &&
            holyDay.month == _getMonthFromCalendar(date) &&
            holyDay.day == _getDayFromCalendar(date)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('ERROR: _isHolyDay failed: $e');
      return false; // Default to not holy day if there's an error
    }
  }
  
  int _getDayFromCalendar(dynamic date) {
    debugPrint('DEBUG: _getDayFromCalendar called with date: $date, type: ${date.runtimeType}, calendar: ${widget.mainCalendar.name}');
    try {
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          return date.day;
        case CalendarType.hijri:
          return date.hDay;
        case CalendarType.gregorian:
          return date.day;
      }
    } catch (e) {
      debugPrint('ERROR: _getDayFromCalendar failed: $e');
      // Fallback to current day
      DateTime now = DateTime.now();
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          return Jalali.fromDateTime(now).day;
        case CalendarType.hijri:
          return HijriCalendar.fromDate(now).hDay;
        case CalendarType.gregorian:
          return now.day;
      }
    }
  }
  
  int _getMonthFromCalendar(dynamic date) {
    debugPrint('DEBUG: _getMonthFromCalendar called with date: $date, type: ${date.runtimeType}, calendar: ${widget.mainCalendar.name}');
    try {
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          return date.month;
        case CalendarType.hijri:
          return date.hMonth;
        case CalendarType.gregorian:
          return date.month;
      }
    } catch (e) {
      debugPrint('ERROR: _getMonthFromCalendar failed: $e');
      // Fallback to current month
      DateTime now = DateTime.now();
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          return Jalali.fromDateTime(now).month;
        case CalendarType.hijri:
          return HijriCalendar.fromDate(now).hMonth;
        case CalendarType.gregorian:
          return now.month;
      }
    }
  }
  
  int _getYearFromCalendar(dynamic date) {
    debugPrint('DEBUG: _getYearFromCalendar called with date: $date, type: ${date.runtimeType}, calendar: ${widget.mainCalendar.name}');
    try {
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          return date.year;
        case CalendarType.hijri:
          return date.hYear;
        case CalendarType.gregorian:
          return date.year;
      }
    } catch (e) {
      debugPrint('ERROR: _getYearFromCalendar failed: $e');
      // Fallback to current year
      DateTime now = DateTime.now();
      switch (widget.mainCalendar) {
        case CalendarType.jalali:
          return Jalali.fromDateTime(now).year;
        case CalendarType.hijri:
          return HijriCalendar.fromDate(now).hYear;
        case CalendarType.gregorian:
          return now.year;
      }
    }
  }

  Widget _buildLiquidGlassSelectedDay(dynamic date, Color? styleColor) {
    bool isDark = themeData.brightness == Brightness.dark;
    DateTime dateTime;
    try {
      dateTime = _getDateTimeFromCalendar(date);
    } catch (e) {
      debugPrint('ERROR: _buildLiquidGlassSelectedDay failed to get DateTime: $e');
      dateTime = DateTime.now();
    }
    
    // Get secondary calendar dates for selected day
    String? leftCalendarText;
    String? rightCalendarText;
    
    // Only show secondary calendar text if the calendar type is not null
    if (widget.subCalendarLeft != null) {
      try {
        leftCalendarText = _getSecondaryCalendarDay(dateTime, widget.subCalendarLeft!);
      } catch (e) {
        debugPrint('ERROR: _buildLiquidGlassSelectedDay failed to get left calendar: $e');
      }
    }
    
    // Only show secondary calendar text if the calendar type is not null
    if (widget.subCalendarRight != null) {
      try {
        rightCalendarText = _getSecondaryCalendarDay(dateTime, widget.subCalendarRight!);
      } catch (e) {
        debugPrint('ERROR: _buildLiquidGlassSelectedDay failed to get right calendar: $e');
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 5,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(18),topRight: Radius.circular(26),bottomRight: Radius.circular(18),bottomLeft: Radius.circular(26)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.08),
                        ]
                            : [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.05),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        convertNumbers(_getDayFromCalendar(date), widget.mainCalendar),
                        style: widget.option?.daysStyle
                                ?.copyWith(color: styleColor) ??
                            TextStyle(color: styleColor),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (leftCalendarText != null)
            Positioned(
              bottom: 8,
              left: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  leftCalendarText!,
                  style: TextStyle(
                    fontSize: 10,
                    color: styleColor,
                  ),
                ),
              ),
            ),
          if (rightCalendarText != null)
            Positioned(
              bottom: 8,
              right: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  rightCalendarText!,
                  style: TextStyle(
                    fontSize: 10,
                    color: styleColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCellWithSecondaryCalendars(dynamic date, Color? styleColor) {
    debugPrint('DEBUG: _buildDayCellWithSecondaryCalendars called with date: $date, type: ${date.runtimeType}');
    DateTime dateTime;
    try {
      dateTime = _getDateTimeFromCalendar(date);
      debugPrint('DEBUG: _buildDayCellWithSecondaryCalendars - converted to DateTime: $dateTime');
    } catch (e) {
      debugPrint('ERROR: _buildDayCellWithSecondaryCalendars failed to get DateTime: $e');
      dateTime = DateTime.now();
    }
    
    // Get secondary calendar dates
    String? leftCalendarText;
    String? rightCalendarText;
    
    // Only show secondary calendar text if the calendar type is not null
    if (widget.subCalendarLeft != null) {
      try {
        debugPrint('DEBUG: _buildDayCellWithSecondaryCalendars - getting left calendar for type: ${widget.subCalendarLeft!.name}');
        leftCalendarText = _getSecondaryCalendarDay(dateTime, widget.subCalendarLeft!);
        debugPrint('DEBUG: _buildDayCellWithSecondaryCalendars - left calendar result: $leftCalendarText');
      } catch (e) {
        debugPrint('ERROR: _buildDayCellWithSecondaryCalendars failed to get left calendar: $e');
      }
    }
    
    // Only show secondary calendar text if the calendar type is not null
    if (widget.subCalendarRight != null) {
      try {
        debugPrint('DEBUG: _buildDayCellWithSecondaryCalendars - getting right calendar for type: ${widget.subCalendarRight!.name}');
        rightCalendarText = _getSecondaryCalendarDay(dateTime, widget.subCalendarRight!);
        debugPrint('DEBUG: _buildDayCellWithSecondaryCalendars - right calendar result: $rightCalendarText');
      } catch (e) {
        debugPrint('ERROR: _buildDayCellWithSecondaryCalendars failed to get right calendar: $e');
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                convertNumbers(_getDayFromCalendar(date), widget.mainCalendar),
                style: widget.option?.daysStyle
                        ?.copyWith(color: styleColor) ??
                    TextStyle(color: styleColor),
              ),
            ),
          ),
          if (leftCalendarText != null)
            Positioned(
              bottom: 6,
              left: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  leftCalendarText!,
                  style: TextStyle(
                    fontSize: 11,
                    color: styleColor,
                  ),
                ),
              ),
            ),
          if (rightCalendarText != null)
            Positioned(
              bottom: 6,
              right: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  rightCalendarText!,
                  style: TextStyle(
                    fontSize: 11,
                    color: styleColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _getSecondaryCalendarDay(DateTime dateTime, CalendarType calendarType) {
    debugPrint('DEBUG: _getSecondaryCalendarDay called with dateTime: $dateTime, calendarType: ${calendarType.name}');
    String result;
    try {
      switch (calendarType) {
        case CalendarType.jalali:
          Jalali jalali = Jalali.fromDateTime(dateTime);
          result = convertNumbers(jalali.day, calendarType);
          break;
        case CalendarType.hijri:
          HijriCalendar hijri = HijriCalendar.fromDate(dateTime);
          hijri.hYear -= 53; // Adjust for hijri package bug
          result = convertNumbers(hijri.hDay, calendarType);
          break;
        case CalendarType.gregorian:
          result = dateTime.day.toString();
          break;
      }
    } catch (e) {
      debugPrint('ERROR: _getSecondaryCalendarDay failed: $e');
      // Fallback to current day in the appropriate calendar type
      DateTime now = DateTime.now();
      switch (calendarType) {
        case CalendarType.jalali:
          Jalali jalali = Jalali.fromDateTime(now);
          result = convertNumbers(jalali.day, calendarType);
          break;
        case CalendarType.hijri:
          HijriCalendar hijri = HijriCalendar.fromDate(now);
          result = convertNumbers(hijri.hDay, calendarType);
          break;
        case CalendarType.gregorian:
          result = now.day.toString();
          break;
      }
    }
    debugPrint('DEBUG: _getSecondaryCalendarDay result: $result');
    return result;
  }
}
