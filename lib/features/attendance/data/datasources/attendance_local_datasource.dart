import 'dart:convert';

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
    if (contactData == null) {
     
      return null;
    }

    // Convert database entity to JSON with proper key mapping
    // Database uses 'metadata' but Contact model expects 'metadata_'
    final json = contactData.toJson();
    
    if (json.containsKey('metadata') && !json.containsKey('metadata_')) {
      json['metadata_'] = json.remove('metadata');
    }
    // Convert status to string if it's an int (from legacy data or sync)
    if (json.containsKey('status') && json['status'] is int) {
      json['status'] = (json['status'] as int).toString();
    }
    // Convert createdAt from int (epoch ms) to ISO8601 string
    if (json.containsKey('createdAt') && json['createdAt'] is int) {
      final epochMs = json['createdAt'] as int;
      json['createdAt'] = DateTime.fromMillisecondsSinceEpoch(epochMs).toIso8601String();
     
    }
    // Map createdAt to created_at for Contact model compatibility
    // (DB uses createdAt but Contact.fromJson expects created_at)
    if (json.containsKey('createdAt') && !json.containsKey('created_at')) {
      json['created_at'] = json.remove('createdAt');
    }
  
    try {
      final result = Contact.fromJson(json);
    
      return result;
    } catch (e) {
      
      rethrow;
    }
  }

  /// Gets a contact by ID.
  Future<Contact?> getContactById(int id) async {
   
    final contactData = await _db.getContactById(id);
   
    if (contactData == null) return null;
    // Convert database entity to JSON with proper key mapping
    // Database uses 'metadata' but Contact model expects 'metadata_'
    final json = contactData.toJson();
   
    if (json.containsKey('metadata') && !json.containsKey('metadata_')) {
      json['metadata_'] = json.remove('metadata');
    }
    // Convert status to string if it's an int (from legacy data or sync)
    if (json.containsKey('status') && json['status'] is int) {
      json['status'] = (json['status'] as int).toString();
    }
    // Convert createdAt from int (epoch ms) to ISO8601 string
    if (json.containsKey('createdAt') && json['createdAt'] is int) {
      final epochMs = json['createdAt'] as int;
      json['createdAt'] = DateTime.fromMillisecondsSinceEpoch(epochMs).toIso8601String();
     
    }
    // Map createdAt to created_at for Contact model compatibility
    // (DB uses createdAt but Contact.fromJson expects created_at)
    if (json.containsKey('createdAt') && !json.containsKey('created_at')) {
      json['created_at'] = json.remove('createdAt');
    }
   
    return Contact.fromJson(json);
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
    
    // Convert metadata to JSON string if provided
    String? metadataString;
    if (metadata != null) {
      metadataString = jsonEncode(metadata);
    }

    final companion = ContactsCompanion(
      phone: drift.Value(normalizedPhone),
      name: drift.Value(name),
      metadata: drift.Value(metadataString),
      createdAt: drift.Value(DateTime.now()),
    );

    final id = await _db.insertContact(companion);
    final contactData = await _db.getContactById(id);
    // Convert database values to formats expected by Contact.fromJson
    final json = contactData!.toJson();
    // Database uses 'metadata' but Contact model expects 'metadata_'
    if (json.containsKey('metadata') && !json.containsKey('metadata_')) {
      json['metadata_'] = json.remove('metadata');
    }
    // Convert status to string if it's an int (for consistency)
    if (json.containsKey('status') && json['status'] is int) {
      json['status'] = (json['status'] as int).toString();
    }
    // Convert createdAt from int (epoch ms) to ISO8601 string
    if (json.containsKey('createdAt') && json['createdAt'] is int) {
      final epochMs = json['createdAt'] as int;
      json['createdAt'] = DateTime.fromMillisecondsSinceEpoch(epochMs).toIso8601String();
    }
    return Contact.fromJson(json);
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
    
    // Convert database values to formats expected by Attendance.fromJson
    final json = attendanceData.toJson();
    _convertAttendanceJson(json);
  
    
    try {
      final result = Attendance.fromJson(json);
   
      return result;
    } catch (e ) {
     
      rethrow;
    }
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

    return records.map((r) {
      final json = r.toJson();
      _convertAttendanceJson(json);
      return Attendance.fromJson(json);
    }).toList();
  }

  /// Gets attendance records for a specific contact.
  Future<List<Attendance>> getContactAttendance(int contactId) async {
    final records = await _db.getAttendancesByContact(contactId);
    return records.map((r) {
      final json = r.toJson();
      _convertAttendanceJson(json);
      return Attendance.fromJson(json);
    }).toList();
  }

  /// Gets unsynced attendance records.
  Future<List<Attendance>> getUnsyncedAttendances() async {
    final allRecords = await _db.getAllAttendances();
    final unsynced = allRecords.where((r) => !r.isSynced).toList();
    return unsynced.map((r) {
      final json = r.toJson();
      _convertAttendanceJson(json);
      return Attendance.fromJson(json);
    }).toList();
  }
  
  /// Helper method to convert database values to Attendance.fromJson expected formats
  void _convertAttendanceJson(Map<String, dynamic> json) {
    // DEBUG: Log all keys before conversion
    
    
    // Map database keys to Attendance model expected keys
    // Database uses camelCase (contactId, recordedBy) but model expects snake_case (contact_id, recorded_by)
    if (json.containsKey('contactId') && !json.containsKey('contact_id')) {
      json['contact_id'] = json.remove('contactId');
    }
    if (json.containsKey('recordedBy') && !json.containsKey('recorded_by')) {
      json['recorded_by'] = json.remove('recordedBy');
    }
    
    // Convert serviceType from backend value to enum name
    // Store in service_type (with underscore) as expected by Attendance model
    if (json.containsKey('serviceType') && json['serviceType'] is String) {
      json['service_type'] = ServiceType.fromBackend(json['serviceType'] as String).name;
    }
    
    // Convert serviceDate from epoch milliseconds to ISO8601 string
    // MUST rename key to service_date (snake_case) as expected by Attendance model
    if (json.containsKey('serviceDate') && json['serviceDate'] is int) {
      final epochMs = json['serviceDate'] as int;
      json['service_date'] = DateTime.fromMillisecondsSinceEpoch(epochMs).toIso8601String();
      json.remove('serviceDate');
     
    }
    
    // Convert recordedAt from epoch milliseconds to ISO8601 string
    // MUST rename key to recorded_at (snake_case) as expected by Attendance model
    if (json.containsKey('recordedAt') && json['recordedAt'] is int) {
      final epochMs = json['recordedAt'] as int;
      json['recorded_at'] = DateTime.fromMillisecondsSinceEpoch(epochMs).toIso8601String();
      json.remove('recordedAt');
   
    }
    
  
    
    // Handle serverId - ensure it's not passed as null to non-nullable field
    if (json.containsKey('serverId') && json['serverId'] == null) {
     
      json.remove('serverId');
    }
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
        data: drift.Value(jsonEncode(attendance.toJson())),
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
        data: drift.Value(jsonEncode(data)),
        status: const drift.Value('pending'),
        createdAt: drift.Value(DateTime.now()),
      ),
    );
  }

  /// Updates an existing contact with new name, tags, and location.
  /// This is used when marking attendance for contacts where phone == name.
  Future<Contact> updateContactDetails({
    required int contactId,
    String? name,
    bool isMember = false,
    String? location,
  }) async {

    // Get existing contact
    final existingContact = await getContactById(contactId);
    if (existingContact == null) {
      throw ArgumentError('Contact not found: $contactId');
    }

  

    // Parse existing metadata
    Map<String, dynamic> metadata = {};
    if (existingContact.metadata != null && existingContact.metadata!.isNotEmpty) {
      try {
        metadata = jsonDecode(existingContact.metadata!) as Map<String, dynamic>;
      } catch (e) {
        // Invalid JSON, start fresh
        metadata = {};
      }
    }

    // Update tags - add 'member' if isMember is true
    // Location is stored as a tag (e.g., 'kanana', 'church')
    List<String> tags = [];
    if (metadata.containsKey('tags') && metadata['tags'] is List) {
      tags = List<String>.from(metadata['tags']);
    }
    if (isMember && !tags.contains('member')) {
      tags.add('member');
    }
    // Add location as a tag if provided
    if (location != null && location.isNotEmpty && !tags.contains(location)) {
      tags.add(location);
    }
    metadata['tags'] = tags;

    // Build metadata string
    final metadataString = jsonEncode(metadata);

    // Update contact in database
    await _db.updateContactFields(
      id: contactId,
      name: name,
      metadata: metadataString,
      isSynced: false, // Mark as unsynced so it gets synced later
    );

    // Fetch and return updated contact
    final updatedContact = await getContactById(contactId);
    return updatedContact!;
  }

  /// Gets attendance history with contact names for display.
  Future<List<AttendanceWithContact>> getAttendanceHistory({
    DateTime? dateFrom,
    DateTime? dateTo,
    ServiceType? serviceType,
  }) async {
    List<AttendanceWithContact> results;

    if (serviceType != null) {
      // Get by service type first, then filter by date range
      results = await _db.getAttendancesWithContactsByServiceType(
        serviceType.backendValue,
      );
      
      // Filter by date range in memory
      if (dateFrom != null || dateTo != null) {
        results = results.where((a) {
          final serviceDate = a.attendance.serviceDate;
          
          if (dateFrom != null) {
            final fromStartOfDay = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
            if (serviceDate.isBefore(fromStartOfDay)) return false;
          }
          
          if (dateTo != null) {
            final toEndOfDay = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59);
            if (serviceDate.isAfter(toEndOfDay)) return false;
          }
          
          return true;
        }).toList();
      }
    } else if (dateFrom != null && dateTo != null) {
      // Get by date range
      results = await _db.getAttendancesWithContactsByDateRange(
        dateFrom,
        dateTo.add(const Duration(days: 1)),
      );
    } else {
      // Get all
      final allAttendances = await _db.getAllAttendances();
      final allContacts = await _db.getAllContacts();
      
      results = allAttendances.map((attendance) {
        final contact = allContacts.where((c) => c.id == attendance.contactId).firstOrNull;
        return AttendanceWithContact(
          attendance: attendance,
          contactName: contact?.name,
        );
      }).toList();
    }

    return results;
  }

  /// Calculates service type counts from attendance records.
  Map<String, int> calculateServiceTypeCounts(List<AttendanceWithContact> attendances) {
    final counts = <String, int>{};
    for (final attendance in attendances) {
      counts[attendance.attendance.serviceType] =
          (counts[attendance.attendance.serviceType] ?? 0) + 1;
    }
    return counts;
  }
}
