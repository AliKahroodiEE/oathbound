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

Future<AppDatabase> _seeded(Locale locale) async {
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
  final settings = SettingsRepository(db);
  await settings.saveProfile(const UserProfile(characterName: 'Arin', onboardingComplete: true));
  await settings.saveRegional(RegionalSettings.defaultsFor(locale));
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

  testWidgets('expanded width shows the sidebar', (tester) async {
    final db = await tester.runAsync(() => _seeded(const Locale('en')));
    await _pump(tester, db!, size: const Size(1440, 900));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('New quest'), findsWidgets);
    await tester.runAsync(db.close);
  });
}
