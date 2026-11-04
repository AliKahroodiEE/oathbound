import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oathbound_engine/oathbound_engine.dart';

import 'tokens.dart';

/// Hand-drawn geometric sigils for the six attributes, so attribute
/// identity never depends on colour alone (design-system §2).
class AttributeSigil extends StatelessWidget {
  const AttributeSigil(this.attribute, {super.key, this.size = 20, this.color});

  final Attribute attribute;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _SigilPainter(attribute, color ?? AppColors.forAttribute(attribute)),
    ),
  );
}

class _SigilPainter extends CustomPainter {
  _SigilPainter(this.attribute, this.color);

  final Attribute attribute;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, s / 12)
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    final c = Offset(s / 2, s / 2);
    switch (attribute) {
      case Attribute.strength:
        // Upward chevron over a bar.
        canvas.drawPath(
          Path()
            ..moveTo(s * .2, s * .55)
            ..lineTo(s * .5, s * .22)
            ..lineTo(s * .8, s * .55),
          p,
        );
        canvas.drawLine(Offset(s * .2, s * .78), Offset(s * .8, s * .78), p);
      case Attribute.intelligence:
        // Open eye inside a diamond.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, s * .08)
            ..lineTo(s * .92, c.dy)
            ..lineTo(c.dx, s * .92)
            ..lineTo(s * .08, c.dy)
            ..close(),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(s * .28, c.dy)
            ..quadraticBezierTo(c.dx, s * .3, s * .72, c.dy)
            ..quadraticBezierTo(c.dx, s * .7, s * .28, c.dy),
          p,
        );
        canvas.drawCircle(c, s * .06, p..style = PaintingStyle.fill);
      case Attribute.discipline:
        // A blade between two rails.
        canvas.drawLine(Offset(s * .22, s * .12), Offset(s * .22, s * .88), p);
        canvas.drawLine(Offset(s * .78, s * .12), Offset(s * .78, s * .88), p);
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, s * .1)
            ..lineTo(s * .6, s * .62)
            ..lineTo(c.dx, s * .9)
            ..lineTo(s * .4, s * .62)
            ..close(),
          p,
        );
      case Attribute.creativity:
        // A spiral quill.
        final path = Path();
        for (var i = 0; i <= 48; i++) {
          final t = i / 48 * math.pi * 3;
          final r = s * .04 + s * .11 * t / math.pi;
          final pt = Offset(c.dx + r * math.cos(t), c.dy + r * math.sin(t));
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(path, p);
        canvas.drawLine(Offset(s * .55, s * .55), Offset(s * .9, s * .9), p);
      case Attribute.vitality:
        // A leaf within a circle.
        canvas.drawCircle(c, s * .42, p);
        canvas.drawPath(
          Path()
            ..moveTo(s * .32, s * .7)
            ..quadraticBezierTo(s * .3, s * .3, s * .7, s * .3)
            ..quadraticBezierTo(s * .7, s * .7, s * .32, s * .7)
            ..moveTo(s * .32, s * .7)
            ..lineTo(s * .58, s * .44),
          p,
        );
      case Attribute.social:
        // Three linked rings.
        final r = s * .2;
        canvas.drawCircle(Offset(c.dx, s * .32), r, p);
        canvas.drawCircle(Offset(s * .32, s * .64), r, p);
        canvas.drawCircle(Offset(s * .68, s * .64), r, p);
    }
  }

  @override
  bool shouldRepaint(_SigilPainter old) =>
      old.attribute != attribute || old.color != color;
}

/// Character portrait sigils chosen during onboarding.
const portraitGlyphs = <String, IconData>{
  'crown': Icons.local_fire_department_outlined,
  'tower': Icons.castle_outlined,
  'moon': Icons.dark_mode_outlined,
  'blade': Icons.hardware_outlined,
  'eye': Icons.visibility_outlined,
  'star': Icons.auto_awesome_outlined,
};
