import 'package:flutter/material.dart';

import '../tokens.dart';
import 'motion.dart';

/// Completion control: a ring tinted by the quest's colour that fills into
/// an ember seal.
class SealCheckbox extends StatelessWidget {
  const SealCheckbox({
    super.key,
    required this.checked,
    required this.onPressed,
    required this.semanticLabel,
    this.color = AppColors.ember,
  });

  final bool checked;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: checked,
      label: semanticLabel,
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: motion(context, AppMotion.base),
              curve: AppMotion.standard,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: checked ? AppGradients.emberDiagonal : null,
                border: checked ? null : Border.all(color: color.withValues(alpha: 0.7), width: 2),
                boxShadow: checked ? AppShadows.glow(AppColors.ember, strength: 0.45, blur: 12) : null,
              ),
              child: checked ? const Icon(Icons.check_rounded, size: 17, color: AppColors.onAccent) : null,
            ),
          ),
        ),
      ),
    );
  }
}
