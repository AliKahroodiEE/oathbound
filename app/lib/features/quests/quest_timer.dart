import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Optional time tracking (Q6): one running timer per quest. Stopping
/// returns elapsed whole minutes (at least 1), which the engine treats as
/// the strongest evidence of effort.
class QuestTimers extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => const {};

  void start(String questId) => state = {...state, questId: DateTime.now()};

  int? stop(String questId) {
    final started = state[questId];
    if (started == null) return null;
    state = Map.of(state)..remove(questId);
    final minutes = DateTime.now().difference(started).inMinutes;
    return minutes < 1 ? 1 : minutes;
  }

  void cancel(String questId) => state = Map.of(state)..remove(questId);
}

final questTimerProvider = NotifierProvider<QuestTimers, Map<String, DateTime>>(QuestTimers.new);
