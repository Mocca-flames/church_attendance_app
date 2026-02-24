import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/services/vcf_sharing_service.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';

/// State machine for VCF share intent handling
enum VcfIntentStatus {
  idle,           // No pending VCF
  detected,       // VCF file detected, not yet parsed
  parsing,        // Currently parsing VCF file
  parsed,         // VCF parsed, ready for import
  importing,      // Currently importing to server (fire-and-forget mode)
  backgroundProcessing, // Server processing in background
  success,        // Import completed successfully
  error,          // Error occurred
}

/// Represents background import progress state
class VcfBackgroundImportState {
  final bool isActive;
  final int contactCount;
  final DateTime? startTime;
  final Map<String, dynamic>? result;
  final String? error;

  const VcfBackgroundImportState({
    this.isActive = false,
    this.contactCount = 0,
    this.startTime,
    this.result,
    this.error,
  });

  VcfBackgroundImportState copyWith({
    bool? isActive,
    int? contactCount,
    DateTime? startTime,
    Map<String, dynamic>? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return VcfBackgroundImportState(
      isActive: isActive ?? this.isActive,
      contactCount: contactCount ?? this.contactCount,
      startTime: startTime ?? this.startTime,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// State for VCF share intent handling
class VcfShareIntentState {
  final VcfIntentStatus status;
  final String? vcfFilePath;
  final VcfParseResult? parseResult;
  final Map<String, dynamic>? importResult;
  final String? error;
  final VcfBackgroundImportState backgroundImport;

  const VcfShareIntentState({
    this.status = VcfIntentStatus.idle,
    this.vcfFilePath,
    this.parseResult,
    this.importResult,
    this.error,
    this.backgroundImport = const VcfBackgroundImportState(),
  });

  bool get hasPendingVcf => 
      status == VcfIntentStatus.detected || 
      status == VcfIntentStatus.parsing || 
      status == VcfIntentStatus.parsed;

  bool get isParsing => status == VcfIntentStatus.parsing;
  bool get isImporting => status == VcfIntentStatus.importing || status == VcfIntentStatus.backgroundProcessing;
  bool get isProcessing => isParsing || isImporting;
  bool get hasActiveBackgroundImport => backgroundImport.isActive;

  VcfShareIntentState copyWith({
    VcfIntentStatus? status,
    String? vcfFilePath,
    VcfParseResult? parseResult,
    Map<String, dynamic>? importResult,
    String? error,
    VcfBackgroundImportState? backgroundImport,
    bool clearVcfFilePath = false,
    bool clearParseResult = false,
    bool clearImportResult = false,
    bool clearError = false,
  }) {
    return VcfShareIntentState(
      status: status ?? this.status,
      vcfFilePath: clearVcfFilePath ? null : (vcfFilePath ?? this.vcfFilePath),
      parseResult: clearParseResult ? null : (parseResult ?? this.parseResult),
      importResult: clearImportResult ? null : (importResult ?? this.importResult),
      error: clearError ? null : (error ?? this.error),
      backgroundImport: backgroundImport ?? this.backgroundImport,
    );
  }
}

/// Provider for handling VCF share intents using Riverpod 3.x Notifier
/// Uses MethodChannel to communicate with native Android code
class VcfShareIntentNotifier extends Notifier<VcfShareIntentState> {
  Timer? _pollTimer;
  bool _hasProcessedVcf = false;
  int _pollAttempts = 0;
  static const int _maxPollAttempts = 10; // Try up to 10 times (10 * 500ms = 5 seconds)

  @override
  VcfShareIntentState build() {
    debugPrint('[VCF Intent Provider] Initializing...');
    
    // Set up callback for immediate VCF notification from Android
    VcfSharingService.setVcfReceivedCallback((path) {
      debugPrint('[VCF Intent Provider] Immediate VCF notification received: $path');
      _handleVcfReceived(path);
    });
    
    // Start polling for shared VCF files
    _startPolling();
    
    ref.onDispose(() {
      debugPrint('[VCF Intent Provider] Disposing...');
      _pollTimer?.cancel();
    });

    return const VcfShareIntentState();
  }

  /// Handle VCF received via MethodChannel callback (immediate notification)
  void _handleVcfReceived(String path) {
    if (_hasProcessedVcf || state.hasPendingVcf || state.isProcessing) {
      debugPrint('[VCF Intent Provider] Ignoring VCF - already processing: ${state.status}');
      return;
    }
    
    debugPrint('[VCF Intent Provider] Processing immediate VCF: $path');
    _hasProcessedVcf = true;
    _stopPolling();
    
    state = state.copyWith(
      status: VcfIntentStatus.detected,
      vcfFilePath: path,
      clearImportResult: true,
      clearError: true,
    );
    
    // Parse the VCF for preview
    parseVcf(path);
  }

  void _startPolling() {
    _pollAttempts = 0;
    debugPrint('[VCF Intent Provider] DEBUG: Starting polling timer (every 500ms, max $_maxPollAttempts attempts)');
    // Poll every 500ms for shared VCF
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      debugPrint('[VCF Intent Provider] DEBUG: Timer fired (attempt ${_pollAttempts + 1}), calling _checkForSharedVcf');
      _checkForSharedVcf();
    });
  }

  Future<void> _checkForSharedVcf() async {
    // Skip if already has a pending VCF or is processing
    if (state.hasPendingVcf || state.isProcessing) {
      debugPrint('[VCF Intent Provider] Skipping poll - already processing: ${state.status}');
      return;
    }

    // Skip if we've already processed a VCF (to avoid reprocessing)
    if (_hasProcessedVcf) {
      debugPrint('[VCF Intent Provider] Skipping poll - already processed VCF');
      return;
    }

    // If we've exceeded max poll attempts, stop polling
    _pollAttempts++;
    if (_pollAttempts > _maxPollAttempts) {
      debugPrint('[VCF Intent Provider] DEBUG: Max poll attempts reached ($_maxPollAttempts), stopping polling');
      _stopPolling();
      return;
    }

    try {
      debugPrint('[VCF Intent Provider] Checking for shared VCF (attempt $_pollAttempts/$_maxPollAttempts)...');
      final path = await VcfSharingService.getSharedVcfPath();
      
      if (path != null && path.isNotEmpty) {
        debugPrint('[VCF Intent Provider] VCF file detected: $path');
        _hasProcessedVcf = true;
        _stopPolling(); // Stop polling once we found a VCF
        
        state = state.copyWith(
          status: VcfIntentStatus.detected,
          vcfFilePath: path,
          clearImportResult: true,
          clearError: true,
        );
        // Parse the VCF for preview
        await parseVcf(path);
      } else {
        debugPrint('[VCF Intent Provider] No VCF file found on attempt $_pollAttempts/$_maxPollAttempts - will continue polling');
        // Don't stop polling yet - keep trying up to max attempts
      }
    } catch (e) {
      debugPrint('[VCF Intent Provider] Error checking for VCF: $e');
      // Stop polling on error
      _stopPolling();
    }
  }

  /// Parse the VCF file for preview
  Future<void> parseVcf(String filePath) async {
    debugPrint('[VCF Intent Provider] Parsing VCF file: $filePath');
    state = state.copyWith(status: VcfIntentStatus.parsing, clearError: true);

    try {
      final result = await VcfSharingService.parseVcfFile(filePath);
      debugPrint('[VCF Intent Provider] Parse result: ${result.success}, contacts: ${result.contactCount}');
      
      if (result.error != null) {
        debugPrint('[VCF Intent Provider] Parse error: ${result.error}');
      }
      
      state = state.copyWith(
        status: result.success ? VcfIntentStatus.parsed : VcfIntentStatus.error,
        parseResult: result,
        error: result.error,
      );
    } catch (e) {
      debugPrint('[VCF Intent Provider] Parse exception: $e');
      state = state.copyWith(
        status: VcfIntentStatus.error,
        error: 'Failed to parse VCF: $e',
      );
    }
  }

  /// Import the pending VCF file using existing contact provider
  /// This version waits for the server response (legacy behavior)
  Future<void> importVcf() async {
    final filePath = state.vcfFilePath;
    if (filePath == null) {
      debugPrint('[VCF Intent Provider] No VCF file to import');
      state = state.copyWith(error: 'No VCF file to import');
      return;
    }

    debugPrint('[VCF Intent Provider] Starting import: $filePath');
    state = state.copyWith(status: VcfIntentStatus.importing, clearError: true);

    try {
      // Use existing importVcfFile method from contact provider
      final result = await ref
          .read(contactNotifierProvider.notifier)
          .importVcfFile(filePath);

      debugPrint('[VCF Intent Provider] Import result: $result');
      
      state = state.copyWith(
        status: VcfIntentStatus.success,
        importResult: result,
      );
      
      // Stop polling after successful import
      _stopPolling();
      
    } catch (e) {
      debugPrint('[VCF Intent Provider] Import error: $e');
      state = state.copyWith(
        status: VcfIntentStatus.error,
        error: 'Failed to import VCF: $e',
      );
    }
  }

  /// Fire-and-forget background import
  /// Immediately starts import and returns control to UI
  /// Server result handled via .then() callback - no polling needed
  Future<void> startBackgroundImport() async {
    final filePath = state.vcfFilePath;
    final contactCount = state.parseResult?.contactCount ?? 0;
    
    if (filePath == null) {
      debugPrint('[VCF Intent Provider] No VCF file for background import');
      state = state.copyWith(error: 'No VCF file to import');
      return;
    }

    debugPrint('[VCF Intent Provider] Starting background import: $filePath');
    
    // Initialize background import state
    state = state.copyWith(
      status: VcfIntentStatus.backgroundProcessing,
      backgroundImport: VcfBackgroundImportState(
        isActive: true,
        contactCount: contactCount,
        startTime: DateTime.now(),
      ),
      clearError: true,
    );

    // Start fire-and-forget import - callback handles completion
    _runBackgroundImport(filePath);
  }

  /// Run the actual import in background (fire-and-forget)
  /// Uses .then() callback to handle completion without blocking UI
  Future<void> _runBackgroundImport(String filePath) async {
    try {
      debugPrint('[VCF Intent Provider] Background import running for: $filePath');
      
      // Fire-and-forget - don't await the result
      // Use .then() callback to handle completion
      ref.read(contactNotifierProvider.notifier).importVcfFile(filePath).then((result) {
        debugPrint('[VCF Intent Provider] Background import completed: $result');
        
        // Update state with result - this triggers UI update
        state = state.copyWith(
          backgroundImport: state.backgroundImport.copyWith(
            isActive: false,
            result: result,
          ),
          importResult: result,
          status: VcfIntentStatus.success,
        );
        
      }).catchError((error) {
        debugPrint('[VCF Intent Provider] Background import failed: $error');
        
        state = state.copyWith(
          backgroundImport: state.backgroundImport.copyWith(
            isActive: false,
            error: error.toString(),
          ),
          status: VcfIntentStatus.error,
          error: error.toString(),
        );
      });
      
    } catch (e) {
      debugPrint('[VCF Intent Provider] Background import exception: $e');
      state = state.copyWith(
        backgroundImport: state.backgroundImport.copyWith(
          isActive: false,
          error: e.toString(),
        ),
        status: VcfIntentStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Clear background import state
  void clearBackgroundImport() {
    debugPrint('[VCF Intent Provider] Clearing background import');
    state = state.copyWith(
      backgroundImport: const VcfBackgroundImportState(),
    );
  }

  /// Check if there's a completed import result to show
  bool get hasCompletedImportResult => 
      state.importResult != null && 
      !state.backgroundImport.isActive;

  /// Stop polling for VCF files
  void _stopPolling() {
    debugPrint('[VCF Intent Provider] Stopping polling');
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Reset the provider to allow processing a new VCF
  void resetForNewVcf() {
    debugPrint('[VCF Intent Provider] Resetting for new VCF');
    _hasProcessedVcf = false;
    state = const VcfShareIntentState();
    _startPolling();
  }

  /// Clear the pending VCF without importing
  void clearPendingVcf() {
    debugPrint('[VCF Intent Provider] Clearing pending VCF');
    state = state.copyWith(
      status: VcfIntentStatus.idle,
      clearVcfFilePath: true,
      clearParseResult: true,
      clearImportResult: true,
      clearError: true,
    );
  }

  /// Clear the import result after it has been shown
  void clearImportResult() {
    debugPrint('[VCF Intent Provider] Clearing import result');
    state = state.copyWith(
      status: VcfIntentStatus.idle,
      clearImportResult: true,
    );
  }
}

/// Provider for VCF share intent handling
final vcfShareIntentProvider =
    NotifierProvider<VcfShareIntentNotifier, VcfShareIntentState>(() {
  return VcfShareIntentNotifier();
});
