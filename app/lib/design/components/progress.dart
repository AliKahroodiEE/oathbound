import 'package:flutter/material.dart';
import 'package:oathbound_engine/oathbound_engine.dart';

import '../sigils.dart';
import '../tokens.dart';
import 'motion.dart';

/// True-proportion progress bar that fills from the start edge and
/// animates changes (design-system §6, XP bar).
class XpBar extends StatelessWidget {
  const XpBar({
    super.key,
    required this.fraction,
    this.color = AppColors.crimson,
    this.height = 6,
    this.semanticsLabel,
  });

  final double fraction;
  final Color color;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final f = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;
    return Semantics(
      label: semanticsLabel,
      value: '${(f * 100).round()}%',
      child: ClipRRect(
        borderRadius: AppRadius.sharpAll,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: AppColors.abyss)),
              TweenAnimationBuilder<double>(
                tween: Tween(end: f),
                duration: motion(context, AppMotion.reveal),
                curve: AppMotion.emphasizedDecelerate,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: value,
                  heightFactor: 1,
                  child: ColoredBox(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sigil · name · rank · bar · today's delta.
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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.softAll,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.sm, horizontal: AppSpace.xs),
        child: Row(
          children: [
            AttributeSigil(attribute, size: 22),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: text.titleSmall)),
                      if (todayLabel != null)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
                          child: Text(todayLabel!, style: text.bodySmall),
                        ),
                      Text(rankLabel, style: text.labelMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs + 2),
                  XpBar(fraction: fraction, color: AppColors.forAttribute(attribute), height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The carved level seal shown on the character sheet.
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
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.abyss,
          border: Border.all(color: AppColors.crimson, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(level, style: text.titleLarge?.copyWith(height: 1)),
            Text(caption, style: text.labelSmall?.copyWith(fontSize: 9, height: 1.2)),
          ],
        ),
      ),
    );
  }
}
