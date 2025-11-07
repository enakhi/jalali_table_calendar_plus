import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shamsi_date/shamsi_date.dart';
import 'package:hijri/hijri_calendar.dart';
import '../models/calendar_event.dart';

/// Resolved occurrence for a specific day in Gregorian time.
class ResolvedEvent {
  final String title;
  final bool holiday;
  final String type; // Region/type, e.g. Iran, AncientIran, Afghanistan, International
  final String calendar; // Source calendar system: 'Persian' | 'Hijri' | 'Gregorian'
  final DateTime date; // Start (local midnight)
  final DateTime? endDate; // Optional end date for ranged events (inclusive)

  const ResolvedEvent({
    required this.title,
    required this.holiday,
    required this.type,
    required this.calendar,
    required this.date,
    this.endDate,
  });
}

enum _RuleType {
  nthWeekdayOfMonth, // {calendar, nth, weekday(1=Sun..7=Sat), month}
  lastWeekdayOfMonth, // {calendar, weekday(1=Sun..7=Sat), month, [offset]}
  endOfMonth, // {calendar, month}
  nthDayFrom, // {calendar=Gregorian, nth, month, day}
  singleEvent, // {calendar, year, month, day}
}

class _RuleEvent {
  final String calendar; // 'Persian' | 'Hijri' | 'Gregorian'
  final _RuleType ruleType;
  final int? nth;
  final int? weekday; // 1=Sun ... 7=Sat (matches JSON)
  final int? month;
  final int? day;
  final int? year;
  final int? offset; // day offset after computing base date
  final String type; // Region/type filter
  final String title;
  final bool holiday;

  const _RuleEvent({
    required this.calendar,
    required this.ruleType,
    required this.type,
    required this.title,
    required this.holiday,
    this.nth,
    this.weekday,
    this.month,
    this.day,
    this.year,
    this.offset,
  });
}

class EventRepository {
  // Global filters driven by app settings
  // Types: 'Iran', 'AncientIran', 'International' (never add 'Afghanistan')
  static Set<String>? _globalRegionTypes;
  // Calendars: 'Persian' | 'Hijri' | 'Gregorian'
  static Set<String>? _globalCalendars;
  // Hard exclusion for Afghanistan events
  static bool _excludeAfghanistan = true;
  // Optional inclusion for AncientIran events (code-level toggle)
  static bool _includeAncientIran = true;

  /// Apply app settings to repository global filters.
  /// - holidaysIran => include Persian calendar and Iran types (plus AncientIran if enabled)
  /// - holidaysIslamic => include Hijri calendar (Iran type in Hijri JSON)
  /// - holidaysInternational => include Gregorian calendar (International type)
  /// - includeAncientIran => toggle AncientIran inclusion
  static void applySettingsFilters({
    bool holidaysIran = true,
    bool holidaysIslamic = true,
    bool holidaysInternational = true,
    bool includeAncientIran = true,
  }) {
    _includeAncientIran = includeAncientIran;

    // Region/type filters
    final Set<String> types = <String>{};
    if (holidaysIran) {
      types.add('Iran');
      if (_includeAncientIran) types.add('AncientIran');
    }
    if (holidaysIslamic) {
      // Hijri JSON uses type 'Iran' for Islamic events
      types.add('Iran');
    }
    if (holidaysInternational) {
      types.add('International');
    }
    // Never add 'Afghanistan'
    _globalRegionTypes = types;

    // Calendar filters
    final Set<String> cals = <String>{};
    if (holidaysIran) cals.add('Persian');
    if (holidaysIslamic) cals.add('Hijri');
    if (holidaysInternational) cals.add('Gregorian');
    _globalCalendars = cals;
  }

  bool _loaded = false;

  // Fixed date events from top-level calendar sections
  final List<CalendarEvent> _fixed = [];

  // Irregular recurring/computed rules
  final List<_RuleEvent> _rules = [];

