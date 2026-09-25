import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Dark-first electric teal theme, with a light counterpart from the same tokens.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfaceRaised = isDark
        ? AppColors.surfaceRaisedDark
        : AppColors.surfaceRaisedLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final primaryMuted = isDark
        ? AppColors.primaryMutedDark
        : AppColors.primaryMutedLight;
    final onPrimary = isDark
        ? AppColors.onPrimaryDark
        : AppColors.onPrimaryLight;
    final onPrimaryMuted = isDark
        ? AppColors.onPrimaryMutedDark
        : AppColors.onPrimaryMutedLight;
    final text = isDark ? AppColors.textDark : AppColors.textLight;
    final textMuted = isDark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryMuted,
      onPrimaryContainer: onPrimaryMuted,
      secondary: textMuted,
      onSecondary: isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
      secondaryContainer: surfaceRaised,
      onSecondaryContainer: text,
      tertiary: primary,
      onTertiary: onPrimary,
      tertiaryContainer: primaryMuted,
      onTertiaryContainer: onPrimaryMuted,
      error: isDark ? AppColors.errorDark : AppColors.errorLight,
      onError: isDark ? const Color(0xFF2A0B0E) : AppColors.onPrimaryLight,
      errorContainer: isDark
          ? const Color(0xFF3A1C20)
          : const Color(0xFFFDE8EA),
      onErrorContainer: isDark ? AppColors.errorDark : const Color(0xFF8E1D2A),
      surface: surface,
      onSurface: text,
      onSurfaceVariant: textMuted,
      surfaceContainerLowest: background,
      surfaceContainerLow: isDark
          ? const Color(0xFF0C1118)
          : const Color(0xFFEEF2F4),
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceRaised,
      surfaceContainerHighest: surfaceRaised,
      outline: border,
      outlineVariant: border.withValues(alpha: isDark ? 0.72 : 1),
      inverseSurface: isDark ? AppColors.textDark : const Color(0xFF17202B),
      onInverseSurface: isDark ? AppColors.textLight : AppColors.textDark,
      surfaceTint: Colors.transparent,
      shadow: const Color(0xFF000000),
    );

    final baseText = (isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme).apply(fontFamily: 'Inter');

    TextStyle inter({
      required double size,
      required FontWeight weight,
      double letterSpacing = 0,
      double height = 1.35,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: 'Inter',
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
        color: color ?? text,
      );
    }

    final textTheme = baseText.copyWith(
      displaySmall: inter(
        size: 32,
        weight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.15,
      ),
      headlineMedium: inter(
        size: 24,
        weight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      headlineSmall: inter(
        size: 22,
        weight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.2,
      ),
      titleLarge: inter(size: 18, weight: FontWeight.w600, height: 1.25),
      titleMedium: inter(size: 16, weight: FontWeight.w600, height: 1.3),
      titleSmall: inter(size: 14, weight: FontWeight.w600, height: 1.3),
      bodyLarge: inter(size: 16, weight: FontWeight.w400, height: 1.45),
      bodyMedium: inter(size: 15, weight: FontWeight.w400, height: 1.45),
      bodySmall: inter(
        size: 13,
        weight: FontWeight.w400,
        height: 1.4,
        color: textMuted,
      ),
      labelLarge: inter(size: 13, weight: FontWeight.w600, height: 1.2),
      labelMedium: inter(
        size: 12,
        weight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.3,
        color: textMuted,
      ),
      labelSmall: inter(
        size: 11,
        weight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.3,
        color: textMuted,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
    );
    final buttonText = textTheme.labelLarge;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkRipple.splashFactory,
      iconTheme: IconThemeData(color: text, size: 22),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: text, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
        border: OutlineInputBorder(borderRadius: AppRadius.cardBorder),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceRaised,
        selectedColor: primaryMuted,
        labelStyle: textTheme.labelMedium!.copyWith(color: text),
        secondaryLabelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        backgroundColor: primary,
        foregroundColor: onPrimary,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        extendedTextStyle: buttonText?.copyWith(color: onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.fab),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetBorder,
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textMuted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        dragHandleColor: border,
        dragHandleSize: const Size(36, 4),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textMuted,
        textColor: text,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        minVerticalPadding: AppSpacing.sm,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceRaised,
        circularTrackColor: surfaceRaised,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onPrimary),
        side: BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: primaryMuted,
        useIndicator: true,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        selectedIconTheme: IconThemeData(color: primary, size: 22),
        unselectedIconTheme: IconThemeData(color: textMuted, size: 22),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: primary),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: textMuted,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: buttonText,
          backgroundColor: primary,
          foregroundColor: onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: buttonText,
          foregroundColor: text,
          side: BorderSide(color: border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: buttonText,
          foregroundColor: primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: text,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: primary,
        textColor: onPrimary,
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
    );
  }
}
