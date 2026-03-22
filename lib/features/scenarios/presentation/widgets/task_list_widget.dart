import 'package:flutter/material.dart';
import 'package:church_attendance_app/core/constants/app_colors.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/scenario_task_priority.dart';
import 'package:church_attendance_app/features/scenarios/domain/models/scenario.dart';

class TaskListWidget extends StatelessWidget {
  final ScenarioTask task;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  
  const TaskListWidget({
    required this.task, required this.onTap, required this.onComplete, super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final priority = ScenarioTaskPriority.fromBackend(task.priority);
    final isOverdue = task.dueDate != null && 
        !task.isCompleted && 
        task.dueDate!.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: task.isCompleted,
                onChanged: (_) => onComplete(),
                activeColor: AppColors.success,
              ),
              
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and priority
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.name ?? task.phone,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : null,
                              color: task.isCompleted 
                                  ? Colors.grey 
                                  : null,
                            ),
                          ),
                        ),
                        _PriorityBadge(priority: priority),
                      ],
                    ),
                    
                    const SizedBox(height: AppDimens.paddingXS),
                    
                    // Phone
                    Text(
                      task.phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    // Due date
                    if (task.dueDate != null) ...[
                      const SizedBox(height: AppDimens.paddingXS),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isOverdue ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(task.dueDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue ? Colors.red : Colors.grey.shade600,
                              fontWeight: isOverdue ? FontWeight.w600 : null,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '(Overdue)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    
                    // Notes preview
                    if (task.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: AppDimens.paddingXS),
                      Text(
                        task.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
          Icon(priority.icon, size: 12, color: priority.color),
          const SizedBox(width: 2),
          Text(
            priority.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: priority.color,
            ),
          ),
        ],
      ),
    );
  }
}
