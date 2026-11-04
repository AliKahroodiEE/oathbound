import 'package:flutter/material.dart';

import '../tokens.dart';
import 'motion.dart';

/// Completion control: an empty ring that fills into a crimson seal.
class SealCheckbox extends StatelessWidget {
  const SealCheckbox({super.key, required this.checked, required this.onPressed, required this.semanticLabel});

  final bool checked;
  final VoidCallback? onPressed;
  final String semanticLabel;

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
              duration: motion(context, AppMotion.quick),
              curve: AppMotion.standard,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? AppColors.crimson : Colors.transparent,
                border: Border.all(color: checked ? AppColors.crimson : AppColors.ashMuted, width: 1.5),
              ),
              child: checked ? const Icon(Icons.check, size: 16, color: AppColors.bone) : null,
            ),
          ),
        ),
      ),
    );
  }
}
