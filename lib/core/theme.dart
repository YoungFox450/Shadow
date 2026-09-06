import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShadowColors {
  static const Color primaryGreen = Color(0xFF27E8A2); // Nouveau vert menthe
  static final Color statBoxBackground = Color.alphaBlend(
    Colors.white.withOpacity(0.22),
    primaryGreen,
  );
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color cardDark = Color(0xFF1C1C1E);
  static const Color textBlack = Color(0xFF000000);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
}

class ShadowTheme {
  static ThemeData get onboardingTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: ShadowColors.primaryGreen,
      useMaterial3: true,
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.spaceMono(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          color: ShadowColors.textBlack,
          height: 1.1,
          letterSpacing: -1,
        ),
        bodyLarge: GoogleFonts.spaceMono(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: ShadowColors.textBlack,
          height: 1.4,
        ),
      ),
    );
  }
}
