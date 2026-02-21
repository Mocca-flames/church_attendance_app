import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/services/vcf_sharing_service.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';

/// State for VCF share intent handling
class VcfShareIntentState {
  final bool hasPendingVcf;
  final String? vcfFilePath;
  final VcfParseResult? parseResult;
  final bool isParsing;
  final bool isImporting;
  final Map<String, dynamic>? importResult;
  final String? error;

  const VcfShareIntentState({
    this.hasPendingVcf = false,
    this.vcfFilePath,
    this.parseResult,
    this.isParsing = false,
    this.isImporting = false,
    this.importResult,
    this.error,
  });

  VcfShareIntentState copyWith({
    bool? hasPendingVcf,
    String? vcfFilePath,
    VcfParseResult? parseResult,
    bool? isParsing,
    bool? isImporting,
    Map<String, dynamic>? importResult,
    String? error,
    bool clearVcfFilePath = false,
    bool clearParseResult = false,
    bool clearImportResult = false,
    bool clearError = false,
  }) {
    return VcfShareIntentState(
      hasPendingVcf: hasPendingVcf ?? this.hasPendingVcf,
      vcfFilePath: clearVcfFilePath ? null : (vcfFilePath ?? this.vcfFilePath),
      parseResult: clearParseResult ? null : (parseResult ?? this.parseResult),
      isParsing: isParsing ?? this.isParsing,
      isImporting: isImporting ?? this.isImporting,
      importResult: clearImportResult ? null : (importResult ?? this.importResult),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider for handling VCF share intents using Riverpod 3.x Notifier
/// Uses MethodChannel to communicate with native Android code
class VcfShareIntentNotifier extends Notifier<VcfShareIntentState> {
  Timer? _pollTimer;

  @override
  VcfShareIntentState build() {
    // Start polling for shared VCF files
    _startPolling();
    
    ref.onDispose(() {
      _pollTimer?.cancel();
    });

    return const VcfShareIntentState();
  }

  void _startPolling() {
    // Poll every 500ms for shared VCF
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkForSharedVcf();
    });
  }

  Future<void> _checkForSharedVcf() async {
    // Skip if already has a pending VCF or is processing
    if (state.hasPendingVcf || state.isParsing || state.isImporting) return;

    try {
      final path = await VcfSharingService.getSharedVcfPath();
      if (path != null && path.isNotEmpty) {
        state = state.copyWith(
          hasPendingVcf: true,
          vcfFilePath: path,
          clearImportResult: true,
          clearError: true,
        );
        // Parse the VCF for preview
        await parseVcf(path);
      }
    } catch (e) {
      // Silently ignore polling errors
    }
  }

  /// Parse the VCF file for preview
  Future<void> parseVcf(String filePath) async {
    state = state.copyWith(isParsing: true, clearError: true);

    try {
      final result = await VcfSharingService.parseVcfFile(filePath);
      state = state.copyWith(
        parseResult: result,
        isParsing: false,
        error: result.error,
      );
    } catch (e) {
      state = state.copyWith(
        isParsing: false,
        error: 'Failed to parse VCF: $e',
      );
    }
  }

  /// Import the pending VCF file using existing contact provider
  Future<void> importVcf() async {
    final filePath = state.vcfFilePath;
    if (filePath == null) {
      state = state.copyWith(error: 'No VCF file to import');
      return;
    }

    state = state.copyWith(isImporting: true, clearError: true);

    try {
      // Use existing importVcfFile method from contact provider
      final result = await ref
          .read(contactNotifierProvider.notifier)
          .importVcfFile(filePath);

      state = state.copyWith(
        isImporting: false,
        importResult: result,
        clearVcfFilePath: true,
        clearParseResult: true,
        hasPendingVcf: false,
      );
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        error: 'Failed to import VCF: $e',
      );
    }
  }

  /// Clear the pending VCF without importing
  void clearPendingVcf() {
    state = state.copyWith(
      clearVcfFilePath: true,
      clearParseResult: true,
      hasPendingVcf: false,
      clearImportResult: true,
      clearError: true,
    );
  }

  /// Clear the import result after it has been shown
  void clearImportResult() {
    state = state.copyWith(clearImportResult: true);
  }
}

/// Provider for VCF share intent handling
final vcfShareIntentProvider =
    NotifierProvider<VcfShareIntentNotifier, VcfShareIntentState>(() {
  return VcfShareIntentNotifier();
});
