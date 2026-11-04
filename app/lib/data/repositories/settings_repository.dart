import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../core/locale/regional_settings.dart';
import '../db/database.dart';

/// Light, dark, or whatever the device uses.
enum ThemePreference { system, light, dark }

/// User-owned preferences and character identity.
@immutable
class UserProfile {
  const UserProfile({
    this.characterName = '',
    this.portrait = 'tower',
    this.equippedTitle,
    this.weeklyTarget = 4,
    this.areas = const [],
    this.tone,
    this.drivers = const [],
    this.aiEnabled = true,
    this.aiLocale,
    this.notifReminders = true,
    this.notifGuild = true,
    this.notifWeekly = true,
    this.quietStartMinutes = 22 * 60,
    this.quietEndMinutes = 8 * 60,
    this.reducedMotion = false,
    this.reducedEffects = false,
    this.theme = ThemePreference.system,
    this.onboardingComplete = false,
    this.pauseStartedDay,
    this.returnAcknowledgedDay,
  });

  final String characterName;
  final String portrait;
  final String? equippedTitle;
  final int weeklyTarget;
  final List<String> areas;
  final String? tone;
  final List<String> drivers;
  final bool aiEnabled;
  final String? aiLocale;
  final bool notifReminders;
  final bool notifGuild;
  final bool notifWeekly;
  final int quietStartMinutes;
  final int quietEndMinutes;
  final bool reducedMotion;
  final bool reducedEffects;
  final ThemePreference theme;
  final bool onboardingComplete;

  /// Local day key when pause mode started; null when not paused.
  final String? pauseStartedDay;

  /// Day the welcome-back card was dismissed, so it shows once.
  final String? returnAcknowledgedDay;

  bool get paused => pauseStartedDay != null;

  static const _unset = Object();

  UserProfile copyWith({
    String? characterName,
    String? portrait,
    Object? equippedTitle = _unset,
    int? weeklyTarget,
    List<String>? areas,
    Object? tone = _unset,
    List<String>? drivers,
    bool? aiEnabled,
    Object? aiLocale = _unset,
    bool? notifReminders,
    bool? notifGuild,
    bool? notifWeekly,
    int? quietStartMinutes,
    int? quietEndMinutes,
    bool? reducedMotion,
    bool? reducedEffects,
    ThemePreference? theme,
    bool? onboardingComplete,
    Object? pauseStartedDay = _unset,
    Object? returnAcknowledgedDay = _unset,
  }) => UserProfile(
    characterName: characterName ?? this.characterName,
    portrait: portrait ?? this.portrait,
    equippedTitle: equippedTitle == _unset ? this.equippedTitle : equippedTitle as String?,
    weeklyTarget: weeklyTarget ?? this.weeklyTarget,
    areas: areas ?? this.areas,
    tone: tone == _unset ? this.tone : tone as String?,
    drivers: drivers ?? this.drivers,
    aiEnabled: aiEnabled ?? this.aiEnabled,
    aiLocale: aiLocale == _unset ? this.aiLocale : aiLocale as String?,
    notifReminders: notifReminders ?? this.notifReminders,
    notifGuild: notifGuild ?? this.notifGuild,
    notifWeekly: notifWeekly ?? this.notifWeekly,
    quietStartMinutes: quietStartMinutes ?? this.quietStartMinutes,
    quietEndMinutes: quietEndMinutes ?? this.quietEndMinutes,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    reducedEffects: reducedEffects ?? this.reducedEffects,
    theme: theme ?? this.theme,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    pauseStartedDay: pauseStartedDay == _unset ? this.pauseStartedDay : pauseStartedDay as String?,
    returnAcknowledgedDay: returnAcknowledgedDay == _unset
        ? this.returnAcknowledgedDay
        : returnAcknowledgedDay as String?,
  );

