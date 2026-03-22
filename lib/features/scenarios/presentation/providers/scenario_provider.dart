import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/features/scenarios/data/datasources/scenario_local_datasource.dart';
import 'package:church_attendance_app/features/scenarios/data/datasources/scenario_remote_datasource.dart';
import 'package:church_attendance_app/features/scenarios/data/repositories/scenario_repository_impl.dart';
import 'package:church_attendance_app/features/scenarios/domain/models/scenario.dart';
import 'package:church_attendance_app/features/scenarios/domain/repositories/scenario_repository.dart';
import 'package:church_attendance_app/main.dart';

/// Provider for ScenarioLocalDataSource
final scenarioLocalDataSourceProvider = Provider<ScenarioLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return ScenarioLocalDataSource(database);
});

/// Provider for ScenarioRemoteDataSource
final scenarioRemoteDataSourceProvider = Provider<ScenarioRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ScenarioRemoteDataSource(dioClient);
});

/// Provider for ScenarioRepository
final scenarioRepositoryProvider = Provider<ScenarioRepository>((ref) {
  final localDataSource = ref.watch(scenarioLocalDataSourceProvider);
  final remoteDataSource = ref.watch(scenarioRemoteDataSourceProvider);
  final dioClient = ref.watch(dioClientProvider);
  return ScenarioRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    dioClient: dioClient,
  );
});

/// Scenario state for managing CRUD operations
class ScenarioState {
  final bool isLoading;
  final Scenario? selectedScenario;
  final List<Scenario> scenarios;
  final List<ScenarioTask> tasks;
  final String? error;
  final bool isSaving;
  final bool isDeleting;

  const ScenarioState({
    this.isLoading = false,
    this.selectedScenario,
    this.scenarios = const [],
    this.tasks = const [],
    this.error,
    this.isSaving = false,
    this.isDeleting = false,
  });

