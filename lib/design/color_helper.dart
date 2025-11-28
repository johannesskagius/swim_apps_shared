import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
///  SWIMSUITE DESIGN SYSTEM
/// ---------------------------------------------------------------------------

class SwimSuiteColors {
  // YOUR BRAND COLORS
  static const Color main = Color(0xFF03254C); // Main color
  static const Color accent = Color(0xFF3A86FF); // Accent blue
  static const Color success = Color(0xFFFFC300); // Gold / Framgång
  static const Color background = Color(0xFFF7F7FF); // Light grey

  // Neutral palette
  static const Color black = Color(0xFF0A0A0F);
  static const Color grey900 = Color(0xFF1C1C25);
  static const Color grey700 = Color(0xFF3B3B45);
  static const Color grey500 = Color(0xFF7C7C87);
  static const Color grey300 = Color(0xFFD5D5DB);
  static const Color grey100 = Color(0xFFF0F0F7);
  static const Color white = Color(0xFFFFFFFF);

  static const LinearGradient mainGradient = LinearGradient(
    colors: [main, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// ---------------------------------------------------------------------------
/// TYPOGRAPHY
/// Montserrat = headlines
/// Arial = body
/// ---------------------------------------------------------------------------
class SwimSuiteText {
  static const String headlineFont = 'Montserrat';
  static const String bodyFont = 'Arial';

  // HEADLINES
  static const TextStyle h1 = TextStyle(
    fontFamily: headlineFont,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: SwimSuiteColors.main,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: headlineFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: SwimSuiteColors.main,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: headlineFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: SwimSuiteColors.main,
  );

  // BODY
  static const TextStyle body = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    height: 1.45,
    color: SwimSuiteColors.grey900,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    height: 1.45,
    color: SwimSuiteColors.grey900,
  );

  static const TextStyle small = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    height: 1.4,
    color: SwimSuiteColors.grey700,
  );

  static const TextStyle tiny = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    height: 1.3,
    color: SwimSuiteColors.grey500,
  );
}

/// ---------------------------------------------------------------------------
/// SPACING
/// ---------------------------------------------------------------------------
class SwimSuiteSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// ---------------------------------------------------------------------------
/// THEME DATA
/// Ensures Material widgets automatically use Montserrat/Arial
/// ---------------------------------------------------------------------------
class SwimSuiteTheme {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: SwimSuiteColors.background,
    primaryColor: SwimSuiteColors.main,
    fontFamily: SwimSuiteText.bodyFont,
    // BODY DEFAULT
    textTheme: const TextTheme(
      headlineMedium: SwimSuiteText.h1,
      headlineSmall: SwimSuiteText.h2,
      titleLarge: SwimSuiteText.h3,
      bodyLarge: SwimSuiteText.body,
      bodyMedium: SwimSuiteText.small,
      bodySmall: SwimSuiteText.tiny,
    ),
    colorScheme: const ColorScheme.light(
      primary: SwimSuiteColors.main,
      secondary: SwimSuiteColors.accent,
      background: SwimSuiteColors.background,
      tertiary: SwimSuiteColors.success,
      error: Colors.red,
    ),
  );
}
