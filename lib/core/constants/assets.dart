/// Asset paths for images, icons, and logos used in the RISDi application.
/// Centralize all asset references to prevent broken paths.
class AppAssets {
  // Private constructor to prevent instantiation
  AppAssets._();

  // ======================== ASSET FOLDER PATH ========================
  static const String _assetPath = 'assets/';
  static const String _imagePath = '${_assetPath}images/';
  static const String _iconPath = '${_assetPath}icons/';

  // ======================== LOGOS & BRANDING ========================
  static const String appLogo = '${_assetPath}1.png';
  static const String appLogoWhite = '${_assetPath}1.png'; // Update if separate white version exists
  static const String unicefLogo = '${_assetPath}unicef-logo.png';

  // ======================== SPLASH & ONBOARDING IMAGES ========================
  static const String splashScreen = '${_assetPath}splash screen 6.png';
  static const String splashScreen7 = '${_assetPath}splash screen 7.png';
  static const String frame2 = '${_assetPath}Frame 2.png';

  // ======================== USER AVATARS & PROFILES ========================
  static const String avatar = '${_assetPath}avatar.png';
  static const String userAvatar01 = '${_assetPath}user01.png';
  static const String defaultAvatar = '${_assetPath}avatar.png';

  // ======================== EMPTY STATE IMAGES ========================
  // Add these when creating proper empty state graphics
  static const String emptyStakeholders = '${_imagePath}empty_stakeholders.png';
  static const String emptyFavorites = '${_imagePath}empty_favorites.png';
  static const String emptySearch = '${_imagePath}empty_search.png';
  static const String errorOccurred = '${_imagePath}error_occurred.png';
  static const String noConnection = '${_imagePath}no_connection.png';

  // ======================== COMMON ICONS ========================
  // Note: For better practice, use Material Icons or Flutter icons instead of image files
  // These are placeholders for custom icons if needed
  static const String iconStakeholder = '${_iconPath}stakeholder.png';
  static const String iconFavorite = '${_iconPath}favorite.png';
  static const String iconSettings = '${_iconPath}settings.png';
  static const String iconLogout = '${_iconPath}logout.png';

  // ======================== ILLUSTRATIONS ========================
  static const String illustrationWelcome = '${_imagePath}illustration_welcome.png';
  static const String illustrationEmpty = '${_imagePath}illustration_empty.png';
  static const String illustrationError = '${_imagePath}illustration_error.png';

  // ======================== BACKGROUND IMAGES ========================
  static const String backgroundDark = '${_imagePath}bg_dark.png';
  static const String backgroundLight = '${_imagePath}bg_light.png';
  static const String backgroundGradient = '${_imagePath}bg_gradient.png';

  // ======================== ALL ASSET FILES (for validation) ========================
  static const List<String> allAssets = [
    appLogo,
    unicefLogo,
    splashScreen,
    splashScreen7,
    frame2,
    avatar,
    userAvatar01,
  ];

  /// Check if asset exists in pubspec.yaml
  /// This should be used in debug builds only
  static bool isValidAsset(String assetPath) {
    return allAssets.contains(assetPath) ||
        (assetPath.startsWith(_assetPath) && assetPath.isNotEmpty);
  }

  /// Get placeholder asset for missing images
  static String getPlaceholderAsset(String type) {
    switch (type) {
      case 'avatar':
        return defaultAvatar;
      case 'logo':
        return appLogo;
      default:
        return appLogo;
    }
  }
}
