import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/config.dart';
import '../../core/format/bidi.dart';
import '../../data/remote/backend.dart';
import '../../data/remote/guild_api.dart';
import '../../design/components/panel.dart';
import '../../design/components/states.dart';
import '../../design/tokens.dart';

/// Guilds: clear offline/account states, then the user's guilds with
/// founding and joining by invitation code.
class GuildsScreen extends ConsumerWidget {
  const GuildsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final user = ref.watch(currentUserProvider).value;
    final api = ref.watch(guildApiProvider);

    Widget gate(String message, {bool signIn = false}) => Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.groups_2_outlined, size: 40, color: context.palette.inkMuted),
          const SizedBox(height: AppSpace.md),
          Text(l10n.guildsIntro, style: text.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.lg),
          Text(
            message,
            style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
            textAlign: TextAlign.center,
          ),
          if (signIn) ...[
            const SizedBox(height: AppSpace.lg),
            FilledButton(onPressed: () => context.push('/auth'), child: Text(l10n.signIn)),
          ],
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.guildsTitle)),
      body: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            children: [
              if (!BackendConfig.isConfigured)
                gate(l10n.guildsBackendMissing)
              else if (user == null || api == null)
                gate(l10n.guildsRequireAccount, signIn: true)
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.createGuild),
                        onPressed: () => _create(context, ref, api),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.key_outlined, size: 18),
                        label: Text(l10n.joinGuild),
                        onPressed: () => _join(context, ref, api),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                ref
                    .watch(myGuildsProvider)
                    .when(
                      loading: () => const LoadingPanels(count: 2),
                      error: (_, _) => ErrorState(
                        message: l10n.errorGeneric,
                        retryLabel: l10n.actionRetry,
                        onRetry: () => ref.invalidate(myGuildsProvider),
                      ),
                      data: (guilds) => guilds.isEmpty
                          ? EmptyState(message: l10n.guildsEmpty, icon: Icons.groups_2_outlined)
                          : Column(
                              children: [
                                for (final g in guilds) ...[
                                  Panel(
                                    onTap: () => context.push('/guilds/${g.id}'),
                                    child: Row(
                                      children: [
                                        Icon(Icons.shield_moon_outlined, color: context.palette.accent),
                                        const SizedBox(width: AppSpace.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              UserText(g.name, style: text.titleMedium),
                                              if (g.description.isNotEmpty)
                                                UserText(
                                                  g.description,
                                                  style: text.bodySmall,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, color: context.palette.inkFaint),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.md),
                                ],
                              ],
                            ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref, GuildApi api) async {
    final l10n = context.l10n;
    final name = TextEditingController();
    final description = TextEditingController();
    var visibility = 'private';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: Text(l10n.createGuild),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  maxLength: 60,
                  decoration: InputDecoration(labelText: l10n.guildName),
                ),
                const SizedBox(height: AppSpace.md),
                TextField(
                  controller: description,
                  maxLines: 3,
                  maxLength: 280,
                  decoration: InputDecoration(labelText: l10n.guildDescription),
                ),
                const SizedBox(height: AppSpace.md),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  decoration: InputDecoration(labelText: l10n.guildVisibility),
                  items: [
                    DropdownMenuItem(value: 'private', child: Text(l10n.visibilityPrivate)),
                    DropdownMenuItem(value: 'public', child: Text(l10n.visibilityPublic)),
                  ],
                  onChanged: (v) => setState(() => visibility = v ?? 'private'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.actionCancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.createGuild)),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      final g = await api.create(name: name.text.trim(), description: description.text.trim(), visibility: visibility);
      ref.invalidate(myGuildsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.guildCreated)));
      context.push('/guilds/${g.id}');
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
  }

  Future<void> _join(BuildContext context, WidgetRef ref, GuildApi api) async {
    final l10n = context.l10n;
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.joinGuild),
        content: TextField(
          controller: code,
          autofocus: true,
          textDirection: TextDirection.ltr,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: l10n.inviteCode, hintText: l10n.inviteCodeHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.actionCancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.joinGuild)),
        ],
      ),
    );
    if (ok != true || code.text.trim().isEmpty) return;
    try {
      final g = await api.join(code.text);
      ref.invalidate(myGuildsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.guildJoined)));
      context.push('/guilds/${g.id}');
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
  }
}
