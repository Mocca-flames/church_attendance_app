import 'package:flutter/material.dart';

class ActionItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const ActionItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}
