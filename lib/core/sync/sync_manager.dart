import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:church_attendance_app/core/network/api_constants.dart';


/// Callback for sync progress updates
typedef SyncProgressCallback = void Function(int current, int total, String message);

class SyncManager {
  final AppDatabase _db;
  final DioClient _dioClient;
  final Connectivity _connectivity = Connectivity();
  final Logger _logger = Logger();
  
  // Batch size for paginated fetching - balances network calls vs memory
  static const int _defaultBatchSize = 500;
  // Batch size for database inserts
  static const int _dbBatchSize = 100;
  
  // SharedPreferences key for last sync timestamp
  static const String _lastSyncKey = 'last_contact_sync';

  SyncManager(this._db, this._dioClient);

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    return await _db.getPendingSyncCount();
  }

  /// Get the last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    if (timestamp != null) {
      return DateTime.parse(timestamp);
    }
    return null;
  }

  /// Save the last sync timestamp
  Future<void> _saveLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toUtc().toIso8601String());
  }

  /// Sync all pending items
  Future<SyncResult> syncAll() async {
    if (!await hasInternetConnection()) {
      return SyncResult(
        success: false,
        message: 'No internet connection',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    final pendingItems = await _db.getPendingSyncItems();
    int syncedCount = 0;
    int failedCount = 0;

    for (final item in pendingItems) {
      try {
        await _syncItem(item);
        await _db.deleteSyncQueueItem(item.id);
        syncedCount++;
      } catch (e) {
        _logger.e('Failed to sync item ${item.id}', error: e);
        await _db.updateSyncQueueItem(
          SyncQueueCompanion(
            id: Value(item.id),
            status: const Value('failed'),
            errorMessage: Value(e.toString()),
            retryCount: Value(item.retryCount + 1),
            lastAttemptAt: Value(DateTime.now()),
          ),
        );
        failedCount++;
      }
    }

    return SyncResult(
      success: failedCount == 0,
      message: failedCount == 0
          ? 'Successfully synced all items'
          : 'Synced $syncedCount items, $failedCount failed',
      syncedCount: syncedCount,
      failedCount: failedCount,
    );
  }

  /// Sync individual item based on entity type and action
  Future<void> _syncItem(SyncQueueEntity item) async {
    Map<String, dynamic> data;
    
    // DEBUG: Log the sync item details for debugging null ID issue
    _logger.d('DEBUG SYNC: Processing item - entityType=${item.entityType}, action=${item.action}, localId=${item.localId}, serverId=${item.serverId}');
    
    try {
      data = _parseJsonData(item.data);
    } catch (e) {
      // If parsing fails, the data is corrupted - delete the sync queue item
      _logger.w('Corrupted sync queue item ${item.id}, deleting: $e');
      await _db.deleteSyncQueueItem(item.id);
      return;
    }

    switch (item.entityType) {
      case 'contact':
        await _syncContact(item.action, item.localId, item.serverId, data);
        break;
      case 'attendance':
        await _syncAttendance(item.action, item.localId, item.serverId, data);
        break;
      case 'scenario':
        await _syncScenario(item.action, item.localId, item.serverId, data);
        break;
      case 'scenario_task':
        await _syncScenarioTask(item.action, item.localId, item.serverId, data);
        break;
    }
  }

  /// Parse JSON data, handling common formatting issues
  Map<String, dynamic> _parseJsonData(String dataStr) {
    try {
      // First try standard JSON parsing
      return jsonDecode(dataStr) as Map<String, dynamic>;
    } catch (e) {
      // If that fails, try to fix common issues
      try {
        String fixed = dataStr;
        
        // First, add quotes around unquoted keys
        // This handles data like {id: 7} → {"id": 7}
        fixed = fixed.replaceAllMapped(
          RegExp(r'(\w+):'),
          (match) {
            final key = match[1]!;
            // Skip if it's a JSON keyword
            if (key == 'true' || key == 'false' || key == 'null') {
              return match[0]!;
            }
            return '"$key":';
          },
        );
        
        // Handle values that start with + (phone numbers)
        fixed = fixed.replaceAllMapped(
          RegExp(r':(\+[^,\s\}\]]+)([\s,\}])'),
          (match) => ':"${match[1]}"${match[2]}'
        );
        
        // Handle unquoted string values (like specialEvent -> "specialEvent")
        fixed = fixed.replaceAllMapped(
          RegExp(r':([a-zA-Z][a-zA-Z0-9_]*)([\s,\}])'),
          (match) => ':"${match[1]}"${match[2]}'
        );
        
        // Handle boolean values (true/false)
        fixed = fixed.replaceAllMapped(
          RegExp(r':(true|false)\b'),
          (match) => ':${match[1]}'
        );
        
        // Handle null values
        fixed = fixed.replaceAllMapped(
          RegExp(r':null\b'),
          (match) => ':null'
        );
        
        // Handle numbers
        fixed = fixed.replaceAllMapped(
          RegExp(r':(-?\d+\.?\d*)'),
          (match) => ':${match[1]}'
        );
        
        return jsonDecode(fixed) as Map<String, dynamic>;
      } catch (e2) {
        _logger.e('Unable to parse data: $dataStr', error: e2);
        rethrow;
      }
    }
  }

  // ==========================================================================
  // CONTACT SYNC
  // ==========================================================================

  Future<void> _syncContact(
    String action,
    int localId,
    int? serverId,
    Map<String, dynamic> data,
  ) async {
    // DEBUG: Log serverId handling for debugging null ID issue
    _logger.d('DEBUG SYNC CONTACT: action=$action, localId=$localId, serverId=$serverId (type: ${serverId?.runtimeType})');
    
    // Validate serverId is not null for update/delete operations
    if ((action == 'update' || action == 'delete') && serverId == null) {
      _logger.e('BUG DETECTED: Attempting to $action contact with null serverId! localId=$localId. Fetching serverId from database...');
      // Try to recover by fetching serverId from the contact table
      final contact = await _db.getContactById(localId);
      if (contact != null && contact.serverId != null) {
        _logger.i('Recovered serverId=${contact.serverId} from local database for contact $localId');
        serverId = contact.serverId;
      } else {
        _logger.e('CRITICAL: Cannot recover serverId for contact $localId. Skipping sync.');
        return;
      }
    }
    
    switch (action) {
      case 'create':
        // Check if contact with same phone already exists
        final phone = data['phone'] as String?;
        if (phone != null) {
          // Remove + prefix for search if present
          final searchPhone = phone.startsWith('+') ? phone.substring(1) : phone;
          
          try {
            // Search for existing contact by phone
            final searchResponse = await _dioClient.get(
              '${ApiConstants.contactsSearch}$searchPhone',
            );
            final existingContacts = searchResponse.data as List<dynamic>?;
            
            if (existingContacts != null && existingContacts.isNotEmpty) {
              // Contact exists - update it instead
              final existingContact = existingContacts.first;
              final existingServerId = existingContact['id'] as int?;
              
              if (existingServerId != null) {
                await _dioClient.put(
                  ApiConstants.contactById.replaceAll('{id}', existingServerId.toString()),
                  data: data,
                );
                // Update local contact with existing server ID
                await _db.updateContactFields(
                  id: localId,
                  serverId: existingServerId,
                  isSynced: true,
                );
                _logger.i('Updated existing contact $existingServerId with phone $phone');
                return;
              }
            }
          } catch (e) {
            // If search fails, proceed to create new contact
            _logger.w('Failed to search for existing contact: $e');
          }
        }
        
        // No existing contact found - create new one
        try {
          final response = await _dioClient.post(
            ApiConstants.contacts,
            data: data,
          );
          final newServerId = response.data['id'] as int?;
          if (newServerId != null) {
            await _db.updateContactFields(
              id: localId,
              serverId: newServerId,
              isSynced: true,
            );
          }
        } on DioException catch (e) {
          // If 400 error (contact exists), try to find and update
          if (e.response?.statusCode == 400 && 
              e.response?.data.toString().contains('already exists') != null) {
            // Try one more time with search
            if (phone != null) {
              final searchPhone = phone.startsWith('+') ? phone.substring(1) : phone;
              try {
                final searchResponse = await _dioClient.get(
                  '${ApiConstants.contactsSearch}$searchPhone',
                );
                final existingContacts = searchResponse.data as List<dynamic>?;
                if (existingContacts != null && existingContacts.isNotEmpty) {
                  final existingServerId = existingContacts.first['id'] as int?;
                  if (existingServerId != null) {
                    await _dioClient.put(
                      ApiConstants.contactById.replaceAll('{id}', existingServerId.toString()),
                      data: data,
                    );
                    await _db.updateContactFields(
                      id: localId,
                      serverId: existingServerId,
                      isSynced: true,
                    );
                    _logger.i('Updated existing contact $existingServerId after 400 error');
                    return;
                  }
                }
              } catch (_) {}
            }
          }
          rethrow;
        }
        break;

      case 'update':
        // DEBUG: Log the URL being constructed
        final updateUrl = ApiConstants.contactById.replaceAll('{id}', serverId.toString());
        _logger.d('DEBUG: Sending PUT to $updateUrl with data: $data');
        await _dioClient.put(
          updateUrl,
          data: data,
        );
        await _db.updateContactFields(
          id: localId,
          isSynced: true,
        );
        break;

      case 'delete':
        // DEBUG: Log the URL being constructed
        final deleteUrl = ApiConstants.contactById.replaceAll('{id}', serverId.toString());
        _logger.d('DEBUG: Sending DELETE to $deleteUrl');
        await _dioClient.delete(
          deleteUrl,
        );
        await _db.deleteContact(localId);
        break;
    }
  }

  // ==========================================================================
  // ATTENDANCE SYNC
  // ==========================================================================

  Future<void> _syncAttendance(
    String action,
    int localId,
    int? serverId,
    Map<String, dynamic> data,
  ) async {
    // Attendance is create-only
    if (action == 'create') {
      try {
        final response = await _dioClient.post(
          ApiConstants.attendanceRecord,
          data: data,
        );
        final newServerId = response.data['id'];
        await _db.updateAttendance(
          localId,
          AttendancesCompanion(
            serverId: Value(newServerId),
            isSynced: const Value(true),
          ),
        );
      } on ApiException catch (e) {
        // If server returns 400 with "already recorded", mark as synced
        // since the record already exists on the server
        final message = e.message.toLowerCase();
        if (message.contains('already recorded') || 
            message.contains('already exists') || 
            message.contains('duplicate')) {
          _logger.w('Attendance already exists on server for localId=$localId, marking as synced');
          await _db.updateAttendance(
            localId,
            const AttendancesCompanion(
              isSynced: Value(true),
            ),
          );
          return; // Don't rethrow - this is a successful resolution
        }
        rethrow; // Re-throw other errors
      }
    }
  }

  // ==========================================================================
  // SCENARIO SYNC
  // ==========================================================================

  Future<void> _syncScenario(
    String action,
    int localId,
    int? serverId,
    Map<String, dynamic> data,
  ) async {
    switch (action) {
      case 'create':
        final response = await _dioClient.post(
          ApiConstants.scenarios,
          data: data,
        );
        final newServerId = response.data['id'];
        await _db.updateScenario(
          ScenariosCompanion(
            id: Value(localId),
            serverId: Value(newServerId),
            isSynced: const Value(true),
          ),
        );
        break;

      case 'update':
        await _dioClient.put(
          ApiConstants.scenarioById.replaceAll('{id}', serverId.toString()),
          data: data,
        );
        await _db.updateScenario(
          ScenariosCompanion(
            id: Value(localId),
            isSynced: const Value(true),
          ),
        );
        break;

      case 'delete':
        await _dioClient.delete(
          ApiConstants.scenarioById.replaceAll('{id}', serverId.toString()),
        );
        break;
    }
  }

  // ==========================================================================
  // SCENARIO TASK SYNC
  // ==========================================================================

  Future<void> _syncScenarioTask(
    String action,
    int localId,
    int? serverId,
    Map<String, dynamic> data,
  ) async {
    // Task completion sync
    if (action == 'update' && data['is_completed'] == true) {
      final scenarioServerId = data['scenario_server_id'];
      await _dioClient.put(
        ApiConstants.scenarioTaskComplete
            .replaceAll('{id}', scenarioServerId.toString())
            .replaceAll('{taskId}', serverId.toString()),
      );
      await _db.updateScenarioTask(
        ScenarioTasksCompanion(
          id: Value(localId),
          isSynced: const Value(true),
        ),
      );
    }
  }

  // ==========================================================================
  // PULL DATA FROM SERVER
  // ==========================================================================

  /// Pull contacts from server and update local database.
  /// Uses server-side pagination (skip/limit) and batch processing for better performance.
  /// 
  /// [forceFullSync] - If true, ignores last sync time and fetches all contacts
  /// [batchSize] - Number of contacts to fetch per API call (default: 500)
  /// [progressCallback] - Optional callback for progress updates (current, total, message)
  Future<void> pullContacts({
    bool forceFullSync = false,
    int batchSize = _defaultBatchSize,
    SyncProgressCallback? progressCallback,
  }) async {
    if (!await hasInternetConnection()) {
      _logger.w('No internet connection, skipping contact pull');
      return;
    }

    try {
      // Get last sync time
      final lastSync = await getLastSyncTime();
      
      // Build base query params
      final queryParams = <String, dynamic>{};
      
      // Use incremental sync if not forcing full sync and we have a last sync time
      if (!forceFullSync && lastSync != null) {
        final lastSyncIso = lastSync.toUtc().toIso8601String();
        queryParams['updated_after'] = lastSyncIso;
        _logger.i('Using incremental sync since $lastSyncIso');
      } else {
        _logger.i('Using full sync (first sync or forced)');
      }

      _logger.i('Starting paginated contact fetch with batch size $batchSize');
      
      // Fetch contacts using server-side pagination
      int skip = 0;
      int totalProcessed = 0;
      List<dynamic> batch;
      
      do {
        // Set pagination params
        queryParams['limit'] = batchSize;
        queryParams['skip'] = skip;
        
        _logger.d('Fetching contacts: limit=$batchSize, skip=$skip');
        
        // Fetch a batch from server
        final response = await _dioClient.get(
          ApiConstants.contacts,
          queryParameters: queryParams,
        );
        
        batch = response.data as List<dynamic>? ?? [];
        _logger.d('Received batch of ${batch.length} contacts');
        
        if (batch.isEmpty) {
          break; // No more data
        }
        
        // Process this batch in smaller DB chunks
        for (var i = 0; i < batch.length; i += _dbBatchSize) {
          final dbBatch = batch.skip(i).take(_dbBatchSize).toList();
          await _saveContactBatch(dbBatch);
          totalProcessed += dbBatch.length;
          
          // Report progress
          progressCallback?.call(
            totalProcessed, 
            -1, // Unknown total until we finish
            'Synced $totalProcessed contacts...',
          );
          
          // Yield to allow UI to update
          await Future.delayed(Duration.zero);
        }
        
        skip += batchSize;
        
      } while (batch.length == batchSize); // Continue if we got a full batch

      // Save last sync time
      await _saveLastSyncTime();

      _logger.i('Contact sync completed: $totalProcessed contacts processed');
      progressCallback?.call(totalProcessed, totalProcessed, 'Sync complete!');
    } catch (e) {
      _logger.e('Failed to pull contacts', error: e);
      rethrow;
    }
  }

  /// Save a batch of contacts from JSON to the local database efficiently
  Future<void> _saveContactBatch(List<dynamic> contactsJson) async {
    _logger.d('Processing batch of ${contactsJson.length} contacts');
    
    // Get all server IDs from the batch
    final serverIds = contactsJson.map((j) => j['id'] as int).toList();
    
    // Query existing contacts in one go
    final existingContacts = await (_db.select(_db.contacts)
          ..where((t) => t.serverId.isIn(serverIds)))
        .get();
    
    // Create a map for quick lookup
    final existingMap = {for (var c in existingContacts) c.serverId: c};
    
    // Separate into inserts and updates
    final List<ContactsCompanion> inserts = [];
    final List<ContactsCompanion> updates = [];
    
    for (final json in contactsJson) {
      final serverId = json['id'] as int;
      final existing = existingMap[serverId];
      
      final companion = ContactsCompanion(
        serverId: Value(serverId),
        name: Value(json['name']),
        phone: Value(json['phone']),
        status: Value(_convertToString(json['status'], 'active')),
        optOutSms: Value(_convertToBool(json['opt_out_sms'])),
        optOutWhatsapp: Value(_convertToBool(json['opt_out_whatsapp'])),
        metadata: Value(json['metadata_']),
        isSynced: const Value(true),
      );
      
      if (existing == null) {
        inserts.add(companion);
      } else {
        updates.add(companion);
      }
    }
    
    // Batch insert new contacts
    if (inserts.isNotEmpty) {
      _logger.d('Batch inserting ${inserts.length} new contacts');
      await _db.batchInsertContacts(inserts);
    }
    
    // Batch update existing contacts
    if (updates.isNotEmpty) {
      _logger.d('Batch updating ${updates.length} existing contacts');
      await _db.batchUpdateContacts(updates);
    }
  }

  /// Start periodic sync that runs every hour.
  /// This keeps contacts updated for offline search.
  /// Returns a timer that can be cancelled.
  Timer startPeriodicSync({Duration interval = const Duration(hours: 1)}) {
    return Timer.periodic(interval, (_) async {
      if (await hasInternetConnection()) {
        try {
          // Pull fresh contacts from server
          await pullContacts();
          // Also sync any pending local changes
          await syncAll();
          _logger.i('Periodic sync completed');
        } catch (e) {
          _logger.e('Periodic sync failed', error: e);
        }
      }
    });
  }

  // ==========================================================================
  // TYPE CONVERSION HELPERS
  // ==========================================================================

  /// Converts a value to String, handling int values from server API.
  String _convertToString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is int) return value.toString();
    return defaultValue;
  }

  /// Converts a value to bool, handling int values (0/1) from server API.
  bool _convertToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
  });
}
