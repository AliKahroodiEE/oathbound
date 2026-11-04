import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'data/db/database.dart';
import 'data/repositories/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final db = AppDatabase();
  final profile = await SettingsRepository(db).profile();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialOnboardedProvider.overrideWithValue(profile.onboardingComplete),
      ],
      child: const OathboundApp(),
    ),
  );
}
