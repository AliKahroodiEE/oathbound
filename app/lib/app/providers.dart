import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oathbound_engine/oathbound_engine.dart';

import '../core/format/formatters.dart';
import '../core/locale/locale_registry.dart';
import '../core/locale/regional_settings.dart';
import '../data/db/database.dart';
import '../data/models.dart';
import '../data/repositories/character_repository.dart';
import '../data/repositories/data_repository.dart';
import '../data/repositories/progression_repository.dart';
import '../data/repositories/quest_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/generated/app_localizations.dart';

/// Overridden in `main()` with the opened database.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));
final questRepositoryProvider = Provider((ref) => QuestRepository(ref.watch(databaseProvider)));
final progressionRepositoryProvider = Provider((ref) => ProgressionRepository(ref.watch(databaseProvider)));
final characterRepositoryProvider = Provider(
  (ref) => CharacterRepository(
    ref.watch(databaseProvider),
    ref.watch(progressionRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
  ),
);

final deviceLocaleProvider = Provider<Locale>((ref) => PlatformDispatcher.instance.locale);

final regionalSettingsProvider = StreamProvider<RegionalSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watchRegional(ref.watch(deviceLocaleProvider)),
);

/// Regional settings with a synchronous fallback for first frames.
final regionalProvider = Provider<RegionalSettings>(
  (ref) =>
      ref.watch(regionalSettingsProvider).value ??
      RegionalSettings.defaultsFor(LocaleRegistry.resolve(ref.watch(deviceLocaleProvider))),
);

final profileProvider = StreamProvider<UserProfile>((ref) => ref.watch(settingsRepositoryProvider).watchProfile());

final characterStateProvider = StreamProvider<CharacterState>((ref) {
  final firstWeekday = ref.watch(regionalProvider.select((r) => r.firstWeekday));
  return ref.watch(characterRepositoryProvider).watch(firstWeekday);
});

final todayQuestsProvider = StreamProvider<List<QuestView>>((ref) {
  final firstWeekday = ref.watch(regionalProvider.select((r) => r.firstWeekday));
  return ref.watch(questRepositoryProvider).watchToday(firstWeekday);
});

final upcomingQuestsProvider = StreamProvider<List<QuestView>>(
  (ref) => ref.watch(questRepositoryProvider).watchUpcoming(),
);

final questsByTierProvider = StreamProvider.family<List<QuestView>, QuestTier>(
  (ref, tier) => ref.watch(questRepositoryProvider).watchByTier(tier),
);

final questProvider = StreamProvider.family<Quest?, String>(
  (ref, id) => ref.watch(questRepositoryProvider).watchById(id),
);

final rewardsProvider = StreamProvider<List<RewardRecord>>(
  (ref) => ref.watch(characterRepositoryProvider).watchRewards(),
);

typedef PeriodRange = ({DateTime start, DateTime end});

final periodStatsProvider = StreamProvider.family<PeriodStats, PeriodRange>(
  (ref, range) => ref.watch(characterRepositoryProvider).watchPeriod(range.start, range.end),
);

extension AppContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Formatters bound to the current localizations and regional settings.
extension FormattersRef on WidgetRef {
  AppFormatters fmt(BuildContext context) => AppFormatters(watch(regionalProvider), AppLocalizations.of(context));
}

final dataRepositoryProvider = Provider((ref) => DataRepository(ref.watch(databaseProvider)));
