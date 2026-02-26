import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/vcf_share_intent_provider.dart';
import 'package:church_attendance_app/features/home/presentation/screens/home_screen.dart' show DebugLogManager;

/// Widget that listens for VCF share intents and tracks state.
/// UI is now handled by VcfImportOverlay in home_screen.dart
class VcfShareIntentHandler extends ConsumerWidget {
  final Widget child;

  const VcfShareIntentHandler({
    required this.child, super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the VCF share intent state - this triggers rebuilds when state changes
    final shareState = ref.watch(vcfShareIntentProvider);

    // Log state for debugging - DELAYED to avoid modifying provider during build
    // This was causing: "Tried to modify a provider while the widget tree was building"
    Future.microtask(() {
      DebugLogManager.addLog('[VCF Handler] State: ${shareState.status}');
    });
    
    // The UI (overlay/dialogs) is handled by:
    // 1. VcfImportOverlay on HomeScreen - shows overlay on home screen
    // 2. If user is on another screen, they won't see the overlay
    //    But they can navigate to home to see the VCF import
    
    return child;
  }
}
