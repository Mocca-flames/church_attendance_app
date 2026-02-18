import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/sync/sync_manager.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/main.dart';


/// Provider for SyncManager instance.
/// 
/// The SyncManager handles:
/// - Pulling contacts from server to local DB
/// - Syncing pending items to server
/// - Checking internet connectivity
/// 
/// Usage:
/// ```dart
/// final syncManager = ref.read(syncManagerProvider);
/// await syncManager.pullContacts();
/// await syncManager.syncAll();
/// ```
final syncManagerProvider = Provider<SyncManager>((ref) {
  final database = ref.watch(databaseProvider);
  final dioClient = ref.watch(dioClientProvider);
  return SyncManager(database, dioClient);
});

/// Provider for checking pending sync count.
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.getPendingSyncCount();
});

/// Provider to check if contacts need syncing.
/// Returns true if there are no local contacts or if refresh is needed.
final contactsNeedSyncProvider = FutureProvider<bool>((ref) async {
  final database = ref.watch(databaseProvider);
  final syncManager = ref.watch(syncManagerProvider);
  
  // Check if device has internet
  final hasConnection = await syncManager.hasInternetConnection();
  if (!hasConnection) return false; // Can't sync without internet
  
  // Check local contact count
  final count = await database.getContactCount();
  return count == 0; // Need sync if no contacts
});

/// Provider for sync status.
class SyncStatus {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingCount;
  final String? error;

  const SyncStatus({
    this.isSyncing = false,
    this.lastSyncTime,
    this.pendingCount = 0,
    this.error,
  });

  SyncStatus copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? pendingCount,
    String? error,
    bool clearError = false,
  }) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingCount: pendingCount ?? this.pendingCount,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Get human-readable time ago string.
  String get timeAgo {
    if (lastSyncTime == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(lastSyncTime!);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}

/// Notifier for managing sync status.
class SyncStatusNotifier extends Notifier<SyncStatus> {
  late final SyncManager _syncManager;

  @override
  SyncStatus build() {
    _syncManager = ref.watch(syncManagerProvider);
    return const SyncStatus();
  }

  /// Pull contacts from server and update sync status.
  Future<void> pullContacts({bool forceFullSync = false}) async {
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      await _syncManager.pullContacts(forceFullSync: forceFullSync);
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Failed to sync contacts: $e',
      );
    }
  }

  /// Sync all pending items.
  Future<void> syncAll() async {
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      final result = await _syncManager.syncAll();
      final pendingCount = await _syncManager.getPendingSyncCount();

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        pendingCount: pendingCount,
        error: result.success ? null : result.message,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Sync failed: $e',
      );
    }
  }

  /// Refresh pending sync count.
  Future<void> refreshPendingCount() async {
    final count = await _syncManager.getPendingSyncCount();
    state = state.copyWith(pendingCount: count);
  }
}

/// Provider for SyncStatusNotifier.
final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatus>(() {
  return SyncStatusNotifier();
});

/// Provider for managing periodic background sync.
/// This starts a 24-hour timer that syncs contacts and pending items.
class PeriodicSyncNotifier extends Notifier<Timer?> {
  @override
  Timer? build() {
    // Don't start automatically - wait for user to authenticate
    return null;
  }

  /// Start periodic sync. Call this after successful login.
  void startPeriodicSync({Duration interval = const Duration(hours: 24)}) {
    // Cancel existing timer if any
    state?.cancel();
    
    final syncManager = ref.read(syncManagerProvider);
    
    // Start new periodic timer
    state = syncManager.startPeriodicSync(interval: interval);
  }

  /// Stop periodic sync. Call this on logout.
  void stopPeriodicSync() {
    state?.cancel();
    state = null;
  }
}

/// Provider for periodic sync timer.
final periodicSyncProvider =
    NotifierProvider<PeriodicSyncNotifier, Timer?>(() {
  return PeriodicSyncNotifier();
});