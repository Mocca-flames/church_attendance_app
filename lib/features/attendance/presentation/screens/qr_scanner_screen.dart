import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/core/services/haptic_service.dart';
import 'package:church_attendance_app/core/sync/sync_manager_provider.dart';
import 'package:church_attendance_app/features/attendance/domain/models/attendance.dart';
import 'package:church_attendance_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:church_attendance_app/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:church_attendance_app/features/attendance/presentation/widgets/quick_contact_dialog.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:flutter/material.dart';
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

/// Animated scanning overlay with frame and scanning line
class _ScanningOverlay extends StatefulWidget {
  const _ScanningOverlay();

  @override
  State<_ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<_ScanningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scanAreaSize = MediaQuery.of(context).size.width * 0.7;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Dark overlay outside scan area
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScannerOverlayPainter(
                scanAreaSize: scanAreaSize,
                overlayColor: Colors.black.withValues(alpha: 0.6),
              ),
            ),

            // Scan frame with corners
            Center(
              child: SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: Stack(
                  children: [
                    // Corner markers
                    _buildCornerMarkers(colorScheme.primary),

                    // Animated scanning line
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Positioned(
                          top: _animationController.value * scanAreaSize,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Scan hint text
            Positioned(
              top: MediaQuery.of(context).size.height * 0.5 + scanAreaSize * 0.5 + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Align QR code within frame',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCornerMarkers(Color color) {
    const cornerSize = 30.0;
    const strokeWidth = 4.0;

    return Stack(
      children: [
        // Top-left corner
        Positioned(
          top: 0,
          left: 0,
          child: _buildCorner(color, cornerSize, strokeWidth, true, true),
        ),
        // Top-right corner
        Positioned(
          top: 0,
          right: 0,
          child: _buildCorner(color, cornerSize, strokeWidth, false, true),
        ),
        // Bottom-left corner
        Positioned(
          bottom: 0,
          left: 0,
          child: _buildCorner(color, cornerSize, strokeWidth, true, false),
        ),
        // Bottom-right corner
        Positioned(
          bottom: 0,
          right: 0,
          child: _buildCorner(color, cornerSize, strokeWidth, false, false),
        ),
      ],
    );
  }

  Widget _buildCorner(
    Color color,
    double size,
    double strokeWidth,
    bool isLeft,
    bool isTop,
  ) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          strokeWidth: strokeWidth,
          isLeft: isLeft,
          isTop: isTop,
        ),
      ),
    );
  }
}

/// Custom painter for the dark overlay with cutout
class _ScannerOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Color overlayColor;

  _ScannerOverlayPainter({
    required this.scanAreaSize,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: scanAreaSize,
            height: scanAreaSize,
          ),
          const Radius.circular(16),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for corner markers
class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool isLeft;
  final bool isTop;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.isLeft,
    required this.isTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const cornerLength = 20.0;

    if (isLeft && isTop) {
      // Top-left: draw right and down
      path.moveTo(0, cornerLength);
      path.lineTo(0, 0);
      path.lineTo(cornerLength, 0);
    } else if (!isLeft && isTop) {
      // Top-right: draw left and down
      path.moveTo(size.width - cornerLength, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, cornerLength);
    } else if (isLeft && !isTop) {
      // Bottom-left: draw right and up
      path.moveTo(0, size.height - cornerLength);
      path.lineTo(0, size.height);
      path.lineTo(cornerLength, size.height);
    } else {
      // Bottom-right: draw left and up
      path.moveTo(size.width - cornerLength, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height - cornerLength);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        // Trigger immediate sync to push attendance to server
        Future.microtask(() {
          ref.read(smartSyncProvider.notifier).triggerImmediateSync();
        });
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
    HapticService.medium();

    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: colorScheme.onTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Marked: $contactName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.tertiary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    // Haptic feedback for error
    HapticService.heavy();

    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: colorScheme.onError),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWarning(String message) {
    // Haptic feedback for warning
    HapticService.medium();

    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: colorScheme.onPrimary),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: colorScheme.primary,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Scan QR - ${widget.serviceType.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
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

          // Scanning Overlay
          const _ScanningOverlay(),

          // Bottom instructions panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.scrim,
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
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(widget.serviceDate),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
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
                      color: colorScheme.outline,
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
