import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:church_attendance_app/core/sync/sync_manager_provider.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';

/// Data class for full dashboard statistics from server
/// Based on /contacts/dashboard/statistics endpoint response
class FullDashboardStatistics {
  final int totalContacts;
  final CountData newContacts;
  final CountData modifiedContacts;
  final Map<String, int> locations;
  final Map<String, int> roles;
  final MembershipData membership;

  const FullDashboardStatistics({
    required this.totalContacts,
    required this.newContacts,
    required this.modifiedContacts,
    required this.locations,
    required this.roles,
    required this.membership,
  });

  factory FullDashboardStatistics.fromJson(Map<String, dynamic> json) {
    // Extract new_contacts data
    final newContactsJson = json['new_contacts'] as Map<String, dynamic>? ?? {};
    final modifiedContactsJson = json['modified_contacts'] as Map<String, dynamic>? ?? {};
    final membershipJson = json['membership'] as Map<String, dynamic>? ?? {};
    
    // Extract locations (dynamic - includes hardcoded and user-added)
    final locationsJson = json['locations'] as Map<String, dynamic>? ?? {};
    final rolesJson = json['roles'] as Map<String, dynamic>? ?? {};
    
    return FullDashboardStatistics(
      totalContacts: json['total_contacts'] as int? ?? 0,
      newContacts: CountData(
        count: newContactsJson['count'] as int? ?? 0,
        dateFrom: newContactsJson['date_from'] as String?,
        dateTo: newContactsJson['date_to'] as String?,
      ),
      modifiedContacts: CountData(
        count: modifiedContactsJson['count'] as int? ?? 0,
        dateFrom: modifiedContactsJson['date_from'] as String?,
        dateTo: modifiedContactsJson['date_to'] as String?,
      ),
      locations: Map<String, int>.from(
        locationsJson.map((key, value) => MapEntry(key, value as int? ?? 0)),
      ),
      roles: Map<String, int>.from(
        rolesJson.map((key, value) => MapEntry(key, value as int? ?? 0)),
      ),
      membership: MembershipData(
        member: membershipJson['member'] as int? ?? 0,
        nonMember: membershipJson['non_member'] as int? ?? 0,
      ),
    );
  }

  /// Get sorted locations by count (descending)
  List<MapEntry<String, int>> get sortedLocations {
    final entries = locations.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Get sorted roles by count (descending)
  List<MapEntry<String, int>> get sortedRoles {
    final entries = roles.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Get total for percentage calculations
  int get locationTotal => locations.values.fold(0, (sum, v) => sum + v);
  int get roleTotal => roles.values.fold(0, (sum, v) => sum + v);
  int get membershipTotal => membership.member + membership.nonMember;
}

/// Data class for count data (new/modified contacts)
class CountData {
  final int count;
  final String? dateFrom;
  final String? dateTo;

  const CountData({
    required this.count,
    this.dateFrom,
    this.dateTo,
  });
}

/// Data class for membership data
class MembershipData {
  final int member;
  final int nonMember;

  const MembershipData({
    required this.member,
    required this.nonMember,
  });
}

/// Data class for dashboard statistics from server
/// Based on /contacts/dashboard/statistics endpoint response
class DashboardStatistics {
  final int totalContacts;
  final int memberCount;
  final int nonMemberCount;

  const DashboardStatistics({
    required this.totalContacts,
    required this.memberCount,
    required this.nonMemberCount,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    // Extract membership data from the response
    final membership = json['membership'] as Map<String, dynamic>? ?? {};
    
    return DashboardStatistics(
      totalContacts: json['total_contacts'] as int? ?? 0,
      memberCount: membership['member'] as int? ?? 0,
      nonMemberCount: membership['non_member'] as int? ?? 0,
    );
  }
}

/// Provider for dashboard statistics from server
/// Returns null when offline or on error
/// When online, fetches from /contacts/dashboard/statistics endpoint
/// which provides accurate member/non-member counts from the server
final dashboardStatisticsProvider = FutureProvider<DashboardStatistics?>((ref) async {
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
    final response = await dioClient.getDashboardStatistics();
    
    if (response.statusCode == 200 && response.data != null) {
      return DashboardStatistics.fromJson(response.data);
    }
    return null;
  } catch (e) {
    // Return null on error - let the UI handle the null case
    return null;
  }
});

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

// ═══════════════════════════════════════════════════════════════════════════
// Full Statistics Screen Providers
// ═══════════════════════════════════════════════════════════════════════════

/// Selected date range for statistics filter
class StatisticsDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null; // null means all time

  void setRange(DateTimeRange range) {
    state = range;
  }

  void setToday() {
    final now = DateTime.now();
    state = DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
  }

  void setThisWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    state = DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: now,
    );
  }

  void setThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    state = DateTimeRange(start: start, end: now);
  }

  void setThisQuarter() {
    final now = DateTime.now();
    final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
    final start = DateTime(now.year, quarterMonth, 1);
    state = DateTimeRange(start: start, end: now);
  }

  void setThisYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    state = DateTimeRange(start: start, end: now);
  }

  void setAllTime() {
    state = null;
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = DateTimeRange(start: start, end: end);
  }
}

/// Provider to track selected date range for statistics filter.
final selectedDateRangeProvider =
    NotifierProvider<StatisticsDateRangeNotifier, DateTimeRange?>(() {
  return StatisticsDateRangeNotifier();
});

