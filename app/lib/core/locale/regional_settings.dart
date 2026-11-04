import 'package:flutter/widgets.dart';

import 'locale_registry.dart';

/// Language, calendar, digits and week start are independent settings
/// (requirements §4.10; localization guide §1). This is the resolved set
/// the app runs with; [RegionalPrefs] is what the user actually chose.
@immutable
class RegionalSettings {
  const RegionalSettings({
    required this.locale,
    required this.calendar,
    required this.digits,
    required this.firstWeekday,
    this.followsDevice = false,
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

  /// Whether [locale] is the device language rather than a chosen one.
  final bool followsDevice;

  LocaleMeta get meta => LocaleRegistry.of(locale);
  TextDirection get direction => meta.direction;

  RegionalSettings copyWith({Locale? locale, CalendarSystem? calendar, DigitStyle? digits, int? firstWeekday}) =>
      RegionalSettings(
        locale: locale ?? this.locale,
        calendar: calendar ?? this.calendar,
        digits: digits ?? this.digits,
        firstWeekday: firstWeekday ?? this.firstWeekday,
        followsDevice: followsDevice,
      );

  @override
  bool operator ==(Object other) =>
      other is RegionalSettings &&
      other.locale == locale &&
      other.calendar == calendar &&
      other.digits == digits &&
      other.firstWeekday == firstWeekday &&
      other.followsDevice == followsDevice;

  @override
  int get hashCode => Object.hash(locale, calendar, digits, firstWeekday, followsDevice);
}

/// What the user chose. A null field follows the device: the language
/// tracks the device language, and calendar, digits and week start track
/// that language's defaults until set explicitly.
@immutable
class RegionalPrefs {
  const RegionalPrefs({this.language, this.calendar, this.digits, this.firstWeekday});

  /// Language code, or null to use the device language.
  final String? language;
  final CalendarSystem? calendar;
  final DigitStyle? digits;
  final int? firstWeekday;

  /// The settings to run with, given the device's preferred language.
  RegionalSettings resolve(Locale device) {
    final base = RegionalSettings.defaultsFor(language == null ? device : Locale(language!));
    return RegionalSettings(
      locale: base.locale,
      calendar: calendar ?? base.calendar,
      digits: digits ?? base.digits,
      firstWeekday: firstWeekday ?? base.firstWeekday,
      followsDevice: language == null,
    );
  }

  static const _unset = Object();

  RegionalPrefs copyWith({
    Object? language = _unset,
    Object? calendar = _unset,
    Object? digits = _unset,
    Object? firstWeekday = _unset,
  }) => RegionalPrefs(
    language: language == _unset ? this.language : language as String?,
    calendar: calendar == _unset ? this.calendar : calendar as CalendarSystem?,
    digits: digits == _unset ? this.digits : digits as DigitStyle?,
    firstWeekday: firstWeekday == _unset ? this.firstWeekday : firstWeekday as int?,
  );

  Map<String, Object?> toJson() => {
    'v': 2,
    'language': language,
    'calendar': calendar?.name,
    'digits': digits?.name,
    'firstWeekday': firstWeekday,
  };

  factory RegionalPrefs.fromJson(Map<String, Object?> json) {
    if (json['v'] != 2) return RegionalPrefs._fromV1(json);
    final language = json['language'];
    return RegionalPrefs(
      language: language is String && LocaleRegistry.isSupported(Locale(language)) ? language : null,
      calendar: CalendarSystem.values.asNameMap()[json['calendar']],
      digits: DigitStyle.values.asNameMap()[json['digits']],
      firstWeekday: _weekday(json['firstWeekday']),
    );
  }

  /// Version 1 stored fully resolved settings, written by onboarding even
  /// when nothing was changed. Keep only what differs from that language's
  /// defaults, so the language follows the device from now on.
  factory RegionalPrefs._fromV1(Map<String, Object?> json) {
    final code = json['locale'];
    if (code is! String) return const RegionalPrefs();
    final defaults = RegionalSettings.defaultsFor(Locale(code));
    final calendar = CalendarSystem.values.asNameMap()[json['calendar']];
    final digits = DigitStyle.values.asNameMap()[json['digits']];
    final weekday = _weekday(json['firstWeekday']);
    return RegionalPrefs(
      calendar: calendar == defaults.calendar ? null : calendar,
      digits: digits == defaults.digits ? null : digits,
      firstWeekday: weekday == defaults.firstWeekday ? null : weekday,
    );
  }

  static int? _weekday(Object? v) => v is int && v >= DateTime.monday && v <= DateTime.sunday ? v : null;

  @override
  bool operator ==(Object other) =>
      other is RegionalPrefs &&
      other.language == language &&
      other.calendar == calendar &&
      other.digits == digits &&
      other.firstWeekday == firstWeekday;

  @override
  int get hashCode => Object.hash(language, calendar, digits, firstWeekday);
}
