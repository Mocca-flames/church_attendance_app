import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/enums/scenario_status.dart';
import 'package:church_attendance_app/features/scenarios/domain/models/scenario.dart';
import 'package:drift/drift.dart' as drift;

/// Local data source for scenario operations.
/// Handles all local database operations using Drift.
class ScenarioLocalDataSource {
  final AppDatabase _db;
  static bool _cleanupDone = false;

  ScenarioLocalDataSource(this._db);

  /// Converts database entity to Scenario model with proper key mapping
  Scenario? _mapEntityToScenario(ScenarioEntity entity) {
    // Build JSON map manually to ensure proper type conversion
    final Map<String, dynamic> json = {
      'id': entity.id,
      'serverId': entity.serverId,
      'name': entity.name,
      'description': entity.description,
      'filterTags': entity.filterTags, // Keep as string for now, convert below
      'status': entity.status, // This is a String from the database
      'createdBy': entity.createdBy,
      'createdAt': entity.createdAt.toIso8601String(),
      'completedAt': entity.completedAt?.toIso8601String(),
      'isSynced': entity.isSynced,
      'isDeleted': entity.isDeleted,
    };

    // Convert status to ScenarioStatus enum - handle both 'active' and 'ScenarioStatus.active' formats
    // NOTE: Keep as string for Freezed compatibility - Freezed expects a string in the JSON
    if (json.containsKey('status')) {
      final statusValue = json['status'];
      debugPrint('[ScenarioLocalDataSource:34] Parsing status: type=${statusValue.runtimeType}, value=$statusValue');
      
      if (statusValue is String) {
        // Handle various formats: 'active', 'completed', 'ScenarioStatus.active', etc.
        String backendValue = statusValue;
        
        // Extract the enum value name from various formats:
        // - 'active' -> 'active'
        // - 'ScenarioStatus.active' -> 'active'
        // - 'ScenarioStatus.completed' -> 'completed'
        if (statusValue.contains('.')) {
          // Format: 'ScenarioStatus.active' or similar -> extract 'active'
          backendValue = statusValue.split('.').last;
        } else if (statusValue.startsWith('ScenarioStatus.')) {
          // Format: 'ScenarioStatus.active' (no dot in split result)
          backendValue = statusValue.replaceFirst('ScenarioStatus.', '');
        }
        
        debugPrint('[ScenarioLocalDataSource:47] Extracted backendValue: $backendValue');
        // Keep as string for Freezed - it will handle the conversion
        json['status'] = backendValue;
        debugPrint('[ScenarioLocalDataSource:49] Status as string: ${json['status']}');
      } else if (statusValue is ScenarioStatus) {
        // Already a ScenarioStatus enum, convert to string for Freezed
        debugPrint('[ScenarioLocalDataSource:52] Status is ScenarioStatus enum, converting to string');
        json['status'] = statusValue.backendValue;
      } else {
        // Unknown type, try to parse anyway
        debugPrint('[ScenarioLocalDataSource:55] WARNING: Unknown status type: ${statusValue.runtimeType}');
        try {
          String statusStr = statusValue.toString();
          if (statusStr.contains('.')) {
            statusStr = statusStr.split('.').last;
          }
          json['status'] = statusStr;
        } catch (e) {
          debugPrint('[ScenarioLocalDataSource:58] ERROR: Failed to parse status: $e');
          json['status'] = 'active';
        }
      }
    }
    // Map filterTags from JSON string to List<String>
    if (json.containsKey('filterTags') && json['filterTags'] is String) {
      try {
        json['filterTags'] = List<String>.from(jsonDecode(json['filterTags'] as String));
      } catch (e) {
        debugPrint('[ScenarioLocalDataSource:76] ERROR parsing filterTags: $e');
        json['filterTags'] = <String>[];
      }
    }
    
    try {
      return Scenario.fromJson(json);
    } catch (e) {
      debugPrint('[ScenarioLocalDataSource:70] ERROR parsing Scenario from entity: $e');
      debugPrint('[ScenarioLocalDataSource:70] Entity JSON: $json');
      // Return a default scenario as fallback to prevent crashes
      return Scenario(
        id: entity.id,
        serverId: entity.serverId,
        name: entity.name,
        description: entity.description,
        filterTags: [],
        createdBy: entity.createdBy,
        createdAt: entity.createdAt,
        status: ScenarioStatus.active,
        isSynced: entity.isSynced,
        isDeleted: entity.isDeleted,
      );
    }
  }

