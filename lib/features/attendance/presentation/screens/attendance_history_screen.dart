import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/main.dart';
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
  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dateTo = DateTime.now();
  ServiceType? _selectedServiceType;
  bool _isLoading = true;
  List<AttendanceWithContact> _attendances = [];
  Map<String, int> _serviceTypeCounts = {};

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    setState(() => _isLoading = true);

    try {
      final database = ref.read(databaseProvider);
      List<AttendanceWithContact> results;

      if (_selectedServiceType != null) {
        results = await database.getAttendancesWithContactsByServiceType(
          _selectedServiceType!.backendValue,
        );
        // Filter by date range in memory
        results = results
            .where((a) =>
                a.attendance.serviceDate
                    .isAfter(_dateFrom.subtract(const Duration(days: 1))) &&
                a.attendance.serviceDate.isBefore(_dateTo.add(const Duration(days: 1))))
            .toList();
      } else {
        results = await database.getAttendancesWithContactsByDateRange(
          _dateFrom,
          _dateTo.add(const Duration(days: 1)),
        );
      }

      // Calculate service type counts
      final counts = <String, int>{};
      for (final attendance in results) {
        counts[attendance.attendance.serviceType] =
            (counts[attendance.attendance.serviceType] ?? 0) + 1;
      }

      setState(() {
        _attendances = results;
        _serviceTypeCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _dateFrom, end: _dateTo),
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
      _loadAttendances();
    }
  }

  void _showServiceTypeFilter() {
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
              groupValue:
                  _selectedServiceType, // Changed from 'value' to 'groupValue'
              onChanged: (value) {
                setState(() => _selectedServiceType = value);
                Navigator.pop(bottomSheetContext);
                _loadAttendances();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RadioListTile<ServiceType?>(
                    value: null,
                    title: Text('All Services'),
                    // onChanged is handled by RadioGroup, but keep the parameter structure
                  ),
                  ...ServiceType.values
                      .map((type) => RadioListTile<ServiceType?>(
                            value: type,
                            title: Text(type.displayName),
                            secondary: Text(
                              '${_serviceTypeCounts[type.backendValue] ?? 0}',
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
        ],
      ),
      body: Column(
        children: [
          // Date range selector
          _buildDateRangeSelector(),

          // Summary cards
          if (!_isLoading) _buildSummaryCards(),

          // Attendance list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendances.isEmpty
                    ? _buildEmptyState()
                    : _buildAttendanceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
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
                    '${_formatDate(_dateFrom)} - ${_formatDate(_dateTo)}',
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

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Total',
              count: _attendances.length,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: _SummaryCard(
              title: 'Sunday',
              count: _serviceTypeCounts[ServiceType.sunday.backendValue] ?? 0,
              color: ServiceType.sunday.color,
            ),
          ),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: _SummaryCard(
              title: 'Tuesday',
              count: _serviceTypeCounts[ServiceType.tuesday.backendValue] ?? 0,
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

  Widget _buildAttendanceList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingL),
      itemCount: _attendances.length,
      itemBuilder: (context, index) {
        final attendance = _attendances[index];
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
