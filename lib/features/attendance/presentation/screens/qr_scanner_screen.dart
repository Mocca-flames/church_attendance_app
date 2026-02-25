import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/features/attendance/domain/models/attendance.dart';
import 'package:church_attendance_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:church_attendance_app/features/attendance/presentation/widgets/quick_contact_dialog.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR Scanner screen for recording attendance.
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => QRScannerScreen(
///       serviceType: ServiceType.sunday,
///       serviceDate: DateTime.now(),
///     ),
///   ),
/// );
/// ```
class QRScannerScreen extends ConsumerStatefulWidget {
  final ServiceType serviceType;
  final DateTime serviceDate;

  const QRScannerScreen({
    required this.serviceType,
    required this.serviceDate,
    super.key,
  });

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  /// Get the current user ID from auth provider, defaults to 1 if not available
  int get _recordedBy {
    final user = ref.watch(currentUserProvider);
    return user?.id ?? 1;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? phone = barcodes.first.rawValue;
    if (phone == null || phone.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Get contact by phone
      final contact =
          await ref.read(attendanceProvider.notifier).getContactByPhone(phone);

      if (contact != null) {
        // Contact found - record attendance
        await _recordAttendanceForContact(contact, phone);
      } else {
        // Contact not found - show quick contact dialog
        if (mounted) {
          final result = await showQuickContactSheet(
            context,
            phone: phone,
            serviceType: widget.serviceType,
            serviceDate: widget.serviceDate,
            recordedBy: _recordedBy,
          );

          if (result != null && mounted) {
            if (result.alreadyMarked) {
              _showWarning('$phone already marked for ${widget.serviceType.displayName} today');
            } else if (result.error != null) {
              _showError(result.error!);
            } else if (result.attendance != null) {
              _showSuccess(result.attendance!, contactName: phone);
            }
          }
        }
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      // Wait before allowing next scan
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _recordAttendanceForContact(
      Contact contact, String phone) async {
    try {
      final attendance =
          await ref.read(attendanceProvider.notifier).recordAttendanceByPhone(
                phone: phone,
                serviceType: widget.serviceType,
                serviceDate: widget.serviceDate,
                recordedBy: _recordedBy,
              );

      if (attendance != null && mounted) {
        _showSuccess(attendance, contactName: contact.name ?? phone);
      }
    } on AttendanceException catch (e) {
      if (e.type == AttendanceExceptionType.alreadyMarked) {
        if (mounted) {
          _showWarning(
              '${contact.name ?? phone} already marked for ${widget.serviceType.displayName} on ${_formatDate(widget.serviceDate)}');
        }
      } else {
        rethrow;
      }
    }
  }

  void _showSuccess(Attendance attendance, {required String contactName}) {
    // Haptic feedback
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Marked: $contactName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    // Haptic feedback for error
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWarning(String message) {
    // Haptic feedback for warning
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR - ${widget.serviceType.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Switch Camera',
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
                color: Colors.black.withValues(alpha: 0.7),
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
                    _formatDate(widget.serviceDate),
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isProcessing
                        ? 'Processing...'
                        : 'Point camera at member QR code',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
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
