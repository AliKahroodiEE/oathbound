import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_planner.dart';

/// Delivers reminder plans on the current platform.
abstract class ReminderScheduler {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> apply(List<ReminderPlan> plans, {required String fallbackBody});
  void dispose() {}

  /// OS scheduling on Android, iOS, macOS and Windows; an in-app timer on
  /// the web, where background scheduling is unavailable.
  factory ReminderScheduler.forPlatform() => kIsWeb ? _InAppScheduler() : _OsScheduler();
}

const _details = NotificationDetails(
  android: AndroidNotificationDetails(
    'quest_reminders',
    'Quest reminders',
    channelDescription: 'Reminders for quests at the times you choose.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  ),
  iOS: DarwinNotificationDetails(),
  macOS: DarwinNotificationDetails(),
);

const _windows = WindowsInitializationSettings(
  appName: 'Wyrd',
  appUserModelId: 'App.Wyrd.Desktop',
  guid: '6f1d4c1e-9a8b-4f3e-b5a2-0b0b10a71924',
);

class _OsScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object {
      // Unknown zone identifier: fall back to UTC offsets via tz.local.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        windows: _windows,
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, sound: true) ?? false;
    final mac = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    if (mac != null) return await mac.requestPermissions(alert: true, sound: true) ?? false;
    return true;
  }

  @override
  Future<void> apply(List<ReminderPlan> plans, {required String fallbackBody}) async {
    await init();
    await _plugin.cancelAll();
    for (final p in plans) {
      await _plugin.zonedSchedule(
        id: p.id,
        title: p.title,
        body: (p.intention ?? '').trim().isEmpty ? fallbackBody : p.intention,
        scheduledDate: tz.TZDateTime.from(p.first, tz.local),
        notificationDetails: _details,
        // Inexact scheduling needs no exact-alarm permission and is gentle
        // on battery; a few minutes of drift is acceptable for reminders.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: p.questId,
        matchDateTimeComponents: switch (p.repeat) {
          ReminderRepeat.once => null,
          ReminderRepeat.daily => DateTimeComponents.time,
          ReminderRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
        },
      );
    }
  }

  @override
  void dispose() {}
}

/// Web: fires due reminders while a tab is open (documented in Settings).
class _InAppScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  List<ReminderPlan> _plans = const [];
  String _body = '';
  final _fired = <String>{};
  Timer? _timer;
  bool _ready = false;

  @override
  Future<void> init() async {
    if (_ready) return;
    await _plugin.initialize(settings: const InitializationSettings(web: WebInitializationSettings()));
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final web = _plugin.resolvePlatformSpecificImplementation<WebFlutterLocalNotificationsPlugin>();
    return await web?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> apply(List<ReminderPlan> plans, {required String fallbackBody}) async {
    await init();
    _plans = plans;
    _body = fallbackBody;
  }

  void _tick() {
    final now = DateTime.now();
    for (final p in _plans) {
      final due = _occurrenceToday(p, now);
      if (due == null || now.isBefore(due) || now.difference(due) > const Duration(minutes: 5)) continue;
      final key = '${p.questId}@${due.toIso8601String()}';
      if (!_fired.add(key)) continue;
      unawaited(
        _plugin.show(
          id: p.id,
          title: p.title,
          body: (p.intention ?? '').trim().isEmpty ? _body : p.intention,
          payload: p.questId,
        ),
      );
    }
  }

  DateTime? _occurrenceToday(ReminderPlan p, DateTime now) {
    final candidate = DateTime(now.year, now.month, now.day, p.first.hour, p.first.minute);
    return switch (p.repeat) {
      ReminderRepeat.once => p.first,
      ReminderRepeat.daily => candidate.isBefore(p.first) ? null : candidate,
      ReminderRepeat.weekly => candidate.weekday == p.first.weekday && !candidate.isBefore(p.first) ? candidate : null,
    };
  }

  @override
  void dispose() => _timer?.cancel();
}
