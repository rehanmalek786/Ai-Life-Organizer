import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for AI Life Organizer.
///
/// Palette is a calm slate-blue paired with a warm coral accent -
/// deliberately not the generic "purple Material default" or the
/// cream+terracotta look that AI-generated apps tend to default to.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3D5A80);
  static const Color primaryLight = Color(0xFF6E88A8);
  static const Color primaryDark = Color(0xFF27374F);

  static const Color accent = Color(0xFFEE6C4D);
  static const Color accentLight = Color(0xFFF4977E);

  static const Color success = Color(0xFF52B788);
  static const Color priorityHigh = Color(0xFFEE6C4D);
  static const Color priorityMedium = Color(0xFFF4A259);
  static const Color priorityLow = Color(0xFF61A5C2);

  static const Color bgLight = Color(0xFFF7F8FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF1C2430);
  static const Color subtleLight = Color(0xFF6B7686);

  static const Color bgDark = Color(0xFF10131A);
  static const Color surfaceDark = Color(0xFF1B1F2A);
  static const Color textDark = Color(0xFFE8EAF0);
  static const Color subtleDark = Color(0xFF9AA3B2);
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color base, Color subtle) {
    final display = GoogleFonts.soraTextTheme();
    final body = GoogleFonts.interTextTheme();
    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(color: base, fontWeight: FontWeight.w700),
      headlineMedium: display.headlineMedium?.copyWith(color: base, fontWeight: FontWeight.w700),
      titleLarge: display.titleLarge?.copyWith(color: base, fontWeight: FontWeight.w600),
      titleMedium: display.titleMedium?.copyWith(color: base, fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(color: base),
      bodyMedium: body.bodyMedium?.copyWith(color: base),
      bodySmall: body.bodySmall?.copyWith(color: subtle),
      labelLarge: body.labelLarge?.copyWith(color: base, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surfaceLight,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgLight,
      textTheme: _textTheme(AppColors.textLight, AppColors.subtleLight),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgLight,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE4E7EC), thickness: 1),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      secondary: AppColors.accent,
      surface: AppColors.surfaceDark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: _textTheme(AppColors.textDark, AppColors.subtleDark),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A2F3B), thickness: 1),
    );
  }

  static Color priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.priorityHigh;
      case 'medium':
        return AppColors.priorityMedium;
      default:
        return AppColors.priorityLow;
    }
  }
}
