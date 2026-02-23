import 'package:flutter/material.dart';

/// Smart enum for Scenario Status with UI and backend mapping
enum ScenarioStatus {
  active(
    backendValue: 'active',
    displayName: 'Active',
    icon: Icons.play_circle,
    color: Colors.green,
  ),
  completed(
    backendValue: 'completed',
    displayName: 'Completed',
    icon: Icons.check_circle,
    color: Colors.blue,
  );

  const ScenarioStatus({
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
  static ScenarioStatus fromBackend(String value) {
    return ScenarioStatus.values.firstWhere(
      (status) => status.backendValue == value,
      orElse: () => ScenarioStatus.active,
    );
  }

  /// Get all display names for UI filters
  static List<String> get displayNames =>
      ScenarioStatus.values.map((e) => e.displayName).toList();
}