  Future<void> loadEvents({String assetPath = 'packages/jalali_table_calendar_plus/assets/data/events.json'}) async {
    if (_loaded) return;

    final String jsonString = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = json.decode(jsonString) as Map<String, dynamic>;

    // Parse fixed sections
    void loadSection(String jsonKey, String calendar) {
      if (!data.containsKey(jsonKey)) return;
      final List<dynamic> arr = data[jsonKey] as List<dynamic>;
      for (final e in arr) {
        if (e is Map<String, dynamic>) {
          _fixed.add(CalendarEvent.fromJson(e, calendar));
        } else if (e is Map) {
          _fixed.add(CalendarEvent.fromJson(e.cast<String, dynamic>(), calendar));
        }
      }
    }

    loadSection('Persian Calendar', 'Persian');
    loadSection('Hijri Calendar', 'Hijri');
    loadSection('Gregorian Calendar', 'Gregorian');

    // Parse irregular rules
    if (data.containsKey('Irregular Recurring')) {
      final List<dynamic> arr = data['Irregular Recurring'] as List<dynamic>;
      for (final raw in arr) {
        final m = raw is Map<String, dynamic> ? raw : (raw as Map).cast<String, dynamic>();
        final cal = (m['calendar'] as String).trim();
        final ruleStr = (m['rule'] as String).trim().toLowerCase();

        _RuleType? rt;
        switch (ruleStr) {
          case 'nth weekday of month':
            rt = _RuleType.nthWeekdayOfMonth;
            break;
          case 'last weekday of month':
            rt = _RuleType.lastWeekdayOfMonth;
            break;
          case 'end of month':
            rt = _RuleType.endOfMonth;
            break;
          case 'nth day from':
            rt = _RuleType.nthDayFrom;
            break;
          case 'single event':
            rt = _RuleType.singleEvent;
            break;
        }
        if (rt == null) continue;

        _rules.add(_RuleEvent(
          calendar: cal,
          ruleType: rt,
          nth: (m['nth'] as num?)?.toInt(),
          weekday: (m['weekday'] as num?)?.toInt(),
          month: (m['month'] as num?)?.toInt(),
          day: (m['day'] as num?)?.toInt(),
          year: (m['year'] as num?)?.toInt(),
          offset: (m['offset'] as num?)?.toInt(),
          type: (m['type'] as String?) ?? '',
          title: (m['title'] as String?) ?? '',
          holiday: (m['holiday'] as bool?) ?? false,
        ));
      }
    }

    _loaded = true;
  }

  // Public API: get all resolved events for a given Gregorian date
  Future<List<ResolvedEvent>> eventsOn(
    DateTime date, {
      Set<String>? regionTypes,
      Set<String>? calendars,
    }) async {
      await loadEvents();

      final d = _atLocalMidnight(date);

      // Combine provided filters with global ones (intersection when both present)
      final Set<String>? effCalendars = _intersectOrFallback(calendars, _globalCalendars);
      final Set<String>? effTypes = _effectiveTypes(regionTypes);

      final List<ResolvedEvent> result = [];

      // Fixed events
      for (final e in _fixed) {
        if (!_filterCalendar(e.calendar, effCalendars)) continue;
        if (!_filterType(e.type, effTypes)) continue;

        if (_matchesFixed(e, d)) {
          result.add(ResolvedEvent(
            title: e.title,
            holiday: e.holiday,
            type: e.type,
            calendar: e.calendar,
            date: d,
          ));
        }
      }

      // Rule events
      for (final r in _rules) {
        if (!_filterCalendar(r.calendar, effCalendars)) continue;
        if (!_filterType(r.type, effTypes)) continue;

        final match = _resolveRuleOccurrence(r, d);
        if (match == true) {
          result.add(ResolvedEvent(
            title: r.title,
            holiday: r.holiday,
            type: r.type,
            calendar: r.calendar,
            date: d,
          ));
        }
      }

      return result;
    }

  // Public API: resolve events over an inclusive date range [start, end]
  Future<List<ResolvedEvent>> eventsInRange(
    DateTime start,
    DateTime end, {
      Set<String>? regionTypes,
      Set<String>? calendars,
    }) async {
      await loadEvents();
      if (end.isBefore(start)) return [];

      final DateTime s = _atLocalMidnight(start);
      final DateTime e = _atLocalMidnight(end);
      final List<ResolvedEvent> all = [];

      DateTime d = s;
      while (!d.isAfter(e)) {
        final daily = await eventsOn(d, regionTypes: regionTypes, calendars: calendars);
        all.addAll(daily);
        d = d.add(const Duration(days: 1));
      }

      return all;
    }

