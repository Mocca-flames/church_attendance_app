import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/qr_bottom_sheet.dart';
import 'package:flutter/material.dart';

/// Contact card with QR code button for eligible members.
/// 
/// Modernized with a flat design, borders, and refined spacing.
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
    // Using a Container with decoration instead of Card to remove elevation
    // and implement the flat, bordered look.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar with subtle border ring
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getAvatarColor().withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: _getAvatarColor().withValues(alpha: 0.1),
                    child: Text(
                      _getInitials(),
                      style: TextStyle(
                        color: _getAvatarColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name
                      Text(
                        contact.name ?? contact.phone,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Phone
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, 
                            size: 14, 
                            color: Colors.grey[500]
                          ),
                          const SizedBox(width: 4),
                          Text(
                            contact.phone,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      // Tags
                      if (contact.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: contact.tags.take(3).map((tag) {
                              final tagColor = _getTagColor(tag);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: tagColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: tagColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: tagColor,
                                    fontWeight: FontWeight.w600,
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
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      onTap: () => _showQRCode(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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