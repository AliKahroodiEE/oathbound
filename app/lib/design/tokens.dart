import 'package:flutter/material.dart';
import 'package:wyrd_engine/wyrd_engine.dart';

/// Brand colours shared by both themes (docs/design/design-system.md §2).
/// Everything that changes between light and dark lives in [Palette].
abstract final class AppColors {
  // Ember family: the primary accent, used for actions and progression.
  static const crimson = Color(0xFFC0202D);
  static const ember = Color(0xFFFF5A64);
  static const emberGlow = Color(0xFFFF8A4C);
  static const arcane = Color(0xFF8B6CFF);

  /// Text and icons drawn on ember gradients, in either theme.
  static const onAccent = Color(0xFFFFF5EA);
}

/// Theme-dependent colours. Read with `context.palette`.
///
/// Dark is "Ashen Codex": cold stone, ember light. Light is "Vellum":
/// warm parchment, iron-gall ink and crimson seals.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette._({
    required this.brightness,
    required this.canvas,
    required this.sunken,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceTop,
    required this.surfaceBottom,
    required this.hairline,
    required this.accentContainer,
    required this.selection,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.inkFaint,
    required this.accent,
    required this.flame,
    required this.arcane,
    required this.gold,
    required this.success,
    required this.warning,
    required this.glow,
    required this.glowSecondary,
    required this.mote,
    required this.strength,
    required this.intelligence,
    required this.discipline,
    required this.creativity,
    required this.vitality,
    required this.social,
    required this.cardShadow,
  });

  static const dark = Palette._(
    brightness: Brightness.dark,
    canvas: Color(0xFF09090E),
    sunken: Color(0xFF111320),
    surface: Color(0xFF181C2B),
    surfaceHigh: Color(0xFF222839),
    surfaceTop: Color(0xFF1C2132),
    surfaceBottom: Color(0xFF151927),
    hairline: Color(0xFF2C3346),
    accentContainer: Color(0xFF4A1A26),
    selection: Color(0x4DC0202D),
    ink: Color(0xFFF1EBDF),
    inkSoft: Color(0xFFC9CCD6),
    inkMuted: Color(0xFF8E94A3),
    inkFaint: Color(0xFF5A6074),
    accent: Color(0xFFFF5A64),
    flame: Color(0xFFFF8A4C),
    arcane: Color(0xFF8B6CFF),
    gold: Color(0xFFE2B45C),
    success: Color(0xFF3FCB8E),
    warning: Color(0xFFF0A93B),
    glow: Color(0xFF241A36),
    glowSecondary: Color(0xFF1E0F17),
    mote: Color(0xFFFF8A4C),
    strength: Color(0xFFF0663E),
    intelligence: Color(0xFF5B95FF),
    discipline: Color(0xFFD9B260),
    creativity: Color(0xFFB476FF),
    vitality: Color(0xFF3FCB8E),
    social: Color(0xFFFF73A8),
    cardShadow: [],
  );

  static const light = Palette._(
    brightness: Brightness.light,
    canvas: Color(0xFFF4EDE1),
    sunken: Color(0xFFECE3D3),
    surface: Color(0xFFFDFAF4),
    surfaceHigh: Color(0xFFE6DCC9),
    surfaceTop: Color(0xFFFFFDF9),
    surfaceBottom: Color(0xFFF9F3E9),
    hairline: Color(0xFFDCCFB8),
    accentContainer: Color(0xFFF7DCDC),
    selection: Color(0x26C0202D),
    ink: Color(0xFF1F1A23),
    inkSoft: Color(0xFF3E3844),
    inkMuted: Color(0xFF6D6571),
    inkFaint: Color(0xFFA0969A),
    accent: Color(0xFFB81D2A),
    flame: Color(0xFFC2561A),
    arcane: Color(0xFF6447D6),
    gold: Color(0xFF8E600F),
    success: Color(0xFF17845A),
    warning: Color(0xFFA86200),
    glow: Color(0xFFF6DCD3),
    glowSecondary: Color(0xFFEAE0F2),
    mote: Color(0xFF9C6B3C),
    strength: Color(0xFFC4441C),
    intelligence: Color(0xFF2C63CF),
    discipline: Color(0xFF8F6A12),
    creativity: Color(0xFF7A3FD4),
    vitality: Color(0xFF178457),
    social: Color(0xFFC42F6C),
    cardShadow: [BoxShadow(color: Color(0x1A3B2414), blurRadius: 22, offset: Offset(0, 8), spreadRadius: -10)],
  );

  final Brightness brightness;

  // Surfaces.
  final Color canvas;
  final Color sunken;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceTop;
  final Color surfaceBottom;
  final Color hairline;
  final Color accentContainer;

  /// Translucent ember wash behind selected chips, segments and nav items.
  final Color selection;

  // Ink, from strongest to faintest.
  final Color ink;
  final Color inkSoft;
  final Color inkMuted;
  final Color inkFaint;

  // Accents tuned for legible text and icons on this theme's surfaces.
  final Color accent;
  final Color flame;
  final Color arcane;
  final Color gold;
  final Color success;
  final Color warning;

  // Backdrop.
  final Color glow;
  final Color glowSecondary;
  final Color mote;

  // Attribute pigments, always paired with a sigil.
  final Color strength;
  final Color intelligence;
  final Color discipline;
  final Color creativity;
  final Color vitality;
  final Color social;

  /// Elevation for cards. Empty in dark, where hairlines carry the edges.
  final List<BoxShadow> cardShadow;

  bool get isDark => brightness == Brightness.dark;

  Color attribute(Attribute a) => switch (a) {
    Attribute.strength => strength,
    Attribute.intelligence => intelligence,
    Attribute.discipline => discipline,
    Attribute.creativity => creativity,
    Attribute.vitality => vitality,
    Attribute.social => social,
  };

  /// Colour of a category's main attribute.
  Color category(QuestCategory c) => attribute(c.defaultWeights.keys.first);

  /// Card surface: lighter at the top, like stone (or vellum) lit from above.
  LinearGradient get surfaceGradient =>
      LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [surfaceTop, surfaceBottom]);

  /// Glow behind the app: arcane (or rose) high at the start edge.
  RadialGradient get backdrop => RadialGradient(
    center: const AlignmentDirectional(-0.6, -1.1),
    radius: 1.3,
    colors: [glow, canvas.withValues(alpha: 0)],
    stops: const [0, 0.7],
  );

  /// Second, fainter glow low at the end edge, for depth.
  RadialGradient get backdropLow => RadialGradient(
    center: const AlignmentDirectional(1.1, 1.2),
    radius: 1.1,
    colors: [glowSecondary, canvas.withValues(alpha: 0)],
    stops: const [0, 0.75],
  );

  /// Bar fill for a solid tint, brightening towards the end edge.
  LinearGradient tint(Color c) => LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
    colors: [c, Color.lerp(c, isDark ? AppColors.onAccent : const Color(0xFFFFFFFF), 0.25)!],
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(covariant Palette? other, double t) {
    if (other == null || identical(this, other)) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette._(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: c(canvas, other.canvas),
      sunken: c(sunken, other.sunken),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      surfaceTop: c(surfaceTop, other.surfaceTop),
      surfaceBottom: c(surfaceBottom, other.surfaceBottom),
      hairline: c(hairline, other.hairline),
      accentContainer: c(accentContainer, other.accentContainer),
      selection: c(selection, other.selection),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      inkMuted: c(inkMuted, other.inkMuted),
      inkFaint: c(inkFaint, other.inkFaint),
      accent: c(accent, other.accent),
      flame: c(flame, other.flame),
      arcane: c(arcane, other.arcane),
      gold: c(gold, other.gold),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      glow: c(glow, other.glow),
      glowSecondary: c(glowSecondary, other.glowSecondary),
      mote: c(mote, other.mote),
      strength: c(strength, other.strength),
      intelligence: c(intelligence, other.intelligence),
      discipline: c(discipline, other.discipline),
      creativity: c(creativity, other.creativity),
      vitality: c(vitality, other.vitality),
      social: c(social, other.social),
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

extension PaletteContext on BuildContext {
  /// Colours of the active theme.
  Palette get palette => Theme.of(this).extension<Palette>() ?? Palette.dark;
}

/// Gradients that look the same in both themes. Linear/radial only (cheap on
/// every renderer); no blurs.
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
