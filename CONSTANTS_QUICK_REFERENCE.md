# Quick Reference: Using RISDi Constants

## Installation - Already Done ✅
Constants are installed in `lib/core/constants/` with a single export barrel for easy access.

## Import Pattern

```dart
// Single import gets you everything
import 'package:mapping/core/constants/constants.dart';
```

## Color Usage Examples

```dart
// Basic color
Container(color: AppColors.primary)

// With opacity
Container(color: AppColors.primary.withOpacity(0.5))

// Status colors
Icon(Icons.check, color: AppColors.success)  // Green
Icon(Icons.error, color: AppColors.error)    // Red

// Semantic colors
Text("Title", style: TextStyle(color: AppColors.textPrimary))
Text("Hint", style: TextStyle(color: AppColors.textTertiary))
```

## Spacing Usage Examples

```dart
// Use pre-built gaps
Column(
  children: [
    Widget1(),
    AppSpacing.verticalGapMd,  // Pre-built SizedBox(height: 12)
    Widget2(),
  ],
)

// Use padding constants
Container(
  padding: AppSpacing.screenPadding,  // 16 all sides
  child: child,
)

Container(
  padding: AppSpacing.paddingXs,  // 4 all sides
)

// Custom spacing
SizedBox(height: AppSpacing.lg)  // 16
```

## Text Style Usage Examples

```dart
// Heading
Text("Welcome", style: AppTextStyles.headingLg)   // 24px, bold

// Body text
Text("Description", style: AppTextStyles.bodyMd)   // 14px, normal

// Button text
Text("Click Me", style: AppTextStyles.buttonMd)    // Buttons

// Custom variations
Text(
  "Special",
  style: AppTextStyles.headingMd.copyWith(color: AppColors.error)
)
```

## Size Usage Examples

```dart
// Icon sizes
Icon(Icons.star, size: AppSizes.iconLg)     // 40px
Icon(Icons.settings, size: AppSizes.iconMd) // 24px

// Border radius
BorderRadius.circular(AppSizes.radiusMd)    // 12px
BorderRadius.circular(AppSizes.radiusLg)    // 16px

// Button sizes
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    fixedSize: Size(AppSizes.buttonWidthLarge, AppSizes.buttonHeightLg),
  ),
  child: Text("Large Button"),
)

// Avatar sizes
CircleAvatar(
  radius: AppSizes.avatarMd,  // 32px
  backgroundImage: AssetImage(AppAssets.userAvatar01),
)
```

## String Usage Examples

```dart
// App metadata
Text(AppStrings.appName)        // "RISDi"
Text(AppStrings.appDescription) // Full description

// Common actions
ElevatedButton(
  onPressed: () {},
  child: Text(AppStrings.save),    // "Save"
)

TextButton(
  onPressed: () {},
  child: Text(AppStrings.cancel),  // "Cancel"
)

// Form labels
TextField(
  decoration: InputDecoration(
    labelText: AppStrings.fullName,  // "Full Name"
    hintText: AppStrings.enterFullName,
  ),
)

// Navigation/Features
Text(AppStrings.stakeholder)     // Stakeholder text
Text(AppStrings.addStakeholder)  // "Add Stakeholder"
```

## Asset Usage Examples

```dart
// Logo
Image.asset(AppAssets.appLogo)
Image.asset(AppAssets.unicefLogo)

// Splash
Image.asset(AppAssets.splashScreen)

// Avatar
Image.asset(AppAssets.userAvatar01)

// With fallback
Image.asset(
  AppAssets.userAvatar01,
  errorBuilder: (_, __, ___) => Image.asset(AppAssets.defaultAvatar),
)
```

## Theme Usage

```dart
// Already integrated in main.dart - no need to do anything
// But if you need to access theme colors programmatically:

final theme = Theme.of(context);
final primaryColor = theme.colorScheme.primary;  // Uses AppColors.primary

// Access text styles from theme
final headingStyle = theme.textTheme.displayLarge;
```

## Complete Screen Refactoring Example

### Before (Hardcoded)
```dart
Container(
  color: Color(0xFF1f6ed4),
  padding: const EdgeInsets.all(16.0),
  child: Column(
    children: [
      Text(
        "Welcome to RISDi",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1f6ed4),
        ),
        child: Text(
          "Get Started",
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    ],
  ),
)
```

### After (Using Constants)
```dart
Container(
  color: AppColors.primary,
  padding: AppSpacing.screenPadding,
  child: Column(
    children: [
      Text(
        AppStrings.welcome,
        style: AppTextStyles.headingLg,
      ),
      AppSpacing.verticalGapMd,
      ElevatedButton(
        onPressed: () {},
        child: Text(AppStrings.getStarted),
      ),
    ],
  ),
)
```

**Result:** -8 lines, much more maintainable, fully themeable

## Checking Available Constants

### Colors - See lib/core/constants/colors.dart
- Primary, Secondary, Accent
- Status: success, error, warning, info
- Neutral: dark, darkGrey, mediumGrey, lightGrey, ultraLightGrey, white
- Semantic: textPrimary, textSecondary, textTertiary, textOnPrimary

### Spacing - See lib/core/constants/spacing.dart
- Base units: xs, sm, md, lg, xl, xxl, xxxl
- Pre-built gaps: verticalGap*, horizontalGap*
- Pre-built padding: padding*, paddingHorizontal*, paddingVertical*
- Special: screenPadding, cardPadding, dialogPadding

### Sizes - See lib/core/constants/sizes.dart
- Icons: iconXs through iconLarge
- Radius: radiusXs through radiusCircle
- Elevation: elevationNone through elevationXl
- Button: heights and widths
- Breakpoints: screenSmall through screenDesktop

### Text Styles - See lib/core/constants/text_styles.dart
- Headings, Subheadings, Body, Captions, Labels, Buttons
- All variants: Lg, Md, Sm, Xs (and XXL, XL for headings)
- Special: error, warning, success, link, disabled, input, appBar

### Strings - See lib/core/constants/strings.dart
- App metadata: appName, appDescription, etc.
- Common actions: save, cancel, submit, etc.
- Form fields: fullName, email, phone, etc.
- Feature strings: stakeholder, favorite, dashboard, etc.
- Help: helpAndSupport, contactSupport, etc.

### Assets - See lib/core/constants/assets.dart
- Logos: appLogo, appLogoWhite, unicefLogo
- Splash: splashScreen, splashScreen7, etc.
- Avatars: avatar, userAvatar01, defaultAvatar, etc.

---

**Need More Details?**
- **Full Examples:** See `REFACTORING_GUIDE.md`
- **For Deployment:** See `PRODUCTION_CHECKLIST.md`
- **Complete Overview:** See `IMPLEMENTATION_SUMMARY.md`
- **Current Status:** See `CONSTANTS_STATUS.md`

