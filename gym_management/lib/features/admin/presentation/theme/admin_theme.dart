import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Black + Orange Admin Theme System
class AdminTheme {
  AdminTheme._();

  // ═══════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════

  // Backgrounds
  static const Color scaffold = Color(0xFF000000); // Pure Black
  static const Color card = Color(0xFF1C1C1C);
  static const Color surface = Color(0xFF252525);
  static const Color surfaceLight = Color(0xFF2E2E2E);

  // Accent
  static const Color orange = Color(0xFFFF6B00);
  static const Color orangeLight = Color(0xFFFF8C3A);
  static const Color orangeDark = Color(0xFFE05E00);

  // Status
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD740);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF448AFF);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF616161);

  // Borders
  static const Color border = Color(0xFF2E2E2E);
  static const Color borderLight = Color(0xFF383838);

  // ═══════════════════════════════════════════════
  // BORDER RADIUS
  // ═══════════════════════════════════════════════

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusRound = 100;

  // ═══════════════════════════════════════════════
  // ANIMATION DURATIONS
  // ═══════════════════════════════════════════════

  static const Duration microDuration = Duration(milliseconds: 150);
  static const Duration shortDuration = Duration(milliseconds: 250);
  static const Duration mediumDuration = Duration(milliseconds: 400);
  static const Duration longDuration = Duration(milliseconds: 600);
  static const Duration bgAnimDuration = Duration(seconds: 6);

  // ═══════════════════════════════════════════════
  // BOX SHADOWS
  // ═══════════════════════════════════════════════

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: orange.withValues(alpha: 0.25),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get liftShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ═══════════════════════════════════════════════
  // DECORATIONS
  // ═══════════════════════════════════════════════

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: border),
    boxShadow: cardShadow,
  );

  /// Use with ClipRRect + a separate accent Container on top.
  /// Non-uniform Border is incompatible with borderRadius in Flutter.
  static BoxDecoration glassDecorationWithAccent([Color? accentColor]) =>
      BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: border),
        boxShadow: cardShadow,
      );

  // ═══════════════════════════════════════════════
  // TEXT STYLES
  // ═══════════════════════════════════════════════

  static TextStyle get headingLarge => GoogleFonts.inter(
    color: textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get headingMedium => GoogleFonts.inter(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get headingSmall => GoogleFonts.inter(
    color: textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    color: textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get label => GoogleFonts.inter(
    color: textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static TextStyle get statValue => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static TextStyle get badgeText => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}
