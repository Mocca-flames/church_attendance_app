import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Widget that displays a QR code for a contact.
/// 
/// The QR code contains the contact's phone number.
/// Only shows for eligible contacts (members with real names).
/// Includes role-based icon and color customization.
class ContactQRCode extends StatelessWidget {
  final Contact contact;
  final double size;
  final bool showRoleIcon;

  const ContactQRCode({
    required this.contact,
    super.key,
    this.size = 200,
    this.showRoleIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    // Check if contact is eligible for QR code
    if (!contact.isEligibleForQRCode) {
      return _buildNotEligible(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code with role badge
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: contact.phone,
                version: QrVersions.auto,
                size: size,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: contact.roleColor,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: contact.roleColor,
                ),
              ),
            ),
            // Role Badge
            if (showRoleIcon && contact.primaryRoleTag != null)
              Positioned(
                top: 8,
                right: 8,
                child: _buildRoleBadge(),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Contact Name
        Text(
          contact.name ?? contact.phone,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // Phone Number
        Text(
          contact.phone,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Role and Member Badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            // Role Badge
            if (contact.primaryRoleTag != null)
              _buildBadge(
                icon: contact.roleIcon,
                label: contact.primaryRole?.displayName ?? contact.primaryRoleTag!,
                color: contact.roleColor,
              ),
            // Member Badge
            if (contact.isMember)
              _buildBadge(
                icon: Icons.card_membership,
                label: 'Member',
                color: Colors.green,
              ),
            // Location Badge
            if (contact.location != null)
              _buildBadge(
                icon: Icons.location_on,
                label: contact.location!.substring(0, 1).toUpperCase() + 
                       contact.location!.substring(1),
                color: Colors.red,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: contact.roleColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        contact.roleIcon,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotEligible(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code_2,
            size: size,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'QR code not available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Only members with names can have QR codes',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
