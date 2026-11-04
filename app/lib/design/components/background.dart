import 'package:flutter/material.dart';

import '../tokens.dart';

/// App backdrop: void with a soft arcane glow at the top. A single radial
/// gradient — no blur, no images — so it costs nothing on any renderer.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.reducedEffects = false});

  final Widget child;
  final bool reducedEffects;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: reducedEffects
        ? BoxDecoration(color: context.palette.canvas)
        : BoxDecoration(gradient: context.palette.backdrop),
    child: child,
  );
}
