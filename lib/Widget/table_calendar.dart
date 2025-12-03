import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:jalali_table_calendar_plus/Utils/holy_day.dart';
import 'package:jalali_table_calendar_plus/Utils/options.dart';
import 'package:jalali_table_calendar_plus/Utils/event.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:jalali_table_calendar_plus/repositories/event_repository.dart';

part 'package:jalali_table_calendar_plus/Utils/select_year_month.dart';
part 'package:jalali_table_calendar_plus/Widget/select_year_month_dialog.dart';

typedef OnDaySelected = void Function(DateTime day);
typedef MarkerBuilder = Widget? Function(DateTime date, List<dynamic> events);
typedef RangeDates = void Function(List<DateTime> dates);
typedef OnPageRangeChanged = void Function(DateTime start, DateTime endExclusive);

enum CalendarType { jalali, gregorian, hijri }

// View type to allow layout adjustments (e.g., cell height for monthly view)
enum CalendarViewType { schedule, monthly, weekly }

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
String convertNumbersBaseOfLanguge(int number, String lang) {
  switch (lang) {
    case "fa":
      return _convertToPersianNumbers(number);
    case "ar":
      return _convertToArabicNumbers(number);
    default:
      return number.toString();
  }
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


List<String> getMonthNames(CalendarType calendarType, {String language = 'en', DayTitleBasedOn basedOn = DayTitleBasedOn.calendar}) {
  if (basedOn == DayTitleBasedOn.language) {
    return getMonthNamesByLanguage(calendarType, language);
  } else {
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
}

List<String> getMonthNamesByLanguage(CalendarType calendarType, String language) {
  switch (calendarType) {
    case CalendarType.jalali:
      switch (language) {
        case 'fa':
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
        case 'ar':
          return [
  'فَروَردين',
  'أرديبهِشت',
  'خُرْداد',
  'تير',
  'مُرْداد',
  'شهْريور',
  'مِهْر',
  'آبَان',
  'آذَر',
  'دِی',
  'بَهْمَن',
  'اسْفَند',
];
        case 'en':
        default:
          return [
            'Farvardin',
            'Ordibehesht',
            'Khordad',
            'Tir',
            'Mordad',
            'Shahrivar',
            'Mehr',
            'Aban',
            'Azar',
            'Dey',
            'Bahman',
            'Esfand',
          ];
      }
    case CalendarType.hijri:
      switch (language) {
        case 'ar':
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
        case 'fa':
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
        case 'en':
        default:
          return [
            'Muharram',
            'Safar',
            'Rabi\' al-awwal',
            'Rabi\' al-thani',
            'Jumada al-awwal',
            'Jumada al-thani',
            'Rajab',
            'Sha\'ban',
            'Ramadan',
            'Shawwal',
            'Dhu al-Qi\'dah',
            'Dhu al-Hijjah',
          ];
      }
    case CalendarType.gregorian:
      switch (language) {
        case 'fa':
          return [
            'ژانویه',
            'فوریه',
            'مارس',
            'آوریل',
            'مه',
            'ژوئن',
            'ژوئیه',
            'اوت',
            'سپتامبر',
            'اکتبر',
            'نوامبر',
            'دسامبر',
          ];
        case 'ar':
          return [
            'يناير',
            'فبراير',
            'مارس',
            'أبريل',
            'مايو',
            'يونيو',
            'يوليو',
            'أغسطس',
            'سبتمبر',
            'أكتوبر',
            'نوفمبر',
            'ديسمبر',
          ];
        case 'en':
        default:
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
}

List<String> getWeekdayNames(CalendarType calendarType, TextDirection direction, {String language = 'en', DayTitleBasedOn basedOn = DayTitleBasedOn.calendar}) {
  if (basedOn == DayTitleBasedOn.language) {
    return getWeekdayNamesByLanguage(language);
  } else {
    switch (calendarType) {
      case CalendarType.jalali:
        return ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
      case CalendarType.hijri:
        return ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
      case CalendarType.gregorian:
        return ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    }
  }
}

List<String> getWeekdayNamesByLanguage(String language) {
  switch (language) {
    case 'fa':
      return ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    case 'ar':
      return ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    case 'en':
    default:
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

String getDateString(DateTime date, CalendarType calendarType,String lang) {
  switch (calendarType) {
    case CalendarType.jalali:
      Jalali jalali = Jalali.fromDateTime(date);
      return '${convertNumbersBaseOfLanguge(jalali.year,lang)}/${convertNumbersBaseOfLanguge(jalali.month,lang)}/${convertNumbersBaseOfLanguge(jalali.day,lang)}';
    case CalendarType.hijri:
      HijriCalendar hijri = HijriCalendar.fromDate(date);
      hijri.hYear -= 53; // Adjust for hijri package bug
      return '${convertNumbersBaseOfLanguge(hijri.hYear,lang)}/${convertNumbersBaseOfLanguge(hijri.hMonth,lang)}/${convertNumbersBaseOfLanguge(hijri.hDay,lang)}';
    case CalendarType.gregorian:
      return '${convertNumbersBaseOfLanguge(date.year,lang)}/${convertNumbersBaseOfLanguge(date.month,lang)}/${convertNumbersBaseOfLanguge(date.day,lang)}';
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
    // New: pass the view type to control layout specifics
    this.viewType = CalendarViewType.schedule,
    // New: page range change callback (start, endExclusive)
    this.onPageRangeChanged,
    // New: header text change callback (month title and year/month)
    this.onHeaderTextChanged,
  });

  final TextDirection direction;
  final MarkerBuilder? marker;
  final OnDaySelected? onDaySelected;
  final RangeDates? onRangeSelected;
  final Map<DateTime, List>? events;
  // New: list-based events with colors, id, times, isHoliday, etc.
  final List<UserEvent>? calendarEvents;
  final bool range;
  final bool useOfficialHolyDays;
  final List<HolyDay> customHolyDays;
  final JalaliTableCalendarOption? option;
  final DateTime? initialDate;
  final CalendarType mainCalendar;
  final CalendarType? subCalendarLeft;
  final CalendarType? subCalendarRight;
  // New: current view type (schedule/monthly/weekly)
  final CalendarViewType viewType;
  // New: page range change listener
  final OnPageRangeChanged? onPageRangeChanged;
  /// Callback for header text (month title) changes. Provides (title, year, month) in mainCalendar.
  final void Function(String title, int year, int month)? onHeaderTextChanged;
 
  @override
  JalaliTableCalendarState createState() => JalaliTableCalendarState();
}

extension JalaliTableCalendarStateExtension on JalaliTableCalendarState {
  void jumpToPage(int page) {
    _pageController.jumpToPage(page);
  }

  void jumpToToday() {
    final now = DateTime.now();
    final page = _calculateInitialPage(_convertToMainCalendar(now));
    _pageController.jumpToPage(page);
    // Update selected date
    setState(() {
      _selectedDate = _convertToMainCalendar(now);
    });
  }

  void jumpToDate(DateTime date) {
    final page = _calculateInitialPage(_convertToMainCalendar(date));
    _pageController.jumpToPage(page);
    // Update selected date
    setState(() {
      _selectedDate = _convertToMainCalendar(date);
    });
  }
}

class JalaliTableCalendarState extends State<JalaliTableCalendar> {
  dynamic _startSelectDate;

  dynamic _endSelectDate;

  late dynamic _selectedDate;

  late dynamic _selectedPage;

  late PageController _pageController;
  late ThemeData themeData;

  // Events repository for official holiday resolution
  late final EventRepository _eventRepository;
  bool _eventsLoaded = false;

  @override
  void initState() {

    
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

    // Initialize events repository and load official events for holiday checks
    _eventRepository = EventRepository();
    _eventRepository.loadEvents().then((_) {
      if (mounted) {
        setState(() {
          _eventsLoaded = true;
        });
      }
    });
 
    // Emit initial header (month title/year/month) after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final dynamic dateObj = _selectedPage;
        int y, m;
        switch (widget.mainCalendar) {
          case CalendarType.jalali:
            y = dateObj.year;
            m = dateObj.month;
            break;
          case CalendarType.hijri:
            y = dateObj.hYear;
            m = dateObj.hMonth;
            break;
          case CalendarType.gregorian:
            y = dateObj.year;
            m = dateObj.month;
            break;
        }
        final monthNames = getMonthNames(widget.mainCalendar,
            language: widget.option?.language ?? 'en',
            basedOn: widget.option?.monthTitleBasedOn ?? DayTitleBasedOn.calendar)[m - 1];
        final title = '$monthNames $y';
        widget.onHeaderTextChanged?.call(title, y, m);
      } catch (e) {
        debugPrint('ERROR: init header emit failed: $e');
      }
    });
 
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
    return result;
  }

  int _calculateInitialPage(dynamic date) {
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
          if (widget.option?.showHeader ?? true)
            _buildHeader(),
          _buildDaysOfWeek(),
          _buildCalendarPageView()
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final List<String> monthNames = getMonthNames(widget.mainCalendar,
        language: widget.option?.language ?? 'en',
        basedOn: widget.option?.monthTitleBasedOn ?? DayTitleBasedOn.calendar);
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
                builder: (_) => SelectYearMonth(
                  year: calendarYear,
                  month: calendarMonth,
                  direction: widget.direction,
                  mainCalendar: widget.mainCalendar,
                  dayTitleBasedOn: widget.option?.dayTitleBasedOn ?? DayTitleBasedOn.calendar,
                  monthTitleBasedOn: widget.option?.monthTitleBasedOn ?? DayTitleBasedOn.calendar,
                  yearTitleBasedOn: widget.option?.yearTitleBasedOn ?? DayTitleBasedOn.calendar,
                  language: widget.option?.language ?? 'en',
                ),
              );
              if (newPage != null) {
                _pageController.jumpToPage(newPage);
              }
            },
            child: Text(
              '${monthNames[calendarMonth - 1]} ${_convertYear(calendarYear)}',
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
    final List<String> base = getWeekdayNames(widget.mainCalendar, widget.direction,
        language: widget.option?.language ?? 'en',
        basedOn: widget.option?.dayTitleBasedOn ?? DayTitleBasedOn.calendar);
    // Allow custom titles; still rotate them according to selected start day
    final List<String> titles = widget.option?.daysOfWeekTitles ?? base;
    final WeekStartDay start = widget.option?.weekStartDay ?? WeekStartDay.saturday;

    // Rotate titles so the header starts at the configured weekday
    final List<String> rotated = _rotateWeekdayTitles(titles, start);

    // Get weekend days for highlighting
    final List<int> weekendDays = widget.option?.weekendDays ?? _getDefaultWeekendDays();
    // Convert weekend days to indices in the rotated array
    final List<int> weekendIndices = weekendDays.map((weekday) {
      // Convert weekday (1=Monday..7=Sunday) to base index (0=Saturday..6=Friday)
      final int baseIndex = (weekday - 6 + 7) % 7; // Saturday=0, Sunday=1, Monday=2, ..., Friday=6
      // Apply rotation to get the actual index in the displayed array
      return (baseIndex - _baseIndexForWeekStart(start) + 7) % 7;
    }).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final Color? weekendColor = weekendIndices.contains(index) ? themeData.colorScheme.primary : null;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Center(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    rotated[index],
                    style: widget.option?.daysOfWeekStyle?.copyWith(
                          color: weekendColor,
                        ) ??
                        TextStyle(
                          color: weekendColor,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                )),
          ),
        );
      }),
    );
  }

  Widget _buildCalendarPageView() {
    // Dynamically compute height for monthly view so the entire month grid fits without vertical scrolling.
    double _computeHeightForCurrentPage() {
      if (widget.viewType != CalendarViewType.monthly) {
        final dynamic date = _selectedPage;
        final int daysInMonth = _getDaysInMonth(date);
        final int startingWeekday = _getStartingWeekday(date, widget.mainCalendar);
        final int slots = daysInMonth + (startingWeekday - 1);
        final int rows = ((slots + 6) ~/ 7); // ceil(slots / 7)
        const double cellExtent = 70; // must match GridView mainAxisExtent for monthly
        const double rowSpacing = 0; // no spacing between rows
        final double height = rows * cellExtent + (rows - 1) * rowSpacing;
        return height;
      }
      try {
        final dynamic date = _selectedPage;
        final int daysInMonth = _getDaysInMonth(date);
        final int startingWeekday = _getStartingWeekday(date, widget.mainCalendar);
        final int slots = daysInMonth + (startingWeekday - 1);
        final int rows = ((slots + 6) ~/ 7); // ceil(slots / 7)
        const double cellExtent = 106; // must match GridView mainAxisExtent for monthly
        const double rowSpacing = 0; // no spacing between rows
        final double height = rows * cellExtent + (rows - 1) * rowSpacing;
        return height;
      } catch (e) {
        debugPrint('ERROR: _computeHeightForCurrentPage failed: $e');
        return 410;
      }
    }

    final double height = _computeHeightForCurrentPage();

    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: _getPageCount(),
        controller: _pageController,
        onPageChanged: (int page) {
          final dynamic dateObj = _getDateFromPage(page);
          setState(() {
            _selectedPage = dateObj;
            debugPrint('DEBUG: onPageChanged - page: $page, new date: $dateObj, type: ${dateObj.runtimeType}');
          });
          // Notify listener with visible page range (start..endExclusive)
          try {
            DateTime start;
            DateTime endExclusive;
            switch (widget.mainCalendar) {
              case CalendarType.jalali:
                // dateObj is Jalali(year, month, 1)
                start = Jalali(dateObj.year, dateObj.month, 1).toDateTime();
                final next = (dateObj.month < 12)
                    ? Jalali(dateObj.year, dateObj.month + 1, 1)
                    : Jalali(dateObj.year + 1, 1, 1);
                endExclusive = next.toDateTime();
                break;
              case CalendarType.hijri:
                // dateObj is HijriCalendar with hYear/hMonth
                final int hy = dateObj.hYear;
                final int hm = dateObj.hMonth;
                start = HijriCalendar().hijriToGregorian(hy, hm, 1);
                final int nextHm = hm < 12 ? hm + 1 : 1;
                final int nextHy = hm < 12 ? hy : hy + 1;
                endExclusive = HijriCalendar().hijriToGregorian(nextHy, nextHm, 1);
                break;
              case CalendarType.gregorian:
                // dateObj is DateTime(year, month, 1)
                start = DateTime(dateObj.year, dateObj.month, 1);
                endExclusive = (dateObj.month < 12)
                    ? DateTime(dateObj.year, dateObj.month + 1, 1)
                    : DateTime(dateObj.year + 1, 1, 1);
                break;
            }
            if (widget.onPageRangeChanged != null) {
              widget.onPageRangeChanged!(start, endExclusive);
            }
          } catch (e) {
            debugPrint('ERROR: onPageChanged range compute failed: $e');
          }
          // Emit header text (month title) for external header
          try {
            int y, m;
            switch (widget.mainCalendar) {
              case CalendarType.jalali:
                y = dateObj.year;
                m = dateObj.month;
                break;
              case CalendarType.hijri:
                y = dateObj.hYear;
                m = dateObj.hMonth;
                break;
              case CalendarType.gregorian:
                y = dateObj.year;
                m = dateObj.month;
                break;
            }
            final monthNames = getMonthNames(widget.mainCalendar,
                language: widget.option?.language ?? 'en',
                basedOn: widget.option?.monthTitleBasedOn ?? DayTitleBasedOn.calendar)[m - 1];
            final title = '$monthNames $y';
            widget.onHeaderTextChanged?.call(title, y, m);
          } catch (e) {
            debugPrint('ERROR: onPageChanged header emit failed: $e');
          }
        },
        itemBuilder: (context, index) {
          var date = _getDateFromPage(index);
          int daysInMonth = _getDaysInMonth(date);
          int startingWeekday = _getStartingWeekday(date, widget.mainCalendar);

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
    return result;
  }
  
  int _getDaysInMonth(dynamic date) {
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
    int slots = daysInMonth + (startingWeekday - 1);
    int numRows = ((slots + 6) ~/ 7);
    double cellHeight = widget.viewType == CalendarViewType.monthly ? 106 : 68;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(numRows, (rowIndex) {
        return Container(
          height: cellHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color.fromARGB(255, 220, 223, 228).withOpacity(0.2),
                width: 1.5,
              ),
            ),
          ),
          child: Padding(padding: EdgeInsetsGeometry.only(bottom: 6),child: Row(
            children: List.generate(7, (colIndex) {
              int index = rowIndex * 7 + colIndex;
              if (index < startingWeekday - 1 || index >= slots) {
                return Expanded(child: Container());
              } else {
                int day = index - (startingWeekday - 2);
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

                // Custom marker receives events from the new calendarEvents API if available;
                // otherwise fallback to legacy Map-based events.
                final List<dynamic> markerData = (widget.calendarEvents != null)
                    ? _eventsOnDay(dateTime)
                    : dayEvents(dateTime);
                Widget? marker = widget.marker != null
                    ? widget.marker!(dateTime, markerData)
                    : null;
                // Ensure custom marker participates in Stack layout. If it isn't already a Positioned,
                // expand it to the cell bounds so layout constraints are tight.
                if (marker != null && marker is! Positioned) {
                  marker = Positioned.fill(child: marker);
                }
                // Default event rendering when no custom marker provided
                Widget? eventWidget;
                if (marker == null) {
                  if (widget.viewType == CalendarViewType.monthly) {
                    eventWidget = _buildEventChips(dateTime);
                  } else {
                    eventWidget = _buildEventDots(dateTime);
                  }
                }

                final styleColor = isToday && !isSelected
                    ? widget.option?.currentDayColor ?? themeData.colorScheme.primary
                    : isSelected
                        ? widget.option?.selectedDayColor ??
                            null
                        : _isWeekend(date) || isHolyDay
                            ? themeData.colorScheme.primary
                            : null;
                return Expanded(
                  child: GestureDetector(
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
                    child: Stack(
                      children: [
                        if (marker == null && eventWidget != null) eventWidget,
                        _buildDayCellWithSecondaryCalendars(date, styleColor, isSelected),
                        if (marker != null) marker,
                      ],
                    ),
                  ),
                );
              }
            }),
          )),
        );
      }),
    );
  }
  
  dynamic _createDateFromMainCalendar(int year, int month, int day) {
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
    return result;
  }
  
  DateTime _getDateTimeFromCalendar(dynamic date) {
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
      result = DateTime.now(); // Fallback to current date on any error
    }
    
    return result;
  }
  
  bool _isWeekend(dynamic date) {
    try {
      DateTime dateTime = _getDateTimeFromCalendar(date);
      // Get weekend days from options or default based on calendar type
      List<int> weekendDays = widget.option?.weekendDays ?? _getDefaultWeekendDays();
      return weekendDays.contains(dateTime.weekday);
    } catch (e) {
      debugPrint('ERROR: _isWeekend failed: $e');
      return false; // Default to not weekend if there's an error
    }
  }

  List<int> _getDefaultWeekendDays() {
    switch (widget.mainCalendar) {
      case CalendarType.jalali:
      case CalendarType.hijri:
        return [5]; // Friday
      case CalendarType.gregorian:
        return [7]; // Sunday
    }
  }

  String _convertYear(int year) {
    if (widget.option?.yearTitleBasedOn == DayTitleBasedOn.language) {
      return convertNumbersBaseOfLanguge(year, widget.option?.language ?? 'en');
    } else {
      return convertNumbers(year, widget.mainCalendar);
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
  List<UserEvent> _eventsOnDay(DateTime date) {
    try {
      if (widget.calendarEvents == null || widget.calendarEvents!.isEmpty) {
        return const <UserEvent>[];
      }
      final day = DateTime(date.year, date.month, date.day);
      return widget.calendarEvents!.where((e) => e.occursOn(day)).toList();
    } catch (e) {
      debugPrint('ERROR: _eventsOnDay failed: $e');
      return const <UserEvent>[];
    }
  }

    // Default marker when no custom marker is supplied.
    // For monthly view: render stacked chips with event titles.
    // For table/non-monthly views: show up to 4 items; when there are more than 4
    // events, render the first 3 colored dots and a "+" as the 4th item.
    // Special case: when there is exactly 1 event on the day (table/schedule views),
    // render a horizontal line whose width represents the event duration within the day.
    // Entire day => full width. Half-day => half width. Other durations proportional.
    // The minimum bar width is not less than the dot size for visibility.
    Widget? _buildEventDots(DateTime date) {
      final events = _eventsOnDay(date);
      if (events.isEmpty) return null;

      // Single-event rendering: proportional timeline bar
      if (events.length == 1) {
        final e = events.first;
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double availRaw = constraints.maxWidth;
                final double avail = (availRaw.isFinite && availRaw > 0) ? availRaw : 60.0;
                const double barHeight = 6.0;
                const double minBarWidth = 12.0; // >= dot diameter (7)

                // Compute start/duration within a 24h day in minutes
                int startMin = 0;
                int endMin = 24 * 60;

                if (!e.isEntireday) {
                  if (e.startTime != null) {
                    startMin = e.startTime!.hour * 60 + e.startTime!.minute;
                  }
                  if (e.endTime != null) {
                    endMin = e.endTime!.hour * 60 + e.endTime!.minute;
                  }
                  // Guard invalid ranges
                  if (endMin <= startMin) {
                    endMin = (startMin + 1).clamp(0, 24 * 60);
                  }
                }

                final int duration = (endMin - startMin).clamp(1, 24 * 60);
                double startFraction = (startMin / (24 * 60)).clamp(0.0, 1.0);
                double widthFraction = (duration / (24 * 60)).clamp(0.0, 1.0);

                double leftPx = avail * startFraction;
                final double effectiveMin = minBarWidth <= avail ? minBarWidth : avail;
                double widthPx = (avail * widthFraction).clamp(effectiveMin, avail);

                // Clamp to the available width and keep minimum width visible
                if (leftPx + widthPx > avail) {
                  widthPx = avail - leftPx;
                  if (widthPx < effectiveMin) {
                    leftPx = (avail - effectiveMin).clamp(0.0, avail);
                    widthPx = effectiveMin;
                  }
                }

                // Ensure finite size for the positioned bar by constraining the Stack.
                return SizedBox(
                  width: avail,
                  height: barHeight + 2,
                  child: Stack(
                    children: [
                      Positioned(
                        left: leftPx,
                        bottom: 1,
                        child: Container(
                          width: widthPx,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: e.userEventColor,
                            border: Border.all(color: e.userEventBorderColor, width: 1.0),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: e.userEventColor.withOpacity(0.35),
                                blurRadius: 3,
                                spreadRadius: 0.3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }

      // Multi-event rendering (existing dots behavior)
      // Compute the day text color to match "+" color with day number color.
      final bool isSelected = _isSelectedDay(date);
      final bool isToday = _isToday(date);
      final bool isHolyDay = _isHolyDay(date);
      final Color? styleColor = isToday && !isSelected
          ? widget.option?.currentDayColor ?? themeData.colorScheme.primary
          : isSelected
              ? widget.option?.selectedDayColor ?? null
              : (_isWeekend(date) || isHolyDay)
                  ? themeData.colorScheme.primary
                  : null;
      final Color plusColor = styleColor ??
          (widget.option?.daysStyle?.color ??
              (themeData.textTheme.bodyMedium?.color ?? Colors.black87));

      const int maxVisibleItems = 4;
      final bool showPlus = events.length > maxVisibleItems;
      final int dotCount =
          showPlus ? 3 : (events.length.clamp(0, maxVisibleItems));

      final List<Widget> children = List<Widget>.generate(dotCount, (i) {
        final color = events[i].userEventColor;
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: events[i].userEventBorderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 2,
                spreadRadius: 0.3,
              ),
            ],
          ),
        );
      });

      if (showPlus) {
        children.add(Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          child: Icon(Icons.add, size: 9, color: plusColor),
        ));
      }

      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      );
    }

  // Monthly view event chips: vertical list of rounded labels under the day number.
  // If there are more than 2 events, show the first 2 chips and add a "+(count-2)" badge.
  Widget? _buildEventChips(DateTime date) {
    final events = _eventsOnDay(date);
    if (events.isEmpty) return null;

    final bool isSingleEvent = events.length == 1;
    final List<UserEvent> visible = isSingleEvent ? events.take(1).toList() : events.take(2).toList();
    final int overflowCount = isSingleEvent ? 0 : (events.length - 2);

    return Positioned(
      top: 54, // below day number and secondary calendar texts
      left: 4,
      right: 4,
      bottom: 0,
      child: Stack(
        children: [
          // Chips column
          Column(
            mainAxisSize: MainAxisSize.max,
            children: List.generate(visible.length, (i) {
              final e = visible[i];
              final bg = e.userEventColor.withOpacity(0.90);
              final on = (bg.computeLuminance() < 0.5) ? Colors.white : Colors.black87;
              return isSingleEvent
                  ? Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 0),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        decoration: BoxDecoration(
                          color: bg,
                          border: Border.all(color: e.userEventBorderColor, width: 1.0),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: e.userEventColor.withOpacity(0.35),
                              blurRadius: 6,
                              spreadRadius: 0.3,
                            ),
                          ],
                        ),
                        child: Text(
                          e.userEventTitle,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          style: TextStyle(
                            fontSize: 8,
                            color: on,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                            letterSpacing: -0.0625,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border.all(color: e.userEventBorderColor, width: 1.0),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: e.userEventColor.withOpacity(0.35),
                            blurRadius: 6,
                            spreadRadius: 0.3,
                          ),
                        ],
                      ),
                      child: Text(
                        e.userEventTitle,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 8,
                          color: on,
                          fontWeight: FontWeight.w600,
                          height: 2.0,
                          letterSpacing: 0.0,
                        ),
                      ),
                    );
            }),
          ),
          // Overflow indicator: "+(count-2)"
          if (!isSingleEvent && overflowCount > 0)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: themeData.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${convertNumbers(overflowCount, widget.mainCalendar)}',
                  style: TextStyle(
                    color: themeData.colorScheme.onPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
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
      // Prefer official events from repository when enabled and loaded
      final DateTime dt = _getDateTimeFromCalendar(date);
      if (widget.useOfficialHolyDays && _eventsLoaded) {
        final events = _eventRepository.getEventsForDate(date: dt);
        if (events.any((e) => e.holiday)) {
          return true;
        }
      }

      // Fallback: static built-in + custom holy days
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
      // silent error for out of range
      return false; // Default to not holy day if there's an error
    }
  }
  
  int _getDayFromCalendar(dynamic date) {
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

  Widget _buildDayCellWithSecondaryCalendars(dynamic date, Color? styleColor, [bool isSelected = false]) {
    DateTime dateTime;
    try {
      dateTime = _getDateTimeFromCalendar(date);
    } catch (e) {
      dateTime = DateTime.now();
    }
    
    // Get secondary calendar dates
    String? leftCalendarText;
    String? rightCalendarText;
    
    // Only show secondary calendar text if the calendar type is not null
    if (widget.subCalendarLeft != null) {
      try {
        leftCalendarText = _getSecondaryCalendarDay(dateTime, widget.subCalendarLeft!);
      } catch (e) {
        debugPrint('ERROR: _buildDayCellWithSecondaryCalendars failed to get left calendar: $e');
      }
    }
    
    // Only show secondary calendar text if the calendar type is not null
    if (widget.subCalendarRight != null) {
      try {
        rightCalendarText = _getSecondaryCalendarDay(dateTime, widget.subCalendarRight!);
      } catch (e) {
        debugPrint('ERROR: _buildDayCellWithSecondaryCalendars failed to get right calendar: $e');
      }
    }
    bool isToday = _isToday(date);
    if (isSelected) {
      bool isDark = themeData.brightness == Brightness.dark;
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
                      width: 35,
                      height: 35,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isToday && widget.option?.todayBackgroundColor != null ?
                          [
                            widget.option!.todayBackgroundColor!.withValues(alpha: 0.8),
                            widget.option!.todayBackgroundColor!.withValues(alpha: 0.8),
                          ] : isDark
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
                          color: Colors.white.withValues(alpha: isToday ? 0.6 : 0.3),
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
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              convertNumbers(_getDayFromCalendar(date),
                                  widget.mainCalendar),
                              style: widget.option?.daysStyle?.copyWith(
                                    color: isToday &&
                                        widget.option?.todayOnColor != null
                                    ? widget.option!.todayOnColor
                                    : styleColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ) ??
                                  TextStyle(
                                    color: isToday &&
                                        widget.option?.todayOnColor != null
                                    ? widget.option!.todayOnColor
                                    : styleColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                            )),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (leftCalendarText != null)
              Positioned(
                top: 38,
                left: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    leftCalendarText!,
                    style: TextStyle(
                      fontSize: 11,
                      color: styleColor,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            if (rightCalendarText != null)
              Positioned(
                top: 38,
                right: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    rightCalendarText!,
                    style: TextStyle(
                      fontSize: 11,
                      color: styleColor,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: isToday && widget.option?.todayBackgroundColor != null
                      ? BoxDecoration(
                          color: widget.option!.todayBackgroundColor,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Center(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          convertNumbers(
                              _getDayFromCalendar(date), widget.mainCalendar),
                          style: widget.option?.daysStyle?.copyWith(
                                color: isToday &&
                                        widget.option?.todayOnColor != null
                                    ? widget.option!.todayOnColor
                                    : styleColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ) ??
                              TextStyle(
                                color: isToday &&
                                        widget.option?.todayOnColor != null
                                    ? widget.option!.todayOnColor
                                    : styleColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                        )),
                  ),
                ),
              ),
            ),
            if (leftCalendarText != null)
              Positioned(
                top: 38,
                left: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    leftCalendarText!,
                    style: TextStyle(
                      color: styleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            if (rightCalendarText != null)
              Positioned(
                top: 38,
                right: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    rightCalendarText!,
                    style: TextStyle(
                      color: styleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }
  
  String _getSecondaryCalendarDay(DateTime dateTime, CalendarType calendarType) {
    // DEBUG print removed for production
    String result = '';
    if (calendarType == CalendarType.hijri) {
      final hijriMin = DateTime(1937, 3, 14);
      final hijriMax = DateTime(2077, 11, 16);
      if (dateTime.isBefore(hijriMin) || dateTime.isAfter(hijriMax)) {
        return result;
      }
    }
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
      result = '';
    }
    return result;
  }
}
