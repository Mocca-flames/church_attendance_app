import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/contact_tag.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/qr_bottom_sheet.dart';
import 'package:church_attendance_app/features/contacts/screens/contact_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contact Detail Screen to view contact information.
///
/// Features:
/// - Display contact details (name, phone, tags)
/// - Show/edit tags
/// - Delete contact option
/// - QR code for eligible members
class ContactDetailScreen extends ConsumerWidget {
  final Contact contact;

  const ContactDetailScreen({ required this.contact, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for contact updates
    final contactAsync = ref.watch(contactByIdProvider(contact.id));
    final displayContact = contactAsync.whenOrNull(data: (c) => c) ?? contact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context, displayContact),
            tooltip: 'Edit Contact',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and Name Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: _getAvatarColor(displayContact),
                    child: Text(
                      _getInitials(displayContact),
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingM),
                  Text(
                    displayContact.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (displayContact.isMember)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text(
                        'Member',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),

            // Contact Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    _buildInfoRow(
                      context,
                      Icons.phone,
                      'Phone',
                      displayContact.phone,
                    ),
                    if (displayContact.name != null)
                      _buildInfoRow(
                        context,
                        Icons.person,
                        'Name',
                        displayContact.name!,
                      ),
                    _buildInfoRow(
                      context,
                      Icons.calendar_today,
                      'Created',
                      _formatDate(displayContact.createdAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),

            // Tags Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimens.paddingM),
                    if (displayContact.tags.isEmpty)
                      Text(
                        'No tags assigned',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: displayContact.tags.map((tag) {
                          final contactTag = ContactTag.fromValue(tag);
                          final color = contactTag?.color ?? Colors.grey;
                          return Chip(
                            avatar: Icon(
                              contactTag?.icon ?? Icons.label,
                              size: 18,
                              color: color,
                            ),
                            label: Text(Contact.getTagDisplayName(tag)),
                            backgroundColor: color.withValues(alpha:0.1),
                            side: BorderSide(color: color),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            // QR Code Section (for eligible contacts)
            if (displayContact.isEligibleForQRCode)
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.paddingM),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR Code',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimens.paddingM),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () => showQRBottomSheet(context, displayContact),
                            icon: const Icon(Icons.qr_code),
                            label: const Text('Show QR Code'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: AppDimens.paddingM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getInitials(Contact contact) {
    if (contact.name != null && contact.name!.isNotEmpty) {
      final parts = contact.name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return contact.name![0].toUpperCase();
    }
    return contact.phone.substring(0, 2);
  }

  Color _getAvatarColor(Contact contact) {
    final hash = contact.phone.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[hash.abs() % colors.length];
  }

  void _navigateToEdit(BuildContext context, Contact contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContactEditScreen(contact: contact),
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Contact'),
          content: const Text(
            'Are you sure you want to delete this contact? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        final success = await ref.read(contactNotifierProvider.notifier)
            .deleteContact(contact.id);
        
        if (success && context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact deleted')),
          );
        }
      }
    }
  }
}
