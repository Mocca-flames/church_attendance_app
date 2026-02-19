import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:church_attendance_app/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:church_attendance_app/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:church_attendance_app/features/attendance/domain/models/attendance.dart';
import 'package:church_attendance_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Implementation of [AttendanceRepository].
/// 
/// Follows Clean Architecture principles:
/// - Coordinates between local and remote data sources
/// - Implements offline-first strategy
/// - Handles sync queue for offline operations
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDataSource _localDataSource;
  final AttendanceRemoteDataSource _remoteDataSource;
  final DioClient _dioClient;

  AttendanceRepositoryImpl({
    required AttendanceLocalDataSource localDataSource,
    required AttendanceRemoteDataSource remoteDataSource,
    required DioClient dioClient,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _dioClient = dioClient;

  @override
  Future<Attendance> recordAttendance({
    required int contactId,
    required String phone,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
  }) async {
    // Check for duplicate
    final exists = await _localDataSource.checkAttendanceExists(
      contactId: contactId,
      date: serviceDate,
      serviceType: serviceType,
    );

    if (exists) {
      throw const AttendanceException(
        'Already marked for this service today',
        type: AttendanceExceptionType.alreadyMarked,
      );
    }

    // Create attendance record locally
    final attendance = await _localDataSource.createAttendance(
      contactId: contactId,
      phone: phone,
      serviceType: serviceType,
      serviceDate: serviceDate,
      recordedBy: recordedBy,
    );

    // Try to sync to server
    if (await _isOnline()) {
      try {
        print('DEBUG REPO: Online, calling remote recordAttendance...');
        final serverAttendance = await _remoteDataSource.recordAttendance(
          contactId: contactId,
          phone: phone,
          serviceType: serviceType,
          serviceDate: serviceDate,
          recordedBy: recordedBy,
        );
        print('DEBUG REPO: Remote recordAttendance succeeded, serverId=${serverAttendance.serverId}');

        // Update local record with server ID and mark as synced
        await _localDataSource.markAsSynced(
          attendance.id,
          serverAttendance.serverId ?? 0,
        );
        print('DEBUG REPO: Local record marked as synced');

        return serverAttendance;
      } on AttendanceRemoteException catch (e) {
        print('DEBUG REPO: AttendanceRemoteException: ${e.message}, isNetworkError: ${e.isNetworkError}');
        // If network error, add to sync queue
        if (e.isNetworkError) {
          await _localDataSource.addToSyncQueue(attendance);
        }
        // Return local record anyway
        return attendance;
      } catch (e, stack) {
        print('DEBUG REPO: Unexpected error: $e');
        print('DEBUG REPO: Stack: $stack');
        // Add to sync queue and return local record
        await _localDataSource.addToSyncQueue(attendance);
        return attendance;
      }
    } else {
      print('DEBUG REPO: Offline, adding to sync queue');
      // Offline: add to sync queue
      await _localDataSource.addToSyncQueue(attendance);
      return attendance;
    }
  }

  @override
  Future<Attendance> recordAttendanceByPhone({
    required String phone,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
  }) async {
    // Find contact by phone
    final contact = await _localDataSource.getContactByPhone(phone);
    
    if (contact == null) {
      throw const AttendanceException(
        'Contact not found',
        type: AttendanceExceptionType.contactNotFound,
      );
    }

    // Record attendance
    return recordAttendance(
      contactId: contact.id,
      phone: phone,
      serviceType: serviceType,
      serviceDate: serviceDate,
      recordedBy: recordedBy,
    );
  }

  @override
  Future<Contact?> getContactByPhone(String phone) async {
    return _localDataSource.getContactByPhone(phone);
  }

  @override
  Future<Contact> createQuickContact({
    required String phone,
    required String name,
    bool isMember = false,
    String? location,
  }) async {
    print('DEBUG REPO: createQuickContact called with phone=$phone, name=$name');
    // Check if contact already exists with this phone number
    print('DEBUG REPO: Calling getContactByPhone...');
    final existingContact = await _localDataSource.getContactByPhone(phone);
    print('DEBUG REPO: getContactByPhone returned: $existingContact');
    
    if (existingContact != null) {
      print('DEBUG REPO: Contact found - id=${existingContact.id}, name=${existingContact.name}, phone=${existingContact.phone}');
      // Check if this is a contact where phone == name (no real name was entered)
      // In this case, we need to update the contact with the new name, tags, and location
      if (existingContact.name != null && existingContact.name == existingContact.phone) {
        print('DEBUG REPO: Contact name == phone, will update contact details');
        // This contact has phone == name, need to update it
        print('DEBUG REPO: About to call updateContactDetails...');
        print('DEBUG: Updating contact ${existingContact.id} - old name: ${existingContact.name}, new name: $name, isMember: $isMember, location: $location');
        final updatedContact = await _localDataSource.updateContactDetails(
          contactId: existingContact.id,
          name: name,
          isMember: isMember,
          location: location,
        );
        print('DEBUG: Updated contact result: ${updatedContact.name}, metadata: ${updatedContact.metadata}');
        
        // Try to sync the update to server
        if (await _isOnline()) {
          try {
            // Update contact details on server
            await _remoteDataSource.updateContact(
              contactId: existingContact.id,
              name: name,
            );
            
            // Add member tag if needed
            if (isMember) {
              await _remoteDataSource.addTagsToContact(
                contactId: existingContact.id,
                tags: ['member'],
              );
            }
            
            // Mark as synced
            if (updatedContact.serverId != null) {
              await _localDataSource.markContactAsSynced(
                updatedContact.id,
                updatedContact.serverId!,
              );
            }
          } on AttendanceRemoteException catch (e) {
            // Failed to sync immediately - add to sync queue for later retry
            // ignore: avoid_print
            print('Failed to sync contact update immediately: ${e.message}. Adding to sync queue.');
            await _localDataSource.addContactToSyncQueue(
              contactId: updatedContact.id,
              data: {
                'action': 'update',
                'phone': phone,
                'name': name,
                'isMember': isMember,
                'location': location,
              },
            );
          }
        } else {
          // Offline - add to sync queue
          await _localDataSource.addContactToSyncQueue(
            contactId: updatedContact.id,
            data: {
              'action': 'update',
              'phone': phone,
              'name': name,
              'isMember': isMember,
              'location': location,
            },
          );
        }
        
        return updatedContact;
      }
      
      // Contact exists with a real name, just return it
      return existingContact;
    }

    // Create contact with optional member tag and location
    // Location is stored as a tag (e.g., 'kanana', 'church')
    List<String> tags = [];
    if (isMember) {
      tags.add('member');
    }
    if (location != null && location.isNotEmpty) {
      tags.add(location);
    }
    
    Map<String, dynamic>? metadata;
    if (tags.isNotEmpty) {
      metadata = <String, dynamic>{
        'tags': tags,
      };
    }

    final contact = await _localDataSource.createContact(
      phone: phone,
      name: name,
      metadata: metadata,
    );

    // Prepare sync data
    final syncData = {
      'phone': phone,
      'name': name,
      if (tags.isNotEmpty) 'tags': tags,
    };

    // Try to sync to server when online
    if (await _isOnline()) {
      try {
        // Attempt immediate sync to server
        final serverContact = await _remoteDataSource.createContact(
          phone: phone,
          name: name,
          tags: tags,
        );
        
        // Update local contact with server ID and mark as synced
        final serverId = serverContact['id'] as int?;
        if (serverId != null) {
          await _localDataSource.markContactAsSynced(contact.id, serverId);
        }
        
        return contact;
      } on AttendanceRemoteException catch (e) {
        // Failed to sync immediately - add to sync queue for later retry
        // ignore: avoid_print
        print('Failed to sync contact immediately: ${e.message}. Adding to sync queue.');
        await _localDataSource.addContactToSyncQueue(
          contactId: contact.id,
          data: syncData,
        );
      }
    } else {
      // Offline - add to sync queue immediately
      await _localDataSource.addContactToSyncQueue(
        contactId: contact.id,
        data: syncData,
      );
    }

    return contact;
  }

  @override
  Future<bool> checkAttendanceExists({
    required int contactId,
    required DateTime date,
    required ServiceType serviceType,
  }) async {
    return _localDataSource.checkAttendanceExists(
      contactId: contactId,
      date: date,
      serviceType: serviceType,
    );
  }

  @override
  Future<List<Attendance>> getAttendanceRecords({
    DateTime? dateFrom,
    DateTime? dateTo,
    ServiceType? serviceType,
    int? contactId,
  }) async {
    // Always return local data first
    return _localDataSource.getAttendanceRecords(
      dateFrom: dateFrom,
      dateTo: dateTo,
      serviceType: serviceType,
      contactId: contactId,
    );
  }

  @override
  Future<List<Attendance>> getContactAttendance(int contactId) async {
    return _localDataSource.getContactAttendance(contactId);
  }

  @override
  Future<Map<String, dynamic>> getAttendanceSummary({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    return _localDataSource.getAttendanceSummary(
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  @override
  Future<void> deleteAttendance(int attendanceId) async {
    await _localDataSource.deleteAttendance(attendanceId);
    
    // Delete from server when online
    if (await _isOnline()) {
      try {
        await _remoteDataSource.deleteAttendance(attendanceId);
      } on AttendanceRemoteException catch (e) {
        // Log error but don't fail - local record was deleted
        // ignore: avoid_print
        print('Failed to delete attendance from server: ${e.message}');
      }
    }
  }

  @override
  Future<void> syncPendingRecords() async {
    if (!await _isOnline()) return;

    final unsyncedRecords = await _localDataSource.getUnsyncedAttendances();

    for (final record in unsyncedRecords) {
      try {
        final serverRecord = await _remoteDataSource.recordAttendance(
          contactId: record.contactId,
          phone: record.phone,
          serviceType: record.serviceType,
          serviceDate: record.serviceDate,
          recordedBy: record.recordedBy,
        );

        await _localDataSource.markAsSynced(
          record.id,
          serverRecord.serverId ?? 0,
        );
      } catch (e) {
        // Skip this record if it fails, will retry next time
        continue;
      }
    }
  }

  /// Checks if the device is online.
  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      // connectivityResult is now a List<ConnectivityResult>
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // Try to reach the server
      final response = await _dioClient.dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
