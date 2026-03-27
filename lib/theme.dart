import 'package:flutter/material.dart';

class AppTheme {
  // Brand Green Palette (Primary)
  static const Color brandGreen = Color(0xFF34C759);
  static const Color brandGreenStrong = Color(0xFF2DB87A); // Deeper teal for tappability
  static const Color brandGreenDeep = Color(0xFF248A3D);
  static const Color brandGreenLight = Color(0xFFD4F5E2);
  static const Color brandGreenGlow = Color(0x3034C759); // 18% opacity

  // Legacy aliases — kept for any remaining references
  static const Color primaryLight = brandGreen;
  static const Color primaryDark = brandGreen;

  // Semantic Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0A0A0F);

  static const Color successLight = Color(0xFF34C759);
  static const Color successDark = Color(0xFF30D158);

  static const Color warningLight = Color(0xFFFF9500);
  static const Color warningDark = Color(0xFFFF9F0A);

  static const Color destructiveLight = Color(0xFFFF3B30);
  static const Color destructiveDark = Color(0xFFFF453A);

  // Text colors for light mode
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textGreen = brandGreenDeep;

  // Glass specific colors
  static const Color glassTintLight = Color(0x8CFFFFFF); // 55% white
  static const Color glassTintDark = Color(0x11FFFFFF);

  static const Color separatorLight = Color(0x14000000); // black 8%
  static const Color separatorDark = Color(0x14FFFFFF);

  // Typography Constants — now using dark text opacities
  static const double textOpacityPrimary = 0.92;
  static const double textOpacitySecondary = 0.55;
  static const double textOpacityTertiary = 0.30;

  // Spring animation curves — UNCHANGED
  static const Curve appleEaseOut = Cubic(0.25, 0.46, 0.45, 0.94);
  static const Curve appleSpring = Cubic(0.34, 1.56, 0.64, 1);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 280);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: brandGreen,
      fontFamilyFallback: const ['Helvetica Neue', 'sans-serif'],
      colorScheme: const ColorScheme.light(
        primary: brandGreen,
        surface: backgroundLight,
        error: destructiveLight,
      ),
      textTheme: TextTheme(
        headlineLarge: const TextStyle(
          color: textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.03,
          height: 1.05,
        ),
        headlineMedium: const TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02,
          height: 1.1,
        ),
        bodyLarge: TextStyle(
          color: textPrimary.withOpacity(0.92),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: textPrimary.withOpacity(0.55),
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.6,
        ),
        labelSmall: TextStyle(
          color: textPrimary.withOpacity(0.45),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.24,
        ),
        labelLarge: TextStyle(
          color: textPrimary.withOpacity(0.85),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
