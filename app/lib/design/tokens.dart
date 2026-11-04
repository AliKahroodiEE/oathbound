import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

/// Ashen Codex colour tokens (docs/design/design-system.md §2).
/// Feature code must use these, never raw colours.
abstract final class AppColors {
  static const void_ = Color(0xFF0B0B10);
  static const abyss = Color(0xFF12131A);
  static const slate = Color(0xFF202A38);
  static const slateHigh = Color(0xFF2A3546);
  static const hairline = Color(0xFF343F52);
  static const wine = Color(0xFF5A2630);
  static const crimson = Color(0xFFA71924);
  static const ember = Color(0xFFE0525C);
  static const bone = Color(0xFFECE6DA);
  static const ash = Color(0xFFC4C7D0);
  static const ashMuted = Color(0xFF8A8F9C);
  static const ashFaint = Color(0xFF5E6372);

  static const warning = Color(0xFFC8933A);
  static const success = attrVitality;
  static const danger = ember;

  static const attrStrength = Color(0xFFB5543C);
  static const attrIntelligence = Color(0xFF5B7FB8);
  static const attrDiscipline = Color(0xFF9A8A6A);
  static const attrCreativity = Color(0xFF8A5FA8);
  static const attrVitality = Color(0xFF4E8C6A);
  static const attrSocial = Color(0xFFC07A8A);

  static Color forAttribute(Attribute a) => switch (a) {
    Attribute.strength => attrStrength,
    Attribute.intelligence => attrIntelligence,
    Attribute.discipline => attrDiscipline,
    Attribute.creativity => attrCreativity,
    Attribute.vitality => attrVitality,
    Attribute.social => attrSocial,
  };
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
  static const sharp = Radius.circular(2);
  static const soft = Radius.circular(6);
  static const sharpAll = BorderRadius.all(sharp);
  static const softAll = BorderRadius.all(soft);
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
