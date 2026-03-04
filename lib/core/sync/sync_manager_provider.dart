import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/sync/sync_manager.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_count_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/tag_statistics_provider.dart';
import 'package:church_attendance_app/features/home/presentation/screens/home_screen.dart';
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

  /// Invalidate all data providers to trigger UI refresh after sync.
  /// This ensures Contact List and Home Screen show updated data.
  void _invalidateDataProviders() {
    // Contact list providers
    ref.invalidate(contactListProvider);
    ref.invalidate(offlineContactCountProvider);
    ref.invalidate(offlineContactStoreInfoProvider);
    
    // Tag statistics providers
    ref.invalidate(tagDistributionProvider);
    ref.invalidate(locationTagDistributionProvider);
    ref.invalidate(roleTagDistributionProvider);
    ref.invalidate(membershipDistributionProvider);
    ref.invalidate(totalContactCountProvider);
    
    // Attendance providers (Home screen)
    ref.invalidate(weeklyAttendanceCountProvider);
    ref.invalidate(attendanceTrendProvider);
    ref.invalidate(attendanceByServiceTypeProvider);
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
      
      // Invalidate data providers to refresh UI with new data
      _invalidateDataProviders();
      
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

      // Invalidate data providers to refresh UI with synced data
      _invalidateDataProviders();

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

/// Provider for periodic sync timer.
final periodicSyncProvider =
    NotifierProvider<PeriodicSyncNotifier, Timer?>(() {
  return PeriodicSyncNotifier();
});

/// Sync mode enum for smart sync behavior
enum SyncMode {
  /// Active mode: User is actively marking attendance or editing contacts
  /// Sync interval: 5 minutes
  active,

  /// Normal mode: User is logged in but not actively using sync-critical features
  /// Sync interval: 1 hour
  normal,

  /// Background mode: App is in background or idle
  /// Sync interval: 24 hours
  background,
}

/// Extension to get interval duration for each sync mode
extension SyncModeExtension on SyncMode {
  Duration get interval {
    switch (this) {
      case SyncMode.active:
        return const Duration(minutes: 5);
      case SyncMode.normal:
        return const Duration(hours: 1);
      case SyncMode.background:
        return const Duration(hours: 24);
    }
  }
}

/// State class for smart sync tracking
class SmartSyncState {
  final SyncMode mode;
  final DateTime lastActivity;
  final bool isImmediateSyncPending;

  const SmartSyncState({
    required this.lastActivity,
    this.mode = SyncMode.normal,
    this.isImmediateSyncPending = false,
  });

  SmartSyncState copyWith({
    SyncMode? mode,
    DateTime? lastActivity,
    bool? isImmediateSyncPending,
  }) {
    return SmartSyncState(
      mode: mode ?? this.mode,
      lastActivity: lastActivity ?? this.lastActivity,
      isImmediateSyncPending: isImmediateSyncPending ?? this.isImmediateSyncPending,
    );
  }
}

/// Notifier that tracks sync mode and manages smart sync behavior.
///
/// Automatically switches between:
/// - Active mode (5 min interval): When user is on attendance screen or editing contacts
/// - Normal mode (1 hour interval): Regular usage
/// - Background mode (24 hour interval): App in background
class SmartSyncNotifier extends Notifier<SmartSyncState> {
  Timer? _inactivityTimer;

  @override
  SmartSyncState build() {
    ref.onDispose(() {
      _inactivityTimer?.cancel();
    });
    return SmartSyncState(lastActivity: DateTime.now());
  }

  /// Set sync mode to active (e.g., when on attendance screen)
  void setActiveMode() {
    _inactivityTimer?.cancel();
    state = state.copyWith(mode: SyncMode.active, lastActivity: DateTime.now());
    
    // Restart periodic sync with new interval
    _restartPeriodicSync();
  }

  /// Set sync mode to normal (e.g., when leaving attendance screen)
  void setNormalMode() {
    _inactivityTimer?.cancel();
    state = state.copyWith(mode: SyncMode.normal, lastActivity: DateTime.now());
    
    // Restart periodic sync with new interval
    _restartPeriodicSync();
  }

  /// Set sync mode to background (e.g., when app goes to background)
  void setBackgroundMode() {
    _inactivityTimer?.cancel();
    state = state.copyWith(mode: SyncMode.background, lastActivity: DateTime.now());
    
    // Restart periodic sync with new interval
    _restartPeriodicSync();
  }

  /// Record activity and reset inactivity timer
  void recordActivity() {
    state = state.copyWith(lastActivity: DateTime.now());
    
    // If in active mode, start timer to eventually return to normal
    if (state.mode == SyncMode.active) {
      _startInactivityTimer();
    }
  }

  /// Start timer to detect inactivity and switch to normal mode
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 10), () {
      if (state.mode == SyncMode.active) {
        setNormalMode();
      }
    });
  }

  /// Restart periodic sync with current mode's interval
  void _restartPeriodicSync() {
    final periodicSync = ref.read(periodicSyncProvider.notifier);
    periodicSync.stopPeriodicSync();
    periodicSync.startPeriodicSync(interval: state.mode.interval);
  }

  /// Trigger immediate sync of pending items
  Future<void> triggerImmediateSync() async {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      // Mark for later sync when back online
      state = state.copyWith(isImmediateSyncPending: true);
      return;
    }

    try {
      await ref.read(syncStatusProvider.notifier).syncAll();
      state = state.copyWith(isImmediateSyncPending: false);
    } catch (e) {
      // Will retry on next periodic sync
      state = state.copyWith(isImmediateSyncPending: true);
    }
  }

  /// Check if immediate sync was pending while offline and retry now
  Future<void> checkPendingImmediateSync() async {
    if (state.isImmediateSyncPending) {
      await triggerImmediateSync();
    }
  }
}

/// Provider for SmartSyncNotifier
final smartSyncProvider = NotifierProvider<SmartSyncNotifier, SmartSyncState>(() {
  return SmartSyncNotifier();
});

/// Provider for managing periodic background sync.
/// This starts a timer that syncs contacts and pending items based on current sync mode.
class PeriodicSyncNotifier extends Notifier<Timer?> {
  @override
  Timer? build() {
    // Don't start automatically - wait for user to authenticate
    return null;
  }

  /// Start periodic sync. Call this after successful login.
  ///
  /// If smart sync is enabled, the interval from SmartSyncState will be used.
  void startPeriodicSync({Duration interval = const Duration(hours: 1)}) {
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

  /// Restart with current smart sync mode interval
  void restartWithSmartMode() {
    final smartSync = ref.read(smartSyncProvider);
    stopPeriodicSync();
    startPeriodicSync(interval: smartSync.mode.interval);
  }
}

/// Provider that watches both online status and pending immediate sync
/// to trigger sync when coming back online
final immediateSyncOnReconnectProvider = Provider<void>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  final smartSync = ref.watch(smartSyncProvider);
  
  // When coming online and there's a pending immediate sync, trigger it
  if (isOnline && smartSync.isImmediateSyncPending) {
    // Use a microtask to avoid provider rebuild issues
    Future.microtask(() {
      ref.read(smartSyncProvider.notifier).checkPendingImmediateSync();
    });
  }
});