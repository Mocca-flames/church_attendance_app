import 'package:church_attendance_app/features/contacts/screens/contacts_screen.dart';
import 'package:flutter/material.dart';
import 'package:church_attendance_app/features/auth/presentation/screens/login_screen.dart';
import 'package:church_attendance_app/features/auth/presentation/screens/sign.in_screen.dart';
import 'package:church_attendance_app/features/home/presentation/screens/home_screen.dart';
import 'package:church_attendance_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:church_attendance_app/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:church_attendance_app/features/scenarios/presentation/screens/scenarios_screen.dart';
import 'package:church_attendance_app/features/scenarios/presentation/screens/scenario_detail_screen.dart';
import 'package:church_attendance_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:church_attendance_app/core/presentation/widgets/main_navigation_shell.dart';

/// Smart enum for application routes.
/// Provides type-safe routing throughout the app.
enum AppRoute {
  splash,
  login,
  signIn,
  main,
  home,
  attendance,
  scenarios,
  scenarioDetail,
  contacts,
  settings;

  /// The path string for the route
  String get path => '/$name';

  /// Human-readable screen name
  String get screenName {
    switch (this) {
      case AppRoute.splash:
        return 'Splash';
      case AppRoute.login:
        return 'Login';
      case AppRoute.signIn:
        return 'Sign In';
      case AppRoute.main:
        return 'Main';
      case AppRoute.home:
        return 'Home';
      case AppRoute.attendance:
        return 'Mark';
      case AppRoute.scenarios:
        return 'To-do';
      case AppRoute.scenarioDetail:
        return 'Scenario Detail';
      case AppRoute.contacts:
        return 'Contacts';
      case AppRoute.settings:
        return 'Settings';
    }
  }

  /// Build the screen widget for this route
  Widget buildScreen() {
    switch (this) {
      case AppRoute.splash:
        return const SplashScreen();
      case AppRoute.login:
        return const LoginScreen();
      case AppRoute.signIn:
        return const SignInScreen();
      case AppRoute.main:
        return const MainNavigationShell();
      case AppRoute.home:
        return const HomeScreen();
      case AppRoute.attendance:
        return const AttendanceScreen();
      case AppRoute.scenarios:
        return const ScenariosScreen();
      case AppRoute.scenarioDetail:
        return const ScenarioDetailScreen(scenarioId: 0);
      case AppRoute.contacts:
        return const ContactsScreen();
      case AppRoute.settings:
        return const SettingsScreen();
    }
  }

  /// Navigate to this route with MaterialPageRoute
  void navigate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => buildScreen()),
    );
  }

  /// Navigate and remove all previous routes
  void navigateAndRemoveUntil(BuildContext context, {bool removeUntil = true}) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => buildScreen()),
      (route) => !removeUntil,
    );
  }

  /// Replace the current route
  void navigateReplacement(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => buildScreen()),
    );
  }

  /// Get the initial route based on authentication status
  static AppRoute getInitialRoute({required bool isAuthenticated}) {
    return isAuthenticated ? AppRoute.main : AppRoute.login;
  }

  /// Find route by path string
  static AppRoute? fromPath(String path) {
    final routeName = path.startsWith('/') ? path.substring(1) : path;
    try {
      return AppRoute.values.firstWhere((route) => route.name == routeName);
    } catch (_) {
      return null;
    }
  }
}
