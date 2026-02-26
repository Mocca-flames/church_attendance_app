import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:church_attendance_app/core/services/vcf_sharing_service.dart';


/// Reusable dialog for showing VCF import results.
/// Used by both FilePicker and Share Intent import flows.
class VcfImportResultDialog extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback? onDismiss;

  const VcfImportResultDialog({
    
    required this.result,
    this.onDismiss,super.key,
  });

  @override
  Widget build(BuildContext context) {
    final success = result['success'] as bool? ?? false;
    final importedCount = result['imported_count'] as int? ?? 0;
    final failedCount = result['failed_count'] as int? ?? 0;
    final errors = (result['errors'] as List<dynamic>?)?.cast<String>() ?? [];

    // Trigger haptic feedback based on result
    if (success) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: success ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            success ? 'Import Complete' : 'Import Issues',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('Imported', '$importedCount', Colors.green),
            if (failedCount > 0) ...[
              const SizedBox(height: 8),
              _buildResultRow('Failed', '$failedCount', Colors.red),
            ],
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors
                      .map((error) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $error',
                                style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Dialog shown while importing VCF file
class VcfImportLoadingDialog extends StatelessWidget {
  const VcfImportLoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      content: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 20),
          Text('Importing contacts...'),
        ],
      ),
    );
  }
}

/// Dialog shown when a VCF file is shared with the app
/// Shows parsed VCF info (contact count, sample names)
class VcfShareConfirmDialog extends StatelessWidget {
  final VcfParseResult parseResult;
  final VoidCallback onImport;
  final VoidCallback onCancel;

  const VcfShareConfirmDialog({
    
    required this.parseResult,
    required this.onImport,
    required this.onCancel,super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(
            Icons.contact_phone_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Import Contacts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    parseResult.fileName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Contact count
          Row(
            children: [
              Icon(
                Icons.people_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${parseResult.contactCount} contact${parseResult.contactCount != 1 ? 's' : ''} found',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          // Sample names (first 5)
          if (parseResult.names.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Preview:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            ...parseResult.names.map((name) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                '• $name',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            )),
            if (parseResult.contactCount > 5)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  '... and ${parseResult.contactCount - 5} more',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
          
          // Error message
          if (parseResult.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      parseResult.error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          Text(
            'Would you like to import these contacts to the server?',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onCancel();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: parseResult.success
              ? () {
                  HapticFeedback.mediumImpact();
                  onImport();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Import'),
        ),
      ],
    );
  }
}