  /// Check if the given Gregorian date has at least one holiday event after filters.
  Future<bool> isHoliday(
    DateTime date, {
      Set<String>? regionTypes,
      Set<String>? calendars,
    }) async {
      final events = await eventsOn(
        date,
        regionTypes: regionTypes ?? _globalRegionTypes,
        calendars: calendars ?? _globalCalendars,
      );
      return events.any((e) => e.holiday);
    }

  /// Convenience: return only holiday events for a day after filters.
  Future<List<ResolvedEvent>> holidaysOn(
    DateTime date, {
      Set<String>? regionTypes,
      Set<String>? calendars,
    }) async {
      final events = await eventsOn(
        date,
        regionTypes: regionTypes ?? _globalRegionTypes,
        calendars: calendars ?? _globalCalendars,
      );
      return events.where((e) => e.holiday).toList(growable: false);
    }

  // Legacy compatibility: returns CalendarEvent entries for the given date
  // Includes fixed and rule-based events, mapped to the originating calendar's month/day values.
  List<CalendarEvent> getEventsForDate({
    required DateTime date,
    String? type,
  }) {
    // Combine provided type with global filters
    final Set<String>? regionFilter = type == null ? _globalRegionTypes : {type};
    final Set<String>? effTypes = _effectiveTypes(regionFilter);
    final Set<String>? effCalendars = _globalCalendars;

    // Synchronously use current loaded state; caller should await loadEvents before using repository normally.
    // But keep previous behavior: lazy load if empty.
    if (!_loaded) {
      // Not awaited here to keep sync signature; rely on empty list until loadEvents is called.
      // For safety in apps, prefer using eventsOn() which awaits load.
    }

    final List<CalendarEvent> out = [];

    // Include fixed
    for (final e in _fixed) {
      if (!_filterCalendar(e.calendar, effCalendars)) continue;
      if (!_filterType(e.type, effTypes)) continue;
      if (_matchesFixed(e, date)) {
        out.add(e);
      }
    }

    // Include rules transformed to CalendarEvent using the source calendar's view of the 'date'
    for (final r in _rules) {
      if (!_filterCalendar(r.calendar, effCalendars)) continue;
      if (!_filterType(r.type, effTypes)) continue;
      if (_resolveRuleOccurrence(r, date)) {
        final (int m, int d) = switch (r.calendar) {
          'Persian' => (Jalali.fromDateTime(date).month, Jalali.fromDateTime(date).day),
          'Hijri' => (HijriCalendar.fromDate(date).hMonth, HijriCalendar.fromDate(date).hDay),
          _ => (date.month, date.day),
        };
        out.add(CalendarEvent(
          month: m,
          day: d,
          title: r.title,
          holiday: r.holiday,
          type: r.type,
          calendar: r.calendar,
          year: switch (r.ruleType) {
            _RuleType.singleEvent => r.year,
            _ => null,
          },
        ));
      }
    }

    return out;
  }

  // =========================
  // Internal helpers
  // =========================

  bool _filterType(String value, Set<String>? allowed) => allowed == null || allowed.contains(value);
  bool _filterCalendar(String value, Set<String>? allowed) => allowed == null || allowed.contains(value);

  bool _matchesFixed(CalendarEvent e, DateTime gDate) {
    switch (e.calendar) {
      case 'Persian':
        final j = Jalali.fromDateTime(gDate);
        if (e.year != null && j.year != e.year) return false;
        return j.month == e.month && j.day == e.day;
      case 'Hijri':
        final h = HijriCalendar.fromDate(gDate);
        if (e.year != null && h.hYear != e.year) return false;
        return h.hMonth == e.month && h.hDay == e.day;
      case 'Gregorian':
      default:
        if (e.year != null && gDate.year != e.year) return false;
        return gDate.month == e.month && gDate.day == e.day;
    }
  }

  // Returns true if the provided Gregorian date 'gDate' is the occurrence defined by rule 'r'
  bool _resolveRuleOccurrence(_RuleEvent r, DateTime gDate) {
    switch (r.ruleType) {
      case _RuleType.nthWeekdayOfMonth:
        return _isNthWeekdayOfMonth(r, gDate);
      case _RuleType.lastWeekdayOfMonth:
        return _isLastWeekdayOfMonth(r, gDate);
      case _RuleType.endOfMonth:
        return _isEndOfMonth(r, gDate);
      case _RuleType.nthDayFrom:
        return _isNthDayFrom(r, gDate);
      case _RuleType.singleEvent:
        return _isSingleEvent(r, gDate);
    }
  }

