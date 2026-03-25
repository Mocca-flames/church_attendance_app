import 'package:flutter_riverpod/flutter_riverpod.dart';

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
