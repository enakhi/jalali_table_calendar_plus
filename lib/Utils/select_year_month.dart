part of 'package:jalali_table_calendar_plus/Widget/table_calendar.dart';

enum SelectMode { year, month }

class SelectYearMonth extends StatefulWidget {
  const SelectYearMonth(
      {required this.month, 
       required this.year, 
       required this.direction, 
       required this.mainCalendar,
       required this.dayTitleBasedOn,
       required this.monthTitleBasedOn,
       required this.yearTitleBasedOn,
       required this.language});

  final int year;
  final int month;
  final TextDirection direction;
  final CalendarType mainCalendar;
  final DayTitleBasedOn dayTitleBasedOn;
  final DayTitleBasedOn monthTitleBasedOn;
  final DayTitleBasedOn yearTitleBasedOn;
  final String language;

  @override
  State<SelectYearMonth> createState() => SelectYearMonthState();
}

class SelectYearMonthState extends State<SelectYearMonth> {
  late PageController _pageController;
  late int page;
  late int selectedYear;
  final List<String> monthNames = [
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
  SelectMode mode = SelectMode.year;

  @override
  void initState() {
    int baseYear;
    switch (widget.mainCalendar) {
      case CalendarType.jalali:
        baseYear = 1304;
        break;
      case CalendarType.hijri:
        baseYear = 1400;
        break;
      case CalendarType.gregorian:
        baseYear = 2000;
        break;
    }
    page = (widget.year - baseYear) ~/ 12;
    _pageController = PageController(initialPage: page);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    
    // Get appropriate month names for the calendar type based on language and title preference
    List<String> monthNames;
    if (widget.monthTitleBasedOn == DayTitleBasedOn.language) {
      monthNames = getMonthNamesByLanguage(widget.mainCalendar, widget.language);
    } else {
      monthNames = _getMonthNamesForCalendar(widget.mainCalendar);
    }
    String yearFormat(int year) {
      if (widget.yearTitleBasedOn == DayTitleBasedOn.language) {
        return convertNumbersBaseOfLanguge(year, widget.language);
      } else {
        switch (widget.mainCalendar) {
          case CalendarType.jalali:
            return _convertToPersianNumbers(year);
          case CalendarType.hijri:
            return _convertToArabicNumbers(year);
          case CalendarType.gregorian:
            return year.toString();
        }
      }
    }
    
    return Directionality(
      textDirection: widget.direction,
      child: Dialog(
        child: SizedBox(
          height: height / 3.5,
          child: PageView.builder(
            itemCount: mode == SelectMode.year ? 17 : 1,
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                this.page = page;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (SelectMode.year == mode)
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease);
                        },
                      ),
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 5,
                                mainAxisExtent: 50),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          if (SelectMode.year == mode) {
                            int baseYear = widget.mainCalendar == CalendarType.jalali
                                ? 1304
                                : widget.mainCalendar == CalendarType.hijri
                                    ? 1400
                                    : 2000;
                            int year = baseYear + (page * 12);
                            return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedYear = year + index;
                                    mode = SelectMode.month;
                                  });
                                },
                                child: Center(
                                    child: Text(yearFormat(year + index))));
                          } else {
                            return GestureDetector(
                                onTap: () {
                                  // Convert back to Gregorian page index
                                  int baseYear = widget.mainCalendar == CalendarType.jalali
                                      ? 1304
                                      : widget.mainCalendar == CalendarType.hijri
                                          ? 1400
                                          : 2000;
                                  Navigator.pop(context,
                                      (selectedYear - baseYear) * 12 + index);
                                },
                                child: Center(child: Text(monthNames[index])));
                          }
                        },
                      ),
                    ),
                    if (SelectMode.year == mode)
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
            },
          ),
        ),
      ),
    );
  }
  
  List<String> _getMonthNamesForCalendar(CalendarType calendarType) {
    switch (calendarType) {
      case CalendarType.jalali:
        return monthNames;
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
}
