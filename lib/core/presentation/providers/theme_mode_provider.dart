// lib/core/presentation/providers/theme_mode_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key used for storing theme mode preference in SharedPreferences
const String _themeModeKey = 'theme_mode';

/// State notifier to manage ThemeMode state with persistence
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Schedule async loading after build completes to avoid modifying
    // provider during widget tree building (which causes hot restart errors)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThemeMode();
    });
    return ThemeMode.system;
  }

  /// Load theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeModeKey);
      if (themeModeIndex != null && themeModeIndex < ThemeMode.values.length) {
        state = ThemeMode.values[themeModeIndex];
      }
    } catch (e) {
      // If loading fails, keep default ThemeMode.system
      debugPrint('Error loading theme mode: $e');
    }
  }

  /// Save theme mode to SharedPreferences
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, state.index);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  /// Toggle between light and dark mode
  void toggleThemeMode() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light;
    }
    _saveThemeMode();
  }

  /// Set a specific theme mode
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _saveThemeMode();
  }

  /// Check if dark mode is currently active
  bool get isDarkMode => state == ThemeMode.dark;
}

/// Provider for theme mode management
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

/// Convenience provider to check if dark mode is active
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.dark;
});
