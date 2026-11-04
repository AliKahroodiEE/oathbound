import 'package:flutter/widgets.dart';

enum CalendarSystem { gregorian, jalali }

enum DigitStyle { latin, native }

/// Everything the app needs to know about a supported language.
/// Adding a language = adding its ARB file and one entry here
/// (docs/localization.md §2).
class LocaleMeta {
  const LocaleMeta({
    required this.locale,
    required this.nativeName,
    required this.direction,
    required this.defaultCalendar,
    required this.defaultDigits,
    required this.firstWeekday,
    required this.nativeZeroCodeUnit,
  });

  final Locale locale;
  final String nativeName;
  final TextDirection direction;
  final CalendarSystem defaultCalendar;
  final DigitStyle defaultDigits;

  /// [DateTime.monday]..[DateTime.sunday].
  final int firstWeekday;

  /// Code unit of the script's native zero (e.g. U+06F0 for Persian).
  final int nativeZeroCodeUnit;
}

abstract final class LocaleRegistry {
  static const List<LocaleMeta> all = [
    LocaleMeta(
      locale: Locale('en'),
      nativeName: 'English',
      direction: TextDirection.ltr,
      defaultCalendar: CalendarSystem.gregorian,
      defaultDigits: DigitStyle.latin,
      firstWeekday: DateTime.monday,
      nativeZeroCodeUnit: 0x30,
    ),
    LocaleMeta(
      locale: Locale('fa'),
      nativeName: 'فارسی',
      direction: TextDirection.rtl,
      defaultCalendar: CalendarSystem.jalali,
      defaultDigits: DigitStyle.native,
      firstWeekday: DateTime.saturday,
      nativeZeroCodeUnit: 0x06F0,
    ),
  ];

  static List<Locale> get supportedLocales => [for (final m in all) m.locale];

  static LocaleMeta of(Locale locale) => all.firstWhere(
    (m) => m.locale.languageCode == locale.languageCode,
    orElse: () => all.first,
  );

  /// Best supported match for the device locale.
  static Locale resolve(Locale? device) {
    if (device == null) return all.first.locale;
    return of(device).locale;
  }
}
