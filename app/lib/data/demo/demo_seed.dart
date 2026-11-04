import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../../core/locale/regional_settings.dart';
import '../db/database.dart';
import '../models.dart';
import '../repositories/progression_repository.dart';
import '../repositories/quest_repository.dart';
import '../repositories/settings_repository.dart';

/// Six weeks of realistic activity for demos and README screenshots.
/// Only used when explicitly requested (`--dart-define=WYRD_DEMO=true`
/// or the screenshot test); production never seeds data.
Future<void> seedDemo(AppDatabase db, {required Locale locale, DateTime? now}) async {
  final fa = locale.languageCode == 'fa';
  final today = now ?? DateTime.now();
  var clock = today.subtract(const Duration(days: 43));
  DateTime time() => clock;
  final quests = QuestRepository(db, clock: time);
  final progression = ProgressionRepository(db, clock: time);
  final settings = SettingsRepository(db);

  String t(String en, String faText) => fa ? faText : en;

  await settings.saveRegional(RegionalSettings.defaultsFor(locale));
  final regional = RegionalSettings.defaultsFor(locale);

  final objective = await quests.create(
    QuestDraft(title: t('Become an embedded engineer', 'مهندس سامانه‌های نهفته شدن'), tier: QuestTier.objective),
  );
  final study = await quests.create(
    QuestDraft(
      title: t('Study electronics', 'مطالعه‌ی الکترونیک'),
      recurrence: Recurrence.daily,
      category: QuestCategory.study,
      estimatedMinutes: 60,
      intention: t('After dinner, at my desk', 'بعد از شام، پشت میزم'),
      parentId: objective.id,
      remindAt: 19 * 60,
    ),
  );
  final run = await quests.create(
    QuestDraft(title: t('Run 5 km', 'دویدن ۵ کیلومتر'), recurrence: Recurrence.daily, category: QuestCategory.fitness),
  );
  final read = await quests.create(
    QuestDraft(
      title: t('Read 20 pages', 'خواندن ۲۰ صفحه'),
      recurrence: Recurrence.daily,
      category: QuestCategory.reading,
    ),
  );
  final sketch = await quests.create(
    QuestDraft(
      title: t('Sketch for 20 minutes', '۲۰ دقیقه طراحی'),
      recurrence: Recurrence.daily,
      category: QuestCategory.creative,
    ),
  );
  final call = await quests.create(
    QuestDraft(
      title: t('Call my sister', 'تماس با خواهرم'),
      recurrence: Recurrence.weekly,
      category: QuestCategory.social,
    ),
  );
  final stretch = await quests.create(
    QuestDraft(
      title: t('Stretch and sleep by 23:00', 'کشش و خواب تا ساعت ۲۳'),
      recurrence: Recurrence.daily,
      category: QuestCategory.health,
    ),
  );

  final rng = Random(7);
  Future<void> doOn(Quest q, int minutes, {int hour = 18}) async {
    final base = clock;
    clock = DateTime(base.year, base.month, base.day, hour, rng.nextInt(50));
    await progression.complete(q, declaredMinutes: minutes, weeklyTarget: 4, firstWeekday: regional.firstWeekday);
    clock = base;
  }

  // Past six weeks: a believable rhythm with quiet days and a rest day.
  for (var d = 42; d >= 1; d--) {
    clock = DateTime(today.year, today.month, today.day - d, 8);
    final day = clock;
    final roll = rng.nextDouble();
    if (roll < 0.12) continue; // a quiet day — never punished
    if (roll < 0.17) {
      await progression.setRestDay(dayKey(day), true);
      continue;
    }
    await doOn(study, 45 + rng.nextInt(60), hour: 20);
    if (rng.nextDouble() < 0.5) await doOn(run, 28 + rng.nextInt(10), hour: 7);
    if (rng.nextDouble() < 0.7) await doOn(read, 20 + rng.nextInt(15), hour: 22);
    if (rng.nextDouble() < 0.3) await doOn(sketch, 20, hour: 17);
    if (day.weekday == DateTime.friday) await doOn(call, 30, hour: 19);
    if (rng.nextDouble() < 0.4) await doOn(stretch, 15, hour: 23);
  }

  // Today: some done, some still waiting.
  clock = DateTime(today.year, today.month, today.day, 7);
  await doOn(run, 32, hour: 7);
  await doOn(read, 25, hour: 8);
  final contract = await quests.create(
    QuestDraft(
      title: t('Write the oscillator lab report', 'نوشتن گزارش آزمایشگاه نوسان‌ساز'),
      tier: QuestTier.contract,
      dueAt: today.add(const Duration(days: 2)),
      estimatedMinutes: 120,
      parentId: objective.id,
    ),
  );
  await quests.addSubtask(contract.id, t('Collect measurements', 'جمع‌آوری اندازه‌گیری‌ها'));
  await quests.addSubtask(contract.id, t('Plot the waveforms', 'رسم شکل موج‌ها'));
  await quests.addSubtask(contract.id, t('Write the conclusion', 'نوشتن نتیجه‌گیری'));
  await quests.create(
    QuestDraft(title: t('Review last week’s notes', 'مرور یادداشت‌های هفته‌ی پیش'), dueAt: today, estimatedMinutes: 30),
  );

  await settings.saveProfile(
    UserProfile(
      characterName: t('Arin Vale', 'آرین'),
      portrait: 'tower',
      equippedTitle: 'sworn',
      weeklyTarget: 4,
      areas: const ['study', 'fitness', 'reading'],
      tone: 'gentle',
      drivers: const ['progress', 'longTerm'],
      onboardingComplete: true,
    ),
  );
}