/// Refresh trigger for statistics screen
class StatisticsRefreshTriggerNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void triggerRefresh() => state = state + 1;
}

/// Provider that tracks manual refresh triggers for statistics screen.
final statisticsRefreshTriggerProvider =
    NotifierProvider<StatisticsRefreshTriggerNotifier, int>(() {
  return StatisticsRefreshTriggerNotifier();
});

/// Provider for full dashboard statistics with date filter support.
/// Returns null when offline or on error.
final fullStatisticsProvider = FutureProvider<FullDashboardStatistics?>((ref) async {
  // Watch refresh triggers to rebuild when needed
  ref.watch(statisticsRefreshTriggerProvider);
  ref.watch(dashboardRefreshTriggerProvider);
  
  // Check if device is online
  final isOnline = ref.watch(isOnlineProvider);
  if (!isOnline) {
    return null;
  }

  try {
    final dioClient = ref.read(dioClientProvider);
    
    // Get date range from filter state
    final dateRange = ref.watch(selectedDateRangeProvider);
    
    String? dateFrom;
    String? dateTo;
    
    if (dateRange != null) {
      // Format dates as ISO 8601 datetime with time component
      dateFrom = '${dateRange.start.year}-${dateRange.start.month.toString().padLeft(2, '0')}-${dateRange.start.day.toString().padLeft(2, '0')}T00:00:00';
      dateTo = '${dateRange.end.year}-${dateRange.end.month.toString().padLeft(2, '0')}-${dateRange.end.day.toString().padLeft(2, '0')}T23:59:59';
    }
    
    final response = await dioClient.getDashboardStatistics(
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    
    // Clear all loading states when data is received
    Future.microtask(() {
      ref.read(widgetLoadingStateProvider.notifier).setAllLoading(false);
    });
    
    if (response.statusCode == 200 && response.data != null) {
      return FullDashboardStatistics.fromJson(response.data);
    }
    return null;
  } catch (e) {
    // Clear loading states on error
    Future.microtask(() {
      ref.read(widgetLoadingStateProvider.notifier).setAllLoading(false);
    });
    // Return null on error - let the UI handle the null case
    return null;
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// Per-Widget Loading State Providers
// ═══════════════════════════════════════════════════════════════════════════

/// State class for individual widget loading states
class WidgetLoadingState {
  final bool isLoadingLocations;
  final bool isLoadingRoles;
  final bool isLoadingMembership;
  final bool isLoadingBreakdown;

  const WidgetLoadingState({
    this.isLoadingLocations = false,
    this.isLoadingRoles = false,
    this.isLoadingMembership = false,
    this.isLoadingBreakdown = false,
  });

  WidgetLoadingState copyWith({
    bool? isLoadingLocations,
    bool? isLoadingRoles,
    bool? isLoadingMembership,
    bool? isLoadingBreakdown,
  }) {
    return WidgetLoadingState(
      isLoadingLocations: isLoadingLocations ?? this.isLoadingLocations,
      isLoadingRoles: isLoadingRoles ?? this.isLoadingRoles,
      isLoadingMembership: isLoadingMembership ?? this.isLoadingMembership,
      isLoadingBreakdown: isLoadingBreakdown ?? this.isLoadingBreakdown,
    );
  }
}

/// Notifier for tracking individual widget loading states
class WidgetLoadingStateNotifier extends Notifier<WidgetLoadingState> {
  @override
  WidgetLoadingState build() => const WidgetLoadingState();

  void setLoadingLocations(bool value) {
    state = state.copyWith(isLoadingLocations: value);
  }

  void setLoadingRoles(bool value) {
    state = state.copyWith(isLoadingRoles: value);
  }

  void setLoadingMembership(bool value) {
    state = state.copyWith(isLoadingMembership: value);
  }

  void setLoadingBreakdown(bool value) {
    state = state.copyWith(isLoadingBreakdown: value);
  }

  void setAllLoading(bool value) {
    state = WidgetLoadingState(
      isLoadingLocations: value,
      isLoadingRoles: value,
      isLoadingMembership: value,
      isLoadingBreakdown: value,
    );
  }

  void refreshLocations() async {
    state = state.copyWith(isLoadingLocations: true);
    // Wait a bit for the UI to show loading state
    await Future.delayed(const Duration(milliseconds: 50));
    ref.read(statisticsRefreshTriggerProvider.notifier).triggerRefresh();
  }

  void refreshRoles() async {
    state = state.copyWith(isLoadingRoles: true);
    await Future.delayed(const Duration(milliseconds: 50));
    ref.read(statisticsRefreshTriggerProvider.notifier).triggerRefresh();
  }

  void refreshMembership() async {
    state = state.copyWith(isLoadingMembership: true);
    await Future.delayed(const Duration(milliseconds: 50));
    ref.read(statisticsRefreshTriggerProvider.notifier).triggerRefresh();
  }

  void refreshBreakdown() async {
    state = state.copyWith(isLoadingBreakdown: true);
    await Future.delayed(const Duration(milliseconds: 50));
    ref.read(statisticsRefreshTriggerProvider.notifier).triggerRefresh();
  }
}

/// Provider for tracking individual widget loading states
final widgetLoadingStateProvider =
    NotifierProvider<WidgetLoadingStateNotifier, WidgetLoadingState>(() {
  return WidgetLoadingStateNotifier();
});