  /// Converts database entity to ScenarioTask model with proper key mapping
  ScenarioTask? _mapEntityToScenarioTask(ScenarioTaskEntity entity) {
    // Build JSON map manually to ensure proper type conversion
    final Map<String, dynamic> json = {
      'id': entity.id,
      'serverId': entity.serverId,
      'scenarioId': entity.scenarioId,
      'contactId': entity.contactId,
      'phone': entity.phone,
      'name': entity.name,
      'isCompleted': entity.isCompleted,
      'completedBy': entity.completedBy,
      'completedAt': entity.completedAt?.toIso8601String(),
      'isSynced': entity.isSynced,
    };
    
    try {
      return ScenarioTask.fromJson(json);
    } catch (e) {
      debugPrint('[ScenarioLocalDataSource:81] ERROR parsing ScenarioTask from entity: $e');
      debugPrint('[ScenarioLocalDataSource:81] Entity JSON: $json');
      return null;
    }
  }

  /// Get all scenarios (excluding deleted)
  Future<List<Scenario>> getAllScenarios() async {
    debugPrint('[ScenarioLocalDataSource:67] getAllScenarios: fetching from DB');
    
    // Run cleanup FIRST to fix any corrupted data before reading
    await cleanupCorruptedStatus();
    
    final entities = await _db.getAllScenarios();
    debugPrint('[ScenarioLocalDataSource:72] getAllScenarios: raw entities count: ${entities.length}');
    final result = entities
        .where((e) => !e.isDeleted)
        .map(_mapEntityToScenario)
        .whereType<Scenario>()
        .toList();
    debugPrint('[ScenarioLocalDataSource:76] getAllScenarios: returning ${result.length} scenarios');
    return result;
  }

  /// Get scenarios by status
  Future<List<Scenario>> getScenariosByStatus(ScenarioStatus status) async {
    debugPrint('[ScenarioLocalDataSource:78] getScenariosByStatus: status=$status');
    
    // Run cleanup on first access to fix any corrupted data
    await cleanupCorruptedStatus();
    
    final entities = await _db.getScenariosByStatus(status.backendValue);
    debugPrint('[ScenarioLocalDataSource:80] getScenariosByStatus: raw entities count: ${entities.length}');
    final result = entities
        .where((e) => !e.isDeleted)
        .map(_mapEntityToScenario)
        .whereType<Scenario>()
        .toList();
    debugPrint('[ScenarioLocalDataSource:84] getScenariosByStatus: returning ${result.length} scenarios');
    return result;
  }

  /// Get scenario by ID
  Future<Scenario?> getScenarioById(int id) async {
    debugPrint('[ScenarioLocalDataSource:88] getScenarioById: fetching id=$id');
    
    // Run cleanup on first access to fix any corrupted data
    await cleanupCorruptedStatus();
    
    final entity = await _db.getScenarioById(id);
    if (entity == null) {
      debugPrint('[ScenarioLocalDataSource:90] getScenarioById: entity is NULL for id=$id');
      return null;
    }
    if (entity.isDeleted) {
      debugPrint('[ScenarioLocalDataSource:91] getScenarioById: entity is deleted for id=$id');
      return null;
    }
    final scenario = _mapEntityToScenario(entity);
    debugPrint('[ScenarioLocalDataSource:93] getScenarioById: mapped scenario: ${scenario != null ? scenario.name : "NULL"}');
    return scenario;
  }

