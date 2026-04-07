// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary     = Color(0xFFE31E24);
  static const Color primaryDark = Color(0xFFC01010);
  static const Color white       = Color(0xFFFFFFFF);
  static const Color background  = Color(0xFFF2F2F7);
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color textDark    = Color(0xFF1A1A2E);
  static const Color textGrey    = Color(0xFF8A8A8E);
  static const Color textLight   = Color(0xFFB0B0B8);
  static const Color borderColor = Color(0xFFE0E0E8);
  static const Color success     = Color(0xFF34C759);
  static const Color warning     = Color(0xFFFF9500);
  static const Color info        = Color(0xFF007AFF);

  // Job status colors
  static const Color statusPending    = Color(0xFFFF9500);
  static const Color statusAssigned   = Color(0xFF007AFF);
  static const Color statusInProgress = Color(0xFF5856D6);
  static const Color statusCompleted  = Color(0xFF34C759);
  static const Color statusCancelled  = Color(0xFF8A8A8E);
}

class AppTheme {
  static ThemeData get theme {
    final poppins = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3:            true,
      primaryColor:            AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily:              GoogleFonts.poppins().fontFamily,

      textTheme: poppins.copyWith(
        displayLarge:   poppins.displayLarge?.copyWith(color: AppColors.textDark,  fontWeight: FontWeight.w800),
        headlineLarge:  poppins.headlineLarge?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
        headlineMedium: poppins.headlineMedium?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w700),
        headlineSmall:  poppins.headlineSmall?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
        titleLarge:     poppins.titleLarge?.copyWith(color: AppColors.textDark,    fontWeight: FontWeight.w600),
        titleMedium:    poppins.titleMedium?.copyWith(color: AppColors.textDark,   fontWeight: FontWeight.w600),
        bodyLarge:      poppins.bodyLarge?.copyWith(color: AppColors.textDark),
        bodyMedium:     poppins.bodyMedium?.copyWith(color: AppColors.textGrey),
        bodySmall:      poppins.bodySmall?.copyWith(color: AppColors.textLight),
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor:   AppColors.primary,
        primary:     AppColors.primary,
        surface:     AppColors.white,
        surfaceTint: Colors.transparent,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation:       0,
        centerTitle:     true,
        titleTextStyle: GoogleFonts.poppins(
          color:      AppColors.white,
          fontSize:   18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.35),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textGrey,
          side: const BorderSide(color: AppColors.borderColor, width: 1.5),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        hintStyle:  GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: AppColors.textGrey,  fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        filled:         true,
        fillColor:      AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      cardTheme: CardThemeData(
        color:       AppColors.cardBg,
        elevation:   0,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color:     AppColors.borderColor,
        thickness: 1,
        space:     1,
      ),
    );
  }
}
