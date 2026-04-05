/// Global string constants for the RISDi application.
/// All static texts are centralized here for easy maintenance and localization support.
class AppStrings {
  // Private constructor to prevent instantiation
  AppStrings._();

  // ======================== APP METADATA ========================
  static const String appName = 'RISDi';
  static const String appNameFull = 'Routine Immunization Stakeholders Directory';
  static const String appDescription = 'A comprehensive stakeholder mapping and management application';

  // ======================== COMMON BUTTONS & ACTIONS ========================
  static const String add = 'Add';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String submit = 'Submit';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String confirm = 'Confirm';
  static const String close = 'Close';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String reset = 'Reset';
  static const String clear = 'Clear';
  static const String done = 'Done';
  static const String back = 'Back';
  static const String home = 'Home';
  static const String logout = 'Logout';
  static const String signOut = 'Sign Out';
  static const String logoutConfirmation = 'Are you sure you want to logout?';
  static const String signOutConfirmation = 'Are you sure you want to sign out?';

  // ======================== FORM FIELDS & LABELS ========================
  static const String fullName = 'Full Name';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String phoneNumber = 'Phone Number';
  static const String whatsappNumber = 'WhatsApp Number';
  static const String country = 'Country';
  static const String state = 'State';
  static const String lga = 'Local Government Area';
  static const String ward = 'Ward';
  static const String association = 'Association';
  static const String levelOfAdministration = 'Level of Administration';
  static const String role = 'Role';
  static const String address = 'Address';
  static const String contactPerson = 'Contact Person';

  // ======================== VALIDATION MESSAGES ========================
  static const String errorFieldRequired = 'This field is required';
  static const String errorInvalidEmail = 'Please enter a valid email address';
  static const String errorInvalidPhoneNumber = 'Please enter a valid phone number';
  static const String errorPasswordMismatch = 'Passwords do not match';
  static const String errorPasswordTooShort = 'Password must be at least 6 characters';
  static const String errorSelectOption = 'Please select an option';
  static const String errorNetworkConnection = 'No internet connection. Please check your connection.';
  static const String errorUnexpected = 'An unexpected error occurred. Please try again.';

  // ======================== AUTHENTICATION & PROFILE ========================
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String createAccount = 'Create Account';
  static const String noAccount = 'Don\'t have an account?';
  static const String haveAccount = 'Already have an account?';
  static const String profile = 'Profile';
  static const String accountInformation = 'Account Information';
  static const String emailVerified = 'Email Verified';
  static const String emailNotVerified = 'Not Verified';
  static const String accountSettings = 'Account Settings';

  // ======================== STAKEHOLDER MANAGEMENT ========================
  static const String stakeholder = 'Stakeholder';
  static const String stakeholders = 'Stakeholders';
  static const String addStakeholder = 'Add Stakeholder';
  static const String addNewStakeholder = 'Add New Stakeholder';
  static const String editStakeholder = 'Edit Stakeholder';
  static const String deleteStakeholder = 'Delete Stakeholder';
  static const String stakeholderDetails = 'Stakeholder Details';
  static const String stakeholderList = 'Stakeholder List';
  static const String totalStakeholders = 'Total Stakeholders';
  static const String recentStakeholders = 'Recent Stakeholders';
  static const String noStakeholdersFound = 'No stakeholders found';
  static const String stakeholderAdded = 'Stakeholder added successfully';
  static const String stakeholderUpdated = 'Stakeholder updated successfully';
  static const String stakeholderDeleted = 'Stakeholder deleted successfully';

  // ======================== FAVORITES & BOOKMARKS ========================
  static const String favorites = 'Favorites';
  static const String addToFavorites = 'Add to Favorites';
  static const String removeFromFavorites = 'Remove from Favorites';
  static const String addedToFavorites = 'Added to favorites';
  static const String removedFromFavorites = 'Removed from favorites';
  static const String noFavoritesYet = 'No favorites yet';
  static const String exploreFavorites = 'Explore and add your favorite stakeholders';

