import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

/// Ashen Codex colour tokens, v2 (docs/design/design-system.md §2).
/// Dark-fantasy base with livelier, saturated accents. Feature code uses
/// these, never raw colours.
abstract final class AppColors {
  // Surfaces: near-black with a cold, slightly blue stone tint.
  static const void_ = Color(0xFF09090E);
  static const abyss = Color(0xFF111320);
  static const slate = Color(0xFF181C2B);
  static const slateHigh = Color(0xFF222839);
  static const hairline = Color(0xFF2C3346);
  static const wine = Color(0xFF4A1A26);

  // Ember family: the primary accent, used for actions and progression.
  static const crimson = Color(0xFFC0202D);
  static const ember = Color(0xFFFF5A64);
  static const emberGlow = Color(0xFFFF8A4C);

  // Secondary accents, used sparingly.
  static const arcane = Color(0xFF8B6CFF);
  static const gold = Color(0xFFE2B45C);

  // Ink.
  static const bone = Color(0xFFF1EBDF);
  static const ash = Color(0xFFC9CCD6);
  static const ashMuted = Color(0xFF8E94A3);
  static const ashFaint = Color(0xFF5A6074);

  static const warning = Color(0xFFF0A93B);
  static const success = attrVitality;
  static const danger = ember;

  // Attributes: saturated pigments, always paired with a sigil.
  static const attrStrength = Color(0xFFF0663E);
  static const attrIntelligence = Color(0xFF5B95FF);
  static const attrDiscipline = Color(0xFFD9B260);
  static const attrCreativity = Color(0xFFB476FF);
  static const attrVitality = Color(0xFF3FCB8E);
  static const attrSocial = Color(0xFFFF73A8);

  static Color forAttribute(Attribute a) => switch (a) {
    Attribute.strength => attrStrength,
    Attribute.intelligence => attrIntelligence,
    Attribute.discipline => attrDiscipline,
    Attribute.creativity => attrCreativity,
    Attribute.vitality => attrVitality,
    Attribute.social => attrSocial,
  };

  /// Colour of a category's main attribute.
  static Color forCategory(QuestCategory c) => forAttribute(c.defaultWeights.keys.first);
}

/// Gradients. Linear/radial only (cheap on every renderer); no blurs.
abstract final class AppGradients {
  static const ember = LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
    colors: [AppColors.crimson, AppColors.emberGlow],
  );

  static const emberDiagonal = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [AppColors.crimson, AppColors.ember, AppColors.emberGlow],
  );

  /// Card surface: lighter at the top, like stone lit from above.
  static const surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1C2132), Color(0xFF151927)],
  );

  /// Background glow behind the app: ember low, arcane high.
  static const backdrop = RadialGradient(
    center: AlignmentDirectional(-0.6, -1.1),
    radius: 1.3,
    colors: [Color(0xFF241A36), AppColors.void_],
    stops: [0, 0.7],
  );

  static LinearGradient tint(Color c) => LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
    colors: [c, Color.lerp(c, AppColors.bone, 0.25)!],
  );
}

/// Shadows: only on a few hero elements (cost matters on web and older phones).
abstract final class AppShadows {
  static List<BoxShadow> glow(Color c, {double strength = 0.35, double blur = 18}) => [
    BoxShadow(
      color: c.withValues(alpha: strength),
      blurRadius: blur,
      spreadRadius: -4,
    ),
  ];
}

/// 4-pt spacing scale.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

abstract final class AppRadius {
  static const sharp = Radius.circular(8);
  static const soft = Radius.circular(14);
  static const card = Radius.circular(18);
  static const pill = Radius.circular(999);
  static const sharpAll = BorderRadius.all(sharp);
  static const softAll = BorderRadius.all(soft);
  static const cardAll = BorderRadius.all(card);
  static const pillAll = BorderRadius.all(pill);
}

/// Motion tokens; durations collapse to zero when motion is reduced.
abstract final class AppMotion {
  static const quick = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const settle = Duration(milliseconds: 320);
  static const reveal = Duration(milliseconds: 900);

  static const standard = Cubic(0.2, 0, 0, 1);
  static const emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);
}

/// Window width classes (ADR-001).
enum WidthClass {
  compact,
  medium,
  expanded;

  static WidthClass of(double width) => width < 600
      ? WidthClass.compact
      : width < 1200
      ? WidthClass.medium
      : WidthClass.expanded;
}
