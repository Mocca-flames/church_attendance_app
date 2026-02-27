// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/scenario_status.dart';
import 'package:church_attendance_app/features/scenarios/presentation/screens/scenario_detail_screen.dart';
import 'package:church_attendance_app/features/scenarios/domain/models/scenario.dart';
import 'package:church_attendance_app/features/scenarios/presentation/providers/scenario_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// Scenarios screen with list view, pull-to-refresh, and create functionality.
class ScenariosScreen extends ConsumerStatefulWidget {
  const ScenariosScreen({super.key});

  @override
  ConsumerState<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends ConsumerState<ScenariosScreen> {
  @override
  void initState() {
    super.initState();
    // Load scenarios on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scenarioNotifierProvider.notifier).loadScenarios();
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(scenarioNotifierProvider.notifier).loadScenarios();
  }

  void _showCreateScenarioDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Scenario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter scenario name',
              ).applyDefaults(Theme.of(context).inputDecorationTheme),
              autofocus: true,
            ),
            const SizedBox(height: AppDimens.paddingM),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter description',
              ).applyDefaults(Theme.of(context).inputDecorationTheme),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a name')),
                );
                return;
              }

              Navigator.pop(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await ref.read(scenarioNotifierProvider.notifier).createScenario(
                    name: nameController.text.trim(),
                    filterTags: [],
                    description: descriptionController.text.trim().isNotEmpty
                        ? descriptionController.text.trim()
                        : null,
                  );

              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Scenario created')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _navigateToScenarioDetail(Scenario scenario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScenarioDetailScreen(scenarioId: scenario.id),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final scenarioState = ref.watch(scenarioNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scenarios),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(scenarioState),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateScenarioDialog,
        backgroundColor: AppColors.scenariosColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ScenarioState state) {
    if (state.isLoading && state.scenarios.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.scenarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimens.iconXXL,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Error loading scenarios',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            FilledButton(
              onPressed: _handleRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.scenarios.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        itemCount: state.scenarios.length,
        itemBuilder: (context, index) {
          final scenario = state.scenarios[index];
          return _ScenarioCard(
            scenario: scenario,
            onTap: () => _navigateToScenarioDetail(scenario),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.checklist,
            size: AppDimens.iconXXL,
            color: AppColors.scenariosColor,
          ),
          const SizedBox(height: AppDimens.paddingL),
          Text(
            'No Scenarios Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Text(
            'Create your first scenario to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppDimens.paddingL),
          FilledButton.icon(
            onPressed: _showCreateScenarioDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Scenario'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.scenariosColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card widget for displaying a scenario in the list.
class _ScenarioCard extends ConsumerWidget {
  final Scenario scenario;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.scenario,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get task stats for this scenario - handle null id gracefully
    final taskStats = scenario.id > 0 
        ? ref.watch(scenarioTaskStatsProvider(scenario.id))
        : const AsyncValue<Map<String, int>>.data({});

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
      elevation: AppDimens.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scenario.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _StatusBadge(status: scenario.status),
                ],
              ),
              if (scenario.description?.isNotEmpty == true) ...[
                const SizedBox(height: AppDimens.paddingS),
                Text(
                  scenario.description ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppDimens.paddingM),
              Row(
                children: [
                  taskStats.when(
                    data: (stats) => _TaskCountBadge(
                      completed: stats['completed'] ?? 0,
                      total: stats['total'] ?? 0,
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => const Icon(
                      Icons.warning,
                      size: AppDimens.iconS,
                      color: AppColors.warning,
                    ),
                  ),
                  const Spacer(),
                  if (!scenario.isSynced)
                    const Icon(
                      Icons.cloud_off,
                      size: AppDimens.iconS,
                      color: AppColors.warning,
                    ),
                  const SizedBox(width: AppDimens.paddingS),
                  Text(
                    _formatDate(scenario.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Badge widget for displaying scenario status.
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
          Icon(
            status.icon,
            size: AppDimens.iconS,
            color: status.color,
          ),
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

/// Badge widget for displaying task count.
class _TaskCountBadge extends StatelessWidget {
  final int completed;
  final int total;

  const _TaskCountBadge({
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final hasTasks = total > 0;
    final color = hasTasks && completed == total
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: AppDimens.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasTasks ? Icons.task_alt : Icons.task,
            size: AppDimens.iconS,
            color: color,
          ),
          const SizedBox(width: AppDimens.paddingXS),
          Text(
            hasTasks ? '$completed / $total' : 'No tasks',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
