import 'package:flutter/material.dart';

/// Global color constants for the RISDi application.
/// All colors are centralized here for easy theming and consistency.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ======================== PRIMARY COLORS ========================
  static const Color primary = Color(0xFF1f6ed4);
  static const Color primaryDark = Color(0xFF1a5bb3);
  static const Color primaryLight = Color(0xFF5a92e8);

  // ======================== SECONDARY COLORS ========================
  static const Color secondary = Color(0xFF673AB7);
  static const Color secondaryDark = Color(0xFF5e35b1);
  static const Color secondaryLight = Color(0xFF9c27b0);

  // ======================== ACCENT COLORS ========================
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentDark = Color(0xFF0097A7);
  static const Color accentLight = Color(0xFF80DEEA);

  // ======================== STATUS COLORS ========================
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFB8C00);
  static const Color info = Color(0xFF1976D2);

  // ======================== NEUTRAL COLORS ========================
  static const Color dark = Color(0xFF212121);
  static const Color darkGrey = Color(0xFF424242);
  static const Color mediumGrey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFBDBDBD);
  static const Color ultraLightGrey = Color(0xFFEEEEEE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ======================== BACKGROUND COLORS ========================
  static const Color bgPrimary = Color(0xFFFAFAFA);
  static const Color bgSecondary = Color(0xFFF5F5F5);
  static const Color bgTertiary = Color(0xFFEBEBEB);

  // ======================== TEXT COLORS ========================
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ======================== BORDER COLORS ========================
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFD0D0D0);
  static const Color borderDark = Color(0xFFC0C0C0);

  // ======================== SPECIAL COLORS ========================
  static const Color transparent = Color(0x00000000);
  static const Color overlay = Color(0x66000000); // 40% opacity black

  // ======================== GRADIENT COLORS ========================
  static const List<Color> primaryGradient = [
    Color(0xFF1f6ed4),
    Color(0xFF1a5bb3),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF673AB7),
    Color(0xFF5e35b1),
  ];

  // ======================== COLOR UTILS ========================
  /// Get opacity variant of a color
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get shade variant (for Material colors)
  static Color getShade(Color baseColor, {int intensity = 100}) {
    final hslColor = HSLColor.fromColor(baseColor);
    return hslColor
        .withLightness((hslColor.lightness - intensity / 1000).clamp(0, 1))
        .toColor();
  }
}
