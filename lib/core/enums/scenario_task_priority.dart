import 'package:flutter/material.dart';

/// Priority levels for scenario tasks
enum ScenarioTaskPriority {
  high(
    backendValue: 'high',
    displayName: 'High',
    color: Color(0xFFEF4444), // Red
    icon: Icons.priority_high,
  ),
  medium(
    backendValue: 'medium',
    displayName: 'Medium',
    color: Color(0xFFF59E0B), // Amber
    icon: Icons.remove,
  ),
  low(
    backendValue: 'low',
    displayName: 'Low',
    color: Color(0xFF22C55E), // Green
    icon: Icons.arrow_downward,
  );

  const ScenarioTaskPriority({
    required this.backendValue,
    required this.displayName,
    required this.color,
    required this.icon,
  });

  final String backendValue;
  final String displayName;
  final Color color;
  final IconData icon;

  /// Convert from backend string value
  static ScenarioTaskPriority fromBackend(String value) {
    return ScenarioTaskPriority.values.firstWhere(
      (priority) => priority.backendValue == value.toLowerCase(),
      orElse: () => ScenarioTaskPriority.medium,
    );
  }
}
