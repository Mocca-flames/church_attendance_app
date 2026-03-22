import 'dart:io';

import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// State for attendance history screen.
class AttendanceHistoryState {
  final bool isLoading;
  final List<AttendanceWithContact> attendances;
  final Map<String, int> serviceTypeCounts;
  final DateTime dateFrom;
  final DateTime dateTo;
  final ServiceType? selectedServiceType;
  final String? error;
  final bool isDownloadingPdf;

  const AttendanceHistoryState({
    required this.dateFrom, required this.dateTo, this.isLoading = false,
    this.attendances = const [],
    this.serviceTypeCounts = const {},
    this.selectedServiceType,
    this.error,
    this.isDownloadingPdf = false,
  });

  AttendanceHistoryState copyWith({
    bool? isLoading,
    List<AttendanceWithContact>? attendances,
    Map<String, int>? serviceTypeCounts,
    DateTime? dateFrom,
    DateTime? dateTo,
    ServiceType? selectedServiceType,
    bool clearSelectedServiceType = false,
    String? error,
    bool clearError = false,
    bool? isDownloadingPdf,
  }) {
    return AttendanceHistoryState(
      isLoading: isLoading ?? this.isLoading,
      attendances: attendances ?? this.attendances,
      serviceTypeCounts: serviceTypeCounts ?? this.serviceTypeCounts,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      selectedServiceType: clearSelectedServiceType ? null : (selectedServiceType ?? this.selectedServiceType),
      error: clearError ? null : (error ?? this.error),
      isDownloadingPdf: isDownloadingPdf ?? this.isDownloadingPdf,
    );
  }
}

/// Notifier for attendance history state.
class AttendanceHistoryNotifier extends Notifier<AttendanceHistoryState> {
  late final AttendanceRepository _repository;

  @override
  AttendanceHistoryState build() {
    _repository = ref.watch(attendanceRepositoryProvider);
    
    // Initialize with default date range (last 30 days)
    final now = DateTime.now();
    return AttendanceHistoryState(
      dateFrom: now.subtract(const Duration(days: 30)),
      dateTo: now,
    );
  }

  /// Loads attendance history with current filters.
  Future<void> loadAttendances() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final attendances = await _repository.getAttendanceHistory(
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        serviceType: state.selectedServiceType,
      );

      // Calculate service type counts
      final counts = <String, int>{};
      for (final attendance in attendances) {
        counts[attendance.attendance.serviceType] =
            (counts[attendance.attendance.serviceType] ?? 0) + 1;
      }

      state = state.copyWith(
        isLoading: false,
        attendances: attendances,
        serviceTypeCounts: counts,
      );
    } on AttendanceException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Sets the date range for filtering.
  void setDateRange(DateTime dateFrom, DateTime dateTo) {
    state = state.copyWith(
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    loadAttendances();
  }

  /// Sets the service type filter.
  void setServiceType(ServiceType? serviceType) {
    if (serviceType == null) {
      state = state.copyWith(clearSelectedServiceType: true);
    } else {
      state = state.copyWith(selectedServiceType: serviceType);
    }
    loadAttendances();
  }

  /// Downloads attendance as PDF and shares it.
  Future<void> downloadPdf() async {
    state = state.copyWith(isDownloadingPdf: true, clearError: true);

    try {
      // Determine whether to use single date or date range
      // If dateFrom and dateTo are the same day, use the new date parameter
      // Otherwise, use the date_from/date_to range
      final isSingleDay = _isSameDay(state.dateFrom, state.dateTo);
      
      final pdfBytes = await _repository.downloadAttendancePdf(
        dateFrom: isSingleDay ? null : state.dateFrom,
        dateTo: isSingleDay ? null : state.dateTo,
        serviceType: state.selectedServiceType,
        date: isSingleDay ? state.dateFrom : null,
      );

      // Save to persistent documents directory and share
      final documentsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${documentsDir.path}/attendance_export_$timestamp.pdf');
      await file.writeAsBytes(pdfBytes);

      // Share the PDF file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Attendance Export',
          subject: 'Attendance Export ${_formatDate(state.dateFrom)} - ${_formatDate(state.dateTo)}',
        ),
      );

      state = state.copyWith(isDownloadingPdf: false);
    } on AttendanceException catch (e) {
      state = state.copyWith(
        isDownloadingPdf: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isDownloadingPdf: false,
        error: e.toString(),
      );
    }
  }

  /// Clears any error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Checks if two dates are the same day (ignoring time).
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}

/// Provider for AttendanceHistoryNotifier
final attendanceHistoryProvider = NotifierProvider<AttendanceHistoryNotifier, AttendanceHistoryState>(() {
  return AttendanceHistoryNotifier();
});
