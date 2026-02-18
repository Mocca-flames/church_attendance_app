import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/sync/sync_manager_provider.dart';

/// Widget that displays the current sync status.
/// 
/// Shows:
/// - Cloud icon (done/offline) based on sync state
/// - Last synced time in human-readable format
/// - Pending sync count (if any items waiting to sync)
/// - Optional tap to trigger manual sync
class SyncStatusIndicator extends ConsumerWidget {
  final bool showPendingCount;
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    super.key,
    this.showPendingCount = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    return InkWell(
      onTap: onTap ?? () => _triggerSync(ref),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sync status icon
            if (syncStatus.isSyncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.orange,
                ),
              )
            else
              Icon(
                syncStatus.lastSyncTime != null
                    ? Icons.cloud_done
                    : Icons.cloud_off,
                size: 16,
                color: syncStatus.lastSyncTime != null
                    ? Colors.green
                    : Colors.orange,
              ),
            const SizedBox(width: 4),
            // Text content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Last synced: ${syncStatus.timeAgo}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                if (showPendingCount && syncStatus.pendingCount > 0)
                  Text(
                    '${syncStatus.pendingCount} pending',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            // Sync icon button
            if (onTap != null || !syncStatus.isSyncing) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.sync,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _triggerSync(WidgetRef ref) async {
    try {
      await ref.read(syncStatusProvider.notifier).syncAll();
    } catch (_) {
      // Silently fail - sync will retry later
    }
  }
}

/// Compact version of sync status for use in app bars or tight spaces.
class SyncStatusIndicatorCompact extends ConsumerWidget {
  const SyncStatusIndicatorCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (syncStatus.isSyncing)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange,
            ),
          )
        else
          Icon(
            syncStatus.lastSyncTime != null
                ? Icons.cloud_done
                : Icons.cloud_off,
            size: 14,
            color: syncStatus.lastSyncTime != null
                ? Colors.green
                : Colors.orange,
          ),
        if (syncStatus.pendingCount > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${syncStatus.pendingCount}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
