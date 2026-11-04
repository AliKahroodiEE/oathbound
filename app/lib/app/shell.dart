import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _go(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  void _newQuest(BuildContext context) => context.push('/quests/new');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destinations = [
      _Destination(Icons.shield_outlined, Icons.shield, l10n.navCharacter),
      _Destination(Icons.flag_outlined, Icons.flag, l10n.navQuests),
      _Destination(Icons.groups_2_outlined, Icons.groups_2, l10n.navGuilds),
      _Destination(Icons.auto_stories_outlined, Icons.auto_stories, l10n.navChronicle),
    ];
    final width = MediaQuery.sizeOf(context).width;
    final widthClass = WidthClass.of(width);

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
          body: shell,
          floatingActionButton: shell.currentIndex <= 1
              ? FloatingActionButton(
                  tooltip: l10n.quickAdd,
                  onPressed: () => _newQuest(context),
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _go,
            destinations: [
              for (final d in destinations)
                NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
            ],
          ),
        );
      case WidthClass.medium:
        body = Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: _go,
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.md),
                  child: FloatingActionButton.small(
                    tooltip: l10n.quickAdd,
                    onPressed: () => _newQuest(context),
                    child: const Icon(Icons.add),
                  ),
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
    return CallbackShortcuts(bindings: shortcuts, child: Focus(autofocus: true, child: body));
  }
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
    final text = Theme.of(context).textTheme;
    final l10n = context.l10n;
    return Container(
      width: 248,
      color: AppColors.abyss,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.lg),
              child: Text(l10n.appName, style: text.titleLarge),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
              child: FilledButton.icon(
                onPressed: onNewQuest,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.quickAdd),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            for (var i = 0; i < destinations.length; i++)
              _SidebarItem(
                destination: destinations[i],
                selected: i == selected,
                onTap: () => onSelect(i),
              ),
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
        color: selected ? AppColors.wine : Colors.transparent,
        borderRadius: AppRadius.softAll,
        child: InkWell(
          borderRadius: AppRadius.softAll,
          onTap: onTap,
          child: Semantics(
            selected: selected,
            button: true,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
              child: Row(
                children: [
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    color: selected ? AppColors.bone : AppColors.ashMuted,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Text(
                    destination.label,
                    style: text.labelLarge?.copyWith(color: selected ? AppColors.bone : AppColors.ash),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