  ScenarioState copyWith({
    bool? isLoading,
    Scenario? selectedScenario,
    List<Scenario>? scenarios,
    List<ScenarioTask>? tasks,
    String? error,
    bool? isSaving,
    bool? isDeleting,
    bool clearError = false,
    bool clearSelectedScenario = false,
  }) {
    return ScenarioState(
      isLoading: isLoading ?? this.isLoading,
      selectedScenario: clearSelectedScenario ? null : (selectedScenario ?? this.selectedScenario),
      scenarios: scenarios ?? this.scenarios,
      tasks: tasks ?? this.tasks,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}

/// Scenario state notifier for managing scenario operations
class ScenarioNotifier extends Notifier<ScenarioState> {
  late final ScenarioRepository _repository;

  @override
  ScenarioState build() {
    _repository = ref.watch(scenarioRepositoryProvider);
    return const ScenarioState();
  }

  /// Load all scenarios
  Future<void> loadScenarios() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final scenarios = await _repository.getAllScenarios();
      state = state.copyWith(
        isLoading: false,
        scenarios: scenarios,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load a scenario by ID
  Future<Scenario?> loadScenario(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final scenario = await _repository.getScenarioById(id);
      state = state.copyWith(
        isLoading: false,
        selectedScenario: scenario,
      );
      return scenario;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Create a new scenario
  Future<Scenario?> createScenario({
    required String name,
    required List<String> filterTags,
    String? description,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      // Get current user ID
      final currentUser = ref.read(currentUserProvider);
      final createdBy = currentUser?.id ?? 0;

      final scenario = await _repository.createScenario(
        name: name,
        filterTags: filterTags,
        createdBy: createdBy,
        description: description,
      );
      
      // Reload scenarios list
      final scenarios = await _repository.getAllScenarios();
      
      state = state.copyWith(
        isSaving: false,
        selectedScenario: scenario,
        scenarios: scenarios,
      );
      return scenario;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Update an existing scenario
  Future<Scenario?> updateScenario(Scenario scenario) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final updated = await _repository.updateScenario(scenario);
      
      // Reload scenarios list
      final scenarios = await _repository.getAllScenarios();
      
      state = state.copyWith(
        isSaving: false,
        selectedScenario: updated,
        scenarios: scenarios,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Delete a scenario (soft delete)
  Future<bool> deleteScenario(int id) async {
    state = state.copyWith(isDeleting: true, clearError: true);
    
    try {
      await _repository.deleteScenario(id);
      
      // Reload scenarios list
      final scenarios = await _repository.getAllScenarios();
      
      state = state.copyWith(
        isDeleting: false,
        clearSelectedScenario: true,
        scenarios: scenarios,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Complete a task
  Future<ScenarioTask?> completeTask({
    required int taskId,
    required int completedBy,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final task = await _repository.completeTask(
        taskId: taskId,
        completedBy: completedBy,
      );
      
      state = state.copyWith(isSaving: false);
      return task;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Create a new task
  Future<ScenarioTask?> createTask({
    required int scenarioId,
    required int contactId,
    required String phone,
    String? name,
    String? notes,
    DateTime? dueDate,
    String priority = 'medium',
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final task = await _repository.createTask(
        scenarioId: scenarioId,
        contactId: contactId,
        phone: phone,
        name: name,
        notes: notes,
        dueDate: dueDate,
        priority: priority,
      );
      
      // Reload tasks for this scenario
      final tasks = await _repository.getTasksByScenario(scenarioId);
      
      state = state.copyWith(
        isSaving: false,
        tasks: tasks,
      );
      return task;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Update a task
  Future<ScenarioTask?> updateTask(ScenarioTask task) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final updated = await _repository.updateTask(task);
      
      // Reload tasks for this scenario
      final tasks = await _repository.getTasksByScenario(task.scenarioId);
      
      state = state.copyWith(
        isSaving: false,
        tasks: tasks,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Delete a task
  Future<bool> deleteTask(int taskId, int scenarioId) async {
    state = state.copyWith(isDeleting: true, clearError: true);
    
    try {
      await _repository.deleteTask(taskId);
      
      // Reload tasks for this scenario
      final tasks = await _repository.getTasksByScenario(scenarioId);
      
      state = state.copyWith(
        isDeleting: false,
        tasks: tasks,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Load tasks for a scenario
  Future<void> loadTasks(int scenarioId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final tasks = await _repository.getTasksByScenario(scenarioId);
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear selected scenario
  void clearSelectedScenario() {
    state = state.copyWith(clearSelectedScenario: true);
  }
}

/// Provider for ScenarioNotifier
final scenarioNotifierProvider = NotifierProvider<ScenarioNotifier, ScenarioState>(() {
  return ScenarioNotifier();
});

/// Scenario list provider
final scenarioListProvider = FutureProvider<List<Scenario>>((ref) async {
  final repository = ref.watch(scenarioRepositoryProvider);
  return repository.getAllScenarios();
});

/// Scenario by ID provider
final scenarioByIdProvider = FutureProvider.family<Scenario?, int>((ref, id) async {
  final repository = ref.watch(scenarioRepositoryProvider);
  return repository.getScenarioById(id);
});

/// Scenario with tasks provider
final scenarioWithTasksProvider = FutureProvider.family<ScenarioWithTasks?, int>((ref, scenarioId) async {
  final repository = ref.watch(scenarioRepositoryProvider);
  return repository.getScenarioWithTasks(scenarioId);
});

/// Tasks by scenario provider
final tasksByScenarioProvider = FutureProvider.family<List<ScenarioTask>, int>((ref, scenarioId) async {
  final repository = ref.watch(scenarioRepositoryProvider);
  return repository.getTasksByScenario(scenarioId);
});

/// Scenario statistics provider
final scenarioTaskStatsProvider = FutureProvider.family<Map<String, int>, int>((ref, scenarioId) async {
  final repository = ref.watch(scenarioRepositoryProvider);
  final completed = await repository.getCompletedTaskCount(scenarioId);
  final total = await repository.getTotalTaskCount(scenarioId);
  return {
    'completed': completed,
    'total': total,
  };
});
