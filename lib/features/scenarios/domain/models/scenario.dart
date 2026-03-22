import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:church_attendance_app/core/enums/scenario_status.dart';

part 'scenario.freezed.dart';
part 'scenario.g.dart';

@freezed
sealed class Scenario with _$Scenario {
  const Scenario._();

  const factory Scenario({
    required List<String> filterTags,
    required String name,
    required int id,
    required int createdBy,
    required DateTime createdAt,
    int? serverId,
    String? description,
    @Default(ScenarioStatus.active) ScenarioStatus status,
    
    DateTime? completedAt,
    @Default(false) bool isSynced,
    @Default(false) bool isDeleted,
  }) = _Scenario;

  factory Scenario.fromJson(Map<String, dynamic> json) =>
      _$ScenarioFromJson(json);

  /// Serialize filterTags to JSON string for database storage
  String get filterTagsJson => jsonEncode(filterTags);
}

@freezed
sealed class ScenarioTask with _$ScenarioTask {
  const factory ScenarioTask({
    required int id,
    required int scenarioId,
    required int contactId,
    required String phone,
    int? serverId,
    
    String? name,
    @Default(false) bool isCompleted,
    int? completedBy,
    DateTime? completedAt,
    @Default(false) bool isSynced,
    String? notes,
    DateTime? dueDate,
    @Default('medium') String priority,
  }) = _ScenarioTask;

  factory ScenarioTask.fromJson(Map<String, dynamic> json) =>
      _$ScenarioTaskFromJson(json);
}

@freezed
sealed class ScenarioWithTasks with _$ScenarioWithTasks {
  const ScenarioWithTasks._();

  const factory ScenarioWithTasks({
    required Scenario scenario,
    required List<ScenarioTask> tasks,
  }) = _ScenarioWithTasks;

  /// Get completion percentage
  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    final completedCount = tasks.where((t) => t.isCompleted).length;
    return (completedCount / tasks.length) * 100;
  }

  /// Get completed task count
  int get completedCount => tasks.where((t) => t.isCompleted).length;

  /// Get total task count
  int get totalCount => tasks.length;

  /// Check if all tasks are completed
  bool get isFullyCompleted => tasks.isNotEmpty && completedCount == totalCount;
}
