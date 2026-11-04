import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// App backdrop: the canvas, a soft glow high at the start edge, a fainter
/// one low at the end edge, and a scatter of still embers (dark) or
/// parchment flecks (light). Painted once into its own layer and never
/// animated, so it costs nothing while the app scrolls.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.reducedEffects = false});

  final Widget child;
  final bool reducedEffects;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (reducedEffects) return ColoredBox(color: p.canvas, child: child);
    return ColoredBox(
      color: p.canvas,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _BackdropPainter(p, Directionality.of(context)))),
          ),
          child,
        ],
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.palette, this.direction);

  final Palette palette;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = palette.backdrop.createShader(rect, textDirection: direction));
    canvas.drawRect(rect, Paint()..shader = palette.backdropLow.createShader(rect, textDirection: direction));

    // Fixed seed: the same sky every time, denser near the top.
    final rnd = math.Random(11);
    final strength = palette.isDark ? 1.0 : 0.55;
    final count = (size.width * size.height / 26000).clamp(18, 64).round();
    final dot = Paint();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = math.pow(rnd.nextDouble(), 1.5) * size.height;
      final r = 0.6 + math.pow(rnd.nextDouble(), 3) * 1.8;
      final a = (0.06 + rnd.nextDouble() * 0.22) * strength * (1 - 0.6 * y / size.height);
      if (r > 1.6) {
        // A few larger embers get a faint halo.
        canvas.drawCircle(Offset(x, y), r * 3.2, dot..color = palette.mote.withValues(alpha: a * 0.18));
      }
      canvas.drawCircle(Offset(x, y), r, dot..color = palette.mote.withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.palette != palette || old.direction != direction;
}
