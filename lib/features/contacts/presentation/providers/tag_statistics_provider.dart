import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/enums/contact_tag.dart';
import 'package:church_attendance_app/main.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';
import 'package:church_attendance_app/features/home/presentation/providers/dashboard_providers.dart';

/// Data class for dynamic location display in charts
/// This supports both hardcoded and user-added locations
class DynamicLocationData {
  final String value;
  final String displayName;
  final int count;
  final Color color;

  const DynamicLocationData({
    required this.value,
    required this.displayName,
    required this.count,
    required this.color,
  });
}

/// Helper function to extract tags from ContactEntity metadata
List<String> _extractTags(String? metadata) {
  if (metadata == null || metadata.isEmpty) return [];
  try {
    final Map<String, dynamic> meta = jsonDecode(metadata);
    if (meta.containsKey('tags') && meta['tags'] is List) {
      return (meta['tags'] as List).map((e) => e.toString()).toList();
    }
  } catch (e) {
    // Invalid JSON, return empty
  }
  return [];
}

/// Provider that calculates tag distribution from contacts.
/// Returns a Map<ContactTag, int with counts for each tag.
/// Only includes tags that have count > 0.
final tagDistributionProvider = FutureProvider<Map<ContactTag, int>>((ref) async {
  // Watch the refresh trigger to rebuild on refresh
  ref.watch(dashboardRefreshTriggerProvider);
  
  final database = ref.watch(databaseProvider);
  final contacts = await database.getAllContacts();
  
  // Map to store tag counts
  final Map<ContactTag, int> tagCounts = {};
  
  for (final contact in contacts) {
    // Get tags from contact metadata
    final tags = _extractTags(contact.metadata);
    
    for (final tagValue in tags) {
      final contactTag = ContactTag.fromValue(tagValue);
      if (contactTag != null) {
        tagCounts[contactTag] = (tagCounts[contactTag] ?? 0) + 1;
      }
    }
  }
  
  // Filter out tags with 0 count
  tagCounts.removeWhere((key, value) => value <= 0);
  
  return tagCounts;
});

/// Provider for location tags distribution (horizontal bar chart)
/// Returns a MapContactTag, int with counts for location tags only
/// FIXED: Count unique contacts per location instead of tag occurrences
final locationTagDistributionProvider = FutureProvider<Map<ContactTag, int>>((ref) async {
  // Watch the refresh trigger to rebuild on refresh
  ref.watch(dashboardRefreshTriggerProvider);
  
  final database = ref.watch(databaseProvider);
  final contacts = await database.getAllContacts();
  
  // Map to store unique contact counts per location
  final Map<ContactTag, Set<int>> locationContacts = {};
  
  for (final contact in contacts) {
    final tags = _extractTags(contact.metadata);
    
    for (final tagValue in tags) {
      final contactTag = ContactTag.fromValue(tagValue);
      if (contactTag != null && contactTag.isLocationTag) {
        // Use a Set to track unique contacts per location
        locationContacts.putIfAbsent(contactTag, () => <int>{}).add(contact.id);
      }
    }
  }
  
  // Convert Sets to counts
  final Map<ContactTag, int> locationCounts = {};
  for (final entry in locationContacts.entries) {
    locationCounts[entry.key] = entry.value.length;
  }
  
  // Remove zero counts
  locationCounts.removeWhere((key, value) => value <= 0);
  
  return locationCounts;
});

/// Provider for role tags distribution (radar chart)
/// Returns a MapContactTag, int> with counts for role tags only
/// FIXED: Count unique contacts per role instead of tag occurrences
final roleTagDistributionProvider = FutureProvider<Map<ContactTag, int>>((ref) async {
  // Watch the refresh trigger to rebuild on refresh
  ref.watch(dashboardRefreshTriggerProvider);
  
  final database = ref.watch(databaseProvider);
  final contacts = await database.getAllContacts();
  
  // Map to store unique contact counts per role
  final Map<ContactTag, Set<int>> roleContacts = {};
  
  for (final contact in contacts) {
    final tags = _extractTags(contact.metadata);
    
    for (final tagValue in tags) {
      final contactTag = ContactTag.fromValue(tagValue);
      if (contactTag != null && contactTag.isRoleTag) {
        roleContacts.putIfAbsent(contactTag, () => <int>{}).add(contact.id);
      }
    }
  }
  
  // Convert Sets to counts
  final Map<ContactTag, int> roleCounts = {};
  for (final entry in roleContacts.entries) {
    roleCounts[entry.key] = entry.value.length;
  }
  
  // Remove zero counts
  roleCounts.removeWhere((key, value) => value <= 0);
  
  return roleCounts;
});

