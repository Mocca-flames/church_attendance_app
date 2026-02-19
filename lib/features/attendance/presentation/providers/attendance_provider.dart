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

/// Attendance state to track recording status and data.
class AttendanceState {
  final bool isLoading;
  final Attendance? lastRecorded;
  final String? error;
  final List<Attendance> recentRecords;

  const AttendanceState({
    this.isLoading = false,
    this.lastRecorded,
    this.error,
    this.recentRecords = const [],
  });

  AttendanceState copyWith({
    bool? isLoading,
    Attendance? lastRecorded,
    String? error,
    List<Attendance>? recentRecords,
    bool clearError = false,
    bool clearLastRecorded = false,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      lastRecorded: clearLastRecorded ? null : (lastRecorded ?? this.lastRecorded),
      error: clearError ? null : (error ?? this.error),
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

  /// Records attendance for a contact.
  Future<Attendance?> recordAttendance({
    required int contactId,
    required String phone,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final attendance = await _repository.recordAttendance(
        contactId: contactId,
        phone: phone,
        serviceType: serviceType,
        serviceDate: serviceDate,
        recordedBy: recordedBy,
      );
      
      state = state.copyWith(
        isLoading: false,
        lastRecorded: attendance,
        recentRecords: [attendance, ...state.recentRecords],
      );
      
      return attendance;
    } on AttendanceException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Records attendance by phone number (from QR scan).
  Future<Attendance?> recordAttendanceByPhone({
    required String phone,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final attendance = await _repository.recordAttendanceByPhone(
        phone: phone,
        serviceType: serviceType,
        serviceDate: serviceDate,
        recordedBy: recordedBy,
      );
      
      state = state.copyWith(
        isLoading: false,
        lastRecorded: attendance,
        recentRecords: [attendance, ...state.recentRecords],
      );
      
      return attendance;
    } on AttendanceException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Creates a quick contact and records attendance.
  /// Returns a CreateContactAttendanceResult to handle different outcomes.
  Future<CreateContactAttendanceResult> createContactAndRecordAttendance({
    required String phone,
    required String name,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
    bool isMember = false,
    String? location,
  }) async {
    print('DEBUG PROVIDER: createContactAndRecordAttendance called');
    print('DEBUG PROVIDER: phone=$phone, name=$name, isMember=$isMember, location=$location');
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      print('DEBUG PROVIDER: Calling repository.createQuickContact...');
      // Create contact first (returns existing if found)
      final contact = await _repository.createQuickContact(
        phone: phone,
        name: name,
        isMember: isMember,
        location: location,
      );
      print('DEBUG PROVIDER: createQuickContact returned: id=${contact.id}, name=${contact.name}');
      
      // Check if attendance already exists for this contact today
      final alreadyMarked = await _repository.checkAttendanceExists(
        contactId: contact.id,
        date: serviceDate,
        serviceType: serviceType,
      );
      
      if (alreadyMarked) {
        // Contact exists/created but already marked
        state = state.copyWith(
          isLoading: false,
          lastRecorded: null,
        );
        return CreateContactAttendanceResult(
          contactSaved: true,
          alreadyMarked: true,
        );
      }
      
      // Then record attendance
      final attendance = await _repository.recordAttendance(
        contactId: contact.id,
        phone: phone,
        serviceType: serviceType,
        serviceDate: serviceDate,
        recordedBy: recordedBy,
      );
      
      state = state.copyWith(
        isLoading: false,
        lastRecorded: attendance,
        recentRecords: [attendance, ...state.recentRecords],
      );
      
      return CreateContactAttendanceResult(
        attendance: attendance,
        contactSaved: true,
      );
    } on AttendanceException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return CreateContactAttendanceResult(error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return CreateContactAttendanceResult(error: e.toString());
    }
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
