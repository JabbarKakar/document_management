import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Refined vault aesthetic: teal–sage palette, Fraunces + Outfit typography.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
      onPrimary: isDark ? const Color(0xFF041F1C) : Colors.white,
      primaryContainer:
          isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
      onPrimaryContainer:
          isDark ? const Color(0xFF99F6E4) : const Color(0xFF042F2E),
      secondary: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      onSecondary: isDark ? const Color(0xFF1C1917) : Colors.white,
      secondaryContainer:
          isDark ? const Color(0xFF713F12) : const Color(0xFFFFEDD5),
      onSecondaryContainer:
          isDark ? const Color(0xFFFEF3C7) : const Color(0xFF7C2D12),
      tertiary: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9),
      onTertiary: Colors.white,
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      surface: isDark ? const Color(0xFF0C0F14) : const Color(0xFFFDFBF7),
      onSurface: isDark ? const Color(0xFFE8EAED) : const Color(0xFF1C1917),
      onSurfaceVariant:
          isDark ? const Color(0xFF9CA3AF) : const Color(0xFF57534E),
      surfaceContainerHighest:
          isDark ? const Color(0xFF1A222D) : const Color(0xFFECE8E2),
      outline: isDark ? const Color(0xFF3F4A5C) : const Color(0xFFD6D3CD),
      outlineVariant: isDark ? const Color(0xFF2A3444) : const Color(0xFFE7E2DA),
    );

    final displayStyle = GoogleFonts.fraunces(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.02,
    );

    final baseText = GoogleFonts.outfitTextTheme(
      brightness == Brightness.light
          ? ThemeData.light().textTheme
          : ThemeData.dark().textTheme,
    );

    final textTheme = baseText.copyWith(
      displaySmall: displayStyle.copyWith(
        fontSize: 32,
        color: colorScheme.onSurface,
      ),
      headlineMedium: displayStyle.copyWith(
        fontSize: 26,
        color: colorScheme.onSurface,
      ),
      headlineSmall: displayStyle.copyWith(
        fontSize: 22,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        height: 1.45,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        height: 1.45,
        color: colorScheme.onSurface,
      ),
      labelLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.02,
        color: colorScheme.primary,
      ),
    );

    final radius = BorderRadius.circular(16);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.65)),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.bodyMedium!,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.outlineVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
