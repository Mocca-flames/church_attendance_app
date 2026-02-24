/// Application-wide string constants.
abstract final class AppStrings {
  AppStrings._();

  // App info
  static const String appName = 'Church Attendance';
  static const String appTagline = 'Offline-First Management';

  // Auth screens
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String login = 'Login';
  static const String register = 'Register';
  static const String createAccount = 'Create Account';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String role = 'Role';

  // Hints
  static const String enterEmail = 'Enter your email';
  static const String enterPassword = 'Enter your password';
  static const String reEnterPassword = 'Re-enter your password';

  // Labels
  static const String welcome = 'Welcome!';
  static const String quickActions = 'Quick Actions';
  static const String selectRole = 'Select your role in the church';

  // Links
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String signInLink = 'Sign In';
  static const String signUpLink = 'Sign Up';

  // Navigation
  static const String home = 'Home';
  static const String contacts = 'Contacts';
  static const String attendance = 'Mark';
  static const String scenarios = 'To-do';
  static const String settings = 'Settings';
  static const String more = 'more';
  static const String sync = 'Sync';
  static const String logout = 'Logout';

  // Coming soon
  static const String comingSoon = 'Coming soon';

  // Auth errors
  static const String emailRequired = 'Please enter your email';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String passwordRequired = 'Please enter your password';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String confirmPasswordRequired = 'Please confirm your password';
  static const String passwordsDoNotMatch = 'Passwords do not match';

  // Splash
  static const String signInToContinue = 'Sign in to continue';
  static const String createYourAccount = 'Create your account to get started';
}