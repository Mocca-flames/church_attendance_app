import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/theme/app_theme.dart';
import 'package:church_attendance_app/core/navigation/app_navigator.dart';
import 'package:church_attendance_app/core/presentation/providers/theme_mode_provider.dart';
import 'package:church_attendance_app/core/services/location_service.dart';
import 'package:church_attendance_app/core/services/location_preferences_service.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/vcf_share_intent_handler.dart';
import 'package:church_attendance_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final database = AppDatabase();
  
  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ChurchAttendanceApp(),
    ),
  );
}

// Global database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database must be overridden in main()');
});

// Shared preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  final database = ref.watch(databaseProvider);
  return LocationService(database);
});

// Location preferences service provider
final locationPreferencesProvider = Provider<LocationPreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocationPreferencesService(prefs);
});

/// Main application widget.
/// Follows Clean Architecture - this is the app composition root.
class ChurchAttendanceApp extends ConsumerWidget {
  const ChurchAttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    // FIX: Removed duplicate VCF check from main.dart
    // The VcfShareIntentHandler + provider now handle VCF detection
    // This prevents duplicate calls to getSharedVcfPath()
    return VcfShareIntentHandler(
      child: MaterialApp(
        navigatorKey: navigatorKey,  // Use global navigator key
        title: 'Church Attendance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        // Always start with SplashScreen - let VcfShareIntentHandler
        // handle showing the import dialog when VCF is detected
        home: const SplashScreen(),
      ),
    );
  }
}
