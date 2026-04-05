/// REFACTORING GUIDE: Converting RISDi to Use Global Constants
/// 
/// This guide shows concrete examples of how to refactor existing screens
/// to use the new centralized constants system.
/// 
/// ========================================================================
/// 1. IMPORT THE CONSTANTS
/// ========================================================================
/// 
/// OLD:
/// ```dart
/// import 'package:flutter/material.dart';
/// ```
/// 
/// NEW:
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:mapping/core/constants/constants.dart';
/// ```
/// 
/// ========================================================================
/// 2. COLORS - BEFORE AND AFTER
/// ========================================================================
/// 
/// EXAMPLE 1: AppBar Colors
/// 
/// OLD CODE:
/// ```dart
/// appBar: AppBar(
///   title: const Text('Profile'),
///   backgroundColor: Colors.indigo,
///   foregroundColor: Colors.white,
///   elevation: 0,
///   centerTitle: false,
/// ),
/// ```
/// 
/// NEW CODE:
/// ```dart
/// appBar: AppBar(
///   title: const Text('Profile'),
///   backgroundColor: AppColors.primary,
///   foregroundColor: AppColors.textOnPrimary,
///   elevation: AppSizes.elevationNone,
///   centerTitle: false,
/// ),
/// ```
/// 
/// BENEFITS:
/// - Centralized color management
/// - Easy theme switching
/// - Consistent across app
/// - Single point of change
/// 
/// ========================================================================
/// 
/// EXAMPLE 2: Card with Gradient
/// 
/// OLD CODE:
/// ```dart
/// Container(
///   padding: const EdgeInsets.all(20),
///   decoration: BoxDecoration(
///     gradient: LinearGradient(
///       colors: [Colors.indigo.shade400, Colors.indigo.shade600],
///       begin: Alignment.topLeft,
///       end: Alignment.bottomRight,
///     ),
///     borderRadius: BorderRadius.circular(16),
///     boxShadow: [
///       BoxShadow(
///         color: Colors.indigo.withOpacity(0.3),
///         blurRadius: 10,
///         offset: const Offset(0, 4),
///       ),
///     ],
///   ),
///   child: Column(...),
/// ),
/// ```
/// 
/// NEW CODE:
/// ```dart
/// Container(
///   padding: AppSpacing.cardPadding,
///   decoration: BoxDecoration(
///     gradient: const LinearGradient(
///       colors: AppColors.primaryGradient,
///       begin: Alignment.topLeft,
///       end: Alignment.bottomRight,
///     ),
///     borderRadius: BorderRadius.circular(AppSizes.radiusLg),
///     boxShadow: [
///       BoxShadow(
///         color: AppColors.primary.withValues(alpha: 0.3),
///         blurRadius: 10,
///         offset: const Offset(0, 4),
///       ),
///     ],
///   ),
///   child: Column(...),
/// ),
/// ```
/// 
/// ========================================================================
/// 3. SPACING - BEFORE AND AFTER
/// ========================================================================
/// 
/// EXAMPLE 1: Multiple SizedBoxes
/// 
/// OLD CODE:
/// ```dart
/// Column(
///   children: [
///     Text('Hello'),
///     const SizedBox(height: 16),
///     Text('World'),
///     const SizedBox(height: 24),
///     Container(...),
///   ],
/// )
/// ```
/// 
/// NEW CODE:
/// ```dart
/// Column(
///   children: [
///     Text('Hello'),
///     AppSpacing.verticalGapLg,
///     Text('World'),
///     AppSpacing.verticalGapXxl,
///     Container(...),
///   ],
/// )
/// ```
/// 
/// BENEFITS:
/// - Consistent spacing throughout
/// - Easy to adjust globally
/// - Readable code
/// - No magic numbers
/// 
/// ========================================================================
/// 
/// EXAMPLE 2: Padding
/// 
/// OLD CODE:
/// ```dart
/// Padding(
///   padding: const EdgeInsets.all(16.0),
///   child: Column(...),
/// )
/// ```
/// 
/// NEW CODE:
/// ```dart
/// Padding(
///   padding: AppSpacing.screenPadding,
///   child: Column(...),
/// )
/// ```
/// 
/// ========================================================================
/// 4. TEXT STYLES - BEFORE AND AFTER
/// ========================================================================
/// 
/// EXAMPLE 1: Multiple TextStyle Definitions
/// 
/// OLD CODE:
/// ```dart
/// Text(
///   'Welcome to RISDi',
///   style: const TextStyle(
///     fontSize: 24.0,
///     fontWeight: FontWeight.bold,
///     color: Colors.black87,
///   ),
/// ),
/// SizedBox(height: 16),
/// Text(
///   'Manage stakeholders',
///   style: TextStyle(
///     fontSize: 14.0,
///     color: Colors.grey[600],
///   ),
/// ),
/// ```
/// 
/// NEW CODE:
/// ```dart
/// Text(
///   'Welcome to RISDi',
///   style: AppTextStyles.headingLg,
/// ),
/// AppSpacing.verticalGapLg,
/// Text(
///   'Manage stakeholders',
///   style: AppTextStyles.bodyMd,
/// ),
/// ```
/// 
/// BENEFITS:
/// - Consistent typography
/// - Matches design system
/// - Less code
/// - Easy maintenance
/// 
/// ========================================================================
/// 
/// EXAMPLE 2: Custom Text Style Variations
/// 
/// OLD CODE:
/// ```dart
/// Text(
///   'Error Message',
///   style: const TextStyle(
///     fontSize: 12.0,
///     fontWeight: FontWeight.w500,
///     color: Colors.red,
///   ),
/// )
/// ```
/// 
/// NEW CODE:
/// ```dart
/// Text(
///   'Error Message',
///   style: AppTextStyles.error,
/// )
/// ```
/// 
/// ========================================================================
/// 5. SIZES - BEFORE AND AFTER
/// ========================================================================
/// 
/// EXAMPLE 1: Icon Sizes
/// 
/// OLD CODE:
/// ```dart
/// CircleAvatar(
///   radius: 40,
///   child: Icon(Icons.person, size: 40),
/// ),
/// ```
/// 
/// NEW CODE:
/// ```dart
/// CircleAvatar(
///   radius: AppSizes.avatarLg / 2,
///   child: Icon(Icons.person, size: AppSizes.iconXl),
/// ),
/// ```
/// 
/// ========================================================================
/// 
/// EXAMPLE 2: Border Radius
/// 
/// OLD CODE:
/// ```dart
/// Card(
///   shape: RoundedRectangleBorder(
///     borderRadius: BorderRadius.circular(12),
///   ),
///   child: ...
/// )
/// ```
/// 
/// NEW CODE:
/// ```dart
/// Card(
///   shape: RoundedRectangleBorder(
///     borderRadius: BorderRadius.circular(AppSizes.radiusMd),
///   ),
///   child: ...
/// )
/// ```
/// 
/// ========================================================================
/// 
/// EXAMPLE 3: Button Heights
/// 
/// OLD CODE:
/// ```dart
/// ElevatedButton(
///   style: ElevatedButton.styleFrom(
///     padding: const EdgeInsets.symmetric(vertical: 16),
///   ),
///   child: const Text('Submit'),
/// )
/// ```
/// 
/// NEW CODE:
/// ```dart
/// ElevatedButton(
///   style: ElevatedButton.styleFrom(
///     padding: EdgeInsets.symmetric(
///       vertical: AppSizes.buttonHeightMd / 2,
///     ),
///   ),
///   child: const Text('Submit'),
/// )
/// ```
/// 
/// ========================================================================
/// 6. STRINGS - BEFORE AND AFTER
/// ========================================================================
/// 
/// EXAMPLE 1: Static Texts
/// 
/// OLD CODE:
/// ```dart
/// Text('Add New Stakeholder'),
/// const SizedBox(height: 16),
/// Text('No stakeholders found'),
/// ```
/// 
/// NEW CODE:
/// ```dart
/// Text(AppStrings.addNewStakeholder),
/// AppSpacing.verticalGapLg,
/// Text(AppStrings.noStakeholdersFound),
/// ```
/// 
/// BENEFITS:
/// - Easy localization support
/// - Single source of truth for text
/// - Reduces string duplication
/// - Better maintainability
/// 
/// ========================================================================
/// 7. COMPLETE EXAMPLE: Refactored Screen Section
/// ========================================================================
/// 
/// OLD CODE:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     backgroundColor: Colors.grey[50],
///     appBar: AppBar(
///       title: const Text('Profile'),
///       backgroundColor: Colors.indigo,
///       foregroundColor: Colors.white,
///     ),
///     body: SingleChildScrollView(
///       padding: const EdgeInsets.all(16.0),
///       child: Column(
///         crossAxisAlignment: CrossAxisAlignment.start,
///         children: [
///           Text(
///             "Manage your account and preferences",
///             style: TextStyle(
///               fontSize: 14,
///               color: Colors.grey[600],
///             ),
///           ),
///           const SizedBox(height: 24),
///           Container(
///             width: double.infinity,
///             padding: const EdgeInsets.all(20),
///             decoration: BoxDecoration(
///               gradient: LinearGradient(
///                 colors: [Colors.indigo.shade400, Colors.indigo.shade600],
///               ),
///               borderRadius: BorderRadius.circular(16),
///             ),
///             child: Column(
///               children: [
///                 const CircleAvatar(
///                   radius: 40,
///                   backgroundColor: Colors.white,
///                   child: Icon(Icons.person, size: 40),
///                 ),
///                 const SizedBox(height: 16),
///                 Text(
///                   'user@example.com',
///                   style: const TextStyle(
///                     color: Colors.white,
///                     fontSize: 18,
///                     fontWeight: FontWeight.bold,
///                   ),
///                 ),
///               ],
///             ),
///           ),
///           const SizedBox(height: 24),
///           const Text(
///             "Account Information",
///             style: TextStyle(
///               fontSize: 18,
///               fontWeight: FontWeight.bold,
///             ),
///           ),
///         ],
///       ),
///     ),
///   );
/// }
/// ```
/// 
/// NEW CODE:
/// ```dart
/// import 'package:mapping/core/constants/constants.dart';
/// 
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     backgroundColor: AppColors.bgPrimary,
///     appBar: AppBar(
///       title: const Text('Profile'),
///       backgroundColor: AppColors.primary,
///       foregroundColor: AppColors.textOnPrimary,
///     ),
///     body: SingleChildScrollView(
///       padding: AppSpacing.screenPadding,
///       child: Column(
///         crossAxisAlignment: CrossAxisAlignment.start,
///         children: [
///           Text(
///             AppStrings.manageAccountPreferences,
///             style: AppTextStyles.bodyMd,
///           ),
///           AppSpacing.verticalGapXxl,
///           Container(
///             width: double.infinity,
///             padding: AppSpacing.cardPaddingLarge,
///             decoration: BoxDecoration(
///               gradient: const LinearGradient(
///                 colors: AppColors.primaryGradient,
///               ),
///               borderRadius: BorderRadius.circular(AppSizes.radiusLg),
///             ),
///             child: Column(
///               children: [
///                 CircleAvatar(
///                   radius: AppSizes.avatarLg / 2,
///                   backgroundColor: AppColors.white,
///                   child: Icon(
///                     Icons.person,
///                     size: AppSizes.iconXl,
///                   ),
///                 ),
///                 AppSpacing.verticalGapLg,
///                 Text(
///                   'user@example.com',
///                   style: AppTextStyles.subheadingLg.copyWith(
///                     color: AppColors.textOnPrimary,
///                   ),
///                 ),
///               ],
///             ),
///           ),
///           AppSpacing.verticalGapXxl,
///           Text(
///             AppStrings.accountInformation,
///             style: AppTextStyles.headingMd,
///           ),
///         ],
///       ),
///     ),
///   );
/// }
/// ```
/// 
/// ========================================================================
/// 8. REFACTORING CHECKLIST
/// ========================================================================
/// 
/// When refactoring a screen, follow this checklist:
/// 
/// - [ ] Add import: `import 'package:mapping/core/constants/constants.dart';`
/// - [ ] Replace Colors.* with AppColors.*
/// - [ ] Replace SizedBox(height/width) with AppSpacing gaps
/// - [ ] Replace EdgeInsets with AppSpacing padding constants
/// - [ ] Replace TextStyle with AppTextStyles
/// - [ ] Replace hardcoded border radius with AppSizes.radius*
/// - [ ] Replace hardcoded icon sizes with AppSizes.icon*
/// - [ ] Replace hardcoded strings with AppStrings.*
/// - [ ] Replace elevation values with AppSizes.elevation*
/// - [ ] Verify UI appearance hasn't changed
/// - [ ] Test navigation and functionality
/// - [ ] Run: `flutter analyze`
/// 
/// ========================================================================
/// 9. GRADUAL MIGRATION STRATEGY
/// ========================================================================
/// 
/// Since this is a large codebase, migrate gradually:
/// 
/// 1. Start with core screens (main.dart, home_screen.dart)
/// 2. Then refactor component files
/// 3. Then refactor less critical screens
/// 4. Finally, refactor utility/service files
/// 
/// This ensures:
/// - No breaking changes
/// - Easy rollback if needed
/// - Incremental testing
/// - Team can adapt gradually
/// 
/// ========================================================================
/// 10. BENEFITS SUMMARY
/// ========================================================================
/// 
/// ✅ Consistency: All colors, spacing, text match throughout the app
/// ✅ Maintainability: Change colors/styles in one place
/// ✅ Scalability: Easy to add new variants
/// ✅ Localization: All strings in one place
/// ✅ Dark theme: Complete theme support
/// ✅ Responsive: Centralized size constants
/// ✅ Clean code: Less duplication, more readable
/// ✅ Production-ready: Professional and polished
/// 
/// ========================================================================

// This is a documentation file - no executable code