/// Provider for membership distribution (member vs non-member)
/// Returns a MapString, int with 'Member' and 'Non-Member' counts
/// This correctly counts each contact once (they're mutually exclusive)
final membershipDistributionProvider = FutureProvider<Map<String, int>>((ref) async {
  // Watch the refresh trigger to rebuild on refresh
  ref.watch(dashboardRefreshTriggerProvider);
  
  final database = ref.watch(databaseProvider);
  final contacts = await database.getAllContacts();
  
  int memberCount = 0;
  int nonMemberCount = 0;
  
  for (final contact in contacts) {
    final tags = _extractTags(contact.metadata);
    
    final bool hasMemberTag = tags.any((tagValue) {
      final contactTag = ContactTag.fromValue(tagValue);
      return contactTag?.isMemberTag ?? false;
    });
    
    if (hasMemberTag) {
      memberCount++;
    } else {
      nonMemberCount++;
    }
  }
  
  return {
    'Member': memberCount,
    'Non-Member': nonMemberCount,
  };
});

/// Data class holding both local and server contact counts
class ContactCountData {
  final int localCount;
  final int serverCount;
  final bool isFromServer;

  const ContactCountData({
    required this.localCount,
    required this.serverCount,
    required this.isFromServer,
  });

  /// Returns the display count (server if available, otherwise local)
  int get displayCount => isFromServer ? serverCount : localCount;

  /// Returns the icon for the current data source
  IconData get icon => isFromServer ? Icons.cloud : Icons.sd_storage;
}

/// Provider for combined local and server contact counts
/// Shows both counts and indicates which source is being displayed
final contactCountDataProvider = FutureProvider<ContactCountData>((ref) async {
  // Watch the refresh trigger to rebuild on refresh
  ref.watch(dashboardRefreshTriggerProvider);
  
  // Get local count
  final database = ref.watch(databaseProvider);
  final contacts = await database.getAllContacts();
  final localCount = contacts.length;

  // Try to get server count
  int serverCount = localCount;
  bool isFromServer = false;

  try {
    final repository = ref.watch(contactRepositoryProvider);
    serverCount = await repository.getTotalContacts();
    isFromServer = true;
  } catch (e) {
    // Server unavailable, will use local count
    isFromServer = false;
  }

  return ContactCountData(
    localCount: localCount,
    serverCount: serverCount,
    isFromServer: isFromServer,
  );
});

/// Provider for total contact count (from server when online, local when offline)
/// This is the primary provider used by the UI
final totalContactCountProvider = FutureProvider<int>((ref) async {
  final countData = await ref.watch(contactCountDataProvider.future);
  return countData.displayCount;
});

/// Provider for dynamic location distribution (horizontal bar chart)
/// Returns a list of DynamicLocationData with counts for ALL locations (hardcoded + dynamic)
/// Sorted by count descending, limited to top 5
/// FIXED: Count unique contacts per location instead of tag occurrences
final dynamicLocationTagDistributionProvider = FutureProvider<List<DynamicLocationData>>((ref) async {
  // Watch the refresh trigger to rebuild on refresh
  ref.watch(dashboardRefreshTriggerProvider);
  
  final database = ref.watch(databaseProvider);
  final contacts = await database.getAllContacts();
  final locations = await database.getAllLocations();
  
  // Map to store unique contact IDs per location
  final Map<String, Set<int>> locationContacts = {};
  
  for (final contact in contacts) {
    final tags = _extractTags(contact.metadata);
    
    for (final tagValue in tags) {
      // Check if this tag matches any known location (hardcoded or dynamic)
      final lowerTag = tagValue.toLowerCase();
      
      // Check against hardcoded ContactTag locations
      final contactTag = ContactTag.fromValue(lowerTag);
      if (contactTag != null && contactTag.isLocationTag) {
        locationContacts.putIfAbsent(lowerTag, () => <int>{}).add(contact.id);
      }
      
      // Check against dynamic locations from database
      for (final loc in locations) {
        if (loc.value.toLowerCase() == lowerTag) {
          locationContacts.putIfAbsent(lowerTag, () => <int>{}).add(contact.id);
        }
      }
    }
  }
  
  // Build list of DynamicLocationData with unique contact counts
  final List<DynamicLocationData> result = [];
  
  // Add hardcoded locations that have counts
  for (final tag in ContactTag.locationTags) {
    final contactIds = locationContacts[tag.value] ?? <int>{};
    if (contactIds.isNotEmpty) {
      result.add(DynamicLocationData(
        value: tag.value,
        displayName: tag.displayName,
        count: contactIds.length,
        color: tag.color,
      ));
    }
  }
  
  // Add dynamic locations from database that have counts
  for (final loc in locations) {
    final contactIds = locationContacts[loc.value.toLowerCase()] ?? <int>{};
    if (contactIds.isNotEmpty) {
      // Check if this location is already added from hardcoded
      final alreadyAdded = result.any((r) => r.value.toLowerCase() == loc.value.toLowerCase());
      if (!alreadyAdded) {
        result.add(DynamicLocationData(
          value: loc.value,
          displayName: loc.displayName,
          count: contactIds.length,
          color: Color(loc.colorValue),
        ));
      }
    }
  }
  
  // Sort by count descending and take top 5
  result.sort((a, b) => b.count.compareTo(a.count));
  
  return result.take(5).toList();
});
