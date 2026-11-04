import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException, AuthRetryableFetchException;
import 'package:wyrd/app/app.dart';
import 'package:wyrd/app/providers.dart';
import 'package:wyrd/app/router.dart';
import 'package:wyrd/core/locale/regional_settings.dart';
import 'package:wyrd/data/db/database.dart';
import 'package:wyrd/data/remote/backend.dart';
import 'package:wyrd/data/repositories/settings_repository.dart';

/// Sign-in errors show wherever the app is: on the web the app has just
/// reloaded from the provider's page, so no sign-in screen is open.
void main() {
  setUpAll(() => initializeDateFormatting());

  late StreamController<Object> errors;
  setUp(() => errors = StreamController<Object>());
  tearDown(() => unawaited(errors.close()));

  const cancelled = AuthException('The user has denied your application access.', code: 'access_denied');

  /// The whole app on the character sheet, in [language], with Auth's errors
  /// coming from [errors]. Pass the result to [closeApp] at the end.
  Future<AppDatabase> pumpApp(WidgetTester tester, {String language = 'en'}) async {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    await tester.runAsync(() async {
      final settings = SettingsRepository(db);
      await settings.saveProfile(const UserProfile(characterName: 'Arin', onboardingComplete: true));
      await settings.saveRegionalPrefs(RegionalPrefs(language: language));
    });
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          initialOnboardedProvider.overrideWithValue(true),
          authErrorsProvider.overrideWithValue(errors.stream),
        ],
        child: const WyrdApp(),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return db;
  }

  Future<void> closeApp(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  }

  /// Lets an error arrive and its snack bar slide in.
  Future<void> arrive(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
  }

  testWidgets('a cancelled Google or GitHub sign-in is explained on whatever screen is open', (tester) async {
    final db = await pumpApp(tester);
    expect(find.text('Arin'), findsOneWidget, reason: 'the character sheet, not the sign-in screen');

    errors.add(cancelled);
    await arrive(tester);
    expect(find.widgetWithText(SnackBar, 'Sign-in was cancelled.'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('an error from the link that opened the app shows once the app is up', (tester) async {
    errors.add(cancelled); // Before the app listens, as when the web app reloads.
    final db = await pumpApp(tester);
    await arrive(tester);
    expect(find.widgetWithText(SnackBar, 'Sign-in was cancelled.'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('the web app reopened at the link\'s fragment lands home and shows it there', (tester) async {
    // Hash routing reads `#error=…` as the location the app opens at.
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        'error=access_denied&error_description=The+user+has+denied+your+application+access.';
    addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
    errors.add(cancelled);
    final db = await pumpApp(tester);
    await arrive(tester);
    expect(find.text('Arin'), findsOneWidget, reason: 'the character sheet, not "Page Not Found"');
    expect(find.widgetWithText(SnackBar, 'Sign-in was cancelled.'), findsOneWidget);
    await closeApp(tester, db);
  });

  testWidgets('in Persian, right to left', (tester) async {
    final db = await pumpApp(tester, language: 'fa');
    errors.add(cancelled);
    await arrive(tester);
    expect(find.widgetWithText(SnackBar, 'ورود لغو شد.'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('ورود لغو شد.'))), TextDirection.rtl);
    await closeApp(tester, db);
  });

  testWidgets('a lost connection or a failed token refresh stays quiet', (tester) async {
    final db = await pumpApp(tester);
    errors
      ..add(AuthRetryableFetchException(message: 'ClientException: Failed host lookup'))
      ..add(AuthRetryableFetchException(statusCode: '503'))
      ..add(const AuthException('Initial session is missing data.', code: 'session_missing'));
    await arrive(tester);
    expect(find.byType(SnackBar), findsNothing);

    errors.add(cancelled); // Still listening after them.
    await arrive(tester);
    expect(find.byType(SnackBar), findsOneWidget);
    await closeApp(tester, db);
  });
}
