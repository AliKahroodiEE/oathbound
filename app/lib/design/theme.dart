import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';
import 'typography.dart';

/// Builds the theme for [locale] from a [Palette] (dark "Ashen Codex" or
/// light "Vellum"). Component shapes are shared; only colours differ.
ThemeData buildAppTheme(Locale locale, Palette p) {
  final type = LocaleTypography.forLocale(locale);
  final text = type.textTheme(p);
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: AppColors.crimson,
    onPrimary: AppColors.onAccent,
    primaryContainer: p.accentContainer,
    onPrimaryContainer: p.ink,
    secondary: p.inkSoft,
    onSecondary: p.canvas,
    secondaryContainer: p.surfaceHigh,
    onSecondaryContainer: p.ink,
    tertiary: p.accent,
    onTertiary: p.canvas,
    error: p.accent,
    onError: AppColors.onAccent,
    surface: p.surface,
    onSurface: p.inkSoft,
    onSurfaceVariant: p.inkMuted,
    surfaceContainerLowest: p.canvas,
    surfaceContainerLow: p.sunken,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surfaceHigh,
    surfaceContainerHighest: p.surfaceHigh,
    outline: p.hairline,
    outlineVariant: p.hairline,
    shadow: const Color(0x00000000),
    scrim: p.isDark ? const Color(0x990B0B10) : const Color(0x661F1A23),
    inverseSurface: p.ink,
    onInverseSurface: p.canvas,
    inversePrimary: p.accent,
  );

  final hairlineSide = BorderSide(color: p.hairline);
  const softShape = RoundedRectangleBorder(borderRadius: AppRadius.softAll);
  const pillShape = StadiumBorder();
  final buttonText = text.labelLarge!;
  final overlay = p.isDark
      ? const SystemUiOverlayStyle(
          statusBarColor: Color(0x00000000),
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0x00000000),
          systemNavigationBarIconBrightness: Brightness.light,
        )
      : const SystemUiOverlayStyle(
          statusBarColor: Color(0x00000000),
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0x00000000),
          systemNavigationBarIconBrightness: Brightness.dark,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    extensions: [p],
    scaffoldBackgroundColor: p.canvas,
    canvasColor: p.canvas,
    textTheme: text,
    fontFamily: type.body,
    fontFamilyFallback: type.fallback,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: p.inkSoft, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      foregroundColor: p.ink,
      systemOverlayStyle: overlay,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll, side: hairlineSide),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.crimson,
        foregroundColor: AppColors.onAccent,
        disabledBackgroundColor: p.surfaceHigh,
        disabledForegroundColor: p.inkFaint,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
        shape: pillShape,
        textStyle: buttonText,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.inkSoft,
        side: hairlineSide,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
        shape: pillShape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        minimumSize: const Size(48, 44),
        shape: softShape,
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: p.inkSoft, minimumSize: const Size(44, 44)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.crimson,
      foregroundColor: AppColors.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.softAll),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.sunken,
      labelStyle: text.bodyMedium!.copyWith(color: p.inkMuted),
      floatingLabelStyle: text.bodySmall!.copyWith(color: p.accent),
      hintStyle: text.bodyMedium!.copyWith(color: p.inkFaint),
      helperStyle: text.bodySmall,
      helperMaxLines: 3,
      errorStyle: text.bodySmall!.copyWith(color: p.accent),
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
      border: OutlineInputBorder(borderRadius: AppRadius.softAll, borderSide: hairlineSide),
      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.softAll, borderSide: hairlineSide),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.softAll,
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.softAll,
        borderSide: BorderSide(color: p.accent),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.sunken,
      selectedColor: p.selection,
      disabledColor: p.sunken,
      side: hairlineSide,
      shape: StadiumBorder(side: hairlineSide),
      labelStyle: text.labelMedium!,
      secondaryLabelStyle: text.labelMedium!.copyWith(color: p.ink),
      checkmarkColor: p.ink,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(hairlineSide),
        shape: const WidgetStatePropertyAll(softShape),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.selection : p.sunken,
        ),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.ink : p.inkSoft),
        iconColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : p.inkMuted),
        textStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.selection,
      indicatorShape: const StadiumBorder(),
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelMedium!.copyWith(
          color: s.contains(WidgetState.selected) ? p.ink : p.inkMuted,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.accent : p.inkMuted),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.sunken.withValues(alpha: p.isDark ? 0.85 : 0.6),
      indicatorColor: p.selection,
      indicatorShape: const StadiumBorder(),
      selectedIconTheme: IconThemeData(color: p.accent),
      unselectedIconTheme: IconThemeData(color: p.inkMuted),
      selectedLabelTextStyle: text.labelMedium!.copyWith(color: p.ink, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: text.labelMedium!.copyWith(color: p.inkMuted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: p.surface,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: p.hairline,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: AppRadius.card),
        side: hairlineSide,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll, side: hairlineSide),
      titleTextStyle: text.titleMedium,
      contentTextStyle: text.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.isDark ? p.surfaceHigh : p.ink,
      contentTextStyle: text.bodyMedium!.copyWith(color: p.isDark ? p.ink : p.canvas),
      actionTextColor: p.isDark ? p.accent : AppColors.ember,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.softAll, side: p.isDark ? hairlineSide : BorderSide.none),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.onAccent : p.inkMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.crimson : p.sunken,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.crimson : p.hairline,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.crimson,
      inactiveTrackColor: p.surfaceHigh,
      thumbColor: p.isDark ? p.ink : AppColors.crimson,
      overlayColor: AppColors.ember.withValues(alpha: 0.2),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.crimson, linearTrackColor: p.surfaceHigh),
    listTileTheme: ListTileThemeData(
      iconColor: p.inkMuted,
      textColor: p.inkSoft,
      titleTextStyle: text.bodyLarge,
      subtitleTextStyle: text.bodySmall,
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
      minVerticalPadding: AppSpace.sm,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: p.isDark ? p.surfaceHigh : p.ink,
        borderRadius: AppRadius.sharpAll,
        border: p.isDark ? Border.fromBorderSide(hairlineSide) : null,
      ),
      textStyle: text.bodySmall!.copyWith(color: p.isDark ? p.ink : p.canvas),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: p.ink,
      unselectedLabelColor: p.inkMuted,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.labelMedium,
      indicator: BoxDecoration(color: p.selection, borderRadius: AppRadius.pillAll),
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      labelPadding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
      splashBorderRadius: AppRadius.pillAll,
      tabAlignment: TabAlignment.start,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: AppColors.ember.withValues(alpha: 0.28),
      selectionHandleColor: p.accent,
    ),
    focusColor: AppColors.ember.withValues(alpha: 0.24),
    hoverColor: p.ink.withValues(alpha: 0.06),
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
