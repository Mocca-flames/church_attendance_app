import 'dart:io';
import 'dart:ui' as ui;

import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Button that shares a contact's QR code via WhatsApp.
/// 
/// Generates a QR code image and shares it with a pre-filled message.
class QRShareButton extends StatefulWidget {
  final Contact contact;

  const QRShareButton({
    
    required this.contact,super.key,
  });

  @override
  State<QRShareButton> createState() => _QRShareButtonState();
}

class _QRShareButtonState extends State<QRShareButton> {
  bool _isSharing = false;
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _shareQRCode() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      // Wait for the widget to render
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture the QR code widget as an image
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate QR code'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate QR code image'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_${widget.contact.id}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Share via WhatsApp
      final message = '''
Hi ${widget.contact.name ?? 'there'}! 

Here's your QR code for church attendance. Simply show this at the entrance to check in quickly.

God bless! 

${widget.contact.phone}
''';

      await SharePlus.instance.share(
        ShareParams(
          text: message,
          files: [XFile(file.path)],
          subject: 'Your Church QR Code',
        ),
      );

      // Clean up temp file after a delay
      Future.delayed(const Duration(minutes: 5), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show for eligible contacts
    if (!widget.contact.isEligibleForQRCode) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hidden QR code widget for capturing
        Opacity(
          opacity: 0,
          child: RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // QR Code
                  QrImageView(
                    data: widget.contact.phone,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  // Contact Name
                  Text(
                    widget.contact.name ?? widget.contact.phone,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Phone
                  Text(
                    widget.contact.phone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Share button
        ElevatedButton.icon(
          onPressed: _isSharing ? null : _shareQRCode,
          icon: _isSharing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.share),
          label: Text(_isSharing ? 'Sharing...' : 'Share via WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), // WhatsApp green
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
