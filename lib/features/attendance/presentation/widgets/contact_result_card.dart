import 'dart:convert';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card widget for displaying a contact in search results.
///
/// Features:
/// - Shows contact name and phone
/// - MEMBER badge for contacts with 'member' tag
/// - Already marked indicator (checkmark + grayed out)
/// - Tap to mark attendance
class ContactResultCard extends ConsumerWidget {
  final ContactEntity contact;
  final ServiceType serviceType;
  final bool isAlreadyMarked;
  final int recordedBy;
  final VoidCallback? onAttendanceMarked;

  const ContactResultCard({
    required this.contact,
    required this.serviceType,
    this.isAlreadyMarked = false,
    super.key,
    this.recordedBy = 1,
    this.onAttendanceMarked,
  });

  /// Extract tags from metadata JSON
  List<String> get _tags {
    if (contact.metadata == null || contact.metadata!.isEmpty) return [];
    try {
      final Map<String, dynamic> meta = jsonDecode(contact.metadata!);
      if (meta.containsKey('tags') && meta['tags'] is List) {
        return (meta['tags'] as List).map((e) => e.toString()).toList();
      }
    } catch (e) {
      // Invalid JSON, return empty
    }
    return [];
  }

  /// Check if contact has a specific tag
  bool _hasTag(String tag) => _tags.contains(tag);

  /// Check if contact is a member
  bool get _isMember => _hasTag('member');

  /// Get display name (use name if available, otherwise phone)
  String get _displayName => contact.name ?? contact.phone;

  Future<void> _markAttendance(BuildContext context, WidgetRef ref) async {
    if (isAlreadyMarked) return;

    try {
      final attendance =
          await ref.read(attendanceProvider.notifier).recordAttendance(
                contactId: contact.id,
                phone: contact.phone,
                serviceType: serviceType,
                serviceDate: DateTime.now(),
                recordedBy: recordedBy,
              );

      if (attendance != null) {
        // Haptic feedback
        HapticFeedback.mediumImpact();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Marked: $_displayName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Callback
        onAttendanceMarked?.call();
      }
    } on AttendanceException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(e.message)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                : Icon(
                    Icons.person,
                    color: _isMember ? AppColors.primary : Colors.grey,
                  ),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            contact.phone,
            style: TextStyle(
              decoration: isAlreadyMarked ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: isAlreadyMarked
              ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
              : const Icon(Icons.touch_app, color: Colors.grey),
          onTap: isAlreadyMarked ? null : () => _markAttendance(context, ref),
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
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Container(
          height: 16,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Container(
          height: 12,
          width: 80,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
