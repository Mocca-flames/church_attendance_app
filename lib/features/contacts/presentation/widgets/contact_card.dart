import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/qr_bottom_sheet.dart';
import 'package:flutter/material.dart';

/// Contact card with QR code button for eligible members.
/// 
/// Usage:
/// ```dart
/// ContactCard(
///   contact: contact,
///   onTap: () => navigateToDetail(contact),
/// )
/// ```
class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ContactCard({
    required this.contact,
    super.key,
    this.onTap,
    this.trailing,
  });

  void _showQRCode(BuildContext context) {
    if (contact.isEligibleForQRCode) {
      showQRBottomSheet(context, contact);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: _getAvatarColor(),
                child: Text(
                  _getInitials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      contact.name ?? contact.phone,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Phone
                    Text(
                      contact.phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),

                    // Tags
                    if (contact.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: contact.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTagColor(tag).withValues(alpha:.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getTagColor(tag),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getTagColor(tag),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),

              // QR Button or Trailing
              if (trailing != null)
                trailing!
              else if (contact.isEligibleForQRCode)
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => _showQRCode(context),
                  tooltip: 'Show QR Code',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha:0.1),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (contact.name != null && contact.name!.isNotEmpty) {
      final parts = contact.name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return contact.name![0].toUpperCase();
    }
    return contact.phone.substring(0, 2);
  }

  Color _getAvatarColor() {
    // Generate a consistent color based on phone number
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

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'member':
        return Colors.green;
      case 'servant':
        return Colors.blue;
      case 'pastor':
        return Colors.purple;
      case 'lead':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
