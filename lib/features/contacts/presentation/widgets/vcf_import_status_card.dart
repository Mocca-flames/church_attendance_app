import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_colors.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/vcf_share_intent_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/vcf_import_dialog.dart';

/// A dismissible status card that shows VCF import progress on the Home screen.
/// This provides real-time feedback while the import runs in the background.
/// Automatically shows a result popup when import completes.
class VcfImportStatusCard extends ConsumerStatefulWidget {
  const VcfImportStatusCard({super.key});

  @override
  ConsumerState<VcfImportStatusCard> createState() => _VcfImportStatusCardState();
}

class _VcfImportStatusCardState extends ConsumerState<VcfImportStatusCard> {
  bool _hasShownResult = false;
  
  @override
  Widget build(BuildContext context) {
    final shareState = ref.watch(vcfShareIntentProvider);
    final backgroundImport = shareState.backgroundImport;
    
    // Don't show if no active background import
    if (!backgroundImport.isActive && shareState.importResult == null) {
      _hasShownResult = false;
      return const SizedBox.shrink();
    }

    // Show result if import completed and we haven't shown the popup yet
    if (shareState.importResult != null && !backgroundImport.isActive) {
      final result = shareState.importResult!;
      final success = result['success'] as bool? ?? false;
      
      // Auto-show result popup after a brief delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasShownResult && mounted) {
          _hasShownResult = true;
          _showResultDialog(context, result);
        }
      });
      
      return _ResultCard(result: result, success: success);
    }

    // Show progress if still importing
    if (backgroundImport.isActive) {
      _hasShownResult = false;
      return _ProgressCard(contactCount: backgroundImport.contactCount);
    }

    return const SizedBox.shrink();
  }
  
  void _showResultDialog(BuildContext context, Map<String, dynamic> result) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => VcfImportResultDialog(
        result: result,
        onDismiss: () {
          ref.read(vcfShareIntentProvider.notifier).clearBackgroundImport();
        },
      ),
    ).then((_) {
      // Clear after dialog is dismissed
      ref.read(vcfShareIntentProvider.notifier).clearBackgroundImport();
    });
  }
}

class _ProgressCard extends StatelessWidget {
  final int contactCount;

  const _ProgressCard({required this.contactCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated progress indicator
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Importing Contacts',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$contactCount contact${contactCount != 1 ? 's' : ''} being imported...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Animated dots
          const _AnimatedDots(),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = value < 0.5 ? value * 2 : 2 - value * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _ResultCard extends ConsumerWidget {
  final Map<String, dynamic> result;
  final bool success;

  const _ResultCard({required this.result, required this.success});

  void _showDetails(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => VcfImportResultDialog(
        result: result,
        onDismiss: () {
          ref.read(vcfShareIntentProvider.notifier).clearBackgroundImport();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importedCount = result['imported_count'] as int? ?? 0;
    final updatedCount = result['updated_count'] as int? ?? 0;
    final failedCount = result['failed_count'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _showDetails(context, ref),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: success 
              ? Colors.green.withValues(alpha: 0.1) 
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: success 
                ? Colors.green.withValues(alpha: 0.3) 
                : Colors.orange.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Success/Error icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: success 
                    ? Colors.green.withValues(alpha: 0.2) 
                    : Colors.orange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle : Icons.warning_amber_rounded,
                color: success ? Colors.green : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    success ? 'Import Complete' : 'Import Issues',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: success ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildResultSummary(importedCount, updatedCount, failedCount),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap for details',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  String _buildResultSummary(int imported, int updated, int failed) {
    final parts = <String>[];
    if (imported > 0) parts.add('$imported imported');
    if (updated > 0) parts.add('$updated updated');
    if (failed > 0) parts.add('$failed failed');
    return parts.isEmpty ? 'No changes' : parts.join(' • ');
  }
}
