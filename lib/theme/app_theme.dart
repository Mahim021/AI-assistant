import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primaryBlue = Color(0xFF0053DE);
  static const primaryBlueDark = Color(0xFF3D7FFF);

  // Light mode
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF2F4F4);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE8EAED);
  static const lightText = Color(0xFF1A1A2E);
  static const lightSubtext = Color(0xFF6B7280);
  static const lightAssistantBubble = Color(0xFFEBEBEB);
  static const lightAssistantText = Color(0xFF1A1A2E);
  static const lightInputBg = Color(0xFFF2F4F4);

  // Dark mode
  static const darkBackground = Color(0xFF0F0F14);
  static const darkSurface = Color(0xFF1A1A24);
  static const darkCard = Color(0xFF1E1E2A);
  static const darkBorder = Color(0xFF2A2A3A);
  static const darkText = Color(0xFFE8E8F0);
  static const darkSubtext = Color(0xFF9090A8);
  static const darkAssistantBubble = Color(0xFF252535);
  static const darkAssistantText = Color(0xFFE8E8F0);
  static const darkInputBg = Color(0xFF1A1A24);

  // Shared
  static const userBubble = primaryBlue;
  static const userText = Colors.white;
  static const dangerRed = Color(0xFFD32F2F);
  static const successGreen = Color(0xFF4CAF50);
  static const warningOrange = Color(0xFFFF9800);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      surface: AppColors.lightBackground,
      surfaceContainerHighest: AppColors.lightSurface,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.lightText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryBlueDark,
      surface: AppColors.darkBackground,
      surfaceContainerHighest: AppColors.darkSurface,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.darkText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
  );
}
