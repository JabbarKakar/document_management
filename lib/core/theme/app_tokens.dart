import 'package:flutter/material.dart';

/// Design tokens for the vault. Widgets read these instead of raw values.
abstract final class AppColors {
  static const backgroundDark = Color(0xFF090D16);
  static const backgroundLight = Color(0xFFF4F6FB);

  static const surfaceDark = Color(0xFF121A27);
  static const surfaceLight = Color(0xFFFFFFFF);

  static const surfaceRaisedDark = Color(0xFF1B2535);
  static const surfaceRaisedLight = Color(0xFFEDF1F8);

  static const borderDark = Color(0xFF2B3749);
  static const borderLight = Color(0xFFDCE3EF);

  static const primaryDark = Color(0xFF83F4D3);
  static const primaryLight = Color(0xFF086A58);
  static const violetDark = Color(0xFFBCADFF);
  static const violetLight = Color(0xFF6651B8);

  static const primaryMutedDark = Color(0xFF123F3A);
  static const primaryMutedLight = Color(0xFFD5F6F1);

  static const onPrimaryDark = Color(0xFF04221E);
  static const onPrimaryLight = Color(0xFFFFFFFF);

  static const onPrimaryMutedDark = Color(0xFFB6F6EA);
  static const onPrimaryMutedLight = Color(0xFF084F4A);

  static const textDark = Color(0xFFE8EEF4);
  static const textLight = Color(0xFF101418);

  static const textMutedDark = Color(0xFFA4B1C4);
  static const textMutedLight = Color(0xFF5C6B76);

  static const warningDark = Color(0xFFF5B942);
  static const warningLight = Color(0xFFB45309);

  static const errorDark = Color(0xFFF07178);
  static const errorLight = Color(0xFFC2414B);

  static const successDark = Color(0xFF3DDC97);
  static const successLight = Color(0xFF0F7A4A);

  static Color warning(Brightness brightness) =>
      brightness == Brightness.dark ? warningDark : warningLight;

  static Color success(Brightness brightness) =>
      brightness == Brightness.dark ? successDark : successLight;

  static Color glassFill(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.06)
      : surfaceLight.withValues(alpha: 0.72);

  static List<BoxShadow> cardShadow(Brightness brightness) => [
    BoxShadow(
      color: const Color(
        0xFF000000,
      ).withValues(alpha: brightness == Brightness.dark ? 0.08 : 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
}

abstract final class AppRadius {
  static const double chip = 12;
  static const double card = 22;
  static const double sheet = 30;
  static const double fab = 28;

  static const BorderRadius cardBorder = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius sheetBorder = BorderRadius.all(
    Radius.circular(sheet),
  );
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 240);
  static const Curve curve = Curves.easeOutCubic;
}

abstract final class AppBreakpoints {
  /// Phone stays a single canvas. At this width a side rail appears.
  static const double rail = 840;

  /// Grid uses three columns once the content column is at least this wide.
  static const double gridThree = 700;
}
