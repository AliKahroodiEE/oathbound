import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';
import 'motion.dart';

/// Completion control: a ring tinted by the quest's colour that fills into
/// an ember seal. When a deed is sealed the seal pops and throws a ring of
/// sparks; if a sheet covered the list at that moment, the celebration
/// waits until the user is back.
class SealCheckbox extends StatefulWidget {
  const SealCheckbox({
    super.key,
    required this.checked,
    required this.onPressed,
    required this.semanticLabel,
    this.color = AppColors.ember,
  });

  final bool checked;
  final FutureOr<void> Function()? onPressed;
  final String semanticLabel;
  final Color color;

  @override
  State<SealCheckbox> createState() => _SealCheckboxState();
}

class _SealCheckboxState extends State<SealCheckbox> with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  late bool _celebrated = widget.checked;

  @override
  void didUpdateWidget(SealCheckbox old) {
    super.didUpdateWidget(old);
    if (!widget.checked) {
      _celebrated = false;
    } else if (!old.checked && (ModalRoute.of(context)?.isCurrent ?? true)) {
      _celebrate();
    }
  }

  void _celebrate() {
    if (_celebrated || !widget.checked) return;
    _celebrated = true;
    if (motion(context, AppMotion.base) != Duration.zero) _burst.forward(from: 0);
  }

  Future<void> _tap() async {
    unawaited(HapticFeedback.selectionClick());
    await widget.onPressed?.call();
    if (mounted) _celebrate();
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checked = widget.checked;
    return Semantics(
      button: true,
      checked: checked,
      label: widget.semanticLabel,
      child: InkResponse(
        onTap: widget.onPressed == null ? null : _tap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: CustomPaint(
            painter: _BurstPainter(_burst, widget.color),
            child: Center(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (context, child) => Transform.scale(
                  scale: _burst.isAnimating ? 0.82 + 0.18 * Curves.easeOutBack.transform(_burst.value) : 1,
                  child: child,
                ),
                child: AnimatedContainer(
                  duration: motion(context, AppMotion.base),
                  curve: AppMotion.standard,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: checked ? AppGradients.emberDiagonal : null,
                    border: checked ? null : Border.all(color: widget.color.withValues(alpha: 0.75), width: 2),
                    boxShadow: checked ? AppShadows.glow(AppColors.ember, strength: 0.45, blur: 12) : null,
                  ),
                  child: checked ? const Icon(Icons.check_rounded, size: 17, color: AppColors.onAccent) : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An expanding ember ring with six sparks; paints nothing at rest.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.animation, this.color) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final v = animation.value;
    if (v <= 0 || v >= 1) return;
    final c = size.center(Offset.zero);
    final out = Curves.easeOutCubic.transform(v);
    final fade = 1 - v;
    canvas.drawCircle(
      c,
      13 + 10 * out,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * fade
        ..color = AppColors.ember.withValues(alpha: 0.55 * fade),
    );
    final spark = Paint()..color = Color.lerp(AppColors.emberGlow, color, 0.35)!.withValues(alpha: 0.9 * fade);
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (14 + 9 * out), 1.8 * fade + 0.4, spark);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.color != color || old.animation != animation;
}
