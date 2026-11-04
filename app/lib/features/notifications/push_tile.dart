import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design/tokens.dart';
import 'push_provider.dart';
import 'push_service.dart';

export 'push_provider.dart' show pushServiceProvider;

/// This device's row in the Notifications panel: whether push reaches it,
/// with an Allow button while the system permission can still be asked for.
/// Hidden when push is not offered (guests, unconfigured builds, switches off).
class PushDeviceTile extends ConsumerStatefulWidget {
  const PushDeviceTile({super.key});

  @override
  ConsumerState<PushDeviceTile> createState() => _PushDeviceTileState();
}

class _PushDeviceTileState extends ConsumerState<PushDeviceTile> {
  @override
  void initState() {
    super.initState();
    // Opening Settings after signing in is the moment to ask, once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(pushServiceProvider).settingsOpened());
    });
  }

  @override
  Widget build(BuildContext context) {
    final push = ref.watch(pushServiceProvider);
    return ValueListenableBuilder(
      valueListenable: push.status,
      builder: (context, status, _) {
        final l10n = context.l10n;
        final palette = context.palette;
        Widget row(IconData icon, Color color, String subtitle, {Widget? trailing}) => ListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          leading: Icon(icon, color: color),
          title: Text(l10n.pushDevice),
          subtitle: Text(subtitle),
          trailing: trailing,
        );
        return switch (status) {
          PushStatus.hidden => const SizedBox.shrink(),
          PushStatus.on => row(Icons.notifications_active_outlined, palette.success, l10n.pushDeviceOn),
          PushStatus.off => row(
            Icons.notifications_none_outlined,
            palette.inkMuted,
            l10n.pushDeviceOff,
            trailing: OutlinedButton(onPressed: push.enable, child: Text(l10n.pushAllow)),
          ),
          PushStatus.blocked => row(Icons.notifications_off_outlined, palette.warning, l10n.pushDeviceBlocked),
          PushStatus.unsupported => row(
            Icons.notifications_off_outlined,
            palette.inkMuted,
            // iPhones get web push only from a Home Screen web app.
            kIsWeb && defaultTargetPlatform == TargetPlatform.iOS ? l10n.pushInstallHint : l10n.pushUnsupported,
          ),
        };
      },
    );
  }
}
