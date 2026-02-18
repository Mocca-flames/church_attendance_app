import 'package:church_attendance_app/features/contacts/screens/contacts_screen.dart';
import 'package:flutter/material.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/features/home/presentation/screens/home_screen.dart';
import 'package:church_attendance_app/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:church_attendance_app/features/scenarios/presentation/screens/scenarios_screen.dart';
import 'package:church_attendance_app/features/settings/presentation/screens/settings_screen.dart';

/// Main navigation shell that provides bottom navigation for the app.
/// Contains the scaffold with BottomNavigationBar and manages tab switching.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  /// List of screens for each bottom navigation tab
  final List<Widget> _screens = const [
    HomeScreen(),
    AttendanceScreen(),
    ContactsScreen(),
    ScenariosScreen(),
    SettingsScreen(),
  ];

  /// List of navigation items
  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: AppStrings.home,
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.qr_code_scanner_outlined),
      activeIcon: Icon(Icons.qr_code_scanner),
      label: AppStrings.attendance,
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.card_membership_outlined),
      activeIcon: Icon(Icons.card_membership),
      label: AppStrings.contacts,
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.checklist_outlined),
      activeIcon: Icon(Icons.checklist),
      label: AppStrings.scenarios,
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: AppStrings.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: _navItems,
      ),
    );
  }
}