  Map<String, Object?> toJson() => {
    'characterName': characterName,
    'portrait': portrait,
    'equippedTitle': equippedTitle,
    'weeklyTarget': weeklyTarget,
    'areas': areas,
    'tone': tone,
    'drivers': drivers,
    'aiEnabled': aiEnabled,
    'aiLocale': aiLocale,
    'notifReminders': notifReminders,
    'notifGuild': notifGuild,
    'notifWeekly': notifWeekly,
    'quietStartMinutes': quietStartMinutes,
    'quietEndMinutes': quietEndMinutes,
    'reducedMotion': reducedMotion,
    'reducedEffects': reducedEffects,
    'theme': theme.name,
    'onboardingComplete': onboardingComplete,
    'pauseStartedDay': pauseStartedDay,
    'returnAcknowledgedDay': returnAcknowledgedDay,
  };

  factory UserProfile.fromJson(Map<String, Object?> j) {
    T? as<T>(String k) => j[k] is T ? j[k] as T : null;
    List<String> strings(String k) => (j[k] is List) ? (j[k]! as List).whereType<String>().toList() : const [];
    return UserProfile(
      characterName: as<String>('characterName') ?? '',
      portrait: as<String>('portrait') ?? 'tower',
      equippedTitle: as<String>('equippedTitle'),
      weeklyTarget: (as<int>('weeklyTarget') ?? 4).clamp(1, 7),
      areas: strings('areas'),
      tone: as<String>('tone'),
      drivers: strings('drivers'),
      aiEnabled: as<bool>('aiEnabled') ?? true,
      aiLocale: as<String>('aiLocale'),
      notifReminders: as<bool>('notifReminders') ?? true,
      notifGuild: as<bool>('notifGuild') ?? true,
      notifWeekly: as<bool>('notifWeekly') ?? true,
      quietStartMinutes: as<int>('quietStartMinutes') ?? 22 * 60,
      quietEndMinutes: as<int>('quietEndMinutes') ?? 8 * 60,
      reducedMotion: as<bool>('reducedMotion') ?? false,
      reducedEffects: as<bool>('reducedEffects') ?? false,
      theme: ThemePreference.values.asNameMap()[j['theme']] ?? ThemePreference.system,
      onboardingComplete: as<bool>('onboardingComplete') ?? false,
      pauseStartedDay: as<String>('pauseStartedDay'),
      returnAcknowledgedDay: as<String>('returnAcknowledgedDay'),
    );
  }
}

/// Persists the profile and regional settings as JSON documents.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;
  static const _profileKey = 'profile';
  static const _regionalKey = 'regional';

  Stream<UserProfile> watchProfile() =>
      _watch(_profileKey).map((v) => v == null ? const UserProfile() : UserProfile.fromJson(v));

  Future<UserProfile> profile() async {
    final v = await _read(_profileKey);
    return v == null ? const UserProfile() : UserProfile.fromJson(v);
  }

  Future<void> saveProfile(UserProfile p) => _write(_profileKey, p.toJson());

  Future<void> updateProfile(UserProfile Function(UserProfile) change) async => saveProfile(change(await profile()));

  /// Regional choices; empty until the user changes something, so the app
  /// follows the device language by default.
  Stream<RegionalPrefs> watchRegionalPrefs() =>
      _watch(_regionalKey).map((v) => v == null ? const RegionalPrefs() : RegionalPrefs.fromJson(v));

  Future<RegionalPrefs> regionalPrefs() async {
    final v = await _read(_regionalKey);
    return v == null ? const RegionalPrefs() : RegionalPrefs.fromJson(v);
  }

  Future<void> saveRegionalPrefs(RegionalPrefs prefs) => _write(_regionalKey, prefs.toJson());

  Future<void> updateRegionalPrefs(RegionalPrefs Function(RegionalPrefs) change) async =>
      saveRegionalPrefs(change(await regionalPrefs()));

  Future<Map<String, Object?>?> _read(String key) async {
    final row = await (_db.select(_db.keyValues)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.value) as Map<String, Object?>;
  }

  Stream<Map<String, Object?>?> _watch(String key) => (_db.select(_db.keyValues)..where((t) => t.key.equals(key)))
      .watchSingleOrNull()
      .map((row) => row == null ? null : jsonDecode(row.value) as Map<String, Object?>);

  Future<void> _write(String key, Map<String, Object?> value) =>
      _db.into(_db.keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: jsonEncode(value)));
}
