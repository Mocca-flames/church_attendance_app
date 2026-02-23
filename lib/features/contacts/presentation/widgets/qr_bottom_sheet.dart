import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/contact_qr_code.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/qr_share_button.dart';
import 'package:flutter/material.dart';

/// Modal bottom sheet that displays a contact's QR code.
/// 
/// Usage:
/// ```dart
/// if (contact.isEligibleForQRCode) {
///   showQRBottomSheet(context, contact);
/// }
/// ```
void showQRBottomSheet(BuildContext context, Contact contact) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _QRBottomSheet(contact: contact),
  );
}

class _QRBottomSheet extends StatelessWidget {
  final Contact contact;

  const _QRBottomSheet({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Your QR Code',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Show this at the entrance for quick check-in',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // QR Code
          ContactQRCode(contact: contact),

          const SizedBox(height: 24),

          // Share Button
          QRShareButton(contact: contact),

          const SizedBox(height: 16),

          // Close Button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
