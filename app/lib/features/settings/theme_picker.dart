import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

IconData themePreferenceIcon(ThemePreference t) => switch (t) {
  ThemePreference.system => Icons.brightness_auto_outlined,
  ThemePreference.light => Icons.light_mode_outlined,
  ThemePreference.dark => Icons.dark_mode_outlined,
};

String themePreferenceLabel(AppLocalizations l10n, ThemePreference t) => switch (t) {
  ThemePreference.system => l10n.themeAuto,
  ThemePreference.light => l10n.themeLight,
  ThemePreference.dark => l10n.themeDark,
};

ThemePreference _current(WidgetRef ref) =>
    ref.watch(profileProvider.select((p) => p.value?.theme)) ?? ref.watch<ThemePreference>(initialThemeProvider);

void _choose(WidgetRef ref, ThemePreference t) =>
    ref.read(settingsRepositoryProvider).updateProfile((p) => p.copyWith(theme: t));

/// One tap from a screen header to Auto, Light or Dark. The icon shows the
/// current choice; Settings → Appearance holds the same switch.
class ThemeMenuButton extends ConsumerWidget {
  const ThemeMenuButton({super.key, this.iconSize = 20});

  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;
    final current = _current(ref);
    return PopupMenuButton<ThemePreference>(
      tooltip: l10n.themeLabel,
      icon: Icon(themePreferenceIcon(current), size: iconSize),
      initialValue: current,
      position: PopupMenuPosition.under,
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.softAll,
        side: BorderSide(color: p.hairline),
      ),
      onSelected: (t) => _choose(ref, t),
      itemBuilder: (context) => [
        for (final t in ThemePreference.values)
          PopupMenuItem(
            value: t,
            child: Row(
              children: [
                Icon(themePreferenceIcon(t), size: 20, color: t == current ? p.accent : p.inkMuted),
                const SizedBox(width: AppSpace.md),
                Expanded(child: Text(themePreferenceLabel(l10n, t))),
                if (t == current) ...[
                  const SizedBox(width: AppSpace.md),
                  Icon(Icons.check_rounded, size: 18, color: p.accent),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Compact three-way switch for roomy layouts such as the desktop sidebar.
class ThemeSegments extends ConsumerWidget {
  const ThemeSegments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SegmentedButton<ThemePreference>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        for (final t in ThemePreference.values)
          ButtonSegment(value: t, icon: Icon(themePreferenceIcon(t), size: 18), tooltip: themePreferenceLabel(l10n, t)),
      ],
      selected: {_current(ref)},
      onSelectionChanged: (s) => _choose(ref, s.first),
    );
  }
}