  /// Create new scenario
  Future<Scenario> createScenario({
    required String name,
    required List<String> filterTags,
    required int createdBy,
    String? description,
  }) async {
    debugPrint('[ScenarioLocalDataSource:98] createScenario: name=$name, createdBy=$createdBy');
    final filterTagsJson = jsonEncode(filterTags);
    
    final companion = ScenariosCompanion(
      name: drift.Value(name),
      filterTags: drift.Value(filterTagsJson),
      createdBy: drift.Value(createdBy),
      description: description != null ? drift.Value(description) : const drift.Value.absent(),
      status: const drift.Value('active'),
      isSynced: const drift.Value(false),
      isDeleted: const drift.Value(false),
    );
    
    final id = await _db.insertScenario(companion);
    debugPrint('[ScenarioLocalDataSource:113] createScenario: inserted with id=$id');
    final scenario = await getScenarioById(id);
    if (scenario == null) {
      debugPrint('[ScenarioLocalDataSource:115] ERROR: createScenario: scenario is NULL after creation!');
      throw Exception('Failed to create scenario: scenario is null after insert');
    }
    debugPrint('[ScenarioLocalDataSource:117] createScenario: created scenario: ${scenario.name}, id=${scenario.id}');
    return scenario;
  }

  /// Update existing scenario
  Future<Scenario> updateScenario(Scenario scenario) async {
    debugPrint('[ScenarioLocalDataSource:121] updateScenario: id=${scenario.id}, name=${scenario.name}');
    final filterTagsJson = jsonEncode(scenario.filterTags);
    
    final companion = ScenariosCompanion(
      id: drift.Value(scenario.id),
      serverId: scenario.serverId != null ? drift.Value(scenario.serverId!) : const drift.Value.absent(),
      name: drift.Value(scenario.name),
      description: scenario.description != null ? drift.Value(scenario.description!) : const drift.Value.absent(),
      filterTags: drift.Value(filterTagsJson),
      status: drift.Value(scenario.status.backendValue),
      createdBy: drift.Value(scenario.createdBy),
      createdAt: drift.Value(scenario.createdAt),
      completedAt: scenario.completedAt != null ? drift.Value(scenario.completedAt) : const drift.Value.absent(),
      isSynced: const drift.Value(false),
      isDeleted: drift.Value(scenario.isDeleted),
    );
    
    await _db.updateScenario(companion);
    debugPrint('[ScenarioLocalDataSource:137] updateScenario: updated in DB, fetching fresh data');
    final updated = await getScenarioById(scenario.id);
    if (updated == null) {
      debugPrint('[ScenarioLocalDataSource:139] ERROR: updateScenario: scenario is NULL after update!');
      throw Exception('Failed to update scenario: scenario is null after update');
    }
    debugPrint('[ScenarioLocalDataSource:141] updateScenario: updated scenario: ${updated.name}');
    return updated;
  }

  /// Soft delete a scenario
  Future<void> softDeleteScenario(int id) async {
    await _db.deleteScenario(id);
  }

  /// Restore a soft-deleted scenario
  Future<void> restoreScenario(int id) async {
    final entity = await _db.getScenarioById(id);
    if (entity == null) return;
    
    final companion = ScenariosCompanion(
      id: drift.Value(entity.id),
      serverId: drift.Value(entity.serverId),
      name: drift.Value(entity.name),
      description: drift.Value(entity.description),
      filterTags: drift.Value(entity.filterTags),
      status: drift.Value(entity.status),
      createdBy: drift.Value(entity.createdBy),
      createdAt: drift.Value(entity.createdAt),
      completedAt: drift.Value(entity.completedAt),
      isSynced: const drift.Value(false),
      isDeleted: const drift.Value(false),
    );
    await _db.updateScenario(companion);
  }