  bool _isSingleEvent(_RuleEvent r, DateTime gDate) {
    if (r.year == null || r.month == null || r.day == null) return false;
    switch (r.calendar) {
      case 'Persian': {
        final j = Jalali.fromDateTime(gDate);
        return j.year == r.year && j.month == r.month && j.day == r.day;
      }
      case 'Hijri': {
        final h = HijriCalendar.fromDate(gDate);
        return h.hYear == r.year && h.hMonth == r.month && h.hDay == r.day;
      }
      case 'Gregorian':
      default:
        return gDate.year == r.year && gDate.month == r.month && gDate.day == r.day;
    }
  }

  bool _isEndOfMonth(_RuleEvent r, DateTime gDate) {
    if (r.month == null) return false;
    switch (r.calendar) {
      case 'Persian': {
        final j = Jalali.fromDateTime(gDate);
        if (j.month != r.month) return false;
        final tomorrow = _atLocalMidnight(gDate.add(const Duration(days: 1)));
        final jTomorrow = Jalali.fromDateTime(tomorrow);
        return jTomorrow.month != j.month;
      }
      case 'Hijri': {
        final h = HijriCalendar.fromDate(gDate);
        if (h.hMonth != r.month) return false;
        final tomorrow = _atLocalMidnight(gDate.add(const Duration(days: 1)));
        final hTomorrow = HijriCalendar.fromDate(tomorrow);
        return hTomorrow.hMonth != h.hMonth;
      }
      case 'Gregorian':
      default: {
        if (gDate.month != r.month) return false;
        final tomorrow = _atLocalMidnight(gDate.add(const Duration(days: 1)));
        return tomorrow.month != gDate.month;
      }
    }
  }

  bool _isNthDayFrom(_RuleEvent r, DateTime gDate) {
    if (r.calendar != 'Gregorian') return false;
    if (r.nth == null || r.month == null || r.day == null) return false;
    final base = DateTime(gDate.year, r.month!, r.day!);
    final target = _atLocalMidnight(base.add(Duration(days: r.nth! - 1 + (r.offset ?? 0))));
    final today = _atLocalMidnight(gDate);
    return _sameYMD(target, today);
  }

  bool _isNthWeekdayOfMonth(_RuleEvent r, DateTime gDate) {
    if (r.nth == null || r.weekday == null || r.month == null) return false;
    final nth = r.nth!;
    final wd = r.weekday!;
    final month = r.month!;
    final today = _atLocalMidnight(gDate);

    switch (r.calendar) {
      case 'Persian': {
        final jy = Jalali.fromDateTime(today).year;
        final first = Jalali(jy, month, 1).toDateTime();
        final target = _nthWeekdayFromFirst(first, wd, nth, calendar: 'Persian', monthCheck: (DateTime d) {
          return Jalali.fromDateTime(d).month == month;
        });
        final shifted = _applyOffset(target, r.offset);
        return _sameYMD(shifted, today);
      }
      case 'Hijri': {
        final hy = HijriCalendar.fromDate(today).hYear;
        final first = HijriCalendar().hijriToGregorian(hy, month, 1);
        final target = _nthWeekdayFromFirst(first, wd, nth, calendar: 'Hijri', monthCheck: (DateTime d) {
          return HijriCalendar.fromDate(d).hMonth == month;
        });
        final shifted = _applyOffset(target, r.offset);
        return _sameYMD(shifted, today);
      }
      case 'Gregorian':
      default: {
        final gy = today.year;
        final first = DateTime(gy, month, 1);
        final target = _nthWeekdayFromFirst(first, wd, nth, calendar: 'Gregorian', monthCheck: (DateTime d) {
          return d.month == month;
        });
        final shifted = _applyOffset(target, r.offset);
        return _sameYMD(shifted, today);
      }
    }
  }

