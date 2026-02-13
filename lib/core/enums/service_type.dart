import 'package:flutter/material.dart';

/// Smart enum for Service Types with UI and backend mapping
enum ServiceType {
  sunday(
    backendValue: 'Sunday',
    displayName: 'Sunday Service',
    icon: Icons.church,
    color: Colors.blue,
  ),
  tuesday(
    backendValue: 'Tuesday',
    displayName: 'Tuesday Service',
    icon: Icons.nightlight,
    color: Colors.purple,
  ),
  specialEvent(
    backendValue: 'Special Event',
    displayName: 'Special Event',
    icon: Icons.event,
    color: Colors.orange,
  );

  const ServiceType({
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
  static ServiceType fromBackend(String value) {
    return ServiceType.values.firstWhere(
      (type) => type.backendValue == value,
      orElse: () => ServiceType.sunday,
    );
  }

  /// Get all display names for UI dropdowns
  static List<String> get displayNames =>
      ServiceType.values.map((e) => e.displayName).toList();
}
