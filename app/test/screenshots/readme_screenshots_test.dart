// Renders README screenshots with the real fonts and six weeks of demo data.
//
//   flutter test --dart-define=SCREENSHOTS=true --update-goldens test/screenshots
//
// Skipped in normal test runs. Output: docs/screenshots/*.png at the repo root.
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
import 'package:wyrd/data/repositories/settings_repository.dart';
import 'package:wyrd/features/quests/complete_flow.dart';

import 'support.dart';

const _enabled = screenshotsEnabled;
const _out = '../../../docs/screenshots';

Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  Locale locale,
  Size logical,
  double dpr,
  ThemePreference theme,
) async {
  final db = (await tester.runAsync(() async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await seedDemo(db, locale: locale, pinLanguage: true);
    await SettingsRepository(db).updateProfile((p) => p.copyWith(theme: theme));
    return db;
  }))!;
  addTearDown(() => tester.runAsync(db.close));
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
  addTearDown(tester.view.reset);
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
    if (!_enabled) return;
    await initializeDateFormatting();
    await loadAppFonts();
  });

  const phone = Size(390, 844);
  const desktop = Size(1440, 900);

  for (final theme in [ThemePreference.dark, ThemePreference.light]) {
    final t = theme.name;

    testWidgets('desktop character sheet ($t, English)', skip: !_enabled, (tester) async {
      await _pumpApp(tester, const Locale('en'), desktop, 1, theme);
      await _shot(tester, 'desktop-character-$t-en');
    });

    testWidgets('desktop chronicle ($t, English)', skip: !_enabled, (tester) async {
      final c = await _pumpApp(tester, const Locale('en'), desktop, 1, theme);
      await _go(tester, c, '/chronicle');
      await _shot(tester, 'desktop-chronicle-$t-en');
    });

    testWidgets('phone character sheet ($t, English)', skip: !_enabled, (tester) async {
      await _pumpApp(tester, const Locale('en'), phone, 2, theme);
      await _shot(tester, 'phone-character-$t-en');
    });

    testWidgets('phone character sheet ($t, Persian)', skip: !_enabled, (tester) async {
      await _pumpApp(tester, const Locale('fa'), phone, 2, theme);
      await _shot(tester, 'phone-character-$t-fa');
    });

    testWidgets('phone quests ($t, English)', skip: !_enabled, (tester) async {
      final c = await _pumpApp(tester, const Locale('en'), phone, 2, theme);
      await _go(tester, c, '/quests');
      await _shot(tester, 'phone-quests-$t-en');
    });

    testWidgets('phone reward reveal ($t, English)', skip: !_enabled, (tester) async {
      final c = await _pumpApp(tester, const Locale('en'), phone, 2, theme);
      // The seeded daily study habit: planned, with a when-and-where intention.
      final outcome = await tester.runAsync(() async {
        final today = await c.read(questRepositoryProvider).today(DateTime.monday);
        final study = today.firstWhere((v) => v.quest.title == 'Study electronics').quest;
        return c.read(progressionRepositoryProvider).complete(study, declaredMinutes: 90);
      });
      final context = c.read(routerProvider).routerDelegate.navigatorKey.currentContext!;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => RewardSheet(outcome: outcome!, questTitle: 'Study electronics'),
      );
      await _settle(tester);
      await _shot(tester, 'phone-reward-$t-en');
    });

    testWidgets('phone chronicle ($t, Persian)', skip: !_enabled, (tester) async {
      final c = await _pumpApp(tester, const Locale('fa'), phone, 2, theme);
      await _go(tester, c, '/chronicle');
      await _shot(tester, 'phone-chronicle-$t-fa');
    });

    testWidgets('phone settings ($t, English)', skip: !_enabled, (tester) async {
      final c = await _pumpApp(tester, const Locale('en'), phone, 2, theme);
      await _go(tester, c, '/settings');
      await _shot(tester, 'phone-settings-$t-en');
    });
  }
}