  // ======================== DASHBOARD & HOME ========================
  static const String dashboard = 'Dashboard';
  static const String adminDashboard = 'Admin Dashboard';
  static const String quickActions = 'Quick Actions';
  static const String exploreStakeholders = 'Explore Stakeholders';
  static const String noDataAvailable = 'No data available';
  static const String loading = 'Loading...';
  static const String loadingData = 'Loading data...';
  static const String retryAgain = 'Retry Again';
  static const String noInternetConnection = 'No Internet Connection';

  // ======================== FILTERS & SEARCH ========================
  static const String filterStakeholders = 'Filter Stakeholders';
  static const String searchStakeholders = 'Search Stakeholders';
  static const String selectLocalGovernment = 'Select Local Government';
  static const String selectWard = 'Select Ward';
  static const String resetFilters = 'Reset Filters';
  static const String applyFilters = 'Apply Filters';
  static const String noResults = 'No results found';
  static const String tryDifferentFilters = 'Try different filters or search terms';

  // ======================== NAVIGATION TABS ========================
  static const String homeTab = 'Home';
  static const String favoritesTab = 'Favorites';
  static const String profileTab = 'Profile';
  static const String adminTab = 'Admin';

  // ======================== HELP & SUPPORT ========================
  static const String helpAndSupport = 'Help & Support';
  static const String getHelp = 'Get Help';
  static const String contactSupport = 'Contact Support';
  static const String faqTitle = 'Frequently Asked Questions';
  static const String reportIssue = 'Report an Issue';
  static const String sendFeedback = 'Send Feedback';
  static const String appVersion = 'App Version';

  // ======================== ONBOARDING ========================
  static const String welcome = 'Welcome';
  static const String getStarted = 'Get Started';
  static const String skip = 'Skip';
  static const String startNow = 'Start Now';
  static const String continueText = 'Continue';
  static const String onboardingTitle = 'Welcome to RISDi';
  static const String onboardingDescription = 'Manage and explore immunization stakeholders efficiently';

  // ======================== SUCCESS/ERROR MESSAGES ========================
  static const String success = 'Success';
  static const String error = 'Error';
  static const String warning = 'Warning';
  static const String info = 'Information';
  static const String operationSuccessful = 'Operation completed successfully';
  static const String operationFailed = 'Operation failed. Please try again.';
  static const String tryAgain = 'Try Again';
  static const String goBack = 'Go Back';

  // ======================== DEVELOPER CONTACT ========================
  static const String developerEmail = 'olatunjioladotun3@gmail.com';
  static const String supportEmail = 'olatunjioladotun3@gmail.com';
  static const String emailSubjectSupport = 'Help & Support - $appName';
  static const String emailBodySupport = 'Hi,\n\nI need help with the $appName app.\n\nPlease describe your issue below:\n\n---\n\n';

  // ======================== PERMISSIONS & LEGAL ========================
  static const String termsOfService = 'Terms of Service';
  static const String privacyPolicy = 'Privacy Policy';
  static const String acceptTerms = 'I accept the terms and conditions';

  // ======================== DATA STATES ========================
  static const String processing = 'Processing...';
  static const String syncing = 'Syncing data...';
  static const String offline = 'Offline Mode';
  static const String online = 'Online';
  static const String connected = 'Connected';
  static const String disconnected = 'Disconnected';

  // ======================== EMPTY STATES ========================
  static const String emptyState = 'Nothing here yet';
  static const String emptyStateDescription = 'Start by adding or exploring stakeholders';
  static const String emptyFavorites = 'No favorite stakeholders';
  static const String emptyFavoritesDescription = 'Add stakeholders to your favorites for quick access';

  // ======================== CONFIRMATION DIALOGS ========================
  static const String deleteConfirmation = 'Are you sure you want to delete this item?';
  static const String deleteWarning = 'This action cannot be undone';
  static const String confirmAction = 'Confirm Action';
}
