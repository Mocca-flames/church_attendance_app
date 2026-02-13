import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:church_attendance_app/core/network/api_constants.dart';

class SyncManager {
  final AppDatabase _db;
  final DioClient _dioClient;
  final Connectivity _connectivity = Connectivity();
  final Logger _logger = Logger();

  SyncManager(this._db, this._dioClient);

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    return await _db.getPendingSyncCount();
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
    final data = jsonDecode(item.data);

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

  // ==========================================================================
  // CONTACT SYNC
  // ==========================================================================

  Future<void> _syncContact(
    String action,
    int localId,
    int? serverId,
    Map<String, dynamic> data,
  ) async {
    switch (action) {
      case 'create':
        final response = await _dioClient.post(
          ApiConstants.contacts,
          data: data,
        );
        final newServerId = response.data['id'];
        await _db.updateContact(
          ContactsCompanion(
            id: Value(localId),
            serverId: Value(newServerId),
            isSynced: const Value(true),
          ),
        );
        break;

      case 'update':
        await _dioClient.put(
          ApiConstants.contactById.replaceAll('{id}', serverId.toString()),
          data: data,
        );
        await _db.updateContact(
          ContactsCompanion(
            id: Value(localId),
            isSynced: const Value(true),
          ),
        );
        break;

      case 'delete':
        await _dioClient.delete(
          ApiConstants.contactById.replaceAll('{id}', serverId.toString()),
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

  /// Pull contacts from server and update local database
  Future<void> pullContacts() async {
    if (!await hasInternetConnection()) return;

    try {
      final response = await _dioClient.get(ApiConstants.contacts);
      final List<dynamic> contactsJson = response.data;

      for (final json in contactsJson) {
        final serverId = json['id'];
        // Check if contact with this serverId already exists
        final existingContacts = await (_db.select(_db.contacts)
              ..where((t) => t.serverId.equals(serverId)))
            .get();

        if (existingContacts.isEmpty) {
          // Insert new contact
          await _db.insertContact(
            ContactsCompanion(
              serverId: Value(serverId),
              name: Value(json['name']),
              phone: Value(json['phone']),
              status: Value(json['status'] ?? 'active'),
              optOutSms: Value(json['opt_out_sms'] ?? false),
              optOutWhatsapp: Value(json['opt_out_whatsapp'] ?? false),
              metadata: Value(json['metadata_']),
              isSynced: const Value(true),
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Failed to pull contacts', error: e);
    }
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
