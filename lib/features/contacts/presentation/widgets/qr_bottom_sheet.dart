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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(50, 12, 50, 16),
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
            const SizedBox(height: 16),

            // Title
            Text(
              'Share QR Code',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share with church members via WhatsApp',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // QR Code
            ContactQRCode(contact: contact),

            const SizedBox(height: 16),
            // Share Button
            QRShareButton(contact: contact),
          ],
        ),
      ),
    );
  }
}