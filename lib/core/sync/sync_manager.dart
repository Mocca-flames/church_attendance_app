import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:church_attendance_app/core/network/api_constants.dart';

/// Callback for sync progress updates
typedef SyncProgressCallback =
    void Function(int current, int total, String message);

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
  // Maximum number of retry attempts before giving up and deleting the sync queue item
  static const int _maxRetryCount = 3;

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
    await prefs.setString(
      _lastSyncKey,
      DateTime.now().toUtc().toIso8601String(),
    );
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
      // Pre-check: Skip items that have exceeded max retries
      if (item.retryCount >= _maxRetryCount) {
        _logger.w(
          'Item ${item.id} already exceeded max retries (${item.retryCount}/$_maxRetryCount), cleaning up',
        );
        await _cleanupFailedSyncItem(item);
        continue;
      }

      try {
        await _syncItem(item);
        await _db.deleteSyncQueueItem(item.id);
        syncedCount++;
      } catch (e) {
        final newRetryCount = item.retryCount + 1;
        _logger.e(
          'Failed to sync item ${item.id} (attempt $newRetryCount/$_maxRetryCount)',
          error: e,
        );

        // Check if this is a 404 Not Found error - resource doesn't exist on server
        final bool isNotFound = _is404Error(e);

        // Check if this is a "Contact not found in local database" error
        final isLocalNotFound = e.toString().contains(
          'not found in local database',
        );

        // For 404 errors, immediately delete the sync item (resource doesn't exist)
        // For local not found errors (orphaned sync items), also delete immediately
        // For other errors, use the max retry count
        if (isNotFound || isLocalNotFound) {
          _logger.w(
            'Resource not found (404=$isNotFound, localNotFound=$isLocalNotFound), deleting sync item ${item.id}',
          );
          await _db.deleteSyncQueueItem(item.id);

          // If it's a delete action for a non-existent resource, clean up local
          if (item.action == 'delete') {
            try {
              await _db.deleteContact(item.localId);
              _logger.w('Cleaned up local contact ${item.localId} after 404');
            } catch (_) {
              // Contact might already be deleted
            }
          }

          // Count as success - resource doesn't exist, nothing to sync
          syncedCount++;
          continue;
        }

        // For other errors, check if we've exceeded retry count
        if (newRetryCount >= _maxRetryCount) {
          _logger.w('Max retries exceeded for item ${item.id}, cleaning up');
          await _cleanupFailedSyncItem(item);
        } else {
          // Update retry count and status for next attempt
          await _db.updateSyncQueueItem(
            SyncQueueCompanion(
              id: Value(item.id),
              status: const Value('failed'),
              errorMessage: Value(e.toString()),
              retryCount: Value(newRetryCount),
              lastAttemptAt: Value(DateTime.now()),
            ),
          );
        }
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

  /// Check if an exception is a 404 error
  bool _is404Error(dynamic e) {
    if (e is DioException && e.response?.statusCode == 404) {
      return true;
    } else if (e is ApiException && e.statusCode == 404) {
      return true;
    }
    return false;
  }

  /// Clean up a failed sync item and its associated local data
  Future<void> _cleanupFailedSyncItem(SyncQueueEntity item) async {
    try {
      await _db.deleteSyncQueueItem(item.id);

      // For contacts, also clean up local record if sync failed permanently
      if (item.entityType == 'contact') {
        try {
          await _db.deleteContact(item.localId);
          _logger.w(
            'Permanently deleted contact ${item.localId} after failed sync (action: ${item.action})',
          );
        } catch (e) {
          // Contact might already be deleted or not exist
          _logger.w('Could not delete contact ${item.localId}: $e');
        }
      }

      _logger.i(
        'Cleaned up sync queue item - entityType=${item.entityType}, localId=${item.localId}, action=${item.action}',
      );
    } catch (e) {
      _logger.w('Failed to cleanup sync item ${item.id}: $e');
    }
  }

  /// Aggressively clean up failed sync queue items when online.
  /// This is called when we detect the app is online to ensure pending items
  /// are processed and failed ones are removed.
  Future<int> aggressiveCleanupWhenOnline() async {
    if (!await hasInternetConnection()) {
      return 0;
    }

    // Get all pending/failed items
    final items = await _db.getPendingSyncItems();

    int cleanedCount = 0;
    for (final item in items) {
      // Skip items that are currently being retried (recently attempted)
      if (item.lastAttemptAt != null) {
        final timeSinceLastAttempt = DateTime.now().difference(
          item.lastAttemptAt!,
        );
        if (timeSinceLastAttempt.inMinutes < 5) {
          // Skip recently attempted items to avoid race conditions
          continue;
        }
      }

      // Check retry count - if already exceeded, delete immediately
      if (item.retryCount >= _maxRetryCount) {
        _logger.w(
          'Aggressive cleanup: Item ${item.id} exceeded max retries (${item.retryCount}/$_maxRetryCount)',
        );
        await _cleanupFailedSyncItem(item);
        cleanedCount++;
      }

      // Also clean up orphaned sync items (items for contacts that no longer exist locally)
      if (item.entityType == 'contact') {
        try {
          final contact = await _db.getContactById(item.localId);
          if (contact == null || contact.isDeleted) {
            _logger.w(
              'Aggressive cleanup: Found orphaned sync item for deleted contact ${item.localId}',
            );
            await _db.deleteSyncQueueItem(item.id);
            cleanedCount++;
          }
        } catch (e) {
          _logger.w(
            'Aggressive cleanup: Could not check contact ${item.localId}: $e',
          );
          // If we can't find the contact, assume it's orphaned
          await _db.deleteSyncQueueItem(item.id);
          cleanedCount++;
        }
      }
    }

    if (cleanedCount > 0) {
      _logger.i(
        'Aggressive cleanup: Removed $cleanedCount failed/orphaned sync items',
      );
    }

    return cleanedCount;
  }

  /// Sync individual item based on entity type and action
  Future<void> _syncItem(SyncQueueEntity item) async {
    Map<String, dynamic> data;

    // DEBUG: Log the sync item details for debugging null ID issue
    _logger.d(
      'DEBUG SYNC: Processing item - entityType=${item.entityType}, action=${item.action}, localId=${item.localId}, serverId=${item.serverId}',
    );

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
        fixed = fixed.replaceAllMapped(RegExp(r'(\w+):'), (match) {
          final key = match[1]!;
          // Skip if it's a JSON keyword
          if (key == 'true' || key == 'false' || key == 'null') {
            return match[0]!;
          }
          return '"$key":';
        });

        // Handle values that start with + (phone numbers)
        fixed = fixed.replaceAllMapped(
          RegExp(r':(\+[^,\s\}\]]+)([\s,\}])'),
          (match) => ':"${match[1]}"${match[2]}',
        );

        // Handle unquoted string values (like specialEvent -> "specialEvent")
        fixed = fixed.replaceAllMapped(
          RegExp(r':([a-zA-Z][a-zA-Z0-9_]*)([\s,\}])'),
          (match) => ':"${match[1]}"${match[2]}',
        );

        // Handle boolean values (true/false)
        fixed = fixed.replaceAllMapped(
          RegExp(r':(true|false)\b'),
          (match) => ':${match[1]}',
        );

        // Handle null values
        fixed = fixed.replaceAllMapped(RegExp(r':null\b'), (match) => ':null');

        // Handle numbers
        fixed = fixed.replaceAllMapped(
          RegExp(r':(-?\d+\.?\d*)'),
          (match) => ':${match[1]}',
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
    _logger.d(
      'DEBUG SYNC CONTACT: action=$action, localId=$localId, serverId=$serverId (type: ${serverId?.runtimeType})',
    );

    // Validate serverId is not null for update/delete operations
    if ((action == 'update' || action == 'delete') && serverId == null) {
      _logger.e(
        'BUG DETECTED: Attempting to $action contact with null serverId! localId=$localId. Fetching serverId from database...',
      );
      // Try to recover by fetching serverId from the contact table
      final contact = await _db.getContactById(localId);
      if (contact != null && contact.serverId != null) {
        _logger.i(
          'Recovered serverId=${contact.serverId} from local database for contact $localId',
        );
        serverId = contact.serverId;
      } else if (contact != null && contact.isDeleted) {
        // Contact was locally deleted - the sync item is orphaned, delete it
        // Instead of throwing (which would trigger retry), return success since we're cleaning up
        _logger.w(
          'Contact $localId is soft-deleted locally, deleting orphaned sync queue item',
        );
        // Return without error - the sync item will be deleted by _syncItem caller
        return;
      } else {
        // Cannot find contact - throw a specific exception that will be caught and handled
        // This will cause the sync to fail, and the main catch block will handle retries/deletion
        throw Exception(
          'Contact $localId not found in local database - cannot sync',
        );
      }
    }

    switch (action) {
      case 'create':
        // Check if contact with same phone already exists
        final phone = data['phone'] as String?;
        if (phone != null) {
          // Remove + prefix for search if present
          final searchPhone = phone.startsWith('+')
              ? phone.substring(1)
              : phone;

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
                  ApiConstants.contactById.replaceAll(
                    '{id}',
                    existingServerId.toString(),
                  ),
                  data: data,
                );
                // Update local contact with existing server ID
                await _db.updateContactFields(
                  id: localId,
                  serverId: existingServerId,
                  isSynced: true,
                );
                _logger.i(
                  'Updated existing contact $existingServerId with phone $phone',
                );
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
              final searchPhone = phone.startsWith('+')
                  ? phone.substring(1)
                  : phone;
              try {
                final searchResponse = await _dioClient.get(
                  '${ApiConstants.contactsSearch}$searchPhone',
                );
                final existingContacts = searchResponse.data as List<dynamic>?;
                if (existingContacts != null && existingContacts.isNotEmpty) {
                  final existingServerId = existingContacts.first['id'] as int?;
                  if (existingServerId != null) {
                    await _dioClient.put(
                      ApiConstants.contactById.replaceAll(
                        '{id}',
                        existingServerId.toString(),
                      ),
                      data: data,
                    );
                    await _db.updateContactFields(
                      id: localId,
                      serverId: existingServerId,
                      isSynced: true,
                    );
                    _logger.i(
                      'Updated existing contact $existingServerId after 400 error',
                    );
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
        final updateUrl = ApiConstants.contactById.replaceAll(
          '{id}',
          serverId.toString(),
        );
        _logger.d('DEBUG: Sending PUT to $updateUrl with data: $data');
        await _dioClient.put(updateUrl, data: data);
        await _db.updateContactFields(id: localId, isSynced: true);
        break;

      case 'delete':
        // DEBUG: Log the URL being constructed
        final deleteUrl = ApiConstants.contactById.replaceAll(
          '{id}',
          serverId.toString(),
        );
        _logger.d('DEBUG: Sending DELETE to $deleteUrl');

        try {
          await _dioClient.delete(deleteUrl);
          await _db.deleteContact(localId);
        } on DioException catch (e) {
          // 404 means contact doesn't exist on server - already deleted, clean up locally
          if (e.response?.statusCode == 404) {
            _logger.w(
              'Contact $serverId not found on server (already deleted), cleaning up local record',
            );
            try {
              await _db.deleteContact(localId);
            } catch (_) {
              // Contact might already be deleted
            }
            return; // Success - resource doesn't exist
          }
          rethrow; // Re-throw other errors
        } on ApiException catch (e) {
          // 404 from ApiException (converted from DioException)
          if (e.statusCode == 404) {
            _logger.w(
              'Contact $serverId not found on server (already deleted), cleaning up local record',
            );
            try {
              await _db.deleteContact(localId);
            } catch (_) {
              // Contact might already be deleted
            }
            return; // Success - resource doesn't exist
          }
          rethrow; // Re-throw other errors
        }
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
          _logger.w(
            'Attendance already exists on server for localId=$localId, marking as synced',
          );
          await _db.updateAttendance(
            localId,
            const AttendancesCompanion(isSynced: Value(true)),
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
          ScenariosCompanion(id: Value(localId), isSynced: const Value(true)),
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
        ScenarioTasksCompanion(id: Value(localId), isSynced: const Value(true)),
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
    final existingContacts = await (_db.select(
      _db.contacts,
    )..where((t) => t.serverId.isIn(serverIds))).get();

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

    // CRITICAL FIX: Delete contacts that exist locally but NOT on server
    // This handles contacts that were deleted by another user
    final serverIdSet = serverIds.toSet();
    final contactsToDelete = existingMap.values
        .where((c) => c.serverId != null && !serverIdSet.contains(c.serverId))
        .toList();

    if (contactsToDelete.isNotEmpty) {
      _logger.i(
        'Deleting ${contactsToDelete.length} contacts that were deleted on server',
      );
      for (final contact in contactsToDelete) {
        try {
          await _db.deleteContact(contact.id);
          _logger.d(
            'Deleted contact ${contact.id} (serverId=${contact.serverId}) - was deleted on server',
          );
        } catch (e) {
          _logger.w('Failed to delete contact ${contact.id}: $e');
        }
      }
    }
  }

  /// Pulls attendance data from server and updates local database.
  /// Uses server data as source of truth - existing local records with same
  /// phone/date/serviceType are updated, but unsynced local records are preserved.
  ///
  /// [date] - The single date to pull attendance for (YYYY-MM-DD)
  /// [serviceType] - Optional service type filter
  Future<void> pullAttendance({
    DateTime? date,
    ServiceType? serviceType,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final useRange = dateFrom != null && dateTo != null;

    DateTime effectiveFrom;
    DateTime effectiveTo;

    if (useRange) {
      effectiveFrom = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
      effectiveTo = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59);
    } else {
      effectiveFrom = date ?? DateTime.now();
      effectiveTo = effectiveFrom.add(const Duration(days: 1));
    }

    if (!await hasInternetConnection()) {
      _logger.w('No internet connection, skipping attendance pull');
      return;
    }

    try {
      _logger.i(
        'Pulling attendance from server: ${useRange ? 'range' : 'single date'}: $effectiveFrom -> $effectiveTo, serviceType: $serviceType',
      );

      final queryParams = <String, dynamic>{};
      if (useRange) {
        queryParams['date_from'] = effectiveFrom.toUtc().toIso8601String();
        queryParams['date_to'] = effectiveTo.toUtc().toIso8601String();
      } else {
        queryParams['date'] =
            '${effectiveFrom.year}-${effectiveFrom.month.toString().padLeft(2, '0')}-${effectiveFrom.day.toString().padLeft(2, '0')}';
      }
      if (serviceType != null) {
        queryParams['service_type'] = serviceType.backendValue;
      }

      final response = await _dioClient.dio.get(
        ApiConstants.attendances,
        queryParameters: queryParams,
      );

      final List<dynamic> serverRecords = response.data as List<dynamic>? ?? [];
      _logger.d(
        'Received ${serverRecords.length} attendance records from server',
      );

      int inserted = 0;
      int updated = 0;
      int skipped = 0;

      for (final record in serverRecords) {
        try {
          final phone = record['phone'] as String?;
          final serviceDateStr = record['service_date'] as String?;
          final serviceTypeStr = record['service_type'] as String?;
          final serverId = record['id'] as int?;
          final recordedBy = record['recorded_by'] as int?;

          if (phone == null ||
              serviceDateStr == null ||
              serviceTypeStr == null) {
            _logger.w('Skipping invalid attendance record: $record');
            skipped++;
            continue;
          }

          final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(phone);
          if (normalizedPhone == null) {
            _logger.w('Skipping attendance with invalid phone: $phone');
            skipped++;
            continue;
          }

          final contact = await _db.getContactByPhone(normalizedPhone);
          if (contact == null) {
            _logger.d('Skipping attendance for unknown contact: $phone');
            skipped++;
            continue;
          }

          final serviceDate = DateTime.parse(serviceDateStr);
          final dateOnly = DateTime(
            serviceDate.year,
            serviceDate.month,
            serviceDate.day,
          );

          final serviceType = ServiceType.fromBackend(serviceTypeStr);

          final existingRecord = await _db.checkAttendanceExists(
            contact.id,
            dateOnly,
            serviceType.backendValue,
          );

          if (existingRecord != null) {
            await _db.updateAttendance(
              existingRecord.id,
              AttendancesCompanion(
                serverId: Value(serverId),
                isSynced: const Value(true),
              ),
            );
            updated++;
          } else {
            final companion = AttendancesCompanion(
              contactId: Value(contact.id),
              phone: Value(normalizedPhone),
              serviceType: Value(serviceType.backendValue),
              serviceDate: Value(dateOnly),
              recordedBy: Value(recordedBy ?? 0),
              recordedAt: Value(DateTime.now()),
              serverId: Value(serverId),
              isSynced: const Value(true),
            );
            await _db.insertAttendance(companion);
            inserted++;
          }
        } catch (e) {
          _logger.w('Failed to process attendance record: $e');
          skipped++;
        }
      }

      final serverKeys = <String>{};
      for (final record in serverRecords) {
        final phone = record['phone'] as String?;
        final serviceDateStr = record['service_date'] as String?;
        final serviceTypeStr = record['service_type'] as String?;
        if (phone != null && serviceDateStr != null && serviceTypeStr != null) {
          final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(phone);
          if (normalizedPhone != null) {
            final dateOnly = serviceDateStr.split('T')[0];
            final key = '$normalizedPhone|$serviceTypeStr|$dateOnly';
            serverKeys.add(key);
          }
        }
      }

      final localRecords = await _db.getAttendancesByDateRange(
        effectiveFrom,
        effectiveTo,
      );
      int deleted = 0;
      for (final local in localRecords) {
        if (serviceType != null && local.serviceType != serviceType.backendValue) {
          continue;
        }

        if (!local.isSynced) continue;

        final key =
            '${local.phone}|${local.serviceType}|${local.serviceDate.toIso8601String().split('T')[0]}';
        if (!serverKeys.contains(key)) {
          await _db.deleteAttendance(local.id);
          deleted++;
        }
      }

      _logger.i(
        'Attendance pull completed: $inserted inserted, $updated updated, $deleted deleted, $skipped skipped',
      );
    } catch (e) {
      _logger.e('Failed to pull attendance from server', error: e);
      rethrow;
    }
  }

  /// Start periodic sync that runs every hour.
  /// This keeps contacts and attendance updated for offline search.
  /// Returns a timer that can be cancelled.
  Timer startPeriodicSync({Duration interval = const Duration(hours: 1)}) {
    return Timer.periodic(interval, (_) async {
      if (await hasInternetConnection()) {
        try {
          // Pull fresh contacts from server
          await pullContacts();

          // DO NOT pull attendance here - controlled by attendance screen only

          // Sync any pending local changes
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
