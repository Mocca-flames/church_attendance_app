import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/domain/models/attendance.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';

/// Repository interface for attendance operations.
/// Following Clean Architecture, this defines the contract for data operations.
abstract class AttendanceRepository {
  /// Records attendance for a contact.
  /// 
  /// [contactId] - The ID of the contact
  /// [phone] - The phone number (from QR code)
  /// [serviceType] - The type of service (Sunday, Tuesday, Special Event)
  /// [serviceDate] - The date/time of the service
  /// [recordedBy] - The user ID who recorded the attendance
  /// 
  /// Returns the created [Attendance] record.
  /// Throws [AttendanceException] if:
  /// - Contact not found
  /// - Already marked for this service today
  /// - Network error (offline mode will queue for sync)
  Future<Attendance> recordAttendance({
    required int contactId,
    required String phone,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
  });

  /// Records attendance by phone number (from QR scan).
  /// 
  /// This method will:
  /// 1. Find the contact by phone number
  /// 2. Check for duplicates
  /// 3. Record attendance if valid
  /// 
  /// [phone] - The phone number from QR code
  /// [serviceType] - The type of service
  /// [serviceDate] - The date/time of the service
  /// [recordedBy] - The user ID who recorded the attendance
  /// 
  /// Returns the created [Attendance] record.
  /// Throws [AttendanceException] with type:
  /// - [AttendanceExceptionType.contactNotFound] - No contact with this phone
  /// - [AttendanceExceptionType.alreadyMarked] - Already marked today
  /// - [AttendanceExceptionType.networkError] - Network issue (queued for sync)
  Future<Attendance> recordAttendanceByPhone({
    required String phone,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
  });

  /// Gets a contact by phone number.
  /// Returns null if not found.
  Future<Contact?> getContactByPhone(String phone);

  /// Creates a quick contact (from QR scan when contact not found).
  /// 
  /// [phone] - The phone number
  /// [name] - The contact name
  /// [isMember] - Whether the contact is a member (default: false)
  /// [location] - The contact location (optional)
  /// 
  /// Returns the created [Contact].
  Future<Contact> createQuickContact({
    required String phone,
    required String name,
    bool isMember = false,
    String? location,
  });

  /// Checks if attendance already exists for a contact on a specific date and service.
  /// 
  /// Returns true if already marked.
  Future<bool> checkAttendanceExists({
    required int contactId,
    required DateTime date,
    required ServiceType serviceType,
  });

  /// Gets attendance records for a specific date range.
  Future<List<Attendance>> getAttendanceRecords({
    DateTime? dateFrom,
    DateTime? dateTo,
    ServiceType? serviceType,
    int? contactId,
  });

  /// Gets attendance records for a specific contact.
  Future<List<Attendance>> getContactAttendance(int contactId);

  /// Gets attendance summary statistics.
  Future<Map<String, dynamic>> getAttendanceSummary({
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  /// Deletes an attendance record.
  Future<void> deleteAttendance(int attendanceId);

  /// Syncs pending attendance records to the server.
  /// Called by SyncManager when online.
  Future<void> syncPendingRecords();
}

/// Exception types for attendance operations.
enum AttendanceExceptionType {
  contactNotFound,
  alreadyMarked,
  networkError,
  invalidPhone,
  unknown,
}

/// Custom exception for attendance operations.
class AttendanceException implements Exception {
  final String message;
  final AttendanceExceptionType type;

  const AttendanceException(
    this.message, {
    this.type = AttendanceExceptionType.unknown,
  });

  @override
  String toString() => 'AttendanceException: $message';
}
