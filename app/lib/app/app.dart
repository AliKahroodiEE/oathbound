import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/sync_coordinator.dart';
import '../data/repositories/settings_repository.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../features/reminders/reminder_coordinator.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class WyrdApp extends ConsumerWidget {
  const WyrdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reminderCoordinatorProvider);
    ref.watch(syncCoordinatorProvider);
    final regional = ref.watch(regionalProvider);
    final reducedMotion = ref.watch(profileProvider.select((p) => p.value?.reducedMotion ?? false));
    final theme =
        ref.watch(profileProvider.select((p) => p.value?.theme)) ?? ref.watch<ThemePreference>(initialThemeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      routerConfig: ref.watch(routerProvider),
      locale: regional.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(regional.locale, Palette.light),
      darkTheme: buildAppTheme(regional.locale, Palette.dark),
      themeMode: switch (theme) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      themeAnimationDuration: AppMotion.settle,
      themeAnimationCurve: AppMotion.standard,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(disableAnimations: mq.disableAnimations || reducedMotion),
          child: child!,
        );
      },
    );
  }
}
