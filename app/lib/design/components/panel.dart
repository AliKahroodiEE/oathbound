import 'package:flutter/material.dart';

import '../tokens.dart';

/// Card surface: stone-lit gradient, hairline border, generous radius.
/// [accent] adds a thin glowing rule along the top edge for featured cards.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.icon,
    this.accent,
    this.padding = const EdgeInsetsDirectional.all(AppSpace.lg),
    this.onTap,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final IconData? icon;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            SectionHeader(title!, trailing: trailing, icon: icon, color: accent),
            const SizedBox(height: AppSpace.md),
          ],
          child,
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.surface,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: AppColors.hairline),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardAll,
        child: Stack(
          children: [
            if (accent != null)
              PositionedDirectional(
                top: 0,
                start: AppSpace.xl,
                end: AppSpace.xl,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent!.withValues(alpha: 0), accent!, accent!.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            Material(
              type: MaterialType.transparency,
              child: onTap == null ? content : InkWell(onTap: onTap, child: content),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small-caps label with an optional glyph and trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing, this.icon, this.color});

  final String text;
  final Widget? trailing;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(color: color ?? AppColors.ashMuted);
    return Semantics(
      header: true,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color ?? AppColors.ember),
            const SizedBox(width: AppSpace.sm),
          ],
          Expanded(
            child: Text(
              Directionality.of(context) == TextDirection.ltr ? text.toUpperCase() : text,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.sm),
            // Natural width, capped so long labels at large text sizes can't crowd out the title.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              // Header actions are compact so the header stays one line tall.
              child: TextButtonTheme(
                data: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                child: trailing!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact rounded label, tinted with [color].
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color = AppColors.ember, this.icon, this.filled = false});

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.labelMedium;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.sm + 2, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.14),
        borderRadius: AppRadius.pillAll,
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: filled ? AppColors.bone : color), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text?.copyWith(color: filled ? AppColors.bone : color, fontWeight: FontWeight.w600, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}
