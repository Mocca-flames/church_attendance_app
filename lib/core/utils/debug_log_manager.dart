import 'package:flutter/foundation.dart';

/// Static debug log manager - stores last 100 log lines globally.
/// Used by VCF import overlay and VCF share intent handler for debugging.
class DebugLogManager {
  static final List<String> _logs = [];
  static VoidCallback? _onLogAdded;
  static bool _isBuilding = false; // Track if we're in widget build phase
  
  static List<String> get logs => List.unmodifiable(_logs);
  
  static void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logLine = '[$timestamp] $message';
    _logs.add(logLine);
    // Keep only last 100 logs
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }
    debugPrint('[DEBUG] $logLine');
    // Safeguard: Only trigger callback if not during widget build
    // This prevents "Tried to modify a provider while the widget tree was building" error
    if (!_isBuilding) {
      _onLogAdded?.call();
    } else {
      // Defer the callback to after build completes
      Future.microtask(() => _onLogAdded?.call());
    }
  }
  
  static void clear() {
    _logs.clear();
    _onLogAdded?.call();
  }
  
  static void setListener(VoidCallback callback) {
    _onLogAdded = callback;
  }
  
  static void setBuilding(bool value) {
    _isBuilding = value;
  }
}
