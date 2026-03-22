import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_colors.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/scenario_task_priority.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/features/scenarios/domain/models/scenario.dart';
import 'package:church_attendance_app/features/scenarios/presentation/providers/scenario_provider.dart';

class TaskDetailSheet extends ConsumerStatefulWidget {
  final ScenarioTask task;
  final int scenarioId;
  
  const TaskDetailSheet({
    required this.task, required this.scenarioId, super.key,
  });

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  late TextEditingController _notesController;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.task.notes);
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final priority = ScenarioTaskPriority.fromBackend(widget.task.priority);
    final isOverdue = widget.task.dueDate != null && 
        !widget.task.isCompleted && 
        widget.task.dueDate!.isBefore(DateTime.now());
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusL),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppDimens.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: AppDimens.paddingL),
                
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.task.name ?? widget.task.phone,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _PriorityBadge(priority: priority),
                  ],
                ),
                
                const SizedBox(height: AppDimens.paddingS),
                
                // Phone
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: Colors.grey),
                    const SizedBox(width: AppDimens.paddingS),
                    Text(
                      widget.task.phone,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                
                // Due date
                if (widget.task.dueDate != null) ...[
                  const SizedBox(height: AppDimens.paddingS),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: isOverdue ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: AppDimens.paddingS),
                      Text(
                        'Due: ${_formatDate(widget.task.dueDate!)}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey.shade600,
                          fontWeight: isOverdue ? FontWeight.w600 : null,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: AppDimens.paddingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OVERDUE',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                
                // Status
                const SizedBox(height: AppDimens.paddingM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM,
                    vertical: AppDimens.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: widget.task.isCompleted 
                        ? AppColors.success.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.task.isCompleted 
                            ? Icons.check_circle 
                            : Icons.pending,
                        color: widget.task.isCompleted 
                            ? AppColors.success 
                            : Colors.orange,
                      ),
                      const SizedBox(width: AppDimens.paddingS),
                      Text(
                        widget.task.isCompleted ? 'Completed' : 'Pending',
                        style: TextStyle(
                          color: widget.task.isCompleted 
                              ? AppColors.success 
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppDimens.paddingL),
                const Divider(),
                const SizedBox(height: AppDimens.paddingM),
                
                // Notes section
                Row(
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (!_isEditing)
                      TextButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppDimens.paddingS),
                
                if (_isEditing) ...[
                  // Editing mode
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add notes...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _notesController.text = widget.task.notes ?? '';
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppDimens.paddingS),
                      FilledButton(
                        onPressed: _saveNotes,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ] else ...[
                  // View mode
                  Text(
                    widget.task.notes?.isNotEmpty == true 
                        ? widget.task.notes! 
                        : 'No notes',
                    style: TextStyle(
                      color: widget.task.notes?.isNotEmpty == true 
                          ? null 
                          : Colors.grey,
                      fontStyle: widget.task.notes?.isNotEmpty == true 
                          ? null 
                          : FontStyle.italic,
                    ),
                  ),
                ],
                
                const SizedBox(height: AppDimens.paddingL),
                
                // Action buttons
                Row(
                  children: [
                    if (!widget.task.isCompleted)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _markComplete,
                          icon: const Icon(Icons.check),
                          label: const Text('Mark Complete'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      ),
                    if (widget.task.isCompleted) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _markIncomplete,
                          icon: const Icon(Icons.undo),
                          label: const Text('Mark Incomplete'),
                        ),
                      ),
                    ],
                    const SizedBox(width: AppDimens.paddingS),
                    IconButton(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _saveNotes() async {
    final updatedTask = widget.task.copyWith(
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );
    
    await ref.read(scenarioNotifierProvider.notifier).updateTask(updatedTask);
    
    if (!mounted) return;
    
    setState(() => _isEditing = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notes saved')),
    );
  }
  
  void _markComplete() async {
    final currentUser = ref.read(currentUserProvider);
    final completedBy = currentUser?.id ?? 0;
    
    await ref.read(scenarioNotifierProvider.notifier).completeTask(
      taskId: widget.task.id,
      completedBy: completedBy,
    );
    
    if (!mounted) return;
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task completed!')),
    );
  }
  
  void _markIncomplete() async {
    // Uncomplete - would need to implement
    // For now, just close the sheet
    Navigator.pop(context);
  }
  
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Store navigator and messenger before async operation
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              navigator.pop(); // Close dialog
              await ref.read(scenarioNotifierProvider.notifier).deleteTask(
                widget.task.id,
                widget.scenarioId,
              );
              if (mounted) {
                navigator.pop(); // Close sheet
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Task deleted')),
                );
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

class _PriorityBadge extends StatelessWidget {
  final ScenarioTaskPriority priority;
  
  const _PriorityBadge({required this.priority});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
        border: Border.all(color: priority.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, size: 14, color: priority.color),
          const SizedBox(width: 4),
          Text(
            priority.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: priority.color,
            ),
          ),
        ],
      ),
    );
  }
}