  /// Mark scenario as synced
  Future<void> markAsSynced(int scenarioId, int serverId) async {
    final entity = await _db.getScenarioById(scenarioId);
    if (entity == null) return;
    
    final companion = ScenariosCompanion(
      id: drift.Value(entity.id),
      serverId: drift.Value(serverId),
      name: drift.Value(entity.name),
      description: drift.Value(entity.description),
      filterTags: drift.Value(entity.filterTags),
      status: drift.Value(entity.status),
      createdBy: drift.Value(entity.createdBy),
      createdAt: drift.Value(entity.createdAt),
      completedAt: drift.Value(entity.completedAt),
      isSynced: const drift.Value(true),
      isDeleted: drift.Value(entity.isDeleted),
    );
    await _db.updateScenario(companion);
  }

  /// Get all tasks for a scenario
  Future<List<ScenarioTask>> getTasksByScenario(int scenarioId) async {
    debugPrint('[ScenarioLocalDataSource:190] getTasksByScenario: scenarioId=$scenarioId');
    final entities = await _db.getTasksByScenario(scenarioId);
    debugPrint('[ScenarioLocalDataSource:192] getTasksByScenario: raw entities count: ${entities.length}');
    final result = entities
        .map(_mapEntityToScenarioTask)
        .whereType<ScenarioTask>()
        .toList();
    debugPrint('[ScenarioLocalDataSource:195] getTasksByScenario: returning ${result.length} tasks');
    return result;
  }

  /// Clean up corrupted status values in the database
  /// This fixes any scenarios that have status stored with the full enum name
  /// Only runs once per app session to avoid repeated writes
  Future<void> cleanupCorruptedStatus() async {
    if (_cleanupDone) {
      debugPrint('[ScenarioLocalDataSource:305] cleanupCorruptedStatus: Already done, skipping');
      return;
    }
    
    debugPrint('[ScenarioLocalDataSource:307] cleanupCorruptedStatus: Starting cleanup');
    try {
      // Fix 'ScenarioStatus.active' -> 'active'
      await _db.customStatement(
        "UPDATE scenarios SET status = 'active' WHERE status = 'ScenarioStatus.active'"
      );
      // Fix 'ScenarioStatus.completed' -> 'completed'
      await _db.customStatement(
        "UPDATE scenarios SET status = 'completed' WHERE status = 'ScenarioStatus.completed'"
      );
      _cleanupDone = true;
      debugPrint('[ScenarioLocalDataSource:317] cleanupCorruptedStatus: Cleanup completed');
    } catch (e) {
      debugPrint('[ScenarioLocalDataSource:319] cleanupCorruptedStatus: ERROR: $e');
    }
  }

  /// Get task by ID
  Future<ScenarioTask?> getTaskById(int id) async {
    debugPrint('[ScenarioLocalDataSource:200] getTaskById: id=$id');
    final entity = await _db.getTaskById(id);
    if (entity == null) {
      debugPrint('[ScenarioLocalDataSource:202] getTaskById: entity is NULL for id=$id');
      return null;
    }
    final task = _mapEntityToScenarioTask(entity);
    debugPrint('[ScenarioLocalDataSource:205] getTaskById: mapped task: ${task != null ? "exists" : "NULL"}');
    return task;
  }

  /// Create new scenario task
  Future<ScenarioTask> createTask({
    required int scenarioId,
    required int contactId,
    required String phone,
    String? name,
  }) async {
    debugPrint('[ScenarioLocalDataSource:209] createTask: scenarioId=$scenarioId, contactId=$contactId');
    final companion = ScenarioTasksCompanion(
      scenarioId: drift.Value(scenarioId),
      contactId: drift.Value(contactId),
      phone: drift.Value(phone),
      name: name != null ? drift.Value(name) : const drift.Value.absent(),
      isCompleted: const drift.Value(false),
      isSynced: const drift.Value(false),
    );
    
    final id = await _db.insertScenarioTask(companion);
    debugPrint('[ScenarioLocalDataSource:220] createTask: inserted with id=$id');
    final task = await getTaskById(id);
    if (task == null) {
      debugPrint('[ScenarioLocalDataSource:222] ERROR: createTask: task is NULL after creation!');
      throw Exception('Failed to create task: task is null after insert');
    }
    debugPrint('[ScenarioLocalDataSource:224] createTask: created task: id=${task.id}');
    return task;
  }

