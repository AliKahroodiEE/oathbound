import 'package:flutter/material.dart';

import '../tokens.dart';

/// App background: void with a faint vignette toward the edges.
/// Disabled when the user reduces visual effects.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.reducedEffects = false});

  final Widget child;
  final bool reducedEffects;

  @override
  Widget build(BuildContext context) {
    if (reducedEffects) return ColoredBox(color: AppColors.void_, child: child);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: AlignmentDirectional(-0.4, -0.9),
          radius: 1.4,
          colors: [Color(0xFF141621), AppColors.void_],
          stops: [0, 0.75],
        ),
      ),
      child: child,
    );
  }
}
