// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Wyrd';

  @override
  String get appTagline => 'Your character is not someone you play. Your character is who you become.';

  @override
  String get navCharacter => 'Character';

  @override
  String get navQuests => 'Quests';

  @override
  String get navGuilds => 'Guilds';

  @override
  String get navChronicle => 'Chronicle';

  @override
  String get navSettings => 'Settings';

  @override
  String get quickAdd => 'New quest';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionDone => 'Done';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get actionCopy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get offlineBanner => 'Working offline — changes will sync when you reconnect.';

  @override
  String get errorGeneric => 'Something went wrong on our side. Your data is safe.';

  @override
  String get loadingLabel => 'Loading';

  @override
  String get attributeStrength => 'Strength';

  @override
  String get attributeIntelligence => 'Intelligence';

  @override
  String get attributeDiscipline => 'Discipline';

  @override
  String get attributeCreativity => 'Creativity';

  @override
  String get attributeVitality => 'Vitality';

  @override
  String get attributeSocial => 'Social';

  @override
  String get attributeStrengthDesc => 'Physical capability built through training and movement.';

  @override
  String get attributeIntelligenceDesc => 'Knowledge and understanding built through study and learning.';

  @override
  String get attributeDisciplineDesc => 'Consistency and follow-through: planning, then keeping your word.';

  @override
  String get attributeCreativityDesc => 'Making things and solving problems in new ways.';

  @override
  String get attributeVitalityDesc => 'Rest, recovery and the habits that keep you well.';

  @override
  String get attributeSocialDesc => 'Connection, communication and showing up for others.';

  @override
  String characterLevel(String level) {
    return 'Level $level';
  }

  @override
  String xpProgress(String current, String total) {
    return '$current / $total XP';
  }

  @override
  String xpToNextLevel(String xp, String level) {
    return '$xp XP to level $level';
  }

  @override
  String attributeRank(String rank) {
    return 'Rank $rank';
  }

  @override
  String xpToday(String xp) {
    return '+$xp today';
  }

  @override
  String totalXp(String xp) {
    return '$xp XP';
  }

  @override
  String get conditionLabel => 'Condition';

  @override
  String get conditionRested => 'Rested';

  @override
  String get conditionSteady => 'Steady';

  @override
  String get conditionStrained => 'Strained';

  @override
  String get conditionRestedHelp =>
      'You are well recovered. Condition only falls from overexertion — never from missed quests.';

  @override
  String get conditionSteadyHelp => 'Recent days have been demanding. A calm day or a rest day restores condition.';

  @override
  String get conditionStrainedHelp => 'You have been pushing very hard. Consider a rest day; your progress is safe.';

  @override
  String get sectionAttributes => 'Attributes';

  @override
  String get sectionToday => 'Today';

  @override
  String get sectionRecentGrowth => 'Recent growth';

  @override
  String get sectionAchievements => 'Achievements';

  @override
  String get sectionConsistency => 'Consistency';

  @override
  String get todayEmpty => 'No quests sworn for today.';

  @override
  String get todayEmptyAction => 'Swear a quest';

  @override
  String get growthEmpty => 'Complete a quest and your growth will be recorded here.';

  @override
  String get achievementsEmpty => 'Achievements mark milestones. Your first one is a single quest away.';

  @override
  String get classUnrevealed => 'Your class reveals itself at level 5.';

  @override
  String get noTitle => 'No title equipped';

  @override
  String get equipTitle => 'Equip title';

  @override
  String weeklyTargetProgress(String active, String target) {
    return '$active of $target days this week';
  }

  @override
  String weeksKept(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText weeks kept',
      one: '$countText week kept',
      zero: 'No weeks kept yet',
    );
    return '$_temp0';
  }

  @override
  String chainDays(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText-day chain',
      one: '$countText-day chain',
      zero: 'No chain yet',
    );
    return '$_temp0';
  }

  @override
  String bestRecord(String value) {
    return 'Best: $value';
  }

  @override
  String get levelLabel => 'Level';

  @override
  String get className_scholar => 'Scholar';

  @override
  String get className_warden => 'Warden';

  @override
  String get className_artisan => 'Artisan';

  @override
  String get className_vanguard => 'Vanguard';

  @override
  String get className_envoy => 'Envoy';

  @override
  String get className_druid => 'Druid';

  @override
  String get className_explorer => 'Explorer';

  @override
  String get className_strategist => 'Strategist';

  @override
  String get className_arcanist => 'Arcanist';

  @override
  String get classDesc_scholar => 'Your recent path has been one of study and understanding.';

  @override
  String get classDesc_warden => 'You plan, you keep your word, and you hold the line.';

  @override
  String get classDesc_artisan => 'Your hands and mind have been busy making things.';

  @override
  String get classDesc_vanguard => 'You have been training the body and leading with strength.';

  @override
  String get classDesc_envoy => 'You have invested in people and the bonds between them.';

  @override
  String get classDesc_druid => 'You have tended rest, recovery and wellbeing.';

  @override
  String get classDesc_explorer => 'You have grown in many directions at once.';

  @override
  String get classDesc_strategist => 'Learning paired with steady execution.';

  @override
  String get classDesc_arcanist => 'Knowledge turned into creation.';

  @override
  String get questsTitle => 'Quests';

  @override
  String get tabToday => 'Today';

  @override
  String get tabUpcoming => 'Upcoming';

  @override
  String get tabContracts => 'Contracts';

  @override
  String get tabObjectives => 'Objectives';

  @override
  String get tabCompleted => 'Completed';

  @override
  String get tierDaily => 'Daily Quest';

  @override
  String get tierContract => 'Contract';

  @override
  String get tierObjective => 'Long-Term Objective';

  @override
  String get tierDailyHelp => 'A small, concrete action for today.';

  @override
  String get tierContractHelp => 'A larger piece of work with steps.';

  @override
  String get tierObjectiveHelp => 'A major goal that quests and contracts build toward.';

  @override
  String get newQuest => 'New quest';

  @override
  String get editQuest => 'Edit quest';

  @override
  String get fieldTitle => 'What will you do?';

  @override
  String get fieldTitleHint => 'e.g. Study electronics for 90 minutes';

  @override
  String get fieldTitleRequired => 'Give the quest a name.';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get fieldTier => 'Kind';

  @override
  String get fieldCategory => 'Category';

  @override
  String get categoryAuto => 'Decide for me';

  @override
  String get category_study => 'Study';

  @override
  String get category_work => 'Work';

  @override
  String get category_fitness => 'Fitness';

  @override
  String get category_health => 'Health';

  @override
  String get category_creative => 'Creative';

  @override
  String get category_social => 'Social';

  @override
  String get category_chores => 'Home';

  @override
  String get category_admin => 'Admin';

  @override
  String get category_mindfulness => 'Mindfulness';

  @override
  String get category_reading => 'Reading';

  @override
  String get category_other => 'Other';

  @override
  String get fieldDue => 'Date';

  @override
  String get fieldDueNone => 'No date';

  @override
  String get fieldEstimate => 'Estimated minutes';

  @override
  String get fieldIntention => 'When and where will you do it?';

  @override
  String get fieldIntentionHint => 'e.g. After dinner, at my desk';

  @override
  String get fieldIntentionHelp => 'Naming a time and place makes follow-through more likely.';

  @override
  String get fieldReminder => 'Reminder';

  @override
  String get reminderNone => 'No reminder';

  @override
  String get reminderBody => 'This quest is ready whenever you are.';

  @override
  String get reminderClear => 'Remove reminder';

  @override
  String get fieldRecurrence => 'Repeats';

  @override
  String get recurrenceNone => 'Does not repeat';

  @override
  String get recurrenceDaily => 'Every day';

  @override
  String get recurrenceWeekdays => 'Weekdays';

  @override
  String get recurrenceWeekly => 'Every week';

  @override
  String get fieldPriority => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityHigh => 'High';

  @override
  String get fieldParent => 'Part of an objective';

  @override
  String get parentNone => 'Standalone';

  @override
  String get fieldSharing => 'Sharing with guilds';

  @override
  String get share_full => 'Title and reward';

  @override
  String get share_titleOnly => 'Title only';

  @override
  String get share_completionOnly => 'Completion only';

  @override
  String get share_private => 'Private';

  @override
  String get moreOptions => 'More options';

  @override
  String get swearQuest => 'Swear quest';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get deleteQuestTitle => 'Delete this quest?';

  @override
  String get deleteQuestBody => 'The quest is removed. Rewards already recorded stay in your chronicle.';

  @override
  String get questDeleted => 'Quest deleted';

  @override
  String get questsEmptyToday => 'Nothing sworn for today. One small quest is enough.';

  @override
  String get questsEmptyUpcoming => 'No upcoming quests.';

  @override
  String get questsEmptyContracts => 'No contracts yet. Contracts hold larger work with steps.';

  @override
  String get questsEmptyObjectives => 'No objectives yet. Objectives give your quests a direction.';

  @override
  String get questsEmptyCompleted => 'Completed quests will gather here.';

  @override
  String get dueToday => 'Today';

  @override
  String get dueTomorrow => 'Tomorrow';

  @override
  String get dueYesterday => 'Yesterday';

  @override
  String get dueEarlier => 'Earlier date';

  @override
  String estimateMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get completeQuest => 'Complete';

  @override
  String get completedLabel => 'Completed';

  @override
  String get subtasks => 'Steps';

  @override
  String get addSubtask => 'Add step';

  @override
  String get subtaskHint => 'Next step';

  @override
  String objectiveProgress(String done, String total) {
    return '$done of $total done';
  }

  @override
  String get completeSheetTitle => 'Seal this deed';

  @override
  String get completeSheetMinutes => 'How many minutes did it take?';

  @override
  String get completeSheetMinutesHelp => 'Optional. Honest numbers keep your character honest.';

  @override
  String get completeSheetConfirm => 'Seal';

  @override
  String get timerStart => 'Start timer';

  @override
  String get timerStop => 'Stop';

  @override
  String timerRunning(String elapsed) {
    return 'Timer running · $elapsed';
  }

  @override
  String get questCompletedToast => 'Deed sealed';

  @override
  String get completionUndone => 'Completion undone';

  @override
  String get rewardTitle => 'Deed recorded';

  @override
  String get rewardProvisional => 'Provisional — will be confirmed when you are online.';

  @override
  String rewardTotal(String xp) {
    return '+$xp XP';
  }

  @override
  String get rewardWhy => 'Why this reward?';

  @override
  String get rewardSourceAi => 'Interpreted by the oracle, decided by the rules.';

  @override
  String get rewardSourceHeuristic => 'Interpreted by the rules on this device.';

  @override
  String get rewardNone => 'No XP this time — the reasons are below.';

  @override
  String levelUp(String level) {
    return 'Level $level reached';
  }

  @override
  String rankUp(String attribute, String rank) {
    return '$attribute reached rank $rank';
  }

  @override
  String reasonDefault(String attribute, String category) {
    return '$attribute grew through $category.';
  }

  @override
  String creditedMinutes(String minutes) {
    return '$minutes minutes credited';
  }

  @override
  String adj_duration_plausibility(String credited, String declared) {
    return 'Credited $credited of $declared minutes — longer than this activity usually takes.';
  }

  @override
  String adj_tier_minutes_cap(String cap) {
    return 'A single quest counts up to $cap minutes.';
  }

  @override
  String get adj_daily_budget => 'Today\'s effort budget is full. Rest is part of growth.';

  @override
  String adj_tier_bonus(String tier) {
    return '$tier bonus for larger work.';
  }

  @override
  String get adj_trivial_floor => 'A very small task counts for a little.';

  @override
  String get adj_trivial_limit => 'Today\'s small tasks have already been counted.';

  @override
  String adj_repetition(String count) {
    return 'Similar deed #$count today — repeated effort counts for less.';
  }

  @override
  String get adj_low_confidence => 'The description was unclear; adding detail gives a fuller reading.';

  @override
  String get adj_follow_through => 'Planned and kept: a Discipline bonus.';

  @override
  String get adj_follow_through_intention => 'Planned, kept, and you named when and where: a larger Discipline bonus.';

  @override
  String adj_soft_cap(String attribute) {
    return '$attribute is near today\'s limit, so it grows more slowly.';
  }

  @override
  String adj_hard_cap(String attribute) {
    return '$attribute has reached today\'s limit. It will grow again tomorrow.';
  }

  @override
  String get adj_weights_defaulted => 'Attributes were chosen from the category.';

  @override
  String achievementUnlocked(String name) {
    return 'Achievement: $name';
  }

  @override
  String titleUnlocked(String title) {
    return 'New title: $title';
  }

  @override
  String get achievement_first_oath_name => 'The First Oath';

  @override
  String get achievement_first_oath_desc => 'Complete your first quest.';

  @override
  String get achievement_deeds_10_name => 'Ten Deeds';

  @override
  String get achievement_deeds_10_desc => 'Complete 10 quests.';

  @override
  String get achievement_deeds_100_name => 'A Hundred Deeds';

  @override
  String get achievement_deeds_100_desc => 'Complete 100 quests.';

  @override
  String get achievement_deeds_1000_name => 'A Thousand Deeds';

  @override
  String get achievement_deeds_1000_desc => 'Complete 1,000 quests.';

  @override
  String get achievement_first_contract_name => 'Contract Sealed';

  @override
  String get achievement_first_contract_desc => 'Complete your first contract.';

  @override
  String get achievement_first_objective_name => 'The Long Road';

  @override
  String get achievement_first_objective_desc => 'Complete a long-term objective.';

  @override
  String get achievement_level_5_name => 'Tempered';

  @override
  String get achievement_level_5_desc => 'Reach level 5.';

  @override
  String get achievement_level_10_name => 'Seasoned';

  @override
  String get achievement_level_10_desc => 'Reach level 10.';

  @override
  String get achievement_level_25_name => 'Veteran';

  @override
  String get achievement_level_25_desc => 'Reach level 25.';

  @override
  String get achievement_rank_10_strength_name => 'Iron in the Bones';

  @override
  String get achievement_rank_10_strength_desc => 'Reach rank 10 in Strength.';

  @override
  String get achievement_rank_10_intelligence_name => 'Keeper of Lore';

  @override
  String get achievement_rank_10_intelligence_desc => 'Reach rank 10 in Intelligence.';

  @override
  String get achievement_rank_10_discipline_name => 'Unbending Will';

  @override
  String get achievement_rank_10_discipline_desc => 'Reach rank 10 in Discipline.';

  @override
  String get achievement_rank_10_creativity_name => 'Dreamwright';

  @override
  String get achievement_rank_10_creativity_desc => 'Reach rank 10 in Creativity.';

  @override
  String get achievement_rank_10_vitality_name => 'Evergreen';

  @override
  String get achievement_rank_10_vitality_desc => 'Reach rank 10 in Vitality.';

  @override
  String get achievement_rank_10_social_name => 'Kindred Spirit';

  @override
  String get achievement_rank_10_social_desc => 'Reach rank 10 in Social.';

  @override
  String get achievement_kept_weeks_4_name => 'A Month of Oaths';

  @override
  String get achievement_kept_weeks_4_desc => 'Keep your weekly target four weeks in a row.';

  @override
  String get achievement_kept_weeks_12_name => 'Steadfast';

  @override
  String get achievement_kept_weeks_12_desc => 'Keep your weekly target twelve weeks in a row.';

  @override
  String get achievement_kept_weeks_52_name => 'Oathkeeper';

  @override
  String get achievement_kept_weeks_52_desc => 'Keep your weekly target for a full year.';

  @override
  String get achievement_the_return_name => 'The Return';

  @override
  String get achievement_the_return_desc => 'Come back after a week away and complete a quest.';

  @override
  String get achievement_balanced_name => 'The Whole';

  @override
  String get achievement_balanced_desc => 'Reach rank 3 in every attribute.';

  @override
  String get achievement_hours_100_name => 'A Hundred Hours';

  @override
  String get achievement_hours_100_desc => 'Invest 100 hours of credited effort.';

  @override
  String get title_sworn => 'the Sworn';

  @override
  String get title_centurion => 'the Centurion';

  @override
  String get title_pathfinder => 'the Pathfinder';

  @override
  String get title_seasoned => 'the Seasoned';

  @override
  String get title_ironbound => 'the Ironbound';

  @override
  String get title_adept_of_lore => 'Adept of Lore';

  @override
  String get title_unbending => 'the Unbending';

  @override
  String get title_dreamwright => 'the Dreamwright';

  @override
  String get title_evergreen => 'the Evergreen';

  @override
  String get title_kindred => 'the Kindred';

  @override
  String get title_steadfast => 'the Steadfast';

  @override
  String get title_oathkeeper => 'the Oathkeeper';

  @override
  String get title_returned => 'the Returned';

  @override
  String get title_whole => 'the Whole';

  @override
  String get chronicleTitle => 'Chronicle';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get periodWeekNoun => 'week';

  @override
  String get periodMonthNoun => 'month';

  @override
  String get periodYearNoun => 'year';

  @override
  String comparedToSamePoint(Object change) {
    return '$change vs the same point last period';
  }

  @override
  String get previousPeriod => 'Previous period';

  @override
  String get nextPeriod => 'Next period';

  @override
  String get statCompletions => 'Deeds';

  @override
  String get statMinutes => 'Time invested';

  @override
  String get statXp => 'XP earned';

  @override
  String get statActiveDays => 'Active days';

  @override
  String get chartXpByAttribute => 'Growth by attribute';

  @override
  String get chartDistribution => 'Where your effort went';

  @override
  String get chartConsistency => 'Rhythm';

  @override
  String get chronicleEmpty => 'No deeds recorded in this period.';

  @override
  String get writtenChronicle => 'The chronicle';

  @override
  String chronicleLocalSummary(String period, String count, String time, String attribute) {
    return 'This $period you completed $count deeds and invested $time. $attribute grew the most.';
  }

  @override
  String get chronicleNeedsAccount => 'Written chronicles are composed by the oracle and need an account.';

  @override
  String get ledgerTitle => 'Reward ledger';

  @override
  String get ledgerEmpty => 'Every reward you earn is recorded here with its reasons.';

  @override
  String comparedToPrevious(String change) {
    return '$change vs previous';
  }

  @override
  String get strongestArea => 'Most practiced';

  @override
  String get quietestArea => 'Least practiced';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get legendActive => 'Active';

  @override
  String get legendRest => 'Rest';

  @override
  String get legendQuiet => 'Quiet';

  @override
  String get guildsTitle => 'Guilds';

  @override
  String get guildsIntro => 'Guilds are small circles of people who encourage each other\'s real-world progress.';

  @override
  String get guildsRequireAccount =>
      'Guilds connect people, so they need an account. Your character and history stay yours.';

  @override
  String get guildsBackendMissing =>
      'Online features are not configured in this build. Everything else works on this device.';

  @override
  String get guildsEmpty => 'You are not part of a guild yet.';

  @override
  String get createGuild => 'Found a guild';

  @override
  String get joinGuild => 'Join with a code';

  @override
  String get guildName => 'Guild name';

  @override
  String get guildDescription => 'What is this guild about?';

  @override
  String get guildVisibility => 'Visibility';

  @override
  String get visibilityPrivate => 'Private — invitation only';

  @override
  String get visibilityPublic => 'Public — discoverable';

  @override
  String get inviteCode => 'Invitation code';

  @override
  String get inviteCodeHint => 'e.g. IRON-PACT-7Q2K';

  @override
  String get shareInvite => 'Share invitation';

  @override
  String get guildFeed => 'Hall';

  @override
  String get guildChallenges => 'Challenges';

  @override
  String get guildMembers => 'Members';

  @override
  String get feedEmpty => 'The hall is quiet. Completed quests shared with this guild appear here.';

  @override
  String memberCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText members',
      one: '$countText member',
    );
    return '$_temp0';
  }

  @override
  String get role_guild_master => 'Guild Master';

  @override
  String get role_officer => 'Officer';

  @override
  String get role_member => 'Member';

  @override
  String get react_honour => 'Honour';

  @override
  String get react_steel => 'Steel';

  @override
  String get react_flame => 'Flame';

  @override
  String get react_laurel => 'Laurel';

  @override
  String commentsCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText comments',
      one: '$countText comment',
      zero: 'Comment',
    );
    return '$_temp0';
  }

  @override
  String get commentHint => 'Write an encouraging word';

  @override
  String feedCompletedFull(String name, String title, String xp) {
    return '$name completed “$title” · +$xp XP';
  }

  @override
  String feedCompletedTitle(String name, String title) {
    return '$name completed “$title”';
  }

  @override
  String feedCompletedOnly(String name, String tier) {
    return '$name completed a $tier';
  }

  @override
  String feedMilestone(String percent, String challenge) {
    return 'The guild reached $percent of “$challenge”';
  }

  @override
  String feedMemberJoined(Object name) {
    return '$name joined the guild';
  }

  @override
  String feedChallengeCreated(Object challenge, Object name) {
    return '$name started “$challenge”';
  }

  @override
  String get formerMember => 'Former member';

  @override
  String challengeProgress(String current, String target) {
    return '$current of $target';
  }

  @override
  String get challengesEmpty => 'No challenges yet. Officers can start a collective challenge.';

  @override
  String get newChallenge => 'New challenge';

  @override
  String get challengeTitle => 'Challenge name';

  @override
  String get challengeMetricMinutes => 'Minutes in a category';

  @override
  String get challengeMetricCompletions => 'Number of deeds';

  @override
  String get challengeTarget => 'Collective target';

  @override
  String get challengeDays => 'Duration in days';

  @override
  String get challengeNoPenalty => 'No one is penalised if the target is not reached.';

  @override
  String get leaveGuild => 'Leave guild';

  @override
  String get muteGuild => 'Mute notifications';

  @override
  String get blockUser => 'Block';

  @override
  String get reportContent => 'Report';

  @override
  String get reportSent => 'Report sent to the guild\'s officers and moderators.';

  @override
  String get guildCreated => 'Guild founded';

  @override
  String get guildJoined => 'Welcome to the guild';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionLanguageRegion => 'Language and region';

  @override
  String get language => 'Language';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarGregorian => 'Gregorian';

  @override
  String get calendarJalali => 'Solar Hijri (Jalali)';

  @override
  String get digits => 'Digits';

  @override
  String get digitsLatin => '0123456789';

  @override
  String get digitsNative => 'Native digits';

  @override
  String get firstDayOfWeek => 'Week starts on';

  @override
  String get sectionProgress => 'Progress';

  @override
  String get weeklyTarget => 'Weekly target';

  @override
  String get weeklyTargetHelp => 'How many active days make a kept week. Set what is realistic, not heroic.';

  @override
  String weeklyTargetValue(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countText days', one: '$countText day');
    return '$_temp0';
  }

  @override
  String get restDayToday => 'Declare today a rest day';

  @override
  String get restDayDeclared => 'Today is a rest day. Recovery counts.';

  @override
  String get pauseMode => 'Pause mode';

  @override
  String get pauseModeHelp => 'For travel, illness or exams. Consistency is frozen and nothing is lost.';

  @override
  String get sectionMotivation => 'Motivation';

  @override
  String get motivationTone => 'How should encouragement sound?';

  @override
  String get toneDirect => 'Direct and concise';

  @override
  String get toneGentle => 'Supportive and gentle';

  @override
  String get toneAchievement => 'Achievement-focused';

  @override
  String get toneAnalytical => 'Analytical';

  @override
  String get motivationDrivers => 'What motivates you most?';

  @override
  String get driverAchievement => 'Achievement';

  @override
  String get driverSocial => 'Encouragement from others';

  @override
  String get driverProgress => 'Visible progress';

  @override
  String get driverLongTerm => 'Long-term goals';

  @override
  String get driverExploration => 'Exploration and customisation';

  @override
  String get driverRoutine => 'Structured routines';

  @override
  String get motivationPrivacy => 'Used only to adjust tone and suggestions. Change or clear it at any time.';

  @override
  String get sectionAi => 'AI';

  @override
  String get aiEvaluation => 'Let AI interpret completed quests';

  @override
  String get aiEvaluationHelp => 'When off, rewards come from the built-in rules only.';

  @override
  String get aiLanguage => 'Language for AI explanations';

  @override
  String get aiSameAsApp => 'Same as the app';

  @override
  String get aiTransparency => 'What the AI sees';

  @override
  String get aiTransparencyBody =>
      'Only the completed quest\'s title, notes, kind, category, minutes and parent objective, plus how often you did similar things this week. Never your guilds, other people, or account details. The AI suggests; fixed rules decide and cap every reward.';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get notifReminders => 'Quest reminders';

  @override
  String get notifGuild => 'Guild reactions and comments';

  @override
  String get notifWeekly => 'Weekly chronicle';

  @override
  String get quietHours => 'Quiet hours';

  @override
  String quietHoursValue(String from, String to) {
    return '$from – $to';
  }

  @override
  String get notificationsWebNote => 'In the browser, reminders appear only while the app is open.';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get reducedMotion => 'Reduce motion';

  @override
  String get reducedEffects => 'Reduce visual effects';

  @override
  String get sectionAccount => 'Account';

  @override
  String get guestMode => 'Playing as a guest. Your data lives on this device.';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get createAccount => 'Create account';

  @override
  String get exportData => 'Export my data';

  @override
  String get exportReady => 'Your data has been copied as JSON.';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllDataBody =>
      'This permanently removes your character, quests and history from this device and, if signed in, from our servers.';

  @override
  String get dataDeleted => 'All data deleted.';

  @override
  String get aboutLicense => 'Source-available under the PolyForm Strict License 1.0.0.';

  @override
  String get authTitle => 'Your account';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authMagicLink => 'Email me a sign-in link';

  @override
  String get authMagicLinkSent => 'Check your inbox for the sign-in link.';

  @override
  String get authInvalid => 'That email and password don\'t match.';

  @override
  String get authBackendMissing => 'Online features are not configured in this build.';

  @override
  String get onbWelcomeBody =>
      'Real effort shapes a character that grows with you — and never loses what it has earned.';

  @override
  String get onbChooseLanguage => 'Choose your language';

  @override
  String get onbNameTitle => 'Name your character';

  @override
  String get onbNameHint => 'Character name';

  @override
  String get onbSigilTitle => 'Choose a sigil';

  @override
  String get onbAreasTitle => 'What do you want to grow?';

  @override
  String get onbAreasHelp => 'Pick up to three. You can change this any time.';

  @override
  String get onbFirstQuestTitle => 'Swear your first quest';

  @override
  String get onbFirstQuestHelp => 'Something real and small you can do today — or already did.';

  @override
  String get onbHowItWorksTitle => 'How growth works';

  @override
  String get onbHowItWorksBody =>
      'You complete real tasks. An oracle interprets each one; fixed rules decide the reward, cap it fairly, and explain it. Nothing you earn is ever taken away.';

  @override
  String get onbBegin => 'Begin';

  @override
  String get onbCompleteNow => 'I\'ve done it — seal it now';

  @override
  String get onbLater => 'I\'ll do it later today';

  @override
  String get suggestStudy => 'Study for 30 minutes';

  @override
  String get suggestWalk => 'Take a 20-minute walk';

  @override
  String get suggestRead => 'Read 10 pages';

  @override
  String get suggestCall => 'Call someone you care about';

  @override
  String get suggestTidy => 'Tidy your workspace for 15 minutes';

  @override
  String get suggestCreate => 'Sketch or write for 20 minutes';

  @override
  String get returnTitle => 'Welcome back';

  @override
  String get returnBody =>
      'You\'ve been away for a few days. That\'s okay. Your journey hasn\'t been erased. Choose one small objective and continue.';

  @override
  String get returnAction => 'Choose a small quest';

  @override
  String get jalaliMonth1 => 'Farvardin';

  @override
  String get jalaliMonth2 => 'Ordibehesht';

  @override
  String get jalaliMonth3 => 'Khordad';

  @override
  String get jalaliMonth4 => 'Tir';

  @override
  String get jalaliMonth5 => 'Mordad';

  @override
  String get jalaliMonth6 => 'Shahrivar';

  @override
  String get jalaliMonth7 => 'Mehr';

  @override
  String get jalaliMonth8 => 'Aban';

  @override
  String get jalaliMonth9 => 'Azar';

  @override
  String get jalaliMonth10 => 'Dey';

  @override
  String get jalaliMonth11 => 'Bahman';

  @override
  String get jalaliMonth12 => 'Esfand';
}
