import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:church_attendance_app/core/sync/sync_manager_provider.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';

/// Data class for daily progress from API
class DailyProgressData {
  final String date;
  final int userId;
  final int newContacts;
  final int modifiedContacts;
  final int total;

  DailyProgressData({
    required this.date,
    required this.userId,
    required this.newContacts,
    required this.modifiedContacts,
    required this.total,
  });

  factory DailyProgressData.fromJson(Map<String, dynamic> json) {
    return DailyProgressData(
      date: json['date'] as String,
      userId: json['user_id'] as int,
      newContacts: json['new_contacts'] as int,
      modifiedContacts: json['modified_contacts'] as int,
      total: json['total'] as int,
    );
  }
}

/// Provider for daily progress data from API
/// Returns null when offline or on error
final dailyProgressProvider = FutureProvider<DailyProgressData?>((ref) async {
  // Watch refresh triggers to rebuild when needed
  ref.watch(dashboardRefreshTriggerProvider);
  ref.watch(lastDashboardRefreshProvider);
  
  // Check if device is online
  final isOnline = ref.watch(isOnlineProvider);
  if (!isOnline) {
    return null;
  }

  try {
    final dioClient = ref.read(dioClientProvider);
    final response = await dioClient.getDailyProgress();
    
    if (response.statusCode == 200 && response.data != null) {
      return DailyProgressData.fromJson(response.data);
    }
    return null;
  } catch (e) {
    // Return null on error - let the UI handle the null case
    return null;
  }
});

/// Notifier for tracking if user is on home screen for smart sync adjustments.
/// This allows the sync system to use faster refresh rates when viewing the dashboard.
class IsOnHomeScreenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Set whether user is on home screen
  void setValue(bool value) {
    state = value;
  }
}

/// Provider to track if user is on home screen for smart sync adjustments.
final isOnHomeScreenProvider = NotifierProvider<IsOnHomeScreenNotifier, bool>(() {
  return IsOnHomeScreenNotifier();
});

/// Notifier for tracking the last time data was refreshed on the dashboard.
class LastDashboardRefreshNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  /// Set the last refresh time
  void setValue(DateTime? value) {
    state = value;
  }
}

/// Provider to track the last time data was refreshed on the dashboard.
final lastDashboardRefreshProvider = NotifierProvider<LastDashboardRefreshNotifier, DateTime?>(() {
  return LastDashboardRefreshNotifier();
});

/// Notifier for tracking if dashboard is currently being refreshed.
class IsDashboardRefreshingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Set whether dashboard is refreshing
  void setValue(bool value) {
    state = value;
  }
}

/// Provider to track if dashboard is currently being refreshed.
final isDashboardRefreshingProvider = NotifierProvider<IsDashboardRefreshingNotifier, bool>(() {
  return IsDashboardRefreshingNotifier();
});

/// Manual refresh trigger for dashboard data.
/// This is a counter that increments each time a manual refresh is triggered.
/// By watching this provider, other providers can rebuild when refresh is requested.
class DashboardRefreshTriggerNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Trigger a manual refresh by incrementing the counter
  void triggerRefresh() {
    state = state + 1;
  }
}

/// Provider that tracks manual refresh triggers for dashboard.
/// When this increments, it signals all dependent providers to refresh.
final dashboardRefreshTriggerProvider =
    NotifierProvider<DashboardRefreshTriggerNotifier, int>(() {
  return DashboardRefreshTriggerNotifier();
});
