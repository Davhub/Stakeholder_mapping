import 'package:flutter/material.dart';

/// Standardized spacing values for consistent layouts across the app.
/// Uses a base unit of 4 (Material Design guideline).
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // ======================== BASE SPACING UNITS ========================
  static const double xs = 4.0;    // Extra small
  static const double sm = 8.0;    // Small
  static const double md = 12.0;   // Medium
  static const double lg = 16.0;   // Large
  static const double xl = 20.0;   // Extra large
  static const double xxl = 24.0;  // Extra extra large
  static const double xxxl = 32.0; // Extra extra extra large

  // ======================== PADDING CONSTANTS ========================
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  // ======================== HORIZONTAL PADDING ========================
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // ======================== VERTICAL PADDING ========================
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);

  // ======================== SCREEN PADDING ========================
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets screenPaddingLarge = EdgeInsets.all(xl);

  // ======================== COMMON GAPS (SizedBox heights/widths) ========================
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl, width: xxl);

  // ======================== VERTICAL GAPS ========================
  static const SizedBox verticalGapXs = SizedBox(height: xs);
  static const SizedBox verticalGapSm = SizedBox(height: sm);
  static const SizedBox verticalGapMd = SizedBox(height: md);
  static const SizedBox verticalGapLg = SizedBox(height: lg);
  static const SizedBox verticalGapXl = SizedBox(height: xl);
  static const SizedBox verticalGapXxl = SizedBox(height: xxl);
  static const SizedBox verticalGapLarge = SizedBox(height: xxxl);

  // ======================== HORIZONTAL GAPS ========================
  static const SizedBox horizontalGapXs = SizedBox(width: xs);
  static const SizedBox horizontalGapSm = SizedBox(width: sm);
  static const SizedBox horizontalGapMd = SizedBox(width: md);
  static const SizedBox horizontalGapLg = SizedBox(width: lg);
  static const SizedBox horizontalGapXl = SizedBox(width: xl);
  static const SizedBox horizontalGapXxl = SizedBox(width: xxl);

  // ======================== CARD SPACING ========================
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xl);
  static const double cardMarginVertical = lg;
  static const double cardMarginHorizontal = sm;

  // ======================== DIALOG SPACING ========================
  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);
  static const double dialogMargin = xl;
}
