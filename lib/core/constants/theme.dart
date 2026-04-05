import 'package:flutter/material.dart';
import 'colors.dart';
import 'sizes.dart';

/// Centralized ThemeData configuration for the RISDi application.
/// Provides both light and dark theme variants with Material Design 3.
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ======================== LIGHT THEME ========================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      
      // ======================== COLOR SCHEME ========================
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        secondaryContainer: AppColors.secondaryLight,
        onSecondaryContainer: AppColors.secondary,
        tertiary: AppColors.accent,
        onTertiary: AppColors.textOnPrimary,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.error.withValues(alpha: 0.1),
        onErrorContainer: AppColors.error,
        outline: AppColors.borderLight,
        outlineVariant: AppColors.borderMedium,
        surface: AppColors.white,
        onSurface: AppColors.textPrimary,
        surfaceContainer: AppColors.bgSecondary,
        onSurfaceVariant: AppColors.textSecondary,
      ),

      // ======================== APPBAR THEME ========================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: AppSizes.elevationMd,
        centerTitle: false,
        iconTheme: const IconThemeData(
          color: AppColors.textOnPrimary,
          size: AppSizes.iconMd,
        ),
      ),

      // ======================== BUTTON THEMES ========================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          elevation: AppSizes.elevationSm,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      ),

      // ======================== INPUT DECORATION THEME ========================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
      ),

      // ======================== CARD THEME ========================
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: AppSizes.elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),

      // ======================== DIALOG THEME ========================
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: AppSizes.elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
      ),

      // ======================== SNACKBAR THEME ========================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        elevation: AppSizes.elevationMd,
      ),

      // ======================== CHIP THEME ========================
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgSecondary,
        disabledColor: AppColors.ultraLightGrey,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),

      // ======================== ICON THEME ========================
      iconTheme: const IconThemeData(
        color: AppColors.primary,
        size: AppSizes.iconMd,
      ),

      // ======================== DIVIDER THEME ========================
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: AppSizes.dividerThin,
        space: 16.0,
      ),

      // ======================== PROGRESS INDICATOR THEME ========================
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.bgSecondary,
      ),
    );
  }

  // ======================== DARK THEME ========================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.dark,
      
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.dark,
        primaryContainer: AppColors.primary,
        onPrimaryContainer: AppColors.textOnPrimary,
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.dark,
        secondaryContainer: AppColors.secondary,
        onSecondaryContainer: AppColors.textOnPrimary,
        tertiary: AppColors.accentLight,
        onTertiary: AppColors.dark,
        error: AppColors.error,
        onError: AppColors.dark,
        errorContainer: AppColors.error.withValues(alpha: 0.2),
        onErrorContainer: AppColors.error,
        outline: AppColors.borderDark,
        outlineVariant: AppColors.borderMedium,
        surface: AppColors.darkGrey,
        onSurface: AppColors.white,
        surfaceContainer: AppColors.dark,
        onSurfaceVariant: AppColors.lightGrey,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkGrey,
        foregroundColor: AppColors.textOnPrimary,
        elevation: AppSizes.elevationMd,
        centerTitle: false,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.dark,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          elevation: AppSizes.elevationSm,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.darkGrey,
        elevation: AppSizes.elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.dark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2.0),
        ),
      ),
    );
  }
}
