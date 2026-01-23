import 'package:flutter/material.dart';

class AppColors {
  // Primary - Deep Indigo/Purple (Knowledge/Premium)
  static const Color primary = Color(0xFF4A148C); // Purple 900
  static const Color primaryLight = Color(0xFF7C43BD); // Purple 400
  static const Color primaryDark = Color(0xFF12005E);

  // Accent - Teal/Mint (Growth/Success)
  static const Color accent = Color(0xFF00BFA5); // Teal A700
  static const Color accentLight = Color(0xFF5DF2D6);

  // Backgrounds
  static const Color background = Color(0xFFF5F5F7); // Light Gray/Off-white
  static const Color surface = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF1D1B20);
  static const Color textSecondary = Color(0xFF49454F);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        // background: AppColors.background, // Deprecated
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',

      // Card Theme
      /* 
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        color: AppColors.surface,
      ), 
      */

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
