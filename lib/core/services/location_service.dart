import 'package:church_attendance_app/core/database/database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

/// Service for managing church locations
/// Provides a clean interface for location operations
class LocationService {
  final AppDatabase _database;

  LocationService(this._database);

  /// Get all active locations
  Future<List<LocationEntity>> getAllLocations() {
    return _database.getAllLocations();
  }

  /// Get location by value
  Future<LocationEntity?> getLocationByValue(String value) {
    return _database.getLocationByValue(value);
  }

  /// Get location by ID
  Future<LocationEntity?> getLocationById(int id) {
    return _database.getLocationById(id);
  }

  /// Add a new location
  Future<int> addLocation({
    required String value,
    required String displayName,
    int? colorValue,
    int sortOrder = 0,
  }) {
    return _database.insertLocation(
      LocationsCompanion.insert(
        value: value.toLowerCase().trim(),
        displayName: displayName.trim(),
        colorValue: Value(colorValue ?? 0xFFF44336),
        sortOrder: Value(sortOrder),
      ),
    );
  }

  /// Update an existing location
  Future<bool> updateLocation(LocationEntity location) {
    return _database.updateLocation(location);
  }

  /// Delete (deactivate) a location
  Future<int> deactivateLocation(int id) {
    return _database.deactivateLocation(id);
  }

  /// Check if location exists
  Future<bool> locationExists(String value) {
    return _database.locationExists(value);
  }

  /// Get location as ContactTag-like object for UI
  /// This maintains compatibility with existing UI components
  LocationDisplayData locationToDisplayData(LocationEntity entity) {
    return LocationDisplayData(
      value: entity.value,
      displayName: entity.displayName,
      color: Color(entity.colorValue),
      icon: Icons.location_on,
    );
  }

  /// Convert list of entities to display data
  Future<List<LocationDisplayData>> getAllLocationsAsDisplayData() async {
    final locations = await getAllLocations();
    return locations.map(locationToDisplayData).toList();
  }
}

/// Data class for location display in UI
/// Similar to ContactTag but for dynamic locations
class LocationDisplayData {
  final String value;
  final String displayName;
  final Color color;
  final IconData icon;

  const LocationDisplayData({
    required this.value,
    required this.displayName,
    required this.color,
    required this.icon,
  });

  bool get isLocationTag => true;
}
