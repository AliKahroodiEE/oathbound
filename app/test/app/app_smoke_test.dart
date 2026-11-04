import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wyrd/app/app.dart';
import 'package:wyrd/app/providers.dart';
import 'package:wyrd/app/router.dart';
import 'package:wyrd/core/locale/regional_settings.dart';
import 'package:wyrd/data/db/database.dart';
import 'package:wyrd/data/models.dart';
import 'package:wyrd/data/repositories/quest_repository.dart';
import 'package:wyrd/data/repositories/settings_repository.dart';

/// [locale] pins the app language; null follows the (test) device.
Future<AppDatabase> _seeded(Locale? locale, {ThemePreference theme = ThemePreference.system}) async {
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
  final settings = SettingsRepository(db);
  await settings.saveProfile(UserProfile(characterName: 'Arin', onboardingComplete: true, theme: theme));
  if (locale != null) await settings.saveRegionalPrefs(RegionalPrefs(language: locale.languageCode));
  await QuestRepository(db).create(const QuestDraft(title: 'Study electronics 90m'));
  return db;
}

Future<void> _pump(WidgetTester tester, AppDatabase db, {Size size = const Size(400, 860)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), initialOnboardedProvider.overrideWithValue(true)],
      child: const WyrdApp(),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('character sheet renders in English, left to right', (tester) async {
    final db = await tester.runAsync(() => _seeded(const Locale('en')));
    await _pump(tester, db!);
    expect(find.text('Arin'), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('Study electronics 90m'), findsOneWidget);
    final dir = tester.widget<Directionality>(find.byType(Directionality).first);
    expect(dir.textDirection, TextDirection.ltr);
    await tester.runAsync(db.close);
  });

  testWidgets('character sheet renders in Persian, right to left', (tester) async {
    final db = await tester.runAsync(() => _seeded(const Locale('fa')));
    await _pump(tester, db!);
    expect(find.text('قدرت'), findsOneWidget);
    expect(find.text('شخصیت'), findsWidgets);
    final scaffold = find.byType(Scaffold).first;
    expect(Directionality.of(tester.element(scaffold)), TextDirection.rtl);
    await tester.runAsync(db.close);
  });

  testWidgets('follows the device language when none was chosen', (tester) async {
    // German is unsupported, so the next preferred language wins.
    tester.platformDispatcher.localesTestValue = const [Locale('de', 'DE'), Locale('fa', 'IR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final db = await tester.runAsync(() => _seeded(null));
    await _pump(tester, db!);
    expect(find.text('قدرت'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(Scaffold).first)), TextDirection.rtl);
    await tester.runAsync(db.close);
  });

  testWidgets('a chosen language wins over the device language', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fa', 'IR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final db = await tester.runAsync(() => _seeded(const Locale('en')));
    await _pump(tester, db!);
    expect(find.text('Strength'), findsOneWidget);
    await tester.runAsync(db.close);
  });

  testWidgets('light and dark themes follow the saved preference', (tester) async {
    for (final (pref, brightness) in [
      (ThemePreference.light, Brightness.light),
      (ThemePreference.dark, Brightness.dark),
    ]) {
      final db = await tester.runAsync(() => _seeded(const Locale('en'), theme: pref));
      await _pump(tester, db!);
      expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, brightness);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(db.close);
    }
  });

  testWidgets('the quick theme menu switches the theme from the character sheet', (tester) async {
    final db = await tester.runAsync(() => _seeded(const Locale('en'), theme: ThemePreference.dark));
    await _pump(tester, db!);
    Brightness brightness() => Theme.of(tester.element(find.byType(Scaffold).first)).brightness;
    expect(brightness(), Brightness.dark);
    await tester.tap(find.byTooltip('Theme'));
    // One frame to start the menu's entrance, then let it finish.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Light').last);
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(brightness(), Brightness.light);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });

  testWidgets('expanded width shows the sidebar', (tester) async {
    final db = await tester.runAsync(() => _seeded(const Locale('en')));
    await _pump(tester, db!, size: const Size(1440, 900));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('New quest'), findsWidgets);
    await tester.runAsync(db.close);
  });
}
