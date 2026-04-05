import 'package:flutter/material.dart';
import 'colors.dart';

/// Centralized text styles for the RISDi application.
/// Ensures consistent typography across all screens.
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  // ======================== HEADING STYLES ========================

  /// Extra large heading - 32px, bold
  static const TextStyle headingXxl = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Large heading - 28px, bold
  static const TextStyle headingXl = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
  );

  /// Large heading - 24px, bold
  static const TextStyle headingLg = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  /// Medium heading - 20px, bold
  static const TextStyle headingMd = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Small heading - 18px, bold
  static const TextStyle headingSm = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Extra small heading - 16px, bold
  static const TextStyle headingXs = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ======================== SUBHEADING STYLES ========================

  /// Large subheading - 18px, semi-bold
  static const TextStyle subheadingLg = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// Medium subheading - 16px, semi-bold
  static const TextStyle subheadingMd = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Small subheading - 14px, semi-bold
  static const TextStyle subheadingSm = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ======================== BODY STYLES ========================

  /// Large body text - 16px, regular
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  /// Medium body text - 14px, regular
  static const TextStyle bodyMd = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  /// Small body text - 12px, regular
  static const TextStyle bodySm = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.2,
  );

  // ======================== CAPTION STYLES ========================

  /// Large caption - 13px, medium
  static const TextStyle captionLg = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Medium caption - 12px, medium
  static const TextStyle captionMd = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Small caption - 11px, medium
  static const TextStyle captionSm = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ======================== LABEL STYLES ========================

  /// Large label - 14px, medium, uppercase
  static const TextStyle labelLg = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.5,
  );

  /// Medium label - 13px, medium
  static const TextStyle labelMd = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Small label - 12px, medium
  static const TextStyle labelSm = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ======================== BUTTON STYLES ========================

  /// Large button text - 16px, semi-bold
  static const TextStyle buttonLg = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.5,
    letterSpacing: 0.3,
  );

  /// Medium button text - 14px, semi-bold
  static const TextStyle buttonMd = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.5,
    letterSpacing: 0.2,
  );

  /// Small button text - 12px, semi-bold
  static const TextStyle buttonSm = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.5,
  );

  // ======================== INPUT STYLES ========================

  /// Input field text - 14px, regular
  static const TextStyle input = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Input hint text - 14px, regular, lighter color
  static const TextStyle inputHint = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
    height: 1.5,
  );

  /// Input label - 12px, medium
  static const TextStyle inputLabel = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ======================== ERROR/WARNING STYLES ========================

  /// Error text - 12px, medium, red
  static const TextStyle error = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
    height: 1.4,
  );

  /// Warning text - 12px, medium, warning color
  static const TextStyle warning = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
    height: 1.4,
  );

  /// Success text - 12px, medium, success color
  static const TextStyle success = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
    height: 1.4,
  );

  // ======================== APPBAR STYLES ========================

  /// AppBar title style - 20px, bold, white
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textOnPrimary,
    letterSpacing: -0.2,
  );

  /// AppBar subtitle style - 14px, regular, light
  static const TextStyle appBarSubtitle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textOnPrimary,
  );

  // ======================== SPECIAL STYLES ========================

  /// Link style - blue, underlined
  static const TextStyle link = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );

  /// Disabled text style
  static const TextStyle disabled = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
  );

  // ======================== TEXT STYLE UTILITIES ========================

  /// Create a custom text style based on existing one
  static TextStyle custom({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = AppColors.textPrimary,
    double height = 1.5,
    double letterSpacing = 0.0,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  /// Copy text style with modified properties
  static TextStyle copyWith(
    TextStyle baseStyle, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return baseStyle.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
