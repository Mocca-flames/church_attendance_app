// ignore_for_file: unused_element_parameter

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
        // ── QR Code with Decorative Container ─────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Role Badge at Top ──────────────────────────────
              if (contact.primaryRoleTag != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: contact.roleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: contact.roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(contact.roleIcon, color: contact.roleColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        contact.primaryRole?.displayName ?? contact.primaryRoleTag!,
                        style: TextStyle(
                          color: contact.roleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── QR Code with Decorative Frame ──────────────────
              Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative corner markers
                  Positioned.fill(
                    child: _DecorativeCorners(color: contact.roleColor.withValues(alpha: 0.6)),
                  ),

                  // Main QR Code
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: contact.phone,
                      version: QrVersions.auto,
                      size: size,
                      gapless: true,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
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
                  ),

                  // ── Center Logo Overlay ─────────────────────────────
                  Container(
                    width: size * 0.22,
                    height: size * 0.22,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
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
                icon: Icons.contact_phone,
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

/// Decorative corner markers for QR code frame
class _DecorativeCorners extends StatelessWidget {
  final Color color;
  final double cornerSize;
  final double strokeWidth;

  const _DecorativeCorners({
    required this.color,
    this.cornerSize = 24,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left corner
        Positioned(
          left: 0,
          top: 0,
          child: _buildCorner(CornerPosition.topLeft),
        ),
        // Top-right corner
        Positioned(
          right: 0,
          top: 0,
          child: _buildCorner(CornerPosition.topRight),
        ),
        // Bottom-left corner
        Positioned(
          left: 0,
          bottom: 0,
          child: _buildCorner(CornerPosition.bottomLeft),
        ),
        // Bottom-right corner
        Positioned(
          right: 0,
          bottom: 0,
          child: _buildCorner(CornerPosition.bottomRight),
        ),
      ],
    );
  }

  Widget _buildCorner(CornerPosition position) {
    return CustomPaint(
      size: Size(cornerSize, cornerSize),
      painter: _CornerPainter(
        color: color,
        strokeWidth: strokeWidth,
        position: position,
      ),
    );
  }
}

enum CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final CornerPosition position;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double cornerSize = size.width * 0.6;

    switch (position) {
      case CornerPosition.topLeft:
        path
          ..moveTo(0, cornerSize)
          ..lineTo(0, 0)
          ..lineTo(cornerSize, 0);
        break;
      case CornerPosition.topRight:
        path
          ..moveTo(size.width - cornerSize, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, cornerSize);
        break;
      case CornerPosition.bottomLeft:
        path
          ..moveTo(0, size.height - cornerSize)
          ..lineTo(0, size.height)
          ..lineTo(cornerSize, size.height);
        break;
      case CornerPosition.bottomRight:
        path
          ..moveTo(size.width, size.height - cornerSize)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width - cornerSize, size.height);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


