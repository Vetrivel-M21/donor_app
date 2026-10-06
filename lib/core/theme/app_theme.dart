import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFFD97706); // Warm Amber / Saffron
  static const Color primaryDark = Color(0xFFB45309);
  static const Color primaryLight = Color(0xFFFEF3C7);
  static const Color secondary = Color(0xFF1E1B4B); // Deep Royal Indigo
  static const Color accentBlue = Color(0xFF2563EB); // Highlight Blue
  static const Color surfaceBg = Color(0xFFF9FAFB);
  static const Color cardBg = Colors.white;

  // Dark theme surfaces
  static const Color darkSurface = Color(0xFF0F0E1A);
  static const Color darkCard = Color(0xFF1A1830);
  static const Color darkBorder = Color(0xFF2D2B45);

  static TextTheme _buildTextTheme(Color bodyColor, Color headingColor) {
    return TextTheme(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: headingColor),
      displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: headingColor),
      displaySmall: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: headingColor),
      headlineLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: headingColor),
      headlineMedium: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: headingColor),
      headlineSmall: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: headingColor),
      titleLarge: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: headingColor),
      titleMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: headingColor),
      titleSmall: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: headingColor),
      bodyLarge: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w500, color: bodyColor),
      bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: bodyColor),
      bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: bodyColor),
      labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: bodyColor),
      labelMedium: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: bodyColor),
      labelSmall: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500, color: bodyColor),
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surfaceBg,
      brightness: Brightness.light,
    );

    final textTheme = _buildTextTheme(const Color(0xFF374151), const Color(0xFF111827));

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceBg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: const Color(0xFF111827),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        labelStyle: GoogleFonts.nunito(color: const Color(0xFF4B5563), fontSize: 14),
        hintStyle: GoogleFonts.nunito(color: const Color(0xFF9CA3AF), fontSize: 14),
        errorStyle: GoogleFonts.nunito(color: const Color(0xFFDC2626), fontSize: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 1,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: const Color(0xFF818CF8),
      surface: darkSurface,
      brightness: Brightness.dark,
    );

    final textTheme = _buildTextTheme(const Color(0xFFD1D5DB), const Color(0xFFF9FAFB));

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkSurface,
      cardColor: darkCard,
      dividerColor: darkBorder,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: const Color(0xFFF9FAFB),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        labelStyle: GoogleFonts.nunito(color: const Color(0xFF9CA3AF), fontSize: 14),
        hintStyle: GoogleFonts.nunito(color: const Color(0xFF6B7280), fontSize: 14),
        errorStyle: GoogleFonts.nunito(color: const Color(0xFFF87171), fontSize: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 1,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
