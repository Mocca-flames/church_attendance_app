import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:church_attendance_app/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:church_attendance_app/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:church_attendance_app/features/attendance/domain/models/attendance.dart';
import 'package:church_attendance_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

/// Attendance state to track recording status and data.
class AttendanceState {
  final bool isLoading;
  final bool isSyncing;
  final Attendance? lastRecorded;
  final String? error;
  final String? syncError;
  final List<Attendance> recentRecords;

  const AttendanceState({
    this.isLoading = false,
    this.isSyncing = false,
    this.lastRecorded,
    this.error,
    this.syncError,
    this.recentRecords = const [],
  });

  AttendanceState copyWith({
    bool? isLoading,
    bool? isSyncing,
    Attendance? lastRecorded,
    String? error,
    String? syncError,
    List<Attendance>? recentRecords,
    bool clearError = false,
    bool clearSyncError = false,
    bool clearLastRecorded = false,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      lastRecorded: clearLastRecorded ? null : (lastRecorded ?? this.lastRecorded),
      error: clearError ? null : (error ?? this.error),
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
      recentRecords: recentRecords ?? this.recentRecords,
    );
  }
}

/// Provider for AttendanceLocalDataSource
final attendanceLocalDataSourceProvider = Provider<AttendanceLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return AttendanceLocalDataSource(database);
});

/// Provider for AttendanceRemoteDataSource
final attendanceRemoteDataSourceProvider = Provider<AttendanceRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AttendanceRemoteDataSource(dioClient);
});

/// Provider for AttendanceRepository
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final localDataSource = ref.watch(attendanceLocalDataSourceProvider);
  final remoteDataSource = ref.watch(attendanceRemoteDataSourceProvider);
  final dioClient = ref.watch(dioClientProvider);
  return AttendanceRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    dioClient: dioClient,
  );
});

/// Result class for createContactAndRecordAttendance to handle different outcomes
class CreateContactAttendanceResult {
  final Attendance? attendance;
  final bool contactSaved;
  final bool alreadyMarked;
  final String? error;

  CreateContactAttendanceResult({
    this.attendance,
    this.contactSaved = false,
    this.alreadyMarked = false,
    this.error,
  });
}

/// Attendance state notifier for managing attendance recording state.
class AttendanceNotifier extends Notifier<AttendanceState> {
  late final AttendanceRepository _repository;

  @override
  AttendanceState build() {
    _repository = ref.watch(attendanceRepositoryProvider);
    return const AttendanceState();
  }

  /// Triggers haptic feedback for successful attendance recording.
  void _triggerSuccessHaptic() {
    HapticFeedback.mediumImpact();
  }

  /// Records attendance for a contact with Optimistic UI.
  /// Returns the optimistic attendance immediately while syncing in background.
  Future<Attendance?> recordAttendance({
    required int contactId,
    required String phone,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
  }) async {
    // Create optimistic attendance with a temporary ID (local DB will assign real ID)
    final now = DateTime.now();
    final optimisticAttendance = Attendance(
      id: 0, // Will be replaced by actual ID after local DB insert
      contactId: contactId,
      phone: phone,
      serviceType: serviceType,
      serviceDate: serviceDate,
      recordedBy: recordedBy,
      recordedAt: now,
      isSynced: false, // Mark as not synced for background sync
    );

    // Immediately update UI with optimistic data (no loading state)
    state = state.copyWith(
      isLoading: false,
      isSyncing: true,
      lastRecorded: optimisticAttendance,
      recentRecords: [optimisticAttendance, ...state.recentRecords],
      clearError: true,
    );

    // Trigger haptic feedback for instant tactile confirmation
    _triggerSuccessHaptic();

    // Run actual repository call in background
    _repository.recordAttendance(
      contactId: contactId,
      phone: phone,
      serviceType: serviceType,
      serviceDate: serviceDate,
      recordedBy: recordedBy,
    ).then((attendance) {
      // On success: update with actual attendance data
      // Replace optimistic record with actual record
      final updatedRecords = state.recentRecords.map((r) {
        if (r.contactId == attendance.contactId &&
            r.serviceType == attendance.serviceType &&
            r.serviceDate.year == attendance.serviceDate.year &&
            r.serviceDate.month == attendance.serviceDate.month &&
            r.serviceDate.day == attendance.serviceDate.day) {
          return attendance;
        }
        return r;
      }).toList();

      state = state.copyWith(
        isSyncing: false,
        lastRecorded: attendance,
        recentRecords: updatedRecords,
      );
    }).catchError((error) {
      // On error: show subtle sync error but keep optimistic data in UI
      final errorMessage = error is AttendanceException
          ? error.message
          : error.toString();
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Sync pending: $errorMessage',
      );
    });

