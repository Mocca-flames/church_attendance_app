import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/app_route.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/core/presentation/widgets/sync_status_indicator.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_count_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/tag_statistics_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/vcf_import_overlay.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/vcf_import_status_card.dart';
import 'package:church_attendance_app/core/sync/sync_manager_provider.dart';
import 'package:church_attendance_app/core/enums/contact_tag.dart';
import 'package:church_attendance_app/main.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/gradient_background.dart';
import 'package:church_attendance_app/core/widgets/lottie_loading_widget.dart';

/// Provider for weekly attendance count
final weeklyAttendanceCountProvider = FutureProvider<int>((ref) async {
  final database = ref.watch(databaseProvider);
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  try {
    final attendances = await database.getAttendancesByDateRange(
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
    );
    return attendances.length;
  } catch (e) {
    return 0;
  }
});

/// Provider for last 7 days attendance data for chart
final attendanceTrendProvider = FutureProvider<List<AttendanceDayData>>((
  ref,
) async {
  final database = ref.watch(databaseProvider);
  final now = DateTime.now();
  final List<AttendanceDayData> data = [];

  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final attendances = await database.getAttendancesByDateRange(
        startOfDay,
        endOfDay,
      );
      data.add(AttendanceDayData(date: date, count: attendances.length));
    } catch (e) {
      data.add(AttendanceDayData(date: date, count: 0));
    }
  }

  return data;
});

/// Data class for attendance chart
class AttendanceDayData {
  final DateTime date;
  final int count;

  AttendanceDayData({required this.date, required this.count});

  String get dayLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

/// Data class for service type attendance (for grouped bar chart)
class ServiceTypeAttendanceData {
  final ServiceType serviceType;
  final List<ServiceAttendanceOccurrence> occurrences;
  final int totalAttendance;

  ServiceTypeAttendanceData({
    required this.serviceType,
    required this.occurrences,
    required this.totalAttendance,
  });

  double get averageAttendance {
    if (occurrences.isEmpty) return 0;
    return totalAttendance / occurrences.length;
  }
}

/// Data class for a single attendance occurrence
class ServiceAttendanceOccurrence {
  final DateTime serviceDate;
  final int attendanceCount;

  ServiceAttendanceOccurrence({
    required this.serviceDate,
    required this.attendanceCount,
  });

  String get dateLabel {
    return '${serviceDate.day}/${serviceDate.month}';
  }
}

/// Provider for attendance by service type (last 4 occurrences of each)
final attendanceByServiceTypeProvider =
    FutureProvider<List<ServiceTypeAttendanceData>>((ref) async {
      final database = ref.watch(databaseProvider);

      final List<ServiceTypeAttendanceData> result = [];

      // Get last 4 occurrences for each service type
      for (final serviceType in ServiceType.values) {
        try {
          final attendances = await database.getAttendancesByServiceType(
            serviceType.backendValue,
          );

          // Group by service date to get unique service dates
          final Map<String, List<AttendanceEntity>> groupedByDate = {};
          for (final attendance in attendances) {
            final dateKey =
                '${attendance.serviceDate.year}-${attendance.serviceDate.month}-${attendance.serviceDate.day}';
            groupedByDate.putIfAbsent(dateKey, () => []).add(attendance);
          }

          // Convert to list and sort by date (most recent first)
          final sortedDates = groupedByDate.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          // Take last 4 occurrences
          final lastFourDates = sortedDates.take(4).toList();

          final occurrences = lastFourDates.map((dateKey) {
            final dateParts = dateKey.split('-');
            final date = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );
            return ServiceAttendanceOccurrence(
              serviceDate: date,
              attendanceCount: groupedByDate[dateKey]!.length,
            );
          }).toList();

          // Reverse to show oldest first for the chart
          occurrences.sort((a, b) => a.serviceDate.compareTo(b.serviceDate));

          final totalAttendance = occurrences.fold<int>(
            0,
            (sum, o) => sum + o.attendanceCount,
          );

          result.add(
            ServiceTypeAttendanceData(
              serviceType: serviceType,
              occurrences: occurrences,
              totalAttendance: totalAttendance,
            ),
          );
        } catch (e) {
          result.add(
            ServiceTypeAttendanceData(
              serviceType: serviceType,
              occurrences: [],
              totalAttendance: 0,
            ),
          );
        }
      }

      return result;
    });

