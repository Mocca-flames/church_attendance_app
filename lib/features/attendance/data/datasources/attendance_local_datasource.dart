import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/domain/models/attendance.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:drift/drift.dart' as drift;

/// Local data source for attendance operations.
/// Handles all local database operations using Drift.
class AttendanceLocalDataSource {
  final AppDatabase _db;

  AttendanceLocalDataSource(this._db);

  /// Gets a contact by phone number.
  /// Phone number is normalized to +27XXXXXXXXX format before search.
  Future<Contact?> getContactByPhone(String phone) async {
    final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(phone);
    if (normalizedPhone == null) return null;
    
    final contactData = await _db.getContactByPhone(normalizedPhone);
    if (contactData == null) return null;
    return Contact.fromJson(contactData.toJson());
  }

  /// Gets a contact by ID.
  Future<Contact?> getContactById(int id) async {
    final contactData = await _db.getContactById(id);
    if (contactData == null) return null;
    return Contact.fromJson(contactData.toJson());
  }

  /// Creates a new contact.
  /// Phone number is normalized to +27XXXXXXXXX format before storing.
  Future<Contact> createContact({
    required String phone,
    String? name,
    Map<String, dynamic>? metadata,
  }) async {
    final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(phone);
    if (normalizedPhone == null) {
      throw ArgumentError('Invalid phone number format: $phone');
    }
    
    final companion = ContactsCompanion(
      phone: drift.Value(normalizedPhone),
      name: drift.Value(name),
      metadata: drift.Value(metadata?.toString()),
      createdAt: drift.Value(DateTime.now()),
    );

    final id = await _db.insertContact(companion);
    final contactData = await _db.getContactById(id);
    return Contact.fromJson(contactData!.toJson());
  }

  /// Checks if attendance already exists for a contact on a specific date and service.
  Future<bool> checkAttendanceExists({
    required int contactId,
    required DateTime date,
    required ServiceType serviceType,
  }) async {
    final existing = await _db.checkAttendanceExists(
      contactId,
      date,
      serviceType.backendValue,
    );
    return existing != null;
  }

  /// Creates a new attendance record locally.
  /// Phone number is normalized to +27XXXXXXXXX format before storing.
  Future<Attendance> createAttendance({
    required int contactId,
    required String phone,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
  }) async {
    final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(phone);
    if (normalizedPhone == null) {
      throw ArgumentError('Invalid phone number format: $phone');
    }
    
    final companion = AttendancesCompanion(
      contactId: drift.Value(contactId),
      phone: drift.Value(normalizedPhone),
      serviceType: drift.Value(serviceType.backendValue),
      serviceDate: drift.Value(serviceDate),
      recordedBy: drift.Value(recordedBy),
      recordedAt: drift.Value(DateTime.now()),
      isSynced: const drift.Value(false),
    );

    final id = await _db.insertAttendance(companion);
    
    // Fetch the created attendance
    final attendances = await _db.getAllAttendances();
    final attendanceData = attendances.firstWhere((a) => a.id == id);
    
    return Attendance.fromJson(attendanceData.toJson());
  }

  /// Gets attendance records with optional filters.
  Future<List<Attendance>> getAttendanceRecords({
    DateTime? dateFrom,
    DateTime? dateTo,
    ServiceType? serviceType,
    int? contactId,
  }) async {
    List<AttendanceEntity> records;
    
    if (dateFrom != null && dateTo != null) {
      records = await _db.getAttendancesByDateRange(dateFrom, dateTo);
    } else if (contactId != null) {
      records = await _db.getAttendancesByContact(contactId);
    } else {
      records = await _db.getAllAttendances();
    }

    // Filter by service type if provided
    if (serviceType != null) {
      records = records.where((r) => r.serviceType == serviceType.backendValue).toList();
    }

    return records.map((r) => Attendance.fromJson(r.toJson())).toList();
  }

  /// Gets attendance records for a specific contact.
  Future<List<Attendance>> getContactAttendance(int contactId) async {
    final records = await _db.getAttendancesByContact(contactId);
    return records.map((r) => Attendance.fromJson(r.toJson())).toList();
  }

  /// Gets unsynced attendance records.
  Future<List<Attendance>> getUnsyncedAttendances() async {
    final allRecords = await _db.getAllAttendances();
    final unsynced = allRecords.where((r) => !r.isSynced).toList();
    return unsynced.map((r) => Attendance.fromJson(r.toJson())).toList();
  }

  /// Marks an attendance record as synced.
  Future<void> markAsSynced(int attendanceId, int serverId) async {
    await _db.updateAttendance(
      attendanceId,
      AttendancesCompanion(
        isSynced: const drift.Value(true),
        serverId: drift.Value(serverId),
      ),
    );
  }

  /// Deletes an attendance record.
  Future<void> deleteAttendance(int attendanceId) async {
    await (_db.delete(_db.attendances)
          ..where((t) => t.id.equals(attendanceId)))
        .go();
  }

  /// Adds an attendance record to the sync queue.
  Future<void> addToSyncQueue(Attendance attendance) async {
    await _db.insertSyncQueueItem(
      SyncQueueCompanion(
        entityType: const drift.Value('attendance'),
        action: const drift.Value('create'),
        localId: drift.Value(attendance.id),
        data: drift.Value(attendance.toJson().toString()),
        status: const drift.Value('pending'),
        createdAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Gets attendance summary statistics.
  Future<Map<String, dynamic>> getAttendanceSummary({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final records = await getAttendanceRecords(
      dateFrom: dateFrom,
      dateTo: dateTo,
    );

    final byServiceType = <String, int>{};
    for (final record in records) {
      final type = record.serviceType.backendValue;
      byServiceType[type] = (byServiceType[type] ?? 0) + 1;
    }

    return {
      'total_attendance': records.length,
      'by_service_type': byServiceType,
    };
  }

  /// Marks a contact as synced with the server ID.
  Future<void> markContactAsSynced(int contactId, int serverId) async {
    await _db.updateContactFields(
      id: contactId,
      serverId: serverId,
      isSynced: true,
    );
  }

  /// Adds a contact to the sync queue for later sync.
  Future<void> addContactToSyncQueue({
    required int contactId,
    required Map<String, dynamic> data,
  }) async {
    await _db.insertSyncQueueItem(
      SyncQueueCompanion(
        entityType: const drift.Value('contact'),
        action: const drift.Value('create'),
        localId: drift.Value(contactId),
        data: drift.Value(data.toString()),
        status: const drift.Value('pending'),
        createdAt: drift.Value(DateTime.now()),
      ),
    );
  }
}
