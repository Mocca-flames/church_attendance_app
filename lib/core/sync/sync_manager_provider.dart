import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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

/// Provider for checking internet connectivity.
/// Returns true if device has an active internet connection.
final connectivityProvider = FutureProvider<bool>((ref) async {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.hasInternetConnection();
});

/// StreamProvider for monitoring connectivity changes.
/// This allows the app to react when the device goes online/offline.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Provider for checking if device is currently online.
/// Uses the connectivity stream for real-time updates.
final isOnlineProvider = NotifierProvider<IsOnlineNotifier, bool>(() {
  return IsOnlineNotifier();
});

/// Notifier that tracks online/offline status and triggers sync when coming online.
class IsOnlineNotifier extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  bool build() {
    _initConnectivity();
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return false;
  }

  Future<void> _initConnectivity() async {
    // Check initial connectivity
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen for changes
    _subscription = connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasOnline = state;
    state = !results.contains(ConnectivityResult.none);

    // If we just came online, trigger sync
    if (!wasOnline && state) {
      _triggerAutoSync();
    }
  }

  Future<void> _triggerAutoSync() async {
    try {
      // Sync pending items when coming online
      await ref.read(syncStatusProvider.notifier).syncAll();
    } catch (e) {
      // Silently fail - will retry later
    }
  }
}
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
  // Progress tracking
  final int currentProgress;
  final int totalProgress;
  final String? progressMessage;

  const SyncStatus({
    this.isSyncing = false,
    this.lastSyncTime,
    this.pendingCount = 0,
    this.error,
    this.currentProgress = 0,
    this.totalProgress = 0,
    this.progressMessage,
  });

  SyncStatus copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? pendingCount,
    String? error,
    int? currentProgress,
    int? totalProgress,
    String? progressMessage,
    bool clearError = false,
    bool clearProgress = false,
  }) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingCount: pendingCount ?? this.pendingCount,
      error: clearError ? null : (error ?? this.error),
      currentProgress: clearProgress ? 0 : (currentProgress ?? this.currentProgress),
      totalProgress: clearProgress ? 0 : (totalProgress ?? this.totalProgress),
      progressMessage: clearProgress ? null : (progressMessage ?? this.progressMessage),
    );
  }

  /// Get progress as percentage (0-100)
  double get progressPercent {
    if (totalProgress == 0) return 0;
    return (currentProgress / totalProgress) * 100;
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
  /// Supports progress callbacks for UI feedback.
  Future<void> pullContacts({
    bool forceFullSync = false,
    bool showProgress = true,
  }) async {
    state = state.copyWith(
      isSyncing: true, 
      clearError: true,
      clearProgress: true,
    );

    try {
      // Create progress callback to update state
      void onProgress(int current, int total, String message) {
        if (showProgress) {
          state = state.copyWith(
            currentProgress: current,
            totalProgress: total,
            progressMessage: message,
          );
        }
      }
      
      await _syncManager.pullContacts(
        forceFullSync: forceFullSync,
        progressCallback: onProgress,
      );
      
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        clearProgress: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Failed to sync contacts: $e',
        clearProgress: true,
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