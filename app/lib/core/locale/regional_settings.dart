import 'package:flutter/widgets.dart';

import 'locale_registry.dart';

/// Language, calendar, digits and week start are independent settings
/// (requirements §4.10; localization guide §1).
@immutable
class RegionalSettings {
  const RegionalSettings({
    required this.locale,
    required this.calendar,
    required this.digits,
    required this.firstWeekday,
  });

  factory RegionalSettings.defaultsFor(Locale locale) {
    final meta = LocaleRegistry.of(locale);
    return RegionalSettings(
      locale: meta.locale,
      calendar: meta.defaultCalendar,
      digits: meta.defaultDigits,
      firstWeekday: meta.firstWeekday,
    );
  }

  final Locale locale;
  final CalendarSystem calendar;
  final DigitStyle digits;
  final int firstWeekday;

  LocaleMeta get meta => LocaleRegistry.of(locale);
  TextDirection get direction => meta.direction;

  RegionalSettings copyWith({Locale? locale, CalendarSystem? calendar, DigitStyle? digits, int? firstWeekday}) =>
      RegionalSettings(
        locale: locale ?? this.locale,
        calendar: calendar ?? this.calendar,
        digits: digits ?? this.digits,
        firstWeekday: firstWeekday ?? this.firstWeekday,
      );

  Map<String, Object> toJson() => {
    'locale': locale.languageCode,
    'calendar': calendar.name,
    'digits': digits.name,
    'firstWeekday': firstWeekday,
  };

  static RegionalSettings? fromJson(Map<String, Object?> json) {
    final code = json['locale'];
    if (code is! String) return null;
    final base = RegionalSettings.defaultsFor(Locale(code));
    return base.copyWith(
      calendar: CalendarSystem.values.asNameMap()[json['calendar']],
      digits: DigitStyle.values.asNameMap()[json['digits']],
      firstWeekday: json['firstWeekday'] is int ? json['firstWeekday']! as int : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RegionalSettings &&
      other.locale == locale &&
      other.calendar == calendar &&
      other.digits == digits &&
      other.firstWeekday == firstWeekday;

  @override
  int get hashCode => Object.hash(locale, calendar, digits, firstWeekday);
}
