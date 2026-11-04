import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wyrd/core/locale/locale_registry.dart';
import 'package:wyrd/core/locale/regional_settings.dart';

void main() {
  test('empty preferences follow the device language and its defaults', () {
    final r = const RegionalPrefs().resolve(const Locale('fa'));
    expect(r.locale, const Locale('fa'));
    expect(r.calendar, CalendarSystem.jalali);
    expect(r.digits, DigitStyle.native);
    expect(r.firstWeekday, DateTime.saturday);
    expect(r.followsDevice, isTrue);
  });

  test('explicit choices win over the device', () {
    final r = const RegionalPrefs(language: 'en', calendar: CalendarSystem.jalali).resolve(const Locale('fa'));
    expect(r.locale, const Locale('en'));
    expect(r.calendar, CalendarSystem.jalali);
    expect(r.digits, DigitStyle.latin);
    expect(r.followsDevice, isFalse);
  });

  test('round-trips through JSON', () {
    const prefs = RegionalPrefs(language: 'fa', digits: DigitStyle.latin, firstWeekday: DateTime.monday);
    expect(RegionalPrefs.fromJson(prefs.toJson()), prefs);
    expect(RegionalPrefs.fromJson(const RegionalPrefs().toJson()), const RegionalPrefs());
  });

  test('version 1 settings keep only what differs from the language defaults', () {
    final prefs = RegionalPrefs.fromJson({
      'locale': 'fa',
      'calendar': 'jalali',
      'digits': 'latin',
      'firstWeekday': DateTime.saturday,
    });
    expect(prefs, const RegionalPrefs(digits: DigitStyle.latin));
  });

  test('picks the first device language the app supports', () {
    expect(LocaleRegistry.resolveAll(const [Locale('de'), Locale('fa', 'IR'), Locale('en')]), const Locale('fa'));
    expect(LocaleRegistry.resolveAll(const [Locale('de')]), const Locale('en'));
    expect(LocaleRegistry.resolveAll(const []), const Locale('en'));
  });
}
