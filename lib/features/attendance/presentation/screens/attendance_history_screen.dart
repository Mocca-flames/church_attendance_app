import 'package:church_attendance_app/core/constants/app_colors.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/attendance_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Attendance history screen showing past attendance records.
///
/// Features:
/// - Filter by date range
/// - Filter by service type
/// - Show attendance count by service type
class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load attendances when screen is first displayed
    Future.microtask(() {
      ref.read(attendanceHistoryProvider.notifier).loadAttendances();
    });
  }

  Future<void> _selectDateRange() async {
    final currentState = ref.read(attendanceHistoryProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: currentState.dateFrom,
        end: currentState.dateTo,
      ),
    );

    if (picked != null) {
      ref.read(attendanceHistoryProvider.notifier).setDateRange(
            picked.start,
            picked.end,
          );
    }
  }

  void _showServiceTypeFilter() {
    final currentState = ref.read(attendanceHistoryProvider);
    
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Filter by Service Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            RadioGroup<ServiceType?>(
              groupValue: currentState.selectedServiceType,
              onChanged: (value) {
                ref.read(attendanceHistoryProvider.notifier).setServiceType(value);
                Navigator.pop(bottomSheetContext);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RadioListTile<ServiceType?>(
                    value: null,
                    title: Text('All Services'),
                  ),
                  ...ServiceType.values
                      .map((type) => RadioListTile<ServiceType?>(
                            value: type,
                            title: Text(type.displayName),
                            secondary: Text(
                              '${currentState.serviceTypeCounts[type.backendValue] ?? 0}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceHistoryProvider);
    
    // Listen for errors and show snackbar
    ref.listen<AttendanceHistoryState>(attendanceHistoryProvider, (previous, next) {
      if (next.error != null && (previous?.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(attendanceHistoryProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showServiceTypeFilter,
            tooltip: 'Filter by service type',
          ),
          IconButton(
            icon: state.isDownloadingPdf 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: state.isDownloadingPdf
                ? null
                : () => ref.read(attendanceHistoryProvider.notifier).downloadPdf(),
            tooltip: 'Export to PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range selector
          _buildDateRangeSelector(state),

          // Summary cards
          if (!state.isLoading) _buildSummaryCards(state),

          // Attendance list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.attendances.isEmpty
                    ? _buildEmptyState()
                    : _buildAttendanceList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(AttendanceHistoryState state) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: InkWell(
        onTap: _selectDateRange,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: AppDimens.paddingS),
                  Text(
                    '${_formatDate(state.dateFrom)} - ${_formatDate(state.dateTo)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AttendanceHistoryState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Total',
              count: state.attendances.length,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: _SummaryCard(
              title: 'Sunday',
              count: state.serviceTypeCounts[ServiceType.sunday.backendValue] ?? 0,
              color: ServiceType.sunday.color,
            ),
          ),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: _SummaryCard(
              title: 'Tuesday',
              count: state.serviceTypeCounts[ServiceType.tuesday.backendValue] ?? 0,
              color: ServiceType.tuesday.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            'No attendance records',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Try adjusting the date range or filter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(AttendanceHistoryState state) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingL),
      itemCount: state.attendances.length,
      itemBuilder: (context, index) {
        final attendance = state.attendances[index];
        final serviceType = ServiceType.fromBackend(attendance.attendance.serviceType);

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: serviceType.color.withValues(alpha: 0.1),
              child: Icon(
                serviceType.icon,
                color: serviceType.color,
              ),
            ),
            title: Text(attendance.displayName),
            subtitle: Text(
              _formatDateTime(attendance.attendance.serviceDate),
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: serviceType.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                serviceType.displayName,
                style: TextStyle(
                  color: serviceType.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
