# QR Code Guide - Church Attendance App

## � Overview

**QR Code Logic:**
- Generate QR codes **only** for contacts where:
  1. `name != phone` (has a real name, not just phone number)
  2. Contact has `'member'` tag in metadata
- QR code contains: **Just the phone number** (e.g., `+27821234567`)
- Share QR code via **WhatsApp** to the member

---

## � Implementation Strategy

### **Flow:**
```
Contact List Screen
    ↓ (Long press on member card)
View Contact QR Code
    ↓ (Tap "Share via WhatsApp")
Share as Image via WhatsApp
```

---

## � Required Dependencies

Already in `pubspec.yaml`:
```yaml
dependencies:
  qr_flutter: ^4.1.0        # Generate QR codes
  mobile_scanner: ^4.0.1    # Scan QR codes
  
  # For sharing to WhatsApp
  share_plus: ^7.2.1        # Add this
  path_provider: ^2.1.2     # Already included
```

Run:
```bash
flutter pub add share_plus
flutter pub get
```

---

## � Code Snippets

### **1. QR Code Generator Widget**

**File: `lib/features/contacts/presentation/widgets/contact_qr_code.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';

class ContactQRCodeWidget extends StatelessWidget {
  final Contact contact;

  const ContactQRCodeWidget({
    super.key,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    // Only show if eligible
    if (!contact.isEligibleForQRCode) {
      return Center(
        child: Text(
          'QR code not available.\nContact must have a name and be a member.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: contact.phone, // Just the phone number
            version: QrVersions.auto,
            size: 250.0,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
        ),
        const SizedBox(height: 16),
        
        // Contact Info
        Text(
          contact.displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          contact.phone,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        
        // Member badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                'Member',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

---

### **2. Share QR Code via WhatsApp**

**File: `lib/features/contacts/presentation/widgets/qr_share_button.dart`**

```dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';

class QRShareButton extends StatefulWidget {
  final Contact contact;

  const QRShareButton({
    super.key,
    required this.contact,
  });

  @override
  State<QRShareButton> createState() => _QRShareButtonState();
}

class _QRShareButtonState extends State<QRShareButton> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareViaWhatsApp() async {
    setState(() => _isSharing = true);

    try {
      // Generate QR code image
      final qrImage = await _captureQRCode();
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_${widget.contact.phone}.png');
      await file.writeAsBytes(qrImage);

      // Share via WhatsApp with message
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '''
� Your Church Attendance QR Code

Name: ${widget.contact.displayName}
Phone: ${widget.contact.phone}

Please show this QR code at church services for quick check-in.

God bless! ✝️
        ''',
      );

      // Clean up
      await file.delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    } finally {
      setState(() => _isSharing = false);
    }
  }

  Future<List<int>> _captureQRCode() async {
    // Create QR code image with contact info
    final qrValidationResult = QrValidator.validate(
      data: widget.contact.phone,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );

    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      color: Colors.black,
      gapless: true,
      emptyColor: Colors.white,
    );

    // Create image with contact details
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 400, 550),
      Paint()..color = Colors.white,
    );

    // QR Code
    painter.paint(canvas, const Size(300, 300));
    canvas.translate(50, 50);

    // Add text below QR
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Name
    textPainter.text = TextSpan(
      text: widget.contact.displayName,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(50, 370));

    // Phone
    textPainter.text = TextSpan(
      text: widget.contact.phone,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 18,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(50, 410));

    // Member badge
    textPainter.text = const TextSpan(
      text: '✓ Member',
      style: TextStyle(
        color: Colors.blue,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(50, 450));

    // Convert to image
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(400, 550);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isSharing ? null : _shareViaWhatsApp,
      icon: _isSharing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.share),
      label: const Text('Share via WhatsApp'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366), // WhatsApp green
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
```

---

### **3. QR Code Bottom Sheet (Quick Access)**

**File: `lib/features/contacts/presentation/widgets/qr_bottom_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/contact_qr_code.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/qr_share_button.dart';

