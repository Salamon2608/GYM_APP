import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrainerTheme {
  // === Brand Colors ===
  static const Color orange = Color(0xFFFF8A00);
  static const Color orangeDark = Color(0xFFE55A2B); // or D97200
  static const Color scaffold = Color(0xFF1E1814); // Dark brownish background
  static const Color card = Color(0xFF2A231F); // Slightly lighter for cards
  static const Color border = Color(0xFF3E3631); // For card borders/dividers

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E958F);

  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);

  // === Text Styles ===
  static final TextStyle headingLarge = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static final TextStyle headingMedium = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static final TextStyle headingSmall = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  // === UI Constants ===
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
}
