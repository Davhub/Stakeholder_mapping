/// Global size constants for the RISDi application.
/// Includes dimensions for common UI elements.
class AppSizes {
  // Private constructor to prevent instantiation
  AppSizes._();

  // ======================== ICON SIZES ========================
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  static const double iconXxl = 48.0;
  static const double iconLarge = 64.0;

  // ======================== BORDER RADIUS ========================
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusCircle = 50.0; // For circular shapes

  // ======================== ELEVATION/SHADOW ========================
  static const double elevationNone = 0.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 12.0;

  // ======================== BUTTON SIZES ========================
  static const double buttonHeightXs = 32.0;
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightXl = 56.0;

  static const double buttonWidthMin = 80.0;
  static const double buttonWidthNormal = 120.0;
  static const double buttonWidthLarge = 200.0;

  // ======================== INPUT FIELD SIZES ========================
  static const double inputHeight = 48.0;
  static const double inputHeightSmall = 40.0;
  static const double inputHeightLarge = 56.0;

  static const double inputBorderWidth = 1.0;
  static const double inputBorderWidthFocused = 2.0;

  // ======================== APPBAR SIZES ========================
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 64.0;

  // ======================== AVATAR SIZES ========================
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 48.0;
  static const double avatarXl = 64.0;
  static const double avatarXxl = 80.0;

  // ======================== CARD SIZES ========================
  static const double cardMinHeight = 100.0;
  static const double cardMaxHeight = 300.0;

  // ======================== MODAL SIZES ========================
  static const double modalMaxWidth = 400.0;
  static const double bottomSheetMaxHeight = 600.0;

  // ======================== DIVIDER THICKNESS ========================
  static const double dividerThinnest = 0.5;
  static const double dividerThin = 1.0;
  static const double dividerMd = 1.5;
  static const double dividerThick = 2.0;

  // ======================== DIALOG SIZES ========================
  static const double dialogMaxWidth = 400.0;
  static const double dialogMinWidth = 280.0;

  // ======================== SCREEN BREAKPOINTS ========================
  static const double screenSmall = 360.0;   // Small phones
  static const double screenNormal = 412.0;  // Standard phones
  static const double screenLarge = 600.0;   // Large phones/tablets
  static const double screenTablet = 768.0;  // Tablets
  static const double screenDesktop = 1024.0; // Desktop
}
