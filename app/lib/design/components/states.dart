import 'package:flutter/material.dart';

import '../tokens.dart';
import 'motion.dart';

/// Empty state: a quiet glyph, one sentence in voice, one action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.auto_awesome_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.xl, horizontal: AppSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [context.palette.selection, context.palette.selection.withValues(alpha: 0)],
              ),
              border: Border.all(color: context.palette.hairline),
            ),
            child: Icon(icon, size: 28, color: context.palette.accent),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            message,
            style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpace.md),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Error state: ember hairline on the start edge, plain message, retry.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.retryLabel, this.onRetry});

  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.sunken,
        border: BorderDirectional(start: BorderSide(color: context.palette.accent, width: 2)),
      ),
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Row(
        children: [
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
          if (onRetry != null && retryLabel != null) TextButton(onPressed: onRetry, child: Text(retryLabel!)),
        ],
      ),
    );
  }
}

/// Skeleton block with a slow opacity breathe (no spinners).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 16, this.width});

  final double height;
  final double? width;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motion(context, AppMotion.base) == Duration.zero) {
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.35, end: 0.8).animate(_c),
    child: Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(color: context.palette.surfaceHigh, borderRadius: AppRadius.sharpAll),
    ),
  );
}

/// Page-level loading layout made of skeleton panels.
class LoadingPanels extends StatelessWidget {
  const LoadingPanels({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
    child: Padding(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[const Skeleton(height: 96), const SizedBox(height: AppSpace.lg)],
        ],
      ),
    ),
  );
}
