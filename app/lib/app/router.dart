import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../features/auth/auth_screen.dart';
import '../features/character/character_screen.dart';
import '../features/chronicle/chronicle_screen.dart';
import '../features/chronicle/ledger_screen.dart';
import '../features/guilds/guild_hall_screen.dart';
import '../features/guilds/guilds_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/quests/quest_editor_screen.dart';
import '../features/quests/quests_screen.dart';
import '../features/settings/settings_screen.dart';
import 'providers.dart';
import 'shell.dart';

/// Whether onboarding was complete at launch; overridden in `main()` so
/// the first frame lands on the right screen.
final initialOnboardedProvider = Provider<bool>((ref) => false);

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final onboarded = ValueNotifier<bool>(ref.read(initialOnboardedProvider));
  ref.listen(profileProvider, (_, next) {
    final v = next.value?.onboardingComplete;
    if (v != null) onboarded.value = v;
  });

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: onboarded.value ? '/character' : '/onboarding',
    refreshListenable: onboarded,
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!onboarded.value && !atOnboarding) return '/onboarding';
      if (onboarded.value && atOnboarding) return '/character';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/quest/new',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, state) => MaterialPage(
          fullscreenDialog: true,
          child: QuestEditorScreen(
            initialTier: QuestTier.parse(state.uri.queryParameters['tier']),
            parentId: state.uri.queryParameters['parent'],
          ),
        ),
      ),
      GoRoute(
        path: '/quest/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => QuestEditorScreen(questId: state.pathParameters['id']),
      ),
      GoRoute(path: '/auth', parentNavigatorKey: _rootKey, builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/settings', parentNavigatorKey: _rootKey, builder: (_, _) => const SettingsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdaptiveShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/character', builder: (_, _) => const CharacterScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/quests', builder: (_, _) => const QuestsScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/guilds',
                builder: (_, _) => const GuildsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => GuildHallScreen(guildId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chronicle',
                builder: (_, _) => const ChronicleScreen(),
                routes: [GoRoute(path: 'ledger', builder: (_, _) => const LedgerScreen())],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    onboarded.dispose();
  });
  return router;
});
