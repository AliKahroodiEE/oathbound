import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../l10n/generated/app_localizations.dart';
import '../locale/locale_registry.dart';
import '../locale/regional_settings.dart';

/// The only place numbers, dates and durations become text
/// (localization guide §3). Calendar and digits follow the user's
/// regional settings, independently of the UI language.
class AppFormatters {
  AppFormatters(this.settings, this.l10n);

  final RegionalSettings settings;
  final AppLocalizations l10n;

  String get _tag => settings.locale.languageCode;

  /// Converts every digit in [input] to the configured digit style.
  String digits(String input) {
    final zero = settings.digits == DigitStyle.native ? settings.meta.nativeZeroCodeUnit : 0x30;
    final out = StringBuffer();
    for (final unit in input.runes) {
      final value = _digitValue(unit);
      out.writeCharCode(value == null ? unit : zero + value);
    }
    return out.toString();
  }

  static int? _digitValue(int unit) {
    if (unit >= 0x30 && unit <= 0x39) return unit - 0x30;
    if (unit >= 0x06F0 && unit <= 0x06F9) return unit - 0x06F0;
    if (unit >= 0x0660 && unit <= 0x0669) return unit - 0x0660;
    return null;
  }

  String number(num value) {
    final pattern = settings.digits == DigitStyle.native
        ? NumberFormat.decimalPattern(_tag)
        : NumberFormat.decimalPattern(_tag == 'fa' ? 'en' : _tag);
    return digits(pattern.format(value));
  }

  /// Signed number. A left-to-right mark keeps the sign on the number's
  /// left in right-to-left text ("+۱۲", not "۱۲+").
  String signedNumber(num value) => value > 0 ? '\u200E+${number(value)}' : number(value);

  String percent(double fraction) {
    final f = NumberFormat.percentPattern(settings.digits == DigitStyle.native ? _tag : 'en');
    return digits(f.format(fraction));
  }

  /// Signed percentage change; the mark keeps "+" left of the digits in RTL.
  String signedPercent(double fraction) => fraction > 0 ? '\u200E+${percent(fraction)}' : percent(fraction);

  /// "1 h 30 min" / "۱ ساعت و ۳۰ دقیقه".
  String duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return l10n.durationMinutes(number(m));
    return l10n.durationHoursMinutes(number(h), number(m));
  }

  /// Day, month and year in the configured calendar.
  String date(DateTime d) {
    if (settings.calendar == CalendarSystem.jalali) {
      final j = Jalali.fromDateTime(d);
      final month = jalaliMonth(j.month);
      return _tag == 'fa' ? digits('${j.day} $month ${j.year}') : digits('$month ${j.day}, ${j.year}');
    }
    return digits(DateFormat.yMMMd(_tag).format(d));
  }

  /// Day and month without the year.
  String dayMonth(DateTime d) {
    if (settings.calendar == CalendarSystem.jalali) {
      final j = Jalali.fromDateTime(d);
      final month = jalaliMonth(j.month);
      return _tag == 'fa' ? digits('${j.day} $month') : digits('$month ${j.day}');
    }
    return digits(DateFormat.MMMd(_tag).format(d));
  }

  /// "Aban 1405" / "November 2026".
  String monthYear(DateTime d) {
    if (settings.calendar == CalendarSystem.jalali) {
      final j = Jalali.fromDateTime(d);
      return digits('${jalaliMonth(j.month)} ${j.year}');
    }
    return digits(DateFormat.yMMMM(_tag).format(d));
  }

  String year(DateTime d) =>
      settings.calendar == CalendarSystem.jalali ? digits('${Jalali.fromDateTime(d).year}') : digits('${d.year}');

  String weekdayShort(DateTime d) => DateFormat.E(_tag).format(d);

  String weekdayLong(DateTime d) => DateFormat.EEEE(_tag).format(d);

  String time(DateTime d) => digits(DateFormat.Hm(_tag).format(d));

  /// Today / Tomorrow / Yesterday, or the date.
  String relativeDay(DateTime d, DateTime now) {
    final a = DateTime(d.year, d.month, d.day);
    final b = DateTime(now.year, now.month, now.day);
    final diff = a.difference(b).inDays;
    return switch (diff) {
      0 => l10n.dueToday,
      1 => l10n.dueTomorrow,
      -1 => l10n.dueYesterday,
      _ => dayMonth(d),
    };
  }

  /// Month index 1..12 within the configured calendar for [d].
  int calendarMonth(DateTime d) => settings.calendar == CalendarSystem.jalali ? Jalali.fromDateTime(d).month : d.month;

  /// First instant of the calendar month containing [d].
  DateTime startOfMonth(DateTime d) {
    if (settings.calendar == CalendarSystem.jalali) {
      final j = Jalali.fromDateTime(d);
      return Jalali(j.year, j.month, 1).toDateTime();
    }
    return DateTime(d.year, d.month);
  }

  DateTime addMonths(DateTime monthStart, int delta) {
    if (settings.calendar == CalendarSystem.jalali) {
      final j = Jalali.fromDateTime(monthStart);
      var m = j.month + delta;
      var y = j.year;
      while (m > 12) {
        m -= 12;
        y++;
      }
      while (m < 1) {
        m += 12;
        y--;
      }
      return Jalali(y, m, 1).toDateTime();
    }
    return DateTime(monthStart.year, monthStart.month + delta);
  }

  DateTime startOfYear(DateTime d) {
    if (settings.calendar == CalendarSystem.jalali) {
      return Jalali(Jalali.fromDateTime(d).year, 1, 1).toDateTime();
    }
    return DateTime(d.year);
  }

  DateTime addYears(DateTime yearStart, int delta) {
    if (settings.calendar == CalendarSystem.jalali) {
      return Jalali(Jalali.fromDateTime(yearStart).year + delta, 1, 1).toDateTime();
    }
    return DateTime(yearStart.year + delta);
  }

  String jalaliMonth(int month) => switch (month) {
    1 => l10n.jalaliMonth1,
    2 => l10n.jalaliMonth2,
    3 => l10n.jalaliMonth3,
    4 => l10n.jalaliMonth4,
    5 => l10n.jalaliMonth5,
    6 => l10n.jalaliMonth6,
    7 => l10n.jalaliMonth7,
    8 => l10n.jalaliMonth8,
    9 => l10n.jalaliMonth9,
    10 => l10n.jalaliMonth10,
    11 => l10n.jalaliMonth11,
    _ => l10n.jalaliMonth12,
  };
}