/// Provider for recent attendance records (last 5)
final recentAttendanceProvider = FutureProvider<List<RecentAttendanceItem>>((
  ref,
) async {
  final database = ref.watch(databaseProvider);
  final now = DateTime.now();
  final twoWeeksAgo = now.subtract(const Duration(days: 14));

  try {
    final attendances = await database.getAttendancesByDateRange(
      twoWeeksAgo,
      now,
    );

    // Get contact names for each attendance
    final List<RecentAttendanceItem> items = [];
    for (final attendance in attendances.take(5)) {
      String contactName = attendance.phone;
      try {
        final contacts = await database.getAllContacts();
        final contact = contacts
            .where((c) => c.id == attendance.contactId)
            .firstOrNull;
        if (contact != null) {
          contactName = contact.name ?? contact.phone;
        }
      } catch (_) {}

      items.add(
        RecentAttendanceItem(
          contactName: contactName,
          serviceType: ServiceType.fromBackend(attendance.serviceType),
          serviceDate: attendance.serviceDate,
        ),
      );
    }

    return items.reversed.toList();
  } catch (e) {
    return [];
  }
});

/// Data class for recent attendance item
class RecentAttendanceItem {
  final String contactName;
  final ServiceType serviceType;
  final DateTime serviceDate;

  RecentAttendanceItem({
    required this.contactName,
    required this.serviceType,
    required this.serviceDate,
  });

  String get formattedDate {
    return '${serviceDate.day}/${serviceDate.month}';
  }
}

