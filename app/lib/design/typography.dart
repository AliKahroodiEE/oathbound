import 'package:flutter/material.dart';

import 'tokens.dart';

/// Script-aware type scale (design-system §3). Arabic-script locales get
/// Vazirmatn everywhere, taller line heights and no letter-spacing;
/// Latin locales use Cinzel for short display text and Inter for reading.
class LocaleTypography {
  const LocaleTypography._({
    required this.body,
    required this.display,
    required this.fallback,
    required this.arabicScript,
  });

  factory LocaleTypography.forLocale(Locale locale) {
    const arabicScriptLanguages = {'fa', 'ar', 'ur', 'ps', 'ku'};
    final arabic = arabicScriptLanguages.contains(locale.languageCode);
    return arabic
        ? const LocaleTypography._(body: 'Vazirmatn', display: 'Vazirmatn', fallback: ['Inter'], arabicScript: true)
        : const LocaleTypography._(body: 'Inter', display: 'Cinzel', fallback: ['Vazirmatn'], arabicScript: false);
  }

  final String body;
  final String display;
  final List<String> fallback;
  final bool arabicScript;

  TextStyle _style(
    String family,
    double size,
    double height,
    FontWeight weight, {
    double tracking = 0,
    required Color color,
    List<FontFeature> features = const [],
  }) => TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    letterSpacing: arabicScript ? 0 : tracking,
    color: color,
    fontFeatures: features,
  );

  TextTheme textTheme(Palette p) {
    final a = arabicScript;
    return TextTheme(
      displayLarge: _style(display, 32, 40, a ? FontWeight.w800 : FontWeight.w600, color: p.ink),
      displayMedium: _style(display, 28, 36, a ? FontWeight.w800 : FontWeight.w600, color: p.ink),
      headlineSmall: _style(display, 22, 30, a ? FontWeight.w700 : FontWeight.w600, color: p.ink),
      titleLarge: _style(display, 22, 30, a ? FontWeight.w700 : FontWeight.w600, color: p.ink),
      titleMedium: _style(body, 17, 24, FontWeight.w600, color: p.ink),
      titleSmall: _style(body, 15, 22, FontWeight.w600, color: p.ink),
      bodyLarge: _style(body, 15, a ? 26 : 22, FontWeight.w400, color: p.inkSoft),
      bodyMedium: _style(body, 14, a ? 24 : 20, FontWeight.w400, color: p.inkSoft),
      bodySmall: _style(body, 12, a ? 20 : 16, FontWeight.w400, color: p.inkMuted),
      labelLarge: _style(body, 14, 20, FontWeight.w600, color: p.ink),
      labelMedium: _style(body, 13, 18, FontWeight.w500, color: p.inkSoft),
      labelSmall: _style(display, 11, 16, FontWeight.w600, tracking: 1.2, color: p.inkMuted),
    );
  }
}
