import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_colors.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/scenario_task_priority.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';
import 'package:church_attendance_app/features/scenarios/domain/models/scenario.dart';
import 'package:church_attendance_app/features/scenarios/presentation/providers/scenario_provider.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  final Scenario scenario;
  
  const AddTaskDialog({
    required this.scenario, super.key,
  });

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  Contact? _selectedContact;
  final _notesController = TextEditingController();
  DateTime? _dueDate;
  ScenarioTaskPriority _priority = ScenarioTaskPriority.medium;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  
  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Add Task',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: AppDimens.paddingM),
            
            // Contact selector
            const Text(
              'Select Contact',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppDimens.paddingS),
            
            if (_selectedContact != null) ...[
              // Selected contact card
              Card(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(_selectedContact!.displayName[0].toUpperCase()),
                  ),
                  title: Text(_selectedContact!.displayName),
                  subtitle: Text(_selectedContact!.phone),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedContact = null),
                  ),
                ),
              ),
            ] else ...[
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM,
                    vertical: AppDimens.paddingS,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _isSearching = value.isNotEmpty);
                },
              ),
              
              // Contact list
              if (_isSearching)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: _buildContactList(),
                ),
            ],
            
            const SizedBox(height: AppDimens.paddingM),
            
            // Priority dropdown
            const Text(
              'Priority',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppDimens.paddingS),
            
            DropdownButtonFormField<ScenarioTaskPriority>(
              initialValue: _priority,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM,
                  vertical: AppDimens.paddingS,
                ),
              ),
              items: ScenarioTaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Icon(priority.icon, color: priority.color, size: 20),
                      const SizedBox(width: 8),
                      Text(priority.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),
            
            const SizedBox(height: AppDimens.paddingM),
            
            // Due date picker
            const Text(
              'Due Date (optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppDimens.paddingS),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _dueDate != null 
                          ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                          : 'Select date',
                    ),
                  ),
                ),
                if (_dueDate != null) ...[
                  const SizedBox(width: AppDimens.paddingS),
                  IconButton(
                    onPressed: () => setState(() => _dueDate = null),
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: AppDimens.paddingM),
            
            // Notes field
            const Text(
              'Notes (optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppDimens.paddingS),
            
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
              ),
            ),
            
            const SizedBox(height: AppDimens.paddingL),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppDimens.paddingS),
                FilledButton(
                  onPressed: _selectedContact != null ? _saveTask : null,
                  child: const Text('Add Task'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactList() {
    final contacts = ref.watch(contactListProvider);
    
    return contacts.when(
      data: (contactList) {
        final searchTerm = _searchController.text.toLowerCase();
        final filtered = contactList.where((c) {
          return c.displayName.toLowerCase().contains(searchTerm) ||
              c.phone.contains(searchTerm);
        }).take(10).toList();
        
        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppDimens.paddingM),
            child: Text('No contacts found'),
          );
        }
        
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = filtered[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(contact.displayName[0].toUpperCase()),
                ),
                title: Text(contact.displayName),
                subtitle: Text(contact.phone),
                onTap: () {
                  setState(() {
                    _selectedContact = contact;
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Error loading contacts'),
    );
  }
  
  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }
  
  void _saveTask() async {
    if (_selectedContact == null) return;
    
    final task = await ref.read(scenarioNotifierProvider.notifier).createTask(
      scenarioId: widget.scenario.id,
      contactId: _selectedContact!.id,
      phone: _selectedContact!.phone,
      name: _selectedContact!.name,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      dueDate: _dueDate,
      priority: _priority.backendValue,
    );
    
    if (task != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added')),
      );
    }
  }
}
