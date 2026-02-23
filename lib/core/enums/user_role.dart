import 'package:flutter/material.dart';

/// Smart enum for User Roles with UI and backend mapping
enum UserRole {
  superAdmin(
    backendValue: 'super_admin',
    displayName: 'Super Admin',
    icon: Icons.admin_panel_settings,
    color: Colors.red,
  ),
  secretary(
    backendValue: 'secretary',
    displayName: 'Secretary',
    icon: Icons.edit_note,
    color: Colors.blue,
  ),
  itAdmin(
    backendValue: 'it_admin',
    displayName: 'IT Admin',
    icon: Icons.computer,
    color: Colors.purple,
  ),
  servant(
    backendValue: 'servant',
    displayName: 'Servant',
    icon: Icons.volunteer_activism,
    color: Colors.green,
  );

  const UserRole({
    required this.backendValue,
    required this.displayName,
    required this.icon,
    required this.color,
  });

  final String backendValue;
  final String displayName;
  final IconData icon;
  final Color color;

  /// Convert from backend string value
  static UserRole fromBackend(String value) {
    return UserRole.values.firstWhere(
      (role) => role.backendValue == value,
      orElse: () => UserRole.servant,
    );
  }

  /// Check if user has admin privileges
  bool get isAdmin =>
      this == UserRole.superAdmin ||
      this == UserRole.secretary ||
      this == UserRole.itAdmin;
}
