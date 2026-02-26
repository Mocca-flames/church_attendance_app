import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/vcf_share_intent_provider.dart';
import 'package:church_attendance_app/features/home/presentation/screens/home_screen.dart' show DebugLogManager;

/// Full-screen VCF import overlay that shows when a VCF is received.
/// This avoids conflicts with other dialogs like the sync overlay.
/// Uses fire-and-forget background import for better UX.
class VcfImportOverlay extends ConsumerWidget {
  const VcfImportOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareState = ref.watch(vcfShareIntentProvider);
    
    // Don't show overlay if:
    // 1. No pending VCF and no parse result (idle)
    // 2. Import is running in background (we show status card instead)
    // 3. There's a completed import result (we show result card/popup instead)
    if (!shareState.hasPendingVcf && 
        shareState.parseResult == null && 
        shareState.backgroundImport.isActive == false &&
        shareState.importResult == null && 
        shareState.error == null) {
      return const SizedBox.shrink();
    }
    
    // Don't show overlay if import is running in background - show status card instead
    if (shareState.backgroundImport.isActive) {
      return const SizedBox.shrink();
    }
    
    DebugLogManager.addLog('[VCF Overlay] Building overlay - status: ${shareState.status}');
    
    return Material(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildContent(context, ref, shareState),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, VcfShareIntentState shareState) {
    // Show loading/parsing state
    if (shareState.isParsing) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Parsing VCF file...'),
        ],
      );
    }
    
    // Show confirmation
    if (shareState.parseResult != null && shareState.error == null) {
      final result = shareState.parseResult!;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Import Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('${result.contactCount} contact${result.contactCount != 1 ? 's' : ''} found'),
          if (result.names.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...result.names.take(3).map((name) => Text('• $name')),
          ],
          const SizedBox(height: 16),
          const Text('Would you like to import these contacts?'),
          const SizedBox(height: 8),
          // Quick info about background processing
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Import runs in background - you can continue using the app',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(vcfShareIntentProvider.notifier).clearPendingVcf();
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // Start background import
                  ref.read(vcfShareIntentProvider.notifier).startBackgroundImport();
                  // Close overlay immediately - import runs in background
                  ref.read(vcfShareIntentProvider.notifier).clearPendingVcf();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Import'),
              ),
            ],
          ),
        ],
      );
    }
    
    // Show importing (briefly shown before we close)
    if (shareState.isImporting) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
          const SizedBox(height: 24),
          const Text(
            'Starting import...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Import will continue in background',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }
    
    // Show result
    if (shareState.importResult != null) {
      final result = shareState.importResult!;
      final success = result['success'] as bool? ?? false;
      final importedCount = result['imported_count'] as int? ?? 0;
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle : Icons.warning,
            color: success ? Colors.green : Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(success ? 'Import Complete' : 'Import Issues'),
          const SizedBox(height: 8),
          Text('Imported: $importedCount contacts'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(vcfShareIntentProvider.notifier).clearImportResult();
            },
            child: const Text('OK'),
          ),
        ],
      );
    }
    
    // Show error
    if (shareState.error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(shareState.error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(vcfShareIntentProvider.notifier).clearPendingVcf();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }
}
