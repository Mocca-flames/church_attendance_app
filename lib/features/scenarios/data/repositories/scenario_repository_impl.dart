import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:church_attendance_app/core/enums/scenario_status.dart';
import 'package:church_attendance_app/features/scenarios/data/datasources/scenario_local_datasource.dart';
import 'package:church_attendance_app/features/scenarios/data/datasources/scenario_remote_datasource.dart';
import 'package:church_attendance_app/features/scenarios/domain/models/scenario.dart';
import 'package:church_attendance_app/features/scenarios/domain/repositories/scenario_repository.dart';

/// Implementation of ScenarioRepository.
/// 
/// Follows Clean Architecture principles:
/// - Coordinates between local and remote data sources
/// - Implements offline-first strategy
/// - Handles sync queue for offline operations
class ScenarioRepositoryImpl implements ScenarioRepository {
  final ScenarioLocalDataSource _localDataSource;
  final ScenarioRemoteDataSource _remoteDataSource;
  // ignore: unused_field
  final DioClient _dioClient;

  ScenarioRepositoryImpl({
    required ScenarioLocalDataSource localDataSource,
    required ScenarioRemoteDataSource remoteDataSource,
    required DioClient dioClient,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _dioClient = dioClient;

  @override
  Future<List<Scenario>> getAllScenarios() async {
    return _localDataSource.getAllScenarios();
  }

  @override
  Future<List<Scenario>> getScenariosByStatus(ScenarioStatus status) async {
    return _localDataSource.getScenariosByStatus(status);
  }

  @override
  Future<Scenario?> getScenarioById(int id) async {
    return _localDataSource.getScenarioById(id);
  }

  @override
  Future<Scenario> createScenario({
    required String name,
    required List<String> filterTags,
    required int createdBy,
    String? description,
  }) async {
    // Create locally first
    final createdScenario = await _localDataSource.createScenario(
      name: name,
      filterTags: filterTags,
      createdBy: createdBy,
      description: description,
    );

    // Try to sync to server when online
    if (await _isOnline()) {
      try {
        final serverScenario = await _remoteDataSource.createScenario(
          name: name,
          filterTags: filterTags,
          createdBy: createdBy,
          description: description,
        );

        // Update local with server ID and mark as synced
        final serverId = serverScenario['id'] as int?;
        if (serverId != null) {
          await _localDataSource.markAsSynced(createdScenario.id, serverId);
        }

        return (await _localDataSource.getScenarioById(createdScenario.id))!;
      } catch (e) {
        // Add to sync queue for later retry
        await _localDataSource.addToSyncQueue(
          scenarioId: createdScenario.id,
          action: 'create',
          data: {
            'name': name,
            'filterTags': filterTags,
            'createdBy': createdBy,
            'description': description,
          },
        );
      }
    } else {
      // Offline - add to sync queue
      await _localDataSource.addToSyncQueue(
        scenarioId: createdScenario.id,
        action: 'create',
        data: {
          'name': name,
          'filterTags': filterTags,
          'createdBy': createdBy,
          'description': description,
        },
      );
    }

    return createdScenario;
  }

  @override
  Future<Scenario> updateScenario(Scenario scenario) async {
    // Update locally
    final updatedScenario = await _localDataSource.updateScenario(scenario);

    // Try to sync to server when online
    if (await _isOnline()) {
      try {
        if (scenario.serverId != null) {
          await _remoteDataSource.updateScenario(
            id: scenario.serverId!,
            name: updatedScenario.name,
            filterTags: updatedScenario.filterTags,
            description: updatedScenario.description,
            status: updatedScenario.status.backendValue,
          );
          
          // Mark as synced
          await _localDataSource.markAsSynced(
            updatedScenario.id,
            scenario.serverId!,
          );
        }
      } catch (e) {
        // Add to sync queue for later retry
        await _localDataSource.addToSyncQueue(
          scenarioId: updatedScenario.id,
          action: 'update',
          data: {
            'name': updatedScenario.name,
            'filterTags': updatedScenario.filterTags,
            'description': updatedScenario.description,
            'status': updatedScenario.status.backendValue,
          },
        );
      }
    } else {
      // Offline - add to sync queue
      await _localDataSource.addToSyncQueue(
        scenarioId: updatedScenario.id,
        action: 'update',
        data: {
          'name': updatedScenario.name,
          'filterTags': updatedScenario.filterTags,
          'description': updatedScenario.description,
          'status': updatedScenario.status.backendValue,
        },
      );
    }

    return updatedScenario;
  }

  @override
  Future<void> deleteScenario(int id) async {
    // Get scenario first to check if it has server ID
    final scenario = await _localDataSource.getScenarioById(id);
    
    // Soft delete locally
    await _localDataSource.softDeleteScenario(id);

    // Try to delete on server when online
    if (await _isOnline()) {
      try {
        if (scenario?.serverId != null) {
          await _remoteDataSource.deleteScenario(scenario!.serverId!);
        }
      } catch (e) {
        // Add to sync queue for later retry
        await _localDataSource.addToSyncQueue(
          scenarioId: id,
          action: 'delete',
          data: {},
        );
      }
    } else {
      // Offline - add to sync queue
      await _localDataSource.addToSyncQueue(
        scenarioId: id,
        action: 'delete',
        data: {},
      );
    }
  }

  @override
  Future<List<ScenarioTask>> getTasksByScenario(int scenarioId) async {
    return _localDataSource.getTasksByScenario(scenarioId);
  }

  @override
  Future<ScenarioWithTasks?> getScenarioWithTasks(int scenarioId) async {
    return _localDataSource.getScenarioWithTasks(scenarioId);
  }

  @override
  Future<ScenarioTask> createTask({
    required int scenarioId,
    required int contactId,
    required String phone,
    String? name,
  }) async {
    return _localDataSource.createTask(
      scenarioId: scenarioId,
      contactId: contactId,
      phone: phone,
      name: name,
    );
  }

  @override
  Future<ScenarioTask> completeTask({
    required int taskId,
    required int completedBy,
  }) async {
    // Complete locally first
    final completedTask = await _localDataSource.completeTask(
      taskId: taskId,
      completedBy: completedBy,
    );

    // Try to sync to server when online
    if (await _isOnline()) {
      try {
        if (completedTask.serverId != null) {
          await _remoteDataSource.completeTask(
            scenarioId: completedTask.scenarioId,
            taskId: completedTask.serverId!,
            completedBy: completedBy,
          );
          
          // Mark as synced
          await _localDataSource.markTaskAsSynced(taskId, completedTask.serverId!);
        }
      } catch (e) {
        // Task is still marked as completed locally
        // Sync will handle it later
      }
    }

    return completedTask;
  }

  @override
  Future<int> getCompletedTaskCount(int scenarioId) async {
    return _localDataSource.getCompletedTaskCount(scenarioId);
  }

  @override
  Future<int> getTotalTaskCount(int scenarioId) async {
    return _localDataSource.getTotalTaskCount(scenarioId);
  }

  @override
  Future<void> syncScenarios() async {
    if (!await _isOnline()) return;

    // Pull scenarios from server and merge with local
    try {
      final serverScenarios = await _remoteDataSource.getScenarios();
      final localScenarios = await _localDataSource.getAllScenarios();
      
      // Merge server scenarios with local scenarios
      await _mergeScenarios(serverScenarios, localScenarios);
    } catch (e) {
      // Sync failed - continue with local data
    }
  }

  /// Merges server scenarios with local scenarios.
  /// 
  /// Merge strategy:
  /// - Scenarios only on server (new) → create them locally
  /// - Scenarios only locally → keep them (may be pending sync)
  /// - Scenarios on both (by serverId) → update local with server data if synced
  /// - Scenarios with pending local changes (not synced) → keep local version
  Future<void> _mergeScenarios(
    List<Map<String, dynamic>> serverScenarios,
    List<Scenario> localScenarios,
  ) async {
    // Build lookup maps for efficient matching
    final localByServerId = <int, Scenario>{};
    
    for (final local in localScenarios) {
      // Index by serverId if available
      if (local.serverId != null) {
        localByServerId[local.serverId!] = local;
      }
    }

    // Process each server scenario
    for (final serverScenario in serverScenarios) {
      final serverId = serverScenario['id'] as int?;
      if (serverId == null) continue;

      final serverName = serverScenario['name'] as String?;
      final serverDescription = serverScenario['description'] as String?;
      final serverFilterTags = serverScenario['filter_tags'] as List<dynamic>?;
      final serverStatus = serverScenario['status'] as String?;

      // Check if we already have this scenario locally by serverId
      final existingByServerId = localByServerId[serverId];

      if (existingByServerId != null) {
        // Scenario exists locally - check if we should update
        if (existingByServerId.isSynced) {
          // Local is synced, update with server data (server takes precedence)
          final newName = serverName ?? existingByServerId.name;
          final newDescription = serverDescription ?? existingByServerId.description;
          final newFilterTags = serverFilterTags?.map((e) => e.toString()).toList() ?? existingByServerId.filterTags;
          final newStatus = serverStatus != null 
              ? ScenarioStatus.fromBackend(serverStatus)
              : existingByServerId.status;
          
          await _localDataSource.updateScenario(
            existingByServerId.copyWith(
              name: newName,
              description: newDescription,
              filterTags: newFilterTags,
              status: newStatus,
            ),
          );
          await _localDataSource.markAsSynced(existingByServerId.id, serverId);
        } else {
          // Local has pending changes, keep local version
          // But update the serverId so future syncs work correctly
          await _localDataSource.markAsSynced(existingByServerId.id, serverId);
        }
      } else {
        // Completely new scenario from server - create it locally
        final created = await _localDataSource.createScenario(
          name: serverName ?? '',
          filterTags: serverFilterTags?.map((e) => e.toString()).toList() ?? [],
          createdBy: serverScenario['created_by'] as int? ?? 0,
          description: serverDescription,
        );

        // Mark as synced with server ID
        await _localDataSource.markAsSynced(created.id, serverId);
      }
    }
  }

  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = !connectivityResult.contains(ConnectivityResult.none);
      debugPrint('[Scenario Repository] Online check: $isConnected (connectivity: $connectivityResult)');
      return isConnected;
    } catch (e) {
      debugPrint('[Scenario Repository] Online check failed: $e');
      return false;
    }
  }
}
