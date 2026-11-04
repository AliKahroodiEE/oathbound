import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/sync_coordinator.dart';
import '../design/theme.dart';
import '../features/reminders/reminder_coordinator.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class OathboundApp extends ConsumerWidget {
  const OathboundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reminderCoordinatorProvider);
    ref.watch(syncCoordinatorProvider);
    final regional = ref.watch(regionalProvider);
    final reducedMotion = ref.watch(profileProvider.select((p) => p.value?.reducedMotion ?? false));
    final theme = buildAppTheme(regional.locale);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      routerConfig: ref.watch(routerProvider),
      locale: regional.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
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
