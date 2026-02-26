import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    if (!contact.isEligibleForQRCode) {
      return _buildNotEligible(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── QR Code ────────────────────────────────────────────
        // Role badge is OUTSIDE the QR container — never overlaps
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, // always white bg for max contrast
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              QrImageView(
                data: contact.phone,
                version: QrVersions.auto,
                size: size,
                gapless: true,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel
                    .H, // H = 30% tolerance, needed for center overlay
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
                errorStateBuilder: (context, error) => SizedBox(
                  width: size,
                  height: size,
                  child: const Center(
                    child: Text(
                      'Could not generate QR code',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              // ── Center avatar overlay (Samsung-style) ──────────────
              Container(
                width:
                    size * 0.22, // ~22% of QR size — safe zone for H-level ECC
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: _getAvatarColor(contact),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(contact),
                    style: TextStyle(
                      fontSize: size * 0.075,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Contact Name ───────────────────────────────────────
        Text(
          contact.name ?? contact.phone,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // ── Phone Number ───────────────────────────────────────
        Text(
          contact.phone,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // ── Role Badge row — fully OUTSIDE the QR ─────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (contact.primaryRoleTag != null)
              _buildBadge(
                icon: contact.roleIcon,
                label:
                    contact.primaryRole?.displayName ?? contact.primaryRoleTag!,
                color: contact.roleColor,
              ),
            if (contact.isMember)
              _buildBadge(
                icon: Icons.card_membership,
                label: 'Member',
                color: Colors.green,
              ),
            if (contact.location != null)
              _buildBadge(
                icon: Icons.location_on,
                label:
                    contact.location!.substring(0, 1).toUpperCase() +
                    contact.location!.substring(1),
                color: Colors.red,
              ),
          ],
        ),
      ],
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
        color: color.withValues(alpha: 0.1),
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
          Icon(Icons.qr_code_2, size: size * 0.6, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'QR code not available',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Only members with names can have QR codes',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _getInitials(Contact contact) {
  if (contact.name != null && contact.name!.isNotEmpty) {
    final parts = contact.name!.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return contact.name![0].toUpperCase();
  }
  return contact.phone.substring(0, 2);
}

Color _getAvatarColor(Contact contact) {
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
  return colors[contact.phone.hashCode.abs() % colors.length];
}