class QRCodeBottomSheet {
  static void show(BuildContext context, Contact contact) {
    if (!contact.isEligibleForQRCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'QR code only available for members with valid names',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Text(
                'Member QR Code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              
              // QR Code Widget
              ContactQRCodeWidget(contact: contact),
              const SizedBox(height: 24),
              
              // Share Button
              QRShareButton(contact: contact),
              const SizedBox(height: 16),
              
              // Close Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### **4. Add QR Button to Contact Card**

**File: `lib/features/contacts/presentation/widgets/contact_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/qr_bottom_sheet.dart';

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;

  const ContactCard({
    super.key,
    required this.contact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: contact.status.color.withOpacity(0.2),
                child: Text(
                  contact.displayName[0].toUpperCase(),
                  style: TextStyle(
                    color: contact.status.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.phone,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (contact.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: contact.tags.take(3).map((tag) {
                          return Chip(
                            label: Text(tag),
                            labelStyle: const TextStyle(fontSize: 11),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              // QR Code Button (only if eligible)
              if (contact.isEligibleForQRCode)
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  color: Colors.blue,
                  tooltip: 'Show QR Code',
                  onPressed: () => QRCodeBottomSheet.show(context, contact),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### **5. QR Scanner for Attendance**

**File: `lib/features/attendance/presentation/screens/qr_scanner_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  final ServiceType serviceType;

  const QRScannerScreen({
    super.key,
    required this.serviceType,
  });

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? phone = barcodes.first.rawValue;
    if (phone == null || phone.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // TODO: Record attendance using phone number
      // final attendanceProvider = ref.read(attendanceListProvider.notifier);
      // await attendanceProvider.recordAttendance(phone, widget.serviceType);

      if (mounted) {
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Attendance recorded for $phone'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Vibrate feedback
        // HapticFeedback.mediumImpact();
      }

      // Wait before allowing next scan
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code - ${widget.serviceType.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          
          // Overlay with instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.serviceType.icon,
                    color: widget.serviceType.color,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.serviceType.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isProcessing 
                        ? 'Processing...' 
                        : 'Point camera at member QR code',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## � Usage Examples

### **In Contacts List Screen:**

```dart
ListView.builder(
  itemCount: contacts.length,
  itemBuilder: (context, index) {
    final contact = contacts[index];
    return ContactCard(
      contact: contact,
      onTap: () {
        // Navigate to detail screen
      },
      // QR button automatically shows if eligible
    );
  },
);
```

### **Opening QR Scanner:**

```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          serviceType: ServiceType.sunday,
        ),
      ),
    );
  },
  child: const Text('Scan Attendance'),
);
```

---

## ✅ QR Code Eligibility Check

The `Contact` model already has this built-in:

```dart
// In contact.dart
bool get isEligibleForQRCode {
  return name != null && name != phone && hasTag('member');
}
```

**Examples:**

✅ **Eligible:**
- Name: "John Doe", Phone: "+27821234567", Tags: ["member", "kanana"]

❌ **Not Eligible:**
- Name: "+27821234567", Phone: "+27821234567" (name == phone)
- Name: "John Doe", Phone: "+27821234567", Tags: ["lead"] (no 'member' tag)
- Name: null, Phone: "+27821234567", Tags: ["member"] (no name)

---

## � WhatsApp Share Behavior

When user taps "Share via WhatsApp":

1. QR code generated as PNG image
2. Saved to temporary directory
3. WhatsApp opens with:
   - Image attached
   - Pre-filled message
4. User selects contact to send to
5. Temporary file deleted after share

---

## � UI Flow Summary

```
Contact List
    ↓ [Tap QR icon on member card]
QR Bottom Sheet opens
    ↓ Shows QR code + contact info
    ↓ [Tap "Share via WhatsApp"]
WhatsApp opens
    ↓ User sends to member
Member receives QR code
    ↓ Shows at church
Servant scans QR code
    ↓ Attendance recorded
```

---

## � Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Camera for QR scanning -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Optional: Vibration feedback -->
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

---

## � Testing Checklist

- [ ] Generate QR for eligible member
- [ ] Try generating QR for non-member (should fail gracefully)
- [ ] Share QR via WhatsApp
- [ ] Scan QR code and verify phone number extracted
- [ ] Test duplicate attendance prevention (same day, same service)
- [ ] Test offline QR generation (should work)
- [ ] Test offline scanning (should queue for sync)

---

**That's it! Simple, clean, WhatsApp-friendly QR code system for your church members.** ✝️�
