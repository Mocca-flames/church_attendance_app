import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/theme/app_theme.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/vcf_share_intent_handler.dart';
import 'package:church_attendance_app/features/splash/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final database = AppDatabase();
  
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const ChurchAttendanceApp(),
    ),
  );
}

// Global database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database must be overridden in main()');
});

/// Main application widget.
/// Follows Clean Architecture - this is the app composition root.
class ChurchAttendanceApp extends StatelessWidget {
  const ChurchAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX: Removed duplicate VCF check from main.dart
    // The VcfShareIntentHandler + provider now handle VCF detection
    // This prevents duplicate calls to getSharedVcfPath()
    return VcfShareIntentHandler(
      child: MaterialApp(
        title: 'Church Attendance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Always start with SplashScreen - let VcfShareIntentHandler
        // handle showing the import dialog when VCF is detected
        home: const SplashScreen(),
      ),
    );
  }
}