    // Return optimistic attendance immediately
    return optimisticAttendance;
  }

  /// Records attendance by phone number (from QR scan) with Optimistic UI.
  /// Returns the optimistic attendance immediately while syncing in background.
  Future<Attendance?> recordAttendanceByPhone({
    required String phone,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
  }) async {
    // Create optimistic attendance
    final now = DateTime.now();
    final optimisticAttendance = Attendance(
      id: 0, // Will be replaced by actual ID after local DB insert
      contactId: 0, // Will be determined by repository
      phone: phone,
      serviceType: serviceType,
      serviceDate: serviceDate,
      recordedBy: recordedBy,
      recordedAt: now,
      isSynced: false, // Mark as not synced for background sync
    );

    // Immediately update UI with optimistic data (no loading state)
    state = state.copyWith(
      isLoading: false,
      isSyncing: true,
      lastRecorded: optimisticAttendance,
      recentRecords: [optimisticAttendance, ...state.recentRecords],
      clearError: true,
    );

    // Trigger haptic feedback for instant tactile confirmation
    _triggerSuccessHaptic();

    // Run actual repository call in background
    _repository.recordAttendanceByPhone(
      phone: phone,
      serviceType: serviceType,
      serviceDate: serviceDate,
      recordedBy: recordedBy,
    ).then((attendance) {
      // On success: update with actual attendance data
      // Replace optimistic record with actual record
      final updatedRecords = state.recentRecords.map((r) {
        if (r.phone == attendance.phone &&
            r.serviceType == attendance.serviceType &&
            r.serviceDate.year == attendance.serviceDate.year &&
            r.serviceDate.month == attendance.serviceDate.month &&
            r.serviceDate.day == attendance.serviceDate.day) {
          return attendance;
        }
        return r;
      }).toList();

      state = state.copyWith(
        isSyncing: false,
        lastRecorded: attendance,
        recentRecords: updatedRecords,
      );
    }).catchError((error) {
      // On error: show subtle sync error but keep optimistic data in UI
      final errorMessage = error is AttendanceException
          ? error.message
          : error.toString();
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Sync pending: $errorMessage',
      );
    });

    // Return optimistic attendance immediately
    return optimisticAttendance;
  }

  /// Creates a quick contact and records attendance with Optimistic UI.
  /// Returns the optimistic result immediately while syncing in background.
  Future<CreateContactAttendanceResult> createContactAndRecordAttendance({
    required String phone,
    required String name,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
    bool isMember = false,
    String? location,
  }) async {
    // Create optimistic attendance
    final now = DateTime.now();
    final optimisticAttendance = Attendance(
      id: 0, // Will be replaced by actual ID after local DB insert
      contactId: 0, // Will be determined after contact creation
      phone: phone,
      serviceType: serviceType,
      serviceDate: serviceDate,
      recordedBy: recordedBy,
      recordedAt: now,
      isSynced: false, // Mark as not synced for background sync
    );

    // Immediately update UI with optimistic data (no loading state)
    state = state.copyWith(
      isLoading: false,
      isSyncing: true,
      lastRecorded: optimisticAttendance,
      recentRecords: [optimisticAttendance, ...state.recentRecords],
      clearError: true,
    );

    // Trigger haptic feedback for instant tactile confirmation
    _triggerSuccessHaptic();

    // Return optimistic result immediately
    final optimisticResult = CreateContactAttendanceResult(
      attendance: optimisticAttendance,
      contactSaved: true,
    );

    // Run actual operations in background
    _repository.createQuickContact(
      phone: phone,
      name: name,
      isMember: isMember,
      location: location,
    ).then((contact) async {
      // Check if attendance already exists
      final alreadyMarked = await _repository.checkAttendanceExists(
        contactId: contact.id,
        date: serviceDate,
        serviceType: serviceType,
      );

      if (alreadyMarked) {
        state = state.copyWith(
          isSyncing: false,
          lastRecorded: null,
        );
        return;
      }

      // Record attendance
      final attendance = await _repository.recordAttendance(
        contactId: contact.id,
        phone: phone,
        serviceType: serviceType,
        serviceDate: serviceDate,
        recordedBy: recordedBy,
      );

      // Replace optimistic record with actual record
      final updatedRecords = state.recentRecords.map((r) {
        if (r.phone == attendance.phone &&
            r.serviceType == attendance.serviceType &&
            r.serviceDate.year == attendance.serviceDate.year &&
            r.serviceDate.month == attendance.serviceDate.month &&
            r.serviceDate.day == attendance.serviceDate.day) {
          return attendance;
        }
        return r;
      }).toList();

      state = state.copyWith(
        isSyncing: false,
        lastRecorded: attendance,
        recentRecords: updatedRecords,
      );
    }).catchError((error) {
      // On error: show subtle sync error but keep optimistic data in UI
      final errorMessage = error is AttendanceException
          ? error.message
          : error.toString();
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Sync pending: $errorMessage',
      );
    });

    return optimisticResult;
  }

  /// Gets a contact by phone number.
  Future<Contact?> getContactByPhone(String phone) async {
    return _repository.getContactByPhone(phone);
  }

  /// Checks if attendance already exists.
  Future<bool> checkAttendanceExists({
    required int contactId,
    required DateTime date,
    required ServiceType serviceType,
  }) async {
    return _repository.checkAttendanceExists(
      contactId: contactId,
      date: date,
      serviceType: serviceType,
    );
  }

  /// Gets attendance records.
  Future<List<Attendance>> getAttendanceRecords({
    DateTime? dateFrom,
    DateTime? dateTo,
    ServiceType? serviceType,
    int? contactId,
  }) async {
    return _repository.getAttendanceRecords(
      dateFrom: dateFrom,
      dateTo: dateTo,
      serviceType: serviceType,
      contactId: contactId,
    );
  }

  /// Clears the error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clears the last recorded attendance.
  void clearLastRecorded() {
    state = state.copyWith(clearLastRecorded: true);
  }
}

/// Provider for AttendanceNotifier
final attendanceProvider = NotifierProvider<AttendanceNotifier, AttendanceState>(() {
  return AttendanceNotifier();
});
