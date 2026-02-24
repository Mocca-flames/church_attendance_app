import 'package:church_attendance_app/core/enums/scenario_status.dart';
import 'package:church_attendance_app/features/scenarios/domain/models/scenario.dart';

/// Repository interface for scenario operations.
/// Defines the contract for scenario data operations.
abstract class ScenarioRepository {
  /// Get all scenarios
  Future<List<Scenario>> getAllScenarios();

  /// Get scenarios by status
  Future<List<Scenario>> getScenariosByStatus(ScenarioStatus status);

  /// Get scenario by ID
  Future<Scenario?> getScenarioById(int id);

  /// Create a new scenario
  Future<Scenario> createScenario({
    required String name,
    required List<String> filterTags,
    required int createdBy,
    String? description,
  });

  /// Update an existing scenario
  Future<Scenario> updateScenario(Scenario scenario);

  /// Delete a scenario (soft delete)
  Future<void> deleteScenario(int id);

  /// Get all tasks for a scenario
  Future<List<ScenarioTask>> getTasksByScenario(int scenarioId);

  /// Get scenario with tasks
  Future<ScenarioWithTasks?> getScenarioWithTasks(int scenarioId);

  /// Create a new task
  Future<ScenarioTask> createTask({
    required int scenarioId,
    required int contactId,
    required String phone,
    String? name,
  });

  /// Complete a task
  Future<ScenarioTask> completeTask({
    required int taskId,
    required int completedBy,
  });

  /// Get completed task count for a scenario
  Future<int> getCompletedTaskCount(int scenarioId);

  /// Get total task count for a scenario
  Future<int> getTotalTaskCount(int scenarioId);

  /// Sync scenarios with server
  Future<void> syncScenarios();
}