  bool _isLastWeekdayOfMonth(_RuleEvent r, DateTime gDate) {
    if (r.weekday == null || r.month == null) return false;
    final wd = r.weekday!;
    final month = r.month!;
    final today = _atLocalMidnight(gDate);

    switch (r.calendar) {
      case 'Persian': {
        final jy = Jalali.fromDateTime(today).year;
        final last = Jalali(jy, month, 1);
        final lastDay = last.monthLength;
        DateTime d = Jalali(jy, month, lastDay).toDateTime();
        while (_jsonWeekday(d) != wd) {
          d = d.subtract(const Duration(days: 1));
          if (Jalali.fromDateTime(d).month != month) return false;
        }
        final shifted = _applyOffset(d, r.offset);
        return _sameYMD(shifted, today);
      }
      case 'Hijri': {
        final hy = HijriCalendar.fromDate(today).hYear;
        final firstOfNext = (month < 12)
            ? HijriCalendar().hijriToGregorian(hy, month + 1, 1)
            : HijriCalendar().hijriToGregorian(hy + 1, 1, 1);
        DateTime d = _atLocalMidnight(firstOfNext.subtract(const Duration(days: 1)));
        while (_jsonWeekday(d) != wd) {
          d = d.subtract(const Duration(days: 1));
          if (HijriCalendar.fromDate(d).hMonth != month) return false;
        }
        final shifted = _applyOffset(d, r.offset);
        return _sameYMD(shifted, today);
      }
      case 'Gregorian':
      default: {
        final gy = today.year;
        DateTime d = DateTime(gy, month + 1, 1).subtract(const Duration(days: 1));
        while (_jsonWeekday(d) != wd) {
          d = d.subtract(const Duration(days: 1));
          if (d.month != month) return false;
        }
        final shifted = _applyOffset(d, r.offset);
        return _sameYMD(shifted, today);
      }
    }
  }

  // Compute the nth occurrence of a weekday within the month starting from 'firstDayOfMonth'
  DateTime _nthWeekdayFromFirst(
    DateTime firstDayOfMonth,
    int targetJsonWeekday,
    int nth, {
    required String calendar,
    required bool Function(DateTime) monthCheck,
  }) {
    // Advance to first occurrence
    DateTime d = _atLocalMidnight(firstDayOfMonth);
    while (_jsonWeekday(d) != targetJsonWeekday) {
      d = d.add(const Duration(days: 1));
      if (!monthCheck(d)) return d; // out of month (shouldn't happen)
    }
    // Move to nth
    d = d.add(Duration(days: 7 * (nth - 1)));
    // Validate still in same calendar month
    if (!monthCheck(d)) {
      // If overshot, there is no nth occurrence in this month; keep last valid within month by subtracting weeks
      do {
        d = d.subtract(const Duration(days: 7));
      } while (!monthCheck(d));
    }
    return d;
  }

  // Convert Dart DateTime.weekday (Mon=1..Sun=7) to JSON mapping (Sun=1..Sat=7)
  int _jsonWeekday(DateTime d) {
    final w = d.weekday; // 1..7, Mon..Sun
    // Map: Mon->2, Tue->3, Wed->4, Thu->5, Fri->6, Sat->7, Sun->1
    return (w % 7) + 1;
  }

  DateTime _applyOffset(DateTime base, int? offset) {
    if (offset == null || offset == 0) return _atLocalMidnight(base);
    return _atLocalMidnight(base.add(Duration(days: offset)));
  }

  bool _sameYMD(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _atLocalMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

  // =========================
  // Global filter helpers
  // =========================

  // Intersect two sets when both provided, otherwise fallback to whichever is non-null.
  static Set<T>? _intersectOrFallback<T>(Set<T>? a, Set<T>? b) {
    if (a == null) return b;
    if (b == null) return a;
    final s = Set<T>.from(a);
    s.retainAll(b);
    return s;
  }

  // Effective type set honoring Afghanistan exclusion and AncientIran toggle.
  static Set<String>? _effectiveTypes(Set<String>? provided) {
    // If nothing provided, fallback to global
    final Set<String>? base = provided ?? _globalRegionTypes;
    if (base == null) {
      // Default: exclude Afghanistan, include Iran + International (+AncientIran if enabled)
      final Set<String> defaults = {'Iran', 'International'};
      if (_includeAncientIran) defaults.add('AncientIran');
      return defaults;
    }
    final Set<String> filtered = base.where((t) {
      if (_excludeAfghanistan && t == 'Afghanistan') return false;
      if (t == 'AncientIran' && !_includeAncientIran) return false;
      return true;
    }).toSet();
    return filtered;
  }
}