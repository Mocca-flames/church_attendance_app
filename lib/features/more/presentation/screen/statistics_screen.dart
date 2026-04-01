import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/sync/sync_manager_provider.dart';
import 'package:church_attendance_app/features/home/presentation/providers/dashboard_providers.dart';
import 'package:church_attendance_app/core/widgets/gradient_background.dart';

/// Statistics Screen - Simplified to show All Time statistics only.
/// Accessible from the More menu under "Data Management" section.
/// 
/// Uses per-widget loading approach - each card can refresh independently
/// without causing the entire screen to rebuild.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize with All Time by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedDateRangeProvider.notifier).setAllTime();
      // Clear any loading states from previous visits
      ref.read(widgetLoadingStateProvider.notifier).setAllLoading(false);
      ref.read(statisticsRefreshTriggerProvider.notifier).triggerRefresh();
    });
  }

  void _refreshAllWidgets() {
    // Set all widgets to loading state first
    final loadingNotifier = ref.read(widgetLoadingStateProvider.notifier);
    loadingNotifier.setAllLoading(true);
    // Then trigger the refresh
    ref.read(statisticsRefreshTriggerProvider.notifier).triggerRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final statsAsync = ref.watch(fullStatisticsProvider);
    final widgetLoadingState = ref.watch(widgetLoadingStateProvider);

    return DynamicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Statistics'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (isOnline)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshAllWidgets,
                tooltip: 'Refresh all statistics',
              ),
          ],
        ),
        body: !isOnline
            ? _buildOfflineMessage()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Content
                    statsAsync.when(
                      data: (stats) {
                        if (stats == null) {
                          return _buildNoDataMessage();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Locations Section
                            _buildLocationsCard(context, stats, widgetLoadingState),
                            const SizedBox(height: AppDimens.paddingL),

                            // Roles Section
                            _buildRolesCard(context, stats, widgetLoadingState),
                            const SizedBox(height: AppDimens.paddingL),

                            // Membership Section
                            _buildMembershipCard(context, stats, widgetLoadingState),
                            const SizedBox(height: AppDimens.paddingL),

                            // Detailed Breakdown
                            _buildDetailedBreakdownCard(context, stats, widgetLoadingState),
                            const SizedBox(height: AppDimens.paddingXL),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppDimens.paddingXL),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => _buildErrorMessage(error.toString()),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOfflineMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            'Statistics require internet connection',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppDimens.paddingM),
          FilledButton.icon(
            onPressed: () {
              ref.read(statisticsRefreshTriggerProvider.notifier).triggerRefresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            'No statistics available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            'Error loading statistics',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsCard(BuildContext context, FullDashboardStatistics stats, WidgetLoadingState loadingState) {
    final sortedLocations = stats.sortedLocations;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                const Spacer(),
                if (loadingState.isLoadingLocations)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, size: 18, color: Colors.grey.shade600),
                    onPressed: () => ref.read(widgetLoadingStateProvider.notifier).refreshLocations(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Refresh locations',
                  ),
                const SizedBox(width: 8),
                Text(
                  '${sortedLocations.length} locations',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Chart
            if (sortedLocations.isNotEmpty) ...[
              SizedBox(
                height: 150,
                child: _LocationsBarChart(data: sortedLocations),
              ),
              const SizedBox(height: AppDimens.paddingM),

              // List
              ...sortedLocations.take(7).map((entry) => _buildListItem(
                entry.key,
                entry.value,
                stats.locationTotal,
                Colors.red.shade700,
              )),
              if (sortedLocations.length > 7)
                Text(
                  '+ ${sortedLocations.length - 7} more locations',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ] else
              _buildEmptyState('No location data'),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesCard(BuildContext context, FullDashboardStatistics stats, WidgetLoadingState loadingState) {
    final sortedRoles = stats.sortedRoles;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                const Spacer(),
                if (loadingState.isLoadingRoles)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, size: 18, color: Colors.grey.shade600),
                    onPressed: () => ref.read(widgetLoadingStateProvider.notifier).refreshRoles(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Refresh roles',
                  ),
                const SizedBox(width: 8),
                Text(
                  '${sortedRoles.length} roles',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Chart
            if (sortedRoles.isNotEmpty) ...[
              SizedBox(
                height: 220,
                child: _RolesRadarChart(data: stats.roles),
              ),
              const SizedBox(height: AppDimens.paddingM),

              // List
              ...sortedRoles.map((entry) => _buildListItem(
                _formatRoleName(entry.key),
                entry.value,
                stats.roleTotal,
                Colors.purple.shade700,
              )),
            ] else
              _buildEmptyState('No role data'),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard(BuildContext context, FullDashboardStatistics stats, WidgetLoadingState loadingState) {
    final member = stats.membership.member;
    final nonMember = stats.membership.nonMember;
    final total = stats.membershipTotal;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.contact_phone, size: 20, color: Colors.green.shade700),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  'Membership',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                if (loadingState.isLoadingMembership)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, size: 18, color: Colors.grey.shade600),
                    onPressed: () => ref.read(widgetLoadingStateProvider.notifier).refreshMembership(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Refresh membership',
                  ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Pie Chart
            if (total > 0) ...[
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 25,
                          sections: [
                            PieChartSectionData(
                              color: Colors.green,
                              value: member.toDouble(),
                              title: '${(member / total * 100).toStringAsFixed(0)}%',
                              radius: 35,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: Colors.grey,
                              value: nonMember.toDouble(),
                              title: '${(nonMember / total * 100).toStringAsFixed(0)}%',
                              radius: 35,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.paddingM),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Members', member, Colors.green),
                        const SizedBox(height: 8),
                        _buildLegendItem('Non-Members', nonMember, Colors.grey),
                        const SizedBox(height: 8),
                        _buildLegendItem('Total', total, Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              _buildEmptyState('No membership data'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBreakdownCard(BuildContext context, FullDashboardStatistics stats, WidgetLoadingState loadingState) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.list_alt, size: 20, color: colorScheme.primary),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  'Detailed Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (loadingState.isLoadingBreakdown)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, size: 18, color: Colors.grey.shade600),
                    onPressed: () => ref.read(widgetLoadingStateProvider.notifier).refreshBreakdown(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Refresh breakdown',
                  ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Locations breakdown
            _buildBreakdownSection(
              context,
              'Locations',
              Icons.location_on,
              Colors.red.shade700,
              stats.sortedLocations.map((e) => _BreakdownItem(
                label: e.key,
                value: e.value,
                total: stats.locationTotal,
              )).toList(),
            ),
            const Divider(height: AppDimens.paddingL),

            // Roles breakdown
            _buildBreakdownSection(
              context,
              'Roles',
              Icons.work,
              Colors.purple.shade700,
              stats.sortedRoles.map((e) => _BreakdownItem(
                label: _formatRoleName(e.key),
                value: e.value,
                total: stats.roleTotal,
              )).toList(),
            ),
            const Divider(height: AppDimens.paddingL),

            // Membership breakdown
            _buildBreakdownSection(
              context,
              'Membership',
              Icons.contact_phone,
              Colors.green.shade700,
              [
                _BreakdownItem(
                  label: 'Members',
                  value: stats.membership.member,
                  total: stats.membershipTotal,
                ),
                _BreakdownItem(
                  label: 'Non-Members',
                  value: stats.membership.nonMember,
                  total: stats.membershipTotal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<_BreakdownItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.paddingS),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  item.label,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: item.total > 0 ? item.value / item.total : 0,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: Text(
                  '${item.value}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 40,
                child: Text(
                  item.total > 0 ? '${(item.value / item.total * 100).toStringAsFixed(0)}%' : '0%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildListItem(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '$count ($percentage%)',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color == Colors.grey ? Colors.grey.shade700 : color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _formatRoleName(String role) {
    // Capitalize first letter
    if (role.isEmpty) return role;
    return role[0].toUpperCase() + role.substring(1);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Supporting Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _LocationsBarChart extends StatelessWidget {
  final List<MapEntry<String, int>> data;

  const _LocationsBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxCount = data.first.value.toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: data.take(6).map((entry) {
            final barWidth = (entry.value / maxCount) * constraints.maxWidth;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: barWidth / constraints.maxWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade300,
                                Colors.red.shade700,
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
                    width: 30,
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
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

class _RolesRadarChart extends StatelessWidget {
  final Map<String, int> data;

  const _RolesRadarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Get role entries with at least 1 count
    final roleLabels = ['pastor', 'protocol', 'worshiper', 'usher', 'financier', 'servant'];
    final entries = roleLabels.map((role) {
      return MapEntry(role, data[role] ?? 0);
    }).toList();

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: const Color.fromARGB(255, 191, 100, 207).withValues(alpha: 0.3),
            borderColor: const Color.fromARGB(255, 221, 30, 255),
            borderWidth: 2,
            entryRadius: 3,
            dataEntries: entries.map((e) => 
              RadarEntry(value: e.value.toDouble())
            ).toList(),
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: BorderSide(
          color: Theme.of(context).colorScheme.onSurfaceVariant, 
          width: 0.5,
        ),
        titlePositionPercentageOffset: 0.2,
        titleTextStyle: TextStyle(
          fontSize: 9, 
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        getTitle: (index, angle) {
          return RadarChartTitle(
            text: _capitalizeFirst(entries[index].key),
            angle: 0,
          );
        },
        tickCount: 3,
        ticksTextStyle: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
        tickBorderData: BorderSide(
          color: Theme.of(context).colorScheme.onSurfaceVariant, 
          width: 0.5,
        ),
        gridBorderData: BorderSide(
          color: Theme.of(context).colorScheme.onSurfaceVariant, 
          width: 0.3,
        ),
      ),
    );
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _BreakdownItem {
  final String label;
  final int value;
  final int total;

  _BreakdownItem({
    required this.label,
    required this.value,
    required this.total,
  });
}
