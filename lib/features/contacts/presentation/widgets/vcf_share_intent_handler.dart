import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/vcf_share_intent_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/vcf_import_dialog.dart';

/// Widget that listens for VCF share intents and shows appropriate dialogs.
/// Should be placed at the root of the app (e.g., in main navigation shell).
class VcfShareIntentHandler extends ConsumerStatefulWidget {
  final Widget child;

  const VcfShareIntentHandler({
    required this.child, super.key,
  });

  @override
  ConsumerState<VcfShareIntentHandler> createState() =>
      _VcfShareIntentHandlerState();
}

class _VcfShareIntentHandlerState extends ConsumerState<VcfShareIntentHandler> {
  bool _hasShownDialog = false;

  @override
  Widget build(BuildContext context) {
    // Watch the VCF share intent state
    final shareState = ref.watch(vcfShareIntentProvider);

    // Show confirmation dialog when there's a pending VCF with parse result
    if (shareState.hasPendingVcf && shareState.parseResult != null && !_hasShownDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasShownDialog) {
          _hasShownDialog = true;
          _showShareConfirmDialog(context, shareState.parseResult!);
        }
      });
    }

    // Show parsing loading
    if (shareState.isParsing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showParsingDialog(context);
      });
    }

    // Show result dialog when import is complete
    if (shareState.importResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showImportResultDialog(context, shareState.importResult!);
        // Clear the result after showing
        ref.read(vcfShareIntentProvider.notifier).clearImportResult();
        _hasShownDialog = false;
      });
    }

    // Show error dialog if there's an error and not processing
    if (shareState.error != null && !shareState.isParsing && !shareState.isImporting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(context, shareState.error!);
        _hasShownDialog = false;
      });
    }

    return widget.child;
  }

  void _showParsingDialog(BuildContext context) {
    // Show loading if not already shown
    final existingDialog = Navigator.of(context).mounted;
    if (!existingDialog) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const VcfImportLoadingDialog(),
      );
    }
  }

  void _showShareConfirmDialog(BuildContext context, parseResult) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VcfShareConfirmDialog(
        parseResult: parseResult,
        onImport: () {
          Navigator.of(context).pop();
          // Start the import
          ref.read(vcfShareIntentProvider.notifier).importVcf();
        },
        onCancel: () {
          Navigator.of(context).pop();
          // Clear the pending VCF
          ref.read(vcfShareIntentProvider.notifier).clearPendingVcf();
          _hasShownDialog = false;
        },
      ),
    );
  }

  void _showImportResultDialog(
      BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => VcfImportResultDialog(
        result: result,
        onDismiss: () {
          // Refresh contact list after successful import
        },
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(vcfShareIntentProvider.notifier).clearPendingVcf();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
