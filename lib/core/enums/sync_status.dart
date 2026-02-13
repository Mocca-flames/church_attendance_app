import 'package:flutter/material.dart';

/// Smart enum for Sync Status with UI metadata
enum SyncStatus {
  pending(
    displayName: 'Pending',
    icon: Icons.sync_problem,
    color: Colors.orange,
  ),
  syncing(
    displayName: 'Syncing...',
    icon: Icons.sync,
    color: Colors.blue,
  ),
  synced(
    displayName: 'Synced',
    icon: Icons.cloud_done,
    color: Colors.green,
  ),
  failed(
    displayName: 'Failed',
    icon: Icons.error,
    color: Colors.red,
  );

  const SyncStatus({
    required this.displayName,
    required this.icon,
    required this.color,
  });

  final String displayName;
  final IconData icon;
  final Color color;
}
