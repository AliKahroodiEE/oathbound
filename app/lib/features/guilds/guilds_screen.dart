import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/config.dart';
import '../../design/components/panel.dart';
import '../../design/tokens.dart';

/// Guilds entry point. Guilds are inherently online, so the screen states
/// clearly when this build has no backend or the user has no account,
/// while the rest of the product keeps working locally.
class GuildsScreen extends ConsumerWidget {
  const GuildsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final configured = BackendConfig.isConfigured;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guildsTitle)),
      body: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            children: [
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.groups_2_outlined, size: 40, color: AppColors.ashMuted),
                    const SizedBox(height: AppSpace.md),
                    Text(l10n.guildsIntro, style: text.bodyLarge, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpace.lg),
                    Text(
                      configured ? l10n.guildsRequireAccount : l10n.guildsBackendMissing,
                      style: text.bodyMedium?.copyWith(color: AppColors.ashMuted),
                      textAlign: TextAlign.center,
                    ),
                    if (configured) ...[
                      const SizedBox(height: AppSpace.lg),
                      FilledButton(onPressed: () => context.push('/auth'), child: Text(l10n.signIn)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
