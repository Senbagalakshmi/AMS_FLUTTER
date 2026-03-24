import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Base
  static const Color ink = Color(0xFF0B1628);
  static const Color ink2 = Color(0xFF475569);
  static const Color ink3 = Color(0xFF64748B);
  static const Color ink4 = Color(0xFF94A3B8);
  static const Color bg = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color border2 = Color(0xFFF1F5F9);
  static const Color cardHead = Color(0xFFFFFFFF);

  // Transaction — light blue
  static const Color tBlue = Color(0xFF2196F3);
  static const Color tBlueLt = Color(0xFFE3F2FD);
  static const Color tBlueMd = Color(0xFF90CAF9);
  static const Color tBlueDk = Color(0xFF1976D2);

  // Non-Transaction — deep ocean blue
  static const Color nTeal = Color(0xFF0277BD);
  static const Color nTealLt = Color(0xFFE1F5FE);
  static const Color nTealMd = Color(0xFF4FC3F7);
  static const Color nTealDk = Color(0xFF01579B);

  // Semantic
  static const Color green = Color(0xFF22C55E); // Real green
  static const Color greenLt = Color(0xFFDCFCE7);
  static const Color red = Color(0xFFC9253A);
  static const Color redLt = Color(0xFFFDE8EB);
  static const Color amber = Color(0xFFB85C00);
  static const Color amberLt = Color(0xFFFEF0DB);
  static const Color purple = Color(0xFF6B21C8);
  static const Color purpleLt = Color(0xFFEDE8FF);
  static const Color grayLt = Color(0xFFF1F5F9);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      fontFamily: GoogleFonts.roboto().fontFamily,
      scaffoldBackgroundColor: AppColors.bg,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.tBlue,
        secondary: AppColors.nTeal,
        surface: AppColors.surface,
      ),
    );
  }
}
