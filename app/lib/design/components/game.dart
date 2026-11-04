import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

import '../tokens.dart';
import 'motion.dart';

/// Circular XP ring with an ember sweep, drawn around [child] (the portrait).
class XpRing extends StatelessWidget {
  const XpRing({super.key, required this.fraction, required this.child, this.size = 112, this.stroke = 7});

  final double fraction;
  final Widget child;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final f = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: f),
        duration: motion(context, AppMotion.reveal),
        curve: AppMotion.emphasizedDecelerate,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, stroke),
          child: SizedBox.square(
            dimension: size,
            child: Padding(padding: EdgeInsets.all(stroke * 2), child: child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke);
  final double value;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2 + 2);
    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.hairline,
    );
    if (value <= 0) return;
    final sweep = math.pi * 2 * value;
    // A wider translucent pass gives a soft halo without a blur filter.
    canvas.drawArc(
      arc,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke * 2.2
        ..color = AppColors.ember.withValues(alpha: 0.16),
    );
    canvas.drawArc(
      arc,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..shader = const SweepGradient(
          colors: [AppColors.crimson, AppColors.ember, AppColors.emberGlow, AppColors.crimson],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

/// Hexagonal radar of the six attributes. Values are 0–1 shares of the
/// strongest attribute. Axes run clockwise in LTR and mirror in RTL.
class AttributeRadar extends StatelessWidget {
  const AttributeRadar({super.key, required this.values, required this.labels, this.size = 230});

  final Map<Attribute, double> values;
  final Map<Attribute, String> labels;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      label: [for (final a in Attribute.values) '${labels[a]} ${((values[a] ?? 0) * 100).round()}%'].join(', '),
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: motion(context, AppMotion.reveal),
          curve: AppMotion.emphasizedDecelerate,
          builder: (context, t, _) => CustomPaint(
            size: Size.square(size),
            painter: _RadarPainter(values, labels, style, rtl, t, Directionality.of(context)),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.values, this.labels, this.style, this.rtl, this.t, this.direction);

  final Map<Attribute, double> values;
  final Map<Attribute, String> labels;
  final TextStyle style;
  final bool rtl;
  final double t;
  final TextDirection direction;

  Offset _point(Offset c, double r, int i) {
    final angle = -math.pi / 2 + (rtl ? -1 : 1) * i * math.pi / 3;
    return c + Offset(math.cos(angle), math.sin(angle)) * r;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 30;
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.hairline;
    for (final k in [1 / 3, 2 / 3, 1.0]) {
      final path = Path();
      for (var i = 0; i < 6; i++) {
        final p = _point(c, r * k, i);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path..close(), grid);
    }
    for (var i = 0; i < 6; i++) {
      canvas.drawLine(c, _point(c, r, i), grid);
    }

    final shape = Path();
    const attrs = Attribute.values;
    for (var i = 0; i < 6; i++) {
      final v = ((values[attrs[i]] ?? 0).clamp(0.12, 1.0)) * t;
      final p = _point(c, r * v, i);
      i == 0 ? shape.moveTo(p.dx, p.dy) : shape.lineTo(p.dx, p.dy);
    }
    shape.close();
    canvas.drawPath(
      shape,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.arcane.withValues(alpha: 0.45), AppColors.ember.withValues(alpha: 0.35)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.ember,
    );

    for (var i = 0; i < 6; i++) {
      final a = attrs[i];
      final v = ((values[a] ?? 0).clamp(0.12, 1.0)) * t;
      canvas.drawCircle(_point(c, r * v, i), 4.5, Paint()..color = AppColors.forAttribute(a));
      final tp = TextPainter(
        text: TextSpan(
          text: labels[a] ?? a.name,
          style: style.copyWith(color: AppColors.forAttribute(a)),
        ),
        textDirection: direction,
        maxLines: 1,
      )..layout(maxWidth: 90);
      final lp = _point(c, r + 16, i);
      tp.paint(canvas, lp - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t || old.values != values || old.labels != labels;
}

/// Gradient floating action button with a soft ember glow.
class GlowFab extends StatelessWidget {
  const GlowFab({super.key, required this.onPressed, required this.tooltip, this.icon = Icons.add_rounded});

  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.emberDiagonal,
        borderRadius: AppRadius.softAll,
        boxShadow: AppShadows.glow(AppColors.ember, strength: 0.5, blur: 20),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.softAll,
          onTap: onPressed,
          child: SizedBox.square(dimension: 58, child: Icon(icon, color: AppColors.bone, size: 30)),
        ),
      ),
    ),
  );
}

/// Gradient primary button for hero calls to action.
class GlowButton extends StatelessWidget {
  const GlowButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.ember,
          borderRadius: AppRadius.pillAll,
          boxShadow: enabled ? AppShadows.glow(AppColors.ember, strength: 0.35, blur: 16) : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.pillAll,
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: AppColors.bone, size: 20),
                      const SizedBox(width: AppSpace.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.bone),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon for a quest category.
IconData categoryIcon(QuestCategory? c) => switch (c) {
  QuestCategory.study => Icons.school_outlined,
  QuestCategory.work => Icons.work_outline,
  QuestCategory.fitness => Icons.fitness_center,
  QuestCategory.health => Icons.favorite_outline,
  QuestCategory.creative => Icons.palette_outlined,
  QuestCategory.social => Icons.groups_outlined,
  QuestCategory.chores => Icons.home_outlined,
  QuestCategory.admin => Icons.receipt_long_outlined,
  QuestCategory.mindfulness => Icons.self_improvement,
  QuestCategory.reading => Icons.menu_book_outlined,
  QuestCategory.other || null => Icons.auto_awesome_outlined,
};
