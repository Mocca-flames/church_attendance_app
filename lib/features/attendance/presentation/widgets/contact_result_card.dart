import 'dart:convert';

import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/contact_search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Card widget for displaying a contact in search results.
///
/// Watches [markedContactIdsProvider] directly so it rebuilds the instant
/// attendance is marked — no prop drilling or parent setState required.
class ContactResultCard extends ConsumerWidget {
  final ContactEntity contact;
  final ServiceType serviceType;
  final int recordedBy;
  final VoidCallback? onAttendanceMarked;

  const ContactResultCard({
    required this.contact,
    required this.serviceType,
    super.key,
    this.recordedBy = 1,
    this.onAttendanceMarked,
  });

  List<String> get _tags {
    if (contact.metadata == null || contact.metadata!.isEmpty) return [];
    try {
      final Map<String, dynamic> meta = jsonDecode(contact.metadata!);
      if (meta.containsKey('tags') && meta['tags'] is List) {
        return (meta['tags'] as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  bool _hasTag(String tag) => _tags.contains(tag);
  bool get _isMember => _hasTag('member');
  String get _displayName => contact.name ?? contact.phone;

  bool get _needsUpdate {
    try {
      final name = contact.name;
      if (name == null || name.isEmpty) return false;
      return name == contact.phone;
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
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                ),
                const SizedBox(height: AppDimens.paddingM),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    hintText: 'Enter location',
                  ),
                ),
                const SizedBox(height: AppDimens.paddingM),
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
                logger.d('contact.id: ${contact.id} (type: ${contact.id.runtimeType})');
                logger.d('contact.phone: ${contact.phone} (type: ${contact.phone.runtimeType})');
                logger.d('contact.name: ${contact.name} (type: ${contact.name?.runtimeType})');
                logger.d('serviceType: $serviceType');
                logger.d('recordedBy: $recordedBy');
                logger.d('isMember: $isMember');
                logger.d('formKey.currentState: ${formKey.currentState}');
                
                if (formKey.currentState!.validate()) {
                  logger.d('Form validation passed, popping dialog with true');
                  Navigator.pop(context, true);
                } else {
                  logger.d('Form validation failed, showing snackbar');
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter a valid name.'),
                    backgroundColor: Colors.red,
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
      logger.d('contact.phone: ${contact.phone}');
      logger.d('serviceType: $serviceType');
      logger.d('recordedBy: $recordedBy');
      logger.d('isMember: $isMember');

      try {
        logger.d('Calling createContactAndRecordAttendance...');
        final updateResult = await ref
            .read(attendanceProvider.notifier)
            .createContactAndRecordAttendance(
              phone: contact.phone,
              name: name,
              serviceType: serviceType,
              serviceDate: DateTime.now(),
              recordedBy: recordedBy,
              isMember: isMember,
              location: location,
            );
        
        logger.d('createContactAndRecordAttendance result: $updateResult');

        if (!context.mounted) {
          logger.d('Context not mounted, returning');
          return;
        }

        logger.d('About to update markedContactIdsProvider with contact.id: ${contact.id} (type: ${contact.id.runtimeType})');
        logger.d('Current markedContactIdsProvider state: ${ref.read(markedContactIdsProvider)}');
        
        // Optimistically mark in provider so UI updates immediately.
        ref.read(markedContactIdsProvider.notifier).add(contact.id);
        
        logger.d('markedContactIdsProvider state after add: ${ref.read(markedContactIdsProvider)}');

        logger.d('=== _showUpdateDialog result END ===');
        if (updateResult.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${updateResult.error}'),
            backgroundColor: Colors.red,
          ));
        } else {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Updated & Marked: $name',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ));
          logger.d('Calling onAttendanceMarked callback...');
          onAttendanceMarked?.call();
          logger.d('onAttendanceMarked callback complete');
        }
        logger.d('=== _showUpdateDialog FULLY COMPLETE ===');
      } catch (e, stackTrace) {
        logger.e('Exception in _showUpdateDialog: $e');
        logger.e('Stack trace: $stackTrace');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  Future<void> _markAttendance(BuildContext context, WidgetRef ref) async {
    final Logger logger = Logger();
    logger.d('=== _markAttendance START ===');
    logger.d('contact.id: ${contact.id} (type: ${contact.id.runtimeType})');
    logger.d('contact.phone: ${contact.phone} (type: ${contact.phone.runtimeType})');
    logger.d('contact.name: ${contact.name} (type: ${contact.name?.runtimeType})');
    logger.d('serviceType: $serviceType');
    logger.d('recordedBy: $recordedBy');

    // Read current marked set — if already marked, bail early.
    final alreadyMarked = ref.read(markedContactIdsProvider).contains(contact.id);
    logger.d('alreadyMarked: $alreadyMarked');
    if (alreadyMarked) {
      logger.d('=== _markAttendance END (already marked) ===');
      return;
    }

    try {
      logger.d('Calling recordAttendance...');
      final attendance =
          await ref.read(attendanceProvider.notifier).recordAttendance(
                contactId: contact.id,
                phone: contact.phone,
                serviceType: serviceType,
                serviceDate: DateTime.now(),
                recordedBy: recordedBy,
              );
      logger.d('recordAttendance result: $attendance');

      if (attendance != null) {
        HapticFeedback.heavyImpact();
        logger.i('Attendance recorded for $_displayName');

        // ✅ Optimistically update the shared provider BEFORE the parent
        // re-queries the DB. This gives instant visual feedback.
        ref.read(markedContactIdsProvider.notifier).add(contact.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Marked: $_displayName',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ));
        }

        // Also trigger the parent refresh so the DB and provider stay in sync.
        onAttendanceMarked?.call();
      }
      logger.d('=== _markAttendance END ===');
    } on AttendanceException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(e.message)),
          ]),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e, stackTrace) {
      logger.e('Exception in _markAttendance: $e');
      logger.e('Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to mark attendance: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the shared provider — rebuilds this card instantly when any
    // contact is marked, with no parent setState required.
    final isAlreadyMarked =
        ref.watch(markedContactIdsProvider).contains(contact.id);

    return Opacity(
      opacity: isAlreadyMarked ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isAlreadyMarked
                ? Colors.green.withValues(alpha: 0.2)
                : _isMember
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
            child: isAlreadyMarked
                ? const Icon(Icons.check, color: Colors.green)
                : Icon(Icons.person,
                    color: _isMember ? AppColors.primary : Colors.grey),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _displayName,
                  style: TextStyle(
                    fontWeight:
                        _isMember ? FontWeight.bold : FontWeight.normal,
                    decoration: isAlreadyMarked
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              if (_isMember)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'MEMBER',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            contact.phone,
            style: TextStyle(
                decoration:
                    isAlreadyMarked ? TextDecoration.lineThrough : null),
          ),
          trailing: isAlreadyMarked
              ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
              : const Icon(Icons.touch_app, color: Colors.grey),
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
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Container(
          height: 16,
          width: 120,
          decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4)),
        ),
        subtitle: Container(
          height: 12,
          width: 80,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}