import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_colors.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/scenario_status.dart';
import 'package:church_attendance_app/features/scenarios/domain/models/scenario.dart';
import 'package:church_attendance_app/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:church_attendance_app/features/scenarios/presentation/widgets/task_list_widget.dart';
import 'package:church_attendance_app/features/scenarios/presentation/widgets/add_task_dialog.dart';
import 'package:church_attendance_app/features/scenarios/presentation/widgets/task_detail_sheet.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';

import '../../../../core/widgets/gradient_background.dart';

enum TaskFilter { all, pending, completed }

class ScenarioDetailScreen extends ConsumerStatefulWidget {
  final int scenarioId;
  
  const ScenarioDetailScreen({
    
    required this.scenarioId,super.key,
  });

  @override
  ConsumerState<ScenarioDetailScreen> createState() => _ScenarioDetailScreenState();
}

class _ScenarioDetailScreenState extends ConsumerState<ScenarioDetailScreen> {
  TaskFilter _currentFilter = TaskFilter.all;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  void _loadData() {
    ref.read(scenarioNotifierProvider.notifier).loadScenario(widget.scenarioId);
    ref.read(scenarioNotifierProvider.notifier).loadTasks(widget.scenarioId);
  }

  void _showAddTaskDialog(Scenario scenario) {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(scenario: scenario),
    );
  }

  void _showTaskDetail(ScenarioTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailSheet(
        task: task,
        scenarioId: widget.scenarioId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenarioState = ref.watch(scenarioNotifierProvider);
    final scenario = scenarioState.selectedScenario;
    final tasks = scenarioState.tasks;
    
    // Filter tasks
    final filteredTasks = _filterTasks(tasks);
    
    // Calculate progress
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return DynamicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(scenario?.name ?? 'Scenario'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            if (scenario != null)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete(scenario);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Scenario'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: scenarioState.isLoading && scenario == null
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(scenario, filteredTasks, completedCount, totalCount, progress),
        floatingActionButton: scenario != null
            ? FloatingActionButton(
                onPressed: () => _showAddTaskDialog(scenario),
                backgroundColor: AppColors.scenariosColor,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
  
  List<ScenarioTask> _filterTasks(List<ScenarioTask> tasks) {
    switch (_currentFilter) {
      case TaskFilter.pending:
        return tasks.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        return tasks.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
      return tasks;
    }
  }
  
  Widget _buildBody(Scenario? scenario, List<ScenarioTask> filteredTasks, 
      int completedCount, int totalCount, double progress) {
    if (scenario == null) {
      return const Center(child: Text('Scenario not found'));
    }
    
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(scenario, completedCount, totalCount, progress),
          ),
          
          // Filter chips
          SliverToBoxAdapter(
            child: _buildFilterChips(),
          ),
          
          // Task list
          if (filteredTasks.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = filteredTasks[index];
                    return TaskListWidget(
                      task: task,
                      onTap: () => _showTaskDetail(task),
                      onComplete: () => _toggleTaskComplete(task),
                    );
                  },
                  childCount: filteredTasks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildHeader(Scenario scenario, int completedCount, int totalCount, double progress) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (scenario.description?.isNotEmpty == true) ...[
            Text(
              scenario.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimens.paddingM),
          ],
          
          // Status badge
          Row(
            children: [
              _StatusBadge(status: scenario.status),
              const Spacer(),
              Text(
                '$completedCount / $totalCount tasks',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimens.paddingM),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? AppColors.success : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: _currentFilter == TaskFilter.all,
            onSelected: () => setState(() => _currentFilter = TaskFilter.all),
          ),
          const SizedBox(width: AppDimens.paddingS),
          _FilterChip(
            label: 'Pending',
            isSelected: _currentFilter == TaskFilter.pending,
            onSelected: () => setState(() => _currentFilter = TaskFilter.pending),
          ),
          const SizedBox(width: AppDimens.paddingS),
          _FilterChip(
            label: 'Completed',
            isSelected: _currentFilter == TaskFilter.completed,
            onSelected: () => setState(() => _currentFilter = TaskFilter.completed),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    String message;
    switch (_currentFilter) {
      case TaskFilter.pending:
        message = 'No pending tasks';
        break;
      case TaskFilter.completed:
        message = 'No completed tasks';
        break;
      case TaskFilter.all:
      message = 'No tasks yet. Tap + to add a task.';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: AppDimens.iconXXL,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  void _toggleTaskComplete(ScenarioTask task) async {
    final currentUser = ref.read(currentUserProvider);
    final completedBy = currentUser?.id ?? 0;
    
    if (task.isCompleted) {
      // Uncomplete - you'd need to add this method
      // For now just leave as is
    } else {
      await ref.read(scenarioNotifierProvider.notifier).completeTask(
        taskId: task.id,
        completedBy: completedBy,
      );
      _loadData();
    }
  }
  
  void _confirmDelete(Scenario scenario) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Scenario?'),
        content: Text('Are you sure you want to delete "${scenario.name}"? This will also delete all tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Pop dialog first, synchronously before async gap
              Navigator.pop(dialogContext);
              await ref.read(scenarioNotifierProvider.notifier).deleteScenario(scenario.id);
              // Check mounted before using context after async gap
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ScenarioStatus status;
  
  const _StatusBadge({required this.status});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: AppDimens.paddingXS,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: AppDimens.iconS, color: status.color),
          const SizedBox(width: AppDimens.paddingXS),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.scenariosColor.withValues(alpha: 0.2),
      checkmarkColor: AppColors.scenariosColor,
    );
  }
}
