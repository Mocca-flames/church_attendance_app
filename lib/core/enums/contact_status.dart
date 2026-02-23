import 'package:flutter/material.dart';

/// Smart enum for Contact Status with UI and backend mapping
enum ContactStatus {
  active(
    backendValue: 'active',
    displayName: 'Active',
    icon: Icons.check_circle,
    color: Colors.green,
  ),
  inactive(
    backendValue: 'inactive',
    displayName: 'Inactive',
    icon: Icons.cancel,
    color: Colors.grey,
  ),
  lead(
    backendValue: 'lead',
    displayName: 'Lead',
    icon: Icons.person_add,
    color: Colors.blue,
  ),
  customer(
    backendValue: 'customer',
    displayName: 'Customer',
    icon: Icons.person,
    color: Colors.orange,
  );

  const ContactStatus({
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
  static ContactStatus fromBackend(String value) {
    return ContactStatus.values.firstWhere(
      (status) => status.backendValue.toLowerCase() == value.toLowerCase(),
      orElse: () => ContactStatus.active,
    );
  }

  /// Get all display names for UI dropdowns
  static List<String> get displayNames =>
      ContactStatus.values.map((e) => e.displayName).toList();
}