  /// Complete a task
  Future<ScenarioTask> completeTask({
    required int taskId,
    required int completedBy,
  }) async {
    debugPrint('[ScenarioLocalDataSource:229] completeTask: taskId=$taskId, completedBy=$completedBy');
    await _db.completeTask(taskId, completedBy);
    final task = await getTaskById(taskId);
    if (task == null) {
      debugPrint('[ScenarioLocalDataSource:232] ERROR: completeTask: task is NULL after completion!');
      throw Exception('Failed to complete task: task is null after completion');
    }
    debugPrint('[ScenarioLocalDataSource:234] completeTask: completed task: id=${task.id}');
    return task;
  }

  /// Mark task as synced
  Future<void> markTaskAsSynced(int taskId, int serverId) async {
    final entity = await _db.getTaskById(taskId);
    if (entity == null) return;
    
    final companion = ScenarioTasksCompanion(
      id: drift.Value(entity.id),
      serverId: drift.Value(serverId),
      scenarioId: drift.Value(entity.scenarioId),
      contactId: drift.Value(entity.contactId),
      phone: drift.Value(entity.phone),
      name: drift.Value(entity.name),
      isCompleted: drift.Value(entity.isCompleted),
      completedBy: drift.Value(entity.completedBy),
      completedAt: drift.Value(entity.completedAt),
      isSynced: const drift.Value(true),
    );
    await _db.updateScenarioTask(companion);
  }

  /// Add scenario to sync queue for server sync
  Future<void> addToSyncQueue({
    required int scenarioId,
    required String action,
    Map<String, dynamic>? data,
  }) async {
    final companion = SyncQueueCompanion(
      entityType: const drift.Value('scenario'),
      action: drift.Value(action),
      localId: drift.Value(scenarioId),
      data: drift.Value(jsonEncode(data ?? {})),
      status: const drift.Value('pending'),
    );
    await _db.insertSyncQueueItem(companion);
  }

  /// Add task to sync queue for server sync
  Future<void> addTaskToSyncQueue({
    required int taskId,
    required String action,
    Map<String, dynamic>? data,
  }) async {
    final companion = SyncQueueCompanion(
      entityType: const drift.Value('scenario_task'),
      action: drift.Value(action),
      localId: drift.Value(taskId),
      data: drift.Value(jsonEncode(data ?? {})),
      status: const drift.Value('pending'),
    );
    await _db.insertSyncQueueItem(companion);
  }

  /// Get completed task count for a scenario
  Future<int> getCompletedTaskCount(int scenarioId) async {
    return _db.getCompletedTaskCount(scenarioId);
  }

  /// Get total task count for a scenario
  Future<int> getTotalTaskCount(int scenarioId) async {
    return _db.getTotalTaskCount(scenarioId);
  }

  /// Get scenario with tasks
  Future<ScenarioWithTasks?> getScenarioWithTasks(int scenarioId) async {
    debugPrint('[ScenarioLocalDataSource:285] getScenarioWithTasks: scenarioId=$scenarioId');
    final scenario = await getScenarioById(scenarioId);
    if (scenario == null) {
      debugPrint('[ScenarioLocalDataSource:287] getScenarioWithTasks: scenario is NULL');
      return null;
    }
    
    final tasks = await getTasksByScenario(scenarioId);
    debugPrint('[ScenarioLocalDataSource:290] getScenarioWithTasks: scenario=${scenario.name}, tasks=${tasks.length}');
    return ScenarioWithTasks(
      scenario: scenario,
      tasks: tasks,
    );
  }
}
