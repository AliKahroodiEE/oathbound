import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../design/components/background.dart';
import '../design/components/game.dart';
import '../design/tokens.dart';
import 'providers.dart';

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Adaptive navigation shell (ux-spec §2): bottom bar on compact widths,
/// a rail on medium widths and a full sidebar on expanded widths. The
/// start edge follows text direction, so everything mirrors in RTL.
/// The backdrop gradient is painted once here behind all destinations.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _go(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  void _newQuest(BuildContext context) => context.push('/quest/new');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destinations = [
      _Destination(Icons.shield_outlined, Icons.shield_rounded, l10n.navCharacter),
      _Destination(Icons.flag_outlined, Icons.flag_rounded, l10n.navQuests),
      _Destination(Icons.groups_2_outlined, Icons.groups_2_rounded, l10n.navGuilds),
      _Destination(Icons.auto_stories_outlined, Icons.auto_stories_rounded, l10n.navChronicle),
    ];
    final widthClass = WidthClass.of(MediaQuery.sizeOf(context).width);

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyN): () => _newQuest(context),
      const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () => _go(0),
      const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () => _go(1),
      const SingleActivator(LogicalKeyboardKey.digit3, alt: true): () => _go(2),
      const SingleActivator(LogicalKeyboardKey.digit4, alt: true): () => _go(3),
      const SingleActivator(LogicalKeyboardKey.comma, meta: true): () => context.push('/settings'),
      const SingleActivator(LogicalKeyboardKey.comma, control: true): () => context.push('/settings'),
    };

    final Widget body;
    switch (widthClass) {
      case WidthClass.compact:
        body = Scaffold(
          backgroundColor: Colors.transparent,
          body: shell,
          floatingActionButton: shell.currentIndex <= 1
              ? GlowFab(tooltip: l10n.quickAdd, onPressed: () => _newQuest(context))
              : null,
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
              ],
            ),
          ),
        );
      case WidthClass.medium:
        body = Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _go,
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.md),
                  child: GlowFab(tooltip: l10n.quickAdd, onPressed: () => _newQuest(context)),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.lg),
                      child: IconButton(
                        tooltip: l10n.navSettings,
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => context.push('/settings'),
                      ),
                    ),
                  ),
                ),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: shell),
            ],
          ),
        );
      case WidthClass.expanded:
        body = Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              _Sidebar(
                destinations: destinations,
                selected: shell.currentIndex,
                onSelect: _go,
                onNewQuest: () => _newQuest(context),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: shell),
            ],
          ),
        );
    }
    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(autofocus: true, child: AppBackground(child: body)),
    );
  }
}

/// The wordmark in Cinzel with an ember gradient.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 26});
  final double size;

  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (r) => AppGradients.emberDiagonal.createShader(r, textDirection: Directionality.of(context)),
    child: Text(
      context.l10n.appName,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: size, color: Colors.white),
    ),
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selected,
    required this.onSelect,
    required this.onNewQuest,
  });

  final List<_Destination> destinations;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onNewQuest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: 256,
      color: AppColors.abyss.withValues(alpha: 0.85),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.lg),
              child: Wordmark(),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
              child: GlowButton(label: l10n.quickAdd, icon: Icons.add_rounded, onPressed: onNewQuest),
            ),
            const SizedBox(height: AppSpace.lg),
            for (var i = 0; i < destinations.length; i++)
              _SidebarItem(destination: destinations[i], selected: i == selected, onTap: () => onSelect(i)),
            const Spacer(),
            const Divider(),
            _SidebarItem(
              destination: _Destination(Icons.settings_outlined, Icons.settings, l10n.navSettings),
              selected: false,
              onTap: () => context.push('/settings'),
            ),
            const SizedBox(height: AppSpace.md),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.destination, required this.selected, required this.onTap});

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md, vertical: 2),
      child: Material(
        color: selected ? AppColors.crimson.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: AppRadius.softAll,
        child: InkWell(
          borderRadius: AppRadius.softAll,
          onTap: onTap,
          child: Semantics(
            selected: selected,
            button: true,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppMotion.base,
                  width: 3,
                  height: 22,
                  margin: const EdgeInsetsDirectional.only(start: 2),
                  decoration: BoxDecoration(
                    gradient: selected ? AppGradients.emberDiagonal : null,
                    borderRadius: AppRadius.pillAll,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    color: selected ? AppColors.ember : AppColors.ashMuted,
                    size: 21,
                  ),
                ),
                Text(
                  destination.label,
                  style: text.labelLarge?.copyWith(color: selected ? AppColors.bone : AppColors.ash),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
