import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

/// Builds the Ashen Codex theme for [locale]. Dark-first by design.
ThemeData buildAppTheme(Locale locale) {
  final type = LocaleTypography.forLocale(locale);
  final text = type.textTheme();
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.crimson,
    onPrimary: AppColors.bone,
    primaryContainer: AppColors.wine,
    onPrimaryContainer: AppColors.bone,
    secondary: AppColors.ash,
    onSecondary: AppColors.void_,
    secondaryContainer: AppColors.slateHigh,
    onSecondaryContainer: AppColors.bone,
    tertiary: AppColors.ember,
    onTertiary: AppColors.void_,
    error: AppColors.ember,
    onError: AppColors.void_,
    surface: AppColors.slate,
    onSurface: AppColors.ash,
    onSurfaceVariant: AppColors.ashMuted,
    surfaceContainerLowest: AppColors.void_,
    surfaceContainerLow: AppColors.abyss,
    surfaceContainer: AppColors.slate,
    surfaceContainerHigh: AppColors.slateHigh,
    surfaceContainerHighest: AppColors.slateHigh,
    outline: AppColors.hairline,
    outlineVariant: AppColors.hairline,
    shadow: Color(0x00000000),
    scrim: Color(0x990B0B10),
    inverseSurface: AppColors.bone,
    onInverseSurface: AppColors.void_,
    inversePrimary: AppColors.ember,
  );

  const hairlineSide = BorderSide(color: AppColors.hairline);
  const softShape = RoundedRectangleBorder(borderRadius: AppRadius.softAll);
  final buttonText = text.labelLarge!;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.void_,
    canvasColor: AppColors.void_,
    textTheme: text,
    fontFamily: type.body,
    fontFamilyFallback: type.fallback,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 1, space: 1),
    iconTheme: const IconThemeData(color: AppColors.ash, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.void_,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      foregroundColor: AppColors.bone,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.slate,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.softAll, side: hairlineSide),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.crimson,
        foregroundColor: AppColors.bone,
        disabledBackgroundColor: AppColors.slateHigh,
        disabledForegroundColor: AppColors.ashFaint,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
        shape: softShape,
        textStyle: buttonText,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ash,
        side: hairlineSide,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
        shape: softShape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ember,
        minimumSize: const Size(48, 44),
        shape: softShape,
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.ash, minimumSize: const Size(44, 44)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.crimson,
      foregroundColor: AppColors.bone,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.softAll),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.abyss,
      labelStyle: text.bodyMedium!.copyWith(color: AppColors.ashMuted),
      floatingLabelStyle: text.bodySmall!.copyWith(color: AppColors.ember),
      hintStyle: text.bodyMedium!.copyWith(color: AppColors.ashFaint),
      helperStyle: text.bodySmall,
      helperMaxLines: 3,
      errorStyle: text.bodySmall!.copyWith(color: AppColors.ember),
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
      border: const OutlineInputBorder(borderRadius: AppRadius.softAll, borderSide: hairlineSide),
      enabledBorder: const OutlineInputBorder(borderRadius: AppRadius.softAll, borderSide: hairlineSide),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.softAll,
        borderSide: BorderSide(color: AppColors.ember),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.softAll,
        borderSide: BorderSide(color: AppColors.ember),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.abyss,
      selectedColor: AppColors.wine,
      disabledColor: AppColors.abyss,
      side: hairlineSide,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sharpAll),
      labelStyle: text.labelMedium!,
      secondaryLabelStyle: text.labelMedium!.copyWith(color: AppColors.bone),
      checkmarkColor: AppColors.bone,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(hairlineSide),
        shape: const WidgetStatePropertyAll(softShape),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.wine : AppColors.abyss,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.bone : AppColors.ash,
        ),
        textStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.abyss,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.wine,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) =>
            text.labelMedium!.copyWith(color: s.contains(WidgetState.selected) ? AppColors.bone : AppColors.ashMuted),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.bone : AppColors.ashMuted),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.abyss,
      indicatorColor: AppColors.wine,
      selectedIconTheme: const IconThemeData(color: AppColors.bone),
      unselectedIconTheme: const IconThemeData(color: AppColors.ashMuted),
      selectedLabelTextStyle: text.labelMedium!.copyWith(color: AppColors.bone),
      unselectedLabelTextStyle: text.labelMedium!.copyWith(color: AppColors.ashMuted),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.abyss,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.abyss,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: AppColors.hairline,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.soft),
        side: hairlineSide,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.abyss,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.softAll, side: hairlineSide),
      titleTextStyle: text.titleMedium,
      contentTextStyle: text.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.slateHigh,
      contentTextStyle: text.bodyMedium!.copyWith(color: AppColors.bone),
      actionTextColor: AppColors.ember,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.softAll, side: hairlineSide),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.bone : AppColors.ashMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.crimson : AppColors.abyss,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.hairline),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.crimson,
      inactiveTrackColor: AppColors.abyss,
      thumbColor: AppColors.bone,
      overlayColor: Color(0x33E0525C),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.crimson,
      linearTrackColor: AppColors.abyss,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.ashMuted,
      textColor: AppColors.ash,
      titleTextStyle: text.bodyLarge,
      subtitleTextStyle: text.bodySmall,
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
      minVerticalPadding: AppSpace.sm,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: const BoxDecoration(
        color: AppColors.slateHigh,
        borderRadius: AppRadius.sharpAll,
        border: Border.fromBorderSide(hairlineSide),
      ),
      textStyle: text.bodySmall!.copyWith(color: AppColors.bone),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.bone,
      unselectedLabelColor: AppColors.ashMuted,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.labelMedium,
      indicatorColor: AppColors.crimson,
      dividerColor: AppColors.hairline,
      indicatorSize: TabBarIndicatorSize.label,
      tabAlignment: TabAlignment.start,
    ),
    focusColor: const Color(0x3DE0525C),
    hoverColor: const Color(0x14ECE6DA),
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
