import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing user preferences related to locations
/// - Default location for quick selection
/// - Recent locations for quick access
class LocationPreferencesService {
  static const String _defaultLocationKey = 'default_location';
  static const String _recentLocationsKey = 'recent_locations';
  static const int _maxRecentLocations = 5;

  final SharedPreferences _prefs;

  LocationPreferencesService(this._prefs);

  /// Get the default location value
  String? getDefaultLocation() {
    return _prefs.getString(_defaultLocationKey);
  }

  /// Set the default location
  Future<bool> setDefaultLocation(String? locationValue) async {
    if (locationValue == null) {
      return _prefs.remove(_defaultLocationKey);
    }
    return _prefs.setString(_defaultLocationKey, locationValue);
  }

  /// Get recent locations (most recent first)
  List<String> getRecentLocations() {
    return _prefs.getStringList(_recentLocationsKey) ?? [];
  }

  /// Add a location to recent list
  /// Moves location to top if it already exists
  Future<bool> addRecentLocation(String locationValue) async {
    final recent = getRecentLocations();

    // Remove if already exists (will be added to top)
    recent.remove(locationValue);

    // Add to beginning
    recent.insert(0, locationValue);

    // Keep only the most recent locations
    final trimmed = recent.take(_maxRecentLocations).toList();

    return _prefs.setStringList(_recentLocationsKey, trimmed);
  }

  /// Clear recent locations
  Future<bool> clearRecentLocations() async {
    return _prefs.remove(_recentLocationsKey);
  }
}