/// Home screen - main dashboard after authentication.
/// Shows key metrics, charts, and quick actions for church attendance.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  bool _isInitialSyncDone = false;

  @override
  void initState() {
    super.initState();
    // Register as observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    // Trigger sync on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDataProviders();
      _triggerInitialSync();
    });
  }

  @override
  void dispose() {
    // Unregister observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes back to foreground
    // This ensures the home screen shows updated data after recording attendance
    if (state == AppLifecycleState.resumed) {
      _refreshDataProviders();
    }
  }

  /// Refresh all data providers to get fresh data
  /// This ensures the home screen shows updated data when navigating back
  Future<void> _refreshDataProviders() async {
    // Invalidate all attendance-related providers to fetch fresh data
    ref.invalidate(attendanceByServiceTypeProvider);
    ref.invalidate(weeklyAttendanceCountProvider);
    ref.invalidate(recentAttendanceProvider);
    ref.invalidate(attendanceTrendProvider);
    
    // Invalidate contact-related providers
    ref.invalidate(totalContactCountProvider);
    ref.invalidate(tagDistributionProvider);
    ref.invalidate(offlineContactCountProvider);
    ref.invalidate(offlineContactStoreInfoProvider);
    
    // Invalidate sync-related providers
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Trigger initial sync if not done yet
  Future<void> _triggerInitialSync() async {
    if (_isInitialSyncDone) return;

    _isInitialSyncDone = true;

    try {
      // First, sync any pending offline items (attendance, contacts) to server
      await ref.read(syncStatusProvider.notifier).syncAll();

      // Then pull fresh contacts from server
      final needsSync = await ref.read(contactsNeedSyncProvider.future);
      if (needsSync) {
        await ref
            .read(syncStatusProvider.notifier)
            .pullContacts(forceFullSync: true);
        // Refresh contact count display
        ref.invalidate(offlineContactCountProvider);
        ref.invalidate(offlineContactStoreInfoProvider);
      }
    } catch (e) {
      // Sync failed - continue anyway
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncStatusProvider);

    return DynamicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withValues(alpha: 0.5),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: const [
            // Sync status indicator in app bar
            Padding(
              padding: EdgeInsets.only(right: AppDimens.paddingS),
              child: SyncStatusIndicatorCompact(),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  _buildQuickStatsRow(context, ref),
                  const SizedBox(height: AppDimens.paddingL),

                  // Attendance Trend Chart
                  _buildAttendanceTrendChart(context, ref),
                  const SizedBox(height: AppDimens.paddingL),

                  // Quick Actions Card
                  _buildQuickActionsCard(context, ref),
                  const SizedBox(height: AppDimens.paddingL),

                  // Recent Activity Card
                  _buildRecentActivityCard(context, ref),
                  const SizedBox(height: AppDimens.paddingL),

                  // Dynamic Sync Status Widgets
                  _buildSyncStatusCard(context, ref),
                  const SizedBox(height: AppDimens.paddingL),

                  // Tag Distribution Pie Chart
                  _buildTagDistributionChart(context, ref),
                  const SizedBox(height: AppDimens.paddingL),
                ],
              ),
            ),
            // Sync overlay - shown while syncing
            if (syncStatus.isSyncing)
              LottieLoadingOverlay(
                message: 'Syncing contacts...',
                progressText: syncStatus.totalProgress > 0
                    ? '${syncStatus.currentProgress} / ${syncStatus.totalProgress}'
                    : null,
                progressValue: syncStatus.totalProgress > 0
                    ? syncStatus.progressPercent / 100
                    : null,
              ),
            // VCF Import Overlay - ALWAYS on top, even during sync
            const VcfImportOverlay(),
            // VCF Import Status Card - shows progress/results on home screen
            const VcfImportStatusCard(),
          ],
        ),
      ),
    );
  }

  /// Build quick stats row with key metrics
  Widget _buildQuickStatsRow(BuildContext context, WidgetRef ref) {
    final totalContacts = ref.watch(totalContactCountProvider);
    final contactStoreInfo = ref.watch(offlineContactStoreInfoProvider);
    final weeklyAttendance = ref.watch(weeklyAttendanceCountProvider);
    final pendingSync = ref.watch(pendingSyncCountProvider);

    return Row(
      children: [
        // Total Contacts
        Expanded(
          child: totalContacts.when(
            data: (count) => _QuickStatCard(
              icon: Icons.people,
              label: 'Contacts',
              value: count.toString(),
              color: Theme.of(context).colorScheme.primary,
            ),
            loading: () => _QuickStatCard(
              icon: Icons.people,
              label: 'Contacts',
              value: '...',
              color: Theme.of(context).colorScheme.primary,
            ),
            error: (_, _) => _QuickStatCard(
              icon: Icons.people,
              label: 'Contacts',
              value: '-',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: AppDimens.paddingS),
        // Members
        Expanded(
          child: contactStoreInfo.when(
            data: (info) => _QuickStatCard(
              icon: Icons.card_membership,
              label: 'Members',
              value: info.memberCount.toString(),
              color: ContactTag.member.color,
            ),
            loading: () => _QuickStatCard(
              icon: Icons.card_membership,
              label: 'Members',
              value: '...',
              color: ContactTag.member.color,
            ),
            error: (_, _) => _QuickStatCard(
              icon: Icons.card_membership,
              label: 'Members',
              value: '-',
              color: ContactTag.member.color,
            ),
          ),
        ),
        const SizedBox(width: AppDimens.paddingS),
        // This Week's Attendance
        Expanded(
          child: weeklyAttendance.when(
            data: (count) => _QuickStatCard(
              icon: Icons.event_available,
              label: 'This Week',
              value: count.toString(),
              color: Colors.green,
            ),
            loading: () => const _QuickStatCard(
              icon: Icons.event_available,
              label: 'This Week',
              value: '...',
              color: Colors.green,
            ),
            error: (_, _) => const _QuickStatCard(
              icon: Icons.event_available,
              label: 'This Week',
              value: '-',
              color: Colors.green,
            ),
          ),
        ),
        const SizedBox(width: AppDimens.paddingS),
        // Pending Syncs
        Expanded(
          child: pendingSync.when(
            data: (count) => count > 0
                ? _QuickStatCard(
                    icon: Icons.sync_problem,
                    label: 'Pending',
                    value: count.toString(),
                    color: Colors.orange,
                  )
                : const _QuickStatCard(
                    icon: Icons.sync,
                    label: 'Synced',
                    value: '0',
                    color: Colors.green,
                  ),
            loading: () => const _QuickStatCard(
              icon: Icons.sync,
              label: 'Synced',
              value: '...',
              color: Colors.green,
            ),
            error: (_, _) => const _QuickStatCard(
              icon: Icons.sync,
              label: 'Synced',
              value: '-',
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  /// Build attendance trend chart (grouped bar chart by service type)
  Widget _buildAttendanceTrendChart(BuildContext context, WidgetRef ref) {
    final attendanceByServiceType = ref.watch(attendanceByServiceTypeProvider);

    return attendanceByServiceType.when(
      data: (dataList) {
        // Only show if there's at least some data
        final hasData = dataList.any((d) => d.occurrences.isNotEmpty);
        if (!hasData) {
          return const SizedBox.shrink();
        }

        // Get max value for scaling
        int maxCount = 0;
        for (final data in dataList) {
          for (final occurrence in data.occurrences) {
            if (occurrence.attendanceCount > maxCount) {
              maxCount = occurrence.attendanceCount;
            }
          }
        }
        final double chartMaxY = (maxCount * 1.18).ceilToDouble().clamp(4.0, double.infinity);

        return Card(
          elevation: AppDimens.cardElevation,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppDimens.paddingS),
                    Text(
                      'Attendance by Service Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.paddingS),
                // Legend with hardcoded labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sunday',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tuesday',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Special',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.paddingM),
                SizedBox(
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      maxY: chartMaxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.blueGrey.shade800,
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            // group.x = service type index (0=Sunday, 1=Tuesday, 2=Special)
                            // rodIndex = occurrence index within that service type
                            if (group.x >= dataList.length) return null;
                            final serviceData = dataList[group.x.toInt()];
                            if (rodIndex >= serviceData.occurrences.length) {
                              return null;
                            }
                            final occurrence = serviceData.occurrences[rodIndex];

                            return BarTooltipItem(
                              '${serviceData.serviceType.displayName}\n',
                              TextStyle(
                                color: serviceData.serviceType.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: '${occurrence.dateLabel}: ${rod.toY.toInt()}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              // Show service type labels: Sunday, Tuesday, Special
                              const labels = ['Sunday', 'Tuesday', 'Special'];
                              const colors = [Colors.blue, Colors.purple, Colors.orange];
                              
                              if (idx < 0 || idx >= dataList.length.clamp(0, 3)) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 6,
                                child: Text(
                                  labels[idx],
                                  style: TextStyle(
                                    color: colors[idx],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: maxCount > 10 ? (maxCount / 5).ceilToDouble() : 1,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 4,
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxCount > 10 ? (maxCount / 5).ceilToDouble() : 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: _buildBarGroups(dataList),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.paddingM),
                // Summary row
                _buildServiceTypeSummary(context, dataList),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppDimens.paddingM),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Build bar groups for grouped bar chart
  /// Each service type is a single bar showing total attendance
  List<BarChartGroupData> _buildBarGroups(List<ServiceTypeAttendanceData> dataList) {
    if (dataList.isEmpty) return [];

    // Each service type is a group on X-axis with a single bar showing total
    const double barWidth = 40.0;
    
    return List.generate(dataList.length.clamp(0, 3), (serviceTypeIndex) {
      final serviceData = dataList[serviceTypeIndex];
      final count = serviceData.totalAttendance.toDouble();
      final baseColor = serviceData.serviceType.color;
      
      return BarChartGroupData(
        x: serviceTypeIndex, // Service type index on X-axis
        barsSpace: 2,
        barRods: [
          BarChartRodData(
            toY: count,
            width: barWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                baseColor.withValues(alpha: 0.65),
                baseColor,
              ],
            ),
          ),
        ],
      );
    });
  }

  /// Build attendance numbers below chart (labels already in chart X-axis)
  Widget _buildServiceTypeSummary(
    BuildContext context,
    List<ServiceTypeAttendanceData> dataList,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(dataList.length.clamp(0, 3), (index) {
        final data = dataList[index];
        return Text(
          '${data.totalAttendance}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: data.serviceType.color,
          ),
        );
      }),
    );
  }

  /// Build quick actions card with action buttons
  Widget _buildQuickActionsCard(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: AppDimens.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Scan Attendance
                _QuickActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan',
                  color: Colors.blue,
                  onTap: () {
                    AppRoute.attendance.navigate(context);
                  },
                ),
                // Add Contact
                _QuickActionButton(
                  icon: Icons.person_add,
                  label: 'Add',
                  color: Colors.green,
                  onTap: () {
                    AppRoute.contacts.navigate(context);
                    // The contact screen has an FAB to add new contacts
                  },
                ),
                // Sync Now
                _QuickActionButton(
                  icon: Icons.sync,
                  label: 'Sync',
                  color: Colors.orange,
                  onTap: () async {
                    await ref.read(syncStatusProvider.notifier).syncAll();
                    ref.invalidate(pendingSyncCountProvider);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build recent activity card
  Widget _buildRecentActivityCard(BuildContext context, WidgetRef ref) {
    final recentAttendance = ref.watch(recentAttendanceProvider);

    return recentAttendance.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: AppDimens.cardElevation,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 20,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: AppDimens.paddingS),
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.paddingM),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.serviceType.color.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item.serviceType.icon,
                            size: 16,
                            color: item.serviceType.color,
                          ),
                        ),
                        const SizedBox(width: AppDimens.paddingS),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.contactName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.serviceType.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondary
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Build dynamic sync status card with online/offline indicator and pending syncs
  Widget _buildSyncStatusCard(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingSyncCount = ref.watch(pendingSyncCountProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    // Only show if there's data available
    final pendingCountAsync = pendingSyncCount;
    final pendingCount = pendingCountAsync.hasValue
        ? pendingCountAsync.value!
        : 0;
    final lastSyncTime = syncStatus.lastSyncTime;

    // Don't show if no data at all
    if (!isOnline && pendingCount == 0 && lastSyncTime == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: AppDimens.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with online/offline indicator
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? Colors.green : Colors.orange,
                    boxShadow: [
                      BoxShadow(
                        color: (isOnline ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOnline ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                const Spacer(),
                if (syncStatus.isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),

            // Show pending sync count if > 0
            if (pendingCount > 0) ...[
              const SizedBox(height: AppDimens.paddingM),
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingS),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sync_problem,
                      size: 20,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: AppDimens.paddingS),
                    Expanded(
                      child: Text(
                        '$pendingCount item${pendingCount > 1 ? 's' : ''} pending sync',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Show last sync time if available
            if (lastSyncTime != null) ...[
              const SizedBox(height: AppDimens.paddingS),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: AppDimens.paddingXS),
                  Text(
                    'Last sync: ${syncStatus.timeAgo}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build tag distribution section with three separate charts in separate cards
  Widget _buildTagDistributionChart(BuildContext context, WidgetRef ref) {
    final locationData = ref.watch(locationTagDistributionProvider);
    final roleData = ref.watch(roleTagDistributionProvider);
    final membershipData = ref.watch(membershipDistributionProvider);

    // Check if any category has data
    final hasLocationData = locationData.hasValue && locationData.value!.isNotEmpty;
    final hasRoleData = roleData.hasValue && roleData.value!.isNotEmpty;
    final hasMembershipData = membershipData.hasValue && 
        (membershipData.value!['Member']! > 0 || membershipData.value!['Non-Member']! > 0);

    if (!hasLocationData && !hasRoleData && !hasMembershipData) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppDimens.paddingM),
          child: Row(
            children: [
              Icon(
                Icons.pie_chart,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                'Tag Distribution',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Locations Card - Full width
        _buildLocationChartCard(context, locationData),
        const SizedBox(height: AppDimens.paddingM),

        // Roles Card - Full width
        _buildRoleChartCard(context, roleData),
        const SizedBox(height: AppDimens.paddingM),

        // Membership Card - Full width
        _buildMembershipChartCard(context, membershipData),
      ],
    );
  }

  /// Build Locations card with horizontal bar chart
  Widget _buildLocationChartCard(
    BuildContext context,
    AsyncValue<Map<ContactTag, int>> locationData,
  ) {
    return Card(
      elevation: AppDimens.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 20, color: Colors.red.shade700),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  'Locations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),
            locationData.when(
              data: (locationCounts) {
                if (locationCounts.isEmpty) {
                  return _buildEmptyState('No location data');
                }
                return SizedBox(
                  height: 180,
                  child: HorizontalBarChart(
                    data: locationCounts,
                    barColor: Colors.red,
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _buildEmptyState('Error loading data'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Roles card with radar chart
  Widget _buildRoleChartCard(
    BuildContext context,
    AsyncValue<Map<ContactTag, int>> roleData,
  ) {
    return Card(
      elevation: AppDimens.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, size: 20, color: Colors.purple.shade700),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  'Roles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),
            roleData.when(
              data: (roleCounts) {
                if (roleCounts.isEmpty) {
                  return _buildEmptyState('No role data');
                }
                return SizedBox(
                  height: 220,
                  child: RoleRadarChart(
                    data: roleCounts,
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _buildEmptyState('Error loading data'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Membership card with pie chart
  Widget _buildMembershipChartCard(
    BuildContext context,
    AsyncValue<Map<String, int>> membershipData,
  ) {
    return Card(
      elevation: AppDimens.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership, size: 20, color: Colors.green.shade700),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  'Membership',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),
            membershipData.when(
              data: (membershipCounts) {
                final memberCount = membershipCounts['Member'] ?? 0;
                final nonMemberCount = membershipCounts['Non-Member'] ?? 0;
                if (memberCount == 0 && nonMemberCount == 0) {
                  return _buildEmptyState('No membership data');
                }
                return SizedBox(
                  height: 160,
                  child: MembershipPieChart(
                    memberCount: memberCount,
                    nonMemberCount: nonMemberCount,
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => _buildEmptyState('Error loading data'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState(String message) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Quick stat card widget
class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(
                context,
              ).colorScheme.onSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action button widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple widget to display a stat item with icon, label and value
class StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSecondary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal bar chart widget for Location tags
class HorizontalBarChart extends StatelessWidget {
  final Map<ContactTag, int> data;
  final Color barColor;

  const HorizontalBarChart({
    required this.data, required this.barColor, super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Sort by count descending
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxCount = sortedEntries.first.value.toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: sortedEntries.map((entry) {
            final barWidth = (entry.value / maxCount) * constraints.maxWidth;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      entry.key.displayName,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: barWidth / constraints.maxWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                barColor.withValues(alpha: 0.7),
                                barColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: barColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Radar chart widget for Role tags
class RoleRadarChart extends StatelessWidget {
  final Map<ContactTag, int> data;

  const RoleRadarChart({
    required this.data, super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Get all role tags with their counts (use 0 for missing ones)
    final roleTags = ContactTag.roleTags;
    final entries = roleTags.map((tag) {
      return MapEntry(tag, data[tag] ?? 0);
    }).toList();

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: Colors.purple.withValues(alpha: 0.3),
            borderColor: Colors.purple,
            borderWidth: 2,
            entryRadius: 3,
            dataEntries: entries.map((e) => RadarEntry(value: e.value.toDouble())).toList(),
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: Colors.grey, width: 0.5),
        titlePositionPercentageOffset: 0.2,
        titleTextStyle: const TextStyle(fontSize: 8, color: Colors.black87),
        getTitle: (index, angle) {
          return RadarChartTitle(
            text: entries[index].key.displayName,
            angle: 0,
          );
        },
        tickCount: 3,
        ticksTextStyle: const TextStyle(fontSize: 8, color: Colors.grey),
        tickBorderData: const BorderSide(color: Colors.grey, width: 0.5),
        gridBorderData: const BorderSide(color: Colors.grey, width: 0.3),
      ),
    );
  }
}

/// Pie chart widget for Membership (Member vs Non-Member)
class MembershipPieChart extends StatelessWidget {
  final int memberCount;
  final int nonMemberCount;

  const MembershipPieChart({
    required this.memberCount, required this.nonMemberCount, super.key,
  });

  @override
  Widget build(BuildContext context) {
    final total = memberCount + nonMemberCount;
    if (total == 0) {
      return const Center(child: Text('No data'));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 20,
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: memberCount.toDouble(),
                  title: '${(memberCount / total * 100).toStringAsFixed(0)}%',
                  radius: 30,
                  titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.grey,
                  value: nonMemberCount.toDouble(),
                  title: '${(nonMemberCount / total * 100).toStringAsFixed(0)}%',
                  radius: 30,
                  titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem('Member', memberCount, Colors.green),
            const SizedBox(height: 4),
            _buildLegendItem('Non-Member', nonMemberCount, Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color == Colors.grey ? Colors.grey.shade700 : Colors.green.shade700,
          ),
        ),
      ],
    );
  }
}
