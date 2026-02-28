import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/enums/contact_tag.dart';
import 'package:church_attendance_app/main.dart';

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
final locationTagDistributionProvider = FutureProvider<Map<ContactTag, int>>((ref) async {
  final database = ref.watch(databaseProvider);
  final contacts = await database.getAllContacts();
  
  // Map to store location tag counts
  final Map<ContactTag, int> locationCounts = {};
  
  for (final contact in contacts) {
    final tags = _extractTags(contact.metadata);
    
    for (final tagValue in tags) {
      final contactTag = ContactTag.fromValue(tagValue);
      if (contactTag != null && contactTag.isLocationTag) {
        locationCounts[contactTag] = (locationCounts[contactTag] ?? 0) + 1;
      }
    }
  }
  
  // Remove zero counts
  locationCounts.removeWhere((key, value) => value <= 0);
  
  return locationCounts;
});

/// Provider for role tags distribution (radar chart)
/// Returns a MapContactTag, int> with counts for role tags only
final roleTagDistributionProvider = FutureProvider<Map<ContactTag, int>>((ref) async {
  final database = ref.watch(databaseProvider);
  final contacts = await database.getAllContacts();
  
  // Map to store role tag counts
  final Map<ContactTag, int> roleCounts = {};
  
  for (final contact in contacts) {
    final tags = _extractTags(contact.metadata);
    
    for (final tagValue in tags) {
      final contactTag = ContactTag.fromValue(tagValue);
      if (contactTag != null && contactTag.isRoleTag) {
        roleCounts[contactTag] = (roleCounts[contactTag] ?? 0) + 1;
      }
    }
  }
  
  // Remove zero counts
  roleCounts.removeWhere((key, value) => value <= 0);
  
  return roleCounts;
});

/// Provider for membership distribution (member vs non-member)
/// Returns a MapString, int with 'Member' and 'Non-Member' counts
final membershipDistributionProvider = FutureProvider<Map<String, int>>((ref) async {
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

/// Provider for total contact count (alias for offlineContactCountProvider for convenience)
final totalContactCountProvider = FutureProvider<int>((ref) async {
  final database = ref.watch(databaseProvider);
  final contacts = await database.getAllContacts();
  return contacts.length;
});
