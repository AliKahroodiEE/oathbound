// Renders the README screenshots: the real app with its real fonts and six
// weeks of demo data, in English and Persian, light and dark, phone and
// desktop. Each shot uses the defaults a new user has, so language and theme
// are both on Auto and follow the (simulated) device.
//
//   flutter test --dart-define=SCREENSHOTS=true --update-goldens test/screenshots/readme_screenshots_test.dart
//
// Skipped in normal test runs. Output: raw PNGs in app/build/readme/, which
// tool/readme_images.py turns into the WebP files under docs/.
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wyrd/app/app.dart';
import 'package:wyrd/app/providers.dart';
import 'package:wyrd/app/router.dart';
import 'package:wyrd/data/db/database.dart';
import 'package:wyrd/data/demo/demo_seed.dart';
import 'package:wyrd/features/quests/complete_flow.dart';

import 'support.dart';

const _out = '../../build/readme';

Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  Locale locale,
  Size logical,
  double dpr,
  Brightness brightness,
) async {
  final db = (await tester.runAsync(() async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await seedDemo(db, locale: locale);
    return db;
  }))!;
  addTearDown(() => tester.runAsync(db.close));
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
  addTearDown(tester.view.reset);
  // The simulated device: its language and its light/dark setting.
  tester.platformDispatcher.localesTestValue = [locale];
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), initialOnboardedProvider.overrideWithValue(true)],
      child: const WyrdApp(),
    ),
  );
  await _settle(tester);
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _go(WidgetTester tester, ProviderContainer c, String location) async {
  c.read(routerProvider).go(location);
  await _settle(tester);
}

Future<void> _shot(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('$_out/$name.png'));

void main() {
  setUpAll(() async {
    if (!screenshotsEnabled) return;
    await initializeDateFormatting();
    await loadAppFonts();
  });

  const phone = Size(390, 844);
  const desktop = Size(1440, 900);

  for (final brightness in Brightness.values) {
    final t = brightness == Brightness.dark ? 'dark' : 'light';
    for (final lang in ['en', 'fa']) {
      final locale = Locale(lang);
      final suffix = '$t-$lang';

      testWidgets('desktop character sheet ($suffix)', skip: !screenshotsEnabled, (tester) async {
        await _pumpApp(tester, locale, desktop, 1, brightness);
        await _shot(tester, 'desktop-character-$suffix');
      });

      testWidgets('desktop chronicle ($suffix)', skip: !screenshotsEnabled, (tester) async {
        final c = await _pumpApp(tester, locale, desktop, 1, brightness);
        await _go(tester, c, '/chronicle');
        await _shot(tester, 'desktop-chronicle-$suffix');
      });

      testWidgets('phone character sheet ($suffix)', skip: !screenshotsEnabled, (tester) async {
        await _pumpApp(tester, locale, phone, 2, brightness);
        await _shot(tester, 'phone-character-$suffix');
      });

      testWidgets('phone quests ($suffix)', skip: !screenshotsEnabled, (tester) async {
        final c = await _pumpApp(tester, locale, phone, 2, brightness);
        await _go(tester, c, '/quests');
        await _shot(tester, 'phone-quests-$suffix');
      });

      testWidgets('phone reward reveal ($suffix)', skip: !screenshotsEnabled, (tester) async {
        final c = await _pumpApp(tester, locale, phone, 2, brightness);
        // The seeded daily study habit: planned, with a when-and-where intention.
        final title = lang == 'fa' ? 'مطالعه‌ی الکترونیک' : 'Study electronics';
        final outcome = await tester.runAsync(() async {
          final today = await c.read(questRepositoryProvider).today(DateTime.monday);
          final study = today.firstWhere((v) => v.quest.title == title).quest;
          return c.read(progressionRepositoryProvider).complete(study, declaredMinutes: 90);
        });
        final context = c.read(routerProvider).routerDelegate.navigatorKey.currentContext!;
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => RewardSheet(outcome: outcome!, questTitle: title),
        );
        await _settle(tester);
        await _shot(tester, 'phone-reward-$suffix');
      });

      testWidgets('phone chronicle ($suffix)', skip: !screenshotsEnabled, (tester) async {
        final c = await _pumpApp(tester, locale, phone, 2, brightness);
        await _go(tester, c, '/chronicle');
        await _shot(tester, 'phone-chronicle-$suffix');
      });

      testWidgets('phone settings ($suffix)', skip: !screenshotsEnabled, (tester) async {
        final c = await _pumpApp(tester, locale, phone, 2, brightness);
        await _go(tester, c, '/settings');
        await _shot(tester, 'phone-settings-$suffix');
      });
    }
  }
}
