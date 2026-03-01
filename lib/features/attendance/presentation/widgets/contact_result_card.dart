import 'dart:convert';

import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/contact_search_provider.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';


/// Card widget for displaying a contact in search results.
///
/// Uses local state for instant UI feedback - the card updates immediately
/// when tapped, then syncs with the database in the background.
class ContactResultCard extends ConsumerStatefulWidget {
  final ContactEntity contact;
  final ServiceType serviceType;
  final DateTime serviceDate;
  final int recordedBy;
  final VoidCallback? onAttendanceMarked;

  const ContactResultCard({
    required this.contact,
    required this.serviceType,
    required this.serviceDate,
    super.key,
    this.recordedBy = 1,
    this.onAttendanceMarked,
  });

  @override
  ConsumerState<ContactResultCard> createState() => _ContactResultCardState();
}

class _ContactResultCardState extends ConsumerState<ContactResultCard> {
  // Local state for instant UI feedback - updates immediately on tap
  bool _localIsMarked = false;

  // Local getters for widget properties
  ContactEntity get _contact => widget.contact;
  ServiceType get _serviceType => widget.serviceType;
  DateTime get _serviceDate => widget.serviceDate;
  int get _recordedBy => widget.recordedBy;
  VoidCallback? get _onAttendanceMarked => widget.onAttendanceMarked;

