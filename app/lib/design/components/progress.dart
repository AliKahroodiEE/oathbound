import 'package:flutter/material.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../sigils.dart';
import '../tokens.dart';
import 'motion.dart';

/// True-proportion progress bar with a gradient fill from the start edge.
class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.fraction, this.color, this.height = 8, this.semanticsLabel});

  final double fraction;

  /// Solid tint for attribute bars; null uses the ember gradient.
  final Color? color;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final f = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;
    final c = color;
    return Semantics(
      label: semanticsLabel,
      value: '${(f * 100).round()}%',
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: (c ?? context.palette.accent).withValues(alpha: 0.12))),
              TweenAnimationBuilder<double>(
                tween: Tween(end: f),
                duration: motion(context, AppMotion.reveal),
                curve: AppMotion.emphasizedDecelerate,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: value,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.pillAll,
                      gradient: c == null ? AppGradients.ember : context.palette.tint(c),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sigil · name · rank · bar · today's delta (list form).
class AttributeRow extends StatelessWidget {
  const AttributeRow({
    super.key,
    required this.attribute,
    required this.name,
    required this.rankLabel,
    required this.fraction,
    this.todayLabel,
    this.onTap,
  });

  final Attribute attribute;
  final String name;
  final String rankLabel;
  final double fraction;
  final String? todayLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AttributeTile(
    attribute: attribute,
    name: name,
    rankLabel: rankLabel,
    fraction: fraction,
    todayLabel: todayLabel,
    onTap: onTap,
  );
}

/// Attribute card: tinted sigil badge, name, rank and a progress bar.
class AttributeTile extends StatelessWidget {
  const AttributeTile({
    super.key,
    required this.attribute,
    required this.name,
    required this.rankLabel,
    required this.fraction,
    this.todayLabel,
    this.onTap,
  });

  final Attribute attribute;
  final String name;
  final String rankLabel;
  final double fraction;
  final String? todayLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = context.palette.attribute(attribute);
    return Pressable(
      enabled: onTap != null,
      child: Material(
        color: color.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.softAll,
          side: BorderSide(color: color.withValues(alpha: 0.22)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: AttributeSigil(attribute, size: 18),
                    ),
                    const SizedBox(width: AppSpace.sm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: rankLabel,
                                  style: text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                                ),
                                if (todayLabel != null)
                                  TextSpan(
                                    text: '  $todayLabel',
                                    style: text.labelMedium?.copyWith(color: context.palette.success),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm + 2),
                XpBar(fraction: fraction, color: color, height: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small statistic card: tinted icon, value, label, optional caption.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.caption,
    this.color = AppColors.ember,
    this.vertical = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? caption;
  final Color color;

  /// Stacked layout for narrow, three-across rows.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (vertical) {
      return Container(
        padding: const EdgeInsetsDirectional.all(AppSpace.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: AppRadius.softAll,
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: AppSpace.sm),
            Text(value, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(label, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      decoration: BoxDecoration(
        color: context.palette.sunken.withValues(alpha: 0.7),
        borderRadius: AppRadius.softAll,
        border: Border.all(color: context.palette.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppRadius.sharpAll),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(label, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (caption != null)
                  Text(caption!, style: text.bodySmall?.copyWith(color: context.palette.inkFaint), maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The carved level badge.
class LevelSeal extends StatelessWidget {
  const LevelSeal({super.key, required this.level, required this.caption, this.size = 64});

  final String level;
  final String caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$caption $level',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs + 2),
        decoration: BoxDecoration(
          gradient: AppGradients.emberDiagonal,
          borderRadius: AppRadius.pillAll,
          boxShadow: AppShadows.glow(AppColors.ember, strength: 0.4, blur: 14),
        ),
        child: Text(
          '$caption $level',
          style: text.labelLarge?.copyWith(color: AppColors.onAccent, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
