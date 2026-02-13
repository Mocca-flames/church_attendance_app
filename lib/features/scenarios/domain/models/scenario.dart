import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:church_attendance_app/core/enums/scenario_status.dart';

part 'scenario.freezed.dart';
part 'scenario.g.dart';

@freezed
class Scenario with _$Scenario {
  const Scenario._();

  const factory Scenario({
    required int id,
    int? serverId,
    required String name,
    String? description,
    required List<String> filterTags,
    @Default(ScenarioStatus.active) ScenarioStatus status,
    required int createdBy,
    required DateTime createdAt,
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
class ScenarioTask with _$ScenarioTask {
  const factory ScenarioTask({
    required int id,
    int? serverId,
    required int scenarioId,
    required int contactId,
    required String phone,
    String? name,
    @Default(false) bool isCompleted,
    int? completedBy,
    DateTime? completedAt,
    @Default(false) bool isSynced,
  }) = _ScenarioTask;

  factory ScenarioTask.fromJson(Map<String, dynamic> json) =>
      _$ScenarioTaskFromJson(json);
}

@freezed
class ScenarioWithTasks with _$ScenarioWithTasks {
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