  @override
  void initState() {
    super.initState();
    // Initialize from provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithProvider();
    });
  }

  void _syncWithProvider() {
    final providerMarked = ref.read(markedContactIdsProvider.select(
      (state) => state.markedIds.contains(_contact.id),
    ));
    if (mounted && _localIsMarked != providerMarked) {
      setState(() {
        _localIsMarked = providerMarked;
      });
    }
  }

  List<String> get _tags {
    if (_contact.metadata == null || _contact.metadata!.isEmpty) return [];
    try {
      final Map<String, dynamic> meta = jsonDecode(_contact.metadata!);
      if (meta.containsKey('tags') && meta['tags'] is List) {
        return (meta['tags'] as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  bool _hasTag(String tag) => _tags.contains(tag);
  bool get _isMember => _hasTag('member');
  String get _displayName => _contact.name ?? _contact.phone;

  /// Check if contact has a valid location in metadata
  bool get _hasLocation {
    for (final tag in _tags) {
      if (tag != 'member' && ContactLocations.isValidLocation(tag)) {
        return true;
      }
    }
    return false;
  }

  /// Get the location from metadata if exists
  String? get _location {
    for (final tag in _tags) {
      if (tag != 'member' && ContactLocations.isValidLocation(tag)) {
        return tag;
      }
    }
    return null;
  }

  bool get _needsUpdate {
    try {
      final name = _contact.name;
      if (name == null || name.isEmpty) return false;
      return name == _contact.phone;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showUpdateDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    bool isMember = _isMember;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Contact'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter contact name',
                  ).applyDefaults(Theme.of(context).inputDecorationTheme),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: AppDimens.paddingM),
                
                // Location field - only show if contact doesn't have location
                if (!_hasLocation) ...[
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location (optional)',
                      hintText: 'Enter location',
                    ).applyDefaults(Theme.of(context).inputDecorationTheme),
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Theme.of(context).colorScheme.tertiary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location: $_location',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SwitchListTile(
                  title: const Text('Mark as Member'),
                  value: isMember,
                  onChanged: (value) => setState(() => isMember = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final Logger logger = Logger();
                logger.d('=== FilledButton onPressed START ===');
                logger.d(
                    'contact.id: ${_contact.id} (type: ${_contact.id.runtimeType})');
                logger.d(
                    'contact.phone: ${_contact.phone} (type: ${_contact.phone.runtimeType})');
                logger.d(
                    'contact.name: ${_contact.name} (type: ${_contact.name?.runtimeType})');
                logger.d('serviceType: $_serviceType');
                logger.d('recordedBy: $_recordedBy');
                logger.d('isMember: $isMember');
                logger.d('formKey.currentState: ${formKey.currentState}');

                if (formKey.currentState!.validate()) {
                  logger.d('Form validation passed, popping dialog with true');
                  Navigator.pop(context, true);
                } else {
                  logger.d('Form validation failed, showing snackbar');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Please enter a valid name.'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ));
                }
                logger.d('=== FilledButton onPressed END ===');
              },
              child: const Text('Update & Mark'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      final Logger logger = Logger();
      logger.d('=== _showUpdateDialog result START ===');
      logger.d('result: $result');

      final name = nameController.text.trim();
      final location = locationController.text.trim().isEmpty
          ? null
          : locationController.text.trim();

      logger.d('name: $name');
      logger.d('location: $location');
      logger.d('contact.phone: ${_contact.phone}');
      logger.d('serviceType: $_serviceType');
      logger.d('recordedBy: $_recordedBy');
      logger.d('isMember: $isMember');

      try {
        logger.d('Calling createContactAndRecordAttendance...');
        // ✅ FIRST: Optimistically update UI SYNCHRONOUSLY before async work
        ref.read(markedContactIdsProvider.notifier).add(_contact.id);
        
        await HapticFeedback.mediumImpact();
       
        
        // Then perform the actual database operation
        final updateResult = await ref
            .read(attendanceProvider.notifier)
            .createContactAndRecordAttendance(
              phone: _contact.phone,
              name: name,
              serviceType: _serviceType,
              serviceDate: _serviceDate,
              recordedBy: _recordedBy,
              isMember: isMember,
              location: location,
            );

        logger.d('createContactAndRecordAttendance result: $updateResult');

        if (!context.mounted) {
          logger.d('Context not mounted, returning');
          return;
        }

        logger.d('=== _showUpdateDialog result END ===');
        if (updateResult.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${updateResult.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        } else {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Updated & Marked: $name',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onTertiary)),
              ),
            ]),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ));
          logger.d('Calling onAttendanceMarked callback...');
          _onAttendanceMarked?.call();
          logger.d('onAttendanceMarked callback complete');
        }
        logger.d('=== _showUpdateDialog FULLY COMPLETE ===');
      } catch (e, stackTrace) {
        logger.e('Exception in _showUpdateDialog: $e');
        logger.e('Stack trace: $stackTrace');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        }
      }
    }
  }

  Future<void> _markAttendance(BuildContext context, WidgetRef ref) async {
    final Logger logger = Logger();
    logger.d('=== _markAttendance START ===');
    logger.d('contact.id: ${_contact.id} (type: ${_contact.id.runtimeType})');
    logger.d(
        'contact.phone: ${_contact.phone} (type: ${_contact.phone.runtimeType})');
    logger.d(
        'contact.name: ${_contact.name} (type: ${_contact.name?.runtimeType})');
    logger.d('serviceType: $_serviceType');
    logger.d('recordedBy: $_recordedBy');

    // Read current marked set — if already marked, bail early.
    // Using read() with select() to get just this contact's status
    final alreadyMarked =
        ref.read(markedContactIdsProvider.select(
          (state) => state.markedIds.contains(_contact.id),
        ));
    logger.d('alreadyMarked: $alreadyMarked');
    if (alreadyMarked) {
      logger.d('=== _markAttendance END (already marked) ===');
      return;
    }

    try {
      // ✅ FIRST: Update local state SYNCHRONOUSLY for instant UI feedback
      setState(() {
        _localIsMarked = true;
      });
      
      // Also update the provider for other widgets
      ref.read(markedContactIdsProvider.notifier).add(_contact.id);
      
      // Trigger haptic feedback immediately for tactile confirmation
      try {
        await HapticFeedback.heavyImpact();
      } catch (e) {
        logger.w('Haptic feedback failed: $e');
      }

      logger.d('Calling recordAttendance...');
      // Then perform the actual database operation (can be slow, UI is already updated)
      final attendance =
          await ref.read(attendanceProvider.notifier).recordAttendance(
                contactId: _contact.id,
                phone: _contact.phone,
                serviceType: _serviceType,
                serviceDate: _serviceDate,
                recordedBy: _recordedBy,
              );
      logger.d('recordAttendance result: $attendance');

      if (attendance != null) {
        logger.i('Attendance recorded for $_displayName');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Marked: $_displayName',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onTertiary)),
              ),
            ]),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ));
        }

        // Also trigger the parent refresh so the DB and provider stay in sync.
        _onAttendanceMarked?.call();
      }
      logger.d('=== _markAttendance END ===');
    } on AttendanceException catch (e) {
      // Rollback the local state on error
      setState(() {
        _localIsMarked = false;
      });
      ref.read(markedContactIdsProvider.notifier).remove(_contact.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.onError),
            const SizedBox(width: 8),
            Expanded(child: Text(e.message)),
          ]),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e, stackTrace) {
      logger.e('Exception in _markAttendance: $e');
      logger.e('Stack trace: $stackTrace');
      // Rollback the local state on error
      setState(() {
        _localIsMarked = false;
      });
      ref.read(markedContactIdsProvider.notifier).remove(_contact.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to mark attendance: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use local state for instant UI feedback - updates immediately when tapped
    // Once marked, stay marked (don't sync backwards from provider)
    final isAlreadyMarked = _localIsMarked;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
      decoration: BoxDecoration(
        color: isAlreadyMarked ? Theme.of(context).colorScheme.tertiaryContainer : null,
        borderRadius: BorderRadius.circular(12),
        border: isAlreadyMarked
            ? Border.all(color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: isAlreadyMarked ? Theme.of(context).colorScheme.tertiaryContainer : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isAlreadyMarked
                ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15)
                : _isMember
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: isAlreadyMarked
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.tertiary)
                : Icon(Icons.person,
                    color: _isMember ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _displayName,
                  style: TextStyle(
                    fontWeight: _isMember ? FontWeight.bold : FontWeight.normal,
                    decoration:
                        isAlreadyMarked ? TextDecoration.lineThrough : null,
                    color: isAlreadyMarked ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                  ),
                ),
              ),
              if (_isMember)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'MEMBER',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              
            ],
          ),
          subtitle: Text(
            _contact.phone,
            style: TextStyle(
                decoration: isAlreadyMarked ? TextDecoration.lineThrough : null,
                color: isAlreadyMarked ? Theme.of(context).colorScheme.onSurfaceVariant : null),
          ),
          trailing: isAlreadyMarked
              ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.tertiary, size: 28)
              : Icon(Icons.touch_app, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onTap: isAlreadyMarked
              ? null
              : _needsUpdate
                  ? () => _showUpdateDialog(context, ref)
                  : () => _markAttendance(context, ref),
        ),
      ),
    );
  }
}

/// Loading placeholder for contact cards.
class ContactResultCardSkeleton extends StatelessWidget {
  const ContactResultCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Use theme-aware skeleton colors that work in both light and dark modes
    final skeletonColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    final skeletonSubtleColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05);
    
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: skeletonSubtleColor,
          child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        title: Container(
          height: 16,
          width: 120,
          decoration: BoxDecoration(
              color: skeletonColor, borderRadius: BorderRadius.circular(4)),
        ),
        subtitle: Container(
          height: 12,
          width: 80,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
              color: skeletonSubtleColor, borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}
