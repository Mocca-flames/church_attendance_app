import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:church_attendance_app/core/services/location_service.dart';
import 'package:church_attendance_app/features/contacts/data/datasources/contact_local_datasource.dart';
import 'package:church_attendance_app/features/contacts/data/datasources/contact_remote_datasource.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart' show Contact, ContactLocations;
import 'package:church_attendance_app/features/contacts/domain/repositories/contact_repository.dart';

/// Implementation of ContactRepository.
/// 
/// Follows Clean Architecture principles:
/// - Coordinates between local and remote data sources
/// - Implements offline-first strategy
/// - Handles sync queue for offline operations
class ContactRepositoryImpl implements ContactRepository {
  final ContactLocalDataSource _localDataSource;
  final ContactRemoteDataSource _remoteDataSource;
  final LocationService? _locationService;

  ContactRepositoryImpl({
    required ContactLocalDataSource localDataSource,
    required ContactRemoteDataSource remoteDataSource,
    required DioClient dioClient,
    LocationService? locationService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _locationService = locationService;

  @override
  Future<List<Contact>> getAllContacts() async {
    return _localDataSource.getAllContacts();
  }

  @override
  Future<Contact?> getContactById(int id) async {
    return _localDataSource.getContactById(id);
  }

  @override
  Future<Contact?> getContactByPhone(String phone) async {
    return _localDataSource.getContactByPhone(phone);
  }

  @override
  Future<List<Contact>> searchContacts(String query) async {
    return _localDataSource.searchContacts(query);
  }

  @override
  Future<List<Contact>> getContactsByTag(String tag) async {
    return _localDataSource.getContactsByTag(tag);
  }

  @override
  Future<List<Contact>> getContactsWithoutTag(String tag) async {
    return _localDataSource.getContactsWithoutTag(tag);
  }

  @override
  Future<Contact> createContact(Contact contact) async {
    // Create locally first
    final createdContact = await _localDataSource.createContact(
      phone: contact.phone,
      name: contact.name,
      metadata: contact.metadata != null 
          ? {'tags': contact.tags}
          : null,
      isMember: contact.hasTag('member'),
      location: contact.location,
    );

    // Try to sync to server when online
    if (await _isOnline()) {
      try {
        final serverContact = await _remoteDataSource.createContact(
          phone: createdContact.phone,
          name: createdContact.name,
          tags: createdContact.tags,
        );

        // Update local with server ID and mark as synced
        final serverId = serverContact['id'] as int?;
        if (serverId != null) {
          await _localDataSource.markAsSynced(createdContact.id, serverId);
        }

        return (await _localDataSource.getContactById(createdContact.id))!;
      } catch (e) {
        // Add to sync queue for later retry
        await _localDataSource.addToSyncQueue(
          contactId: createdContact.id,
          action: 'create',
          data: {
            'phone': createdContact.phone,
            'name': createdContact.name,
            'tags': createdContact.tags,
          },
        );
      }
    } else {
      // Offline - add to sync queue
      await _localDataSource.addToSyncQueue(
        contactId: createdContact.id,
        action: 'create',
        data: {
          'phone': createdContact.phone,
          'name': createdContact.name,
          'tags': createdContact.tags,
        },
      );
    }

    return createdContact;
  }

  @override
  Future<Contact> updateContact(Contact contact) async {
    // Update locally
    final updatedContact = await _localDataSource.updateContact(contact);

    // Try to sync to server when online
    if (await _isOnline()) {
      try {
        if (contact.serverId != null) {
          await _remoteDataSource.updateContact(
            id: contact.serverId!,
            name: updatedContact.name,
            phone: updatedContact.phone,
          );
          
          // Mark as synced
          await _localDataSource.markAsSynced(
            updatedContact.id,
            contact.serverId!,
          );
        }
      } catch (e) {
        // Add to sync queue for later retry
        // Fetch current serverId from contact
        final contact = await _localDataSource.getContactById(updatedContact.id);
        await _localDataSource.addToSyncQueue(
          contactId: updatedContact.id,
          action: 'update',
          serverId: contact?.serverId, // Pass serverId for proper sync
          data: {
            'name': updatedContact.name,
            'phone': updatedContact.phone,
            'tags': updatedContact.tags,
          },
        );
      }
    } else {
      // Offline - add to sync queue
      // Fetch current serverId from contact
      final contact = await _localDataSource.getContactById(updatedContact.id);
      await _localDataSource.addToSyncQueue(
        contactId: updatedContact.id,
        action: 'update',
        serverId: contact?.serverId, // Pass serverId for proper sync
        data: {
          'name': updatedContact.name,
          'phone': updatedContact.phone,
          'tags': updatedContact.tags,
        },
      );
    }

    return updatedContact;
  }

  @override
  Future<void> deleteContact(int id) async {
    // Get contact first to check if it has server ID
    final contact = await _localDataSource.getContactById(id);
    
    // Soft delete locally
    await _localDataSource.softDeleteContact(id);

    // Try to delete on server when online
    if (await _isOnline()) {
      try {
        if (contact?.serverId != null) {
          await _remoteDataSource.deleteContact(contact!.serverId!);
        }
      } catch (e) {
        // Add to sync queue for later retry
        await _localDataSource.addToSyncQueue(
          contactId: id,
          action: 'delete',
          serverId: contact?.serverId, // Pass serverId for proper sync
          data: {},
        );
      }
    } else {
      // Offline - add to sync queue
      await _localDataSource.addToSyncQueue(
        contactId: id,
        action: 'delete',
        serverId: contact?.serverId, // Pass serverId for proper sync
        data: {},
      );
    }
  }

  @override
  Future<List<String>> getAllTags() async {
    return _localDataSource.getAllTags();
  }

  @override
  Future<Contact> addTagsToContact(int contactId, List<String> tags) async {
    final updatedContact = await _localDataSource.addTagsToContact(contactId, tags);

    // Try to sync to server when online
    if (await _isOnline()) {
      try {
        final contact = await _localDataSource.getContactById(contactId);
        if (contact?.serverId != null) {
          await _remoteDataSource.addTagsToContact(
            id: contact!.serverId!,
            tags: tags,
          );
        }
      } catch (e) {
        // Add to sync queue for later retry
        final contact = await _localDataSource.getContactById(contactId);
        await _localDataSource.addToSyncQueue(
          contactId: contactId,
          action: 'add_tags',
          serverId: contact?.serverId,
          data: {'tags': tags},
        );
      }
    } else {
      // Offline - add to sync queue
      final contact = await _localDataSource.getContactById(contactId);
      await _localDataSource.addToSyncQueue(
        contactId: contactId,
        action: 'add_tags',
        serverId: contact?.serverId,
        data: {'tags': tags},
      );
    }

    return updatedContact;
  }

  @override
  Future<Contact> removeTagsFromContact(int contactId, List<String> tags) async {
    final updatedContact = await _localDataSource.removeTagsFromContact(contactId, tags);

    // Try to sync to server when online
    if (await _isOnline()) {
      try {
        final contact = await _localDataSource.getContactById(contactId);
        if (contact?.serverId != null) {
          await _remoteDataSource.removeTagsFromContact(
            id: contact!.serverId!,
            tags: tags,
          );
        }
      } catch (e) {
        // Add to sync queue for later retry
        final contact = await _localDataSource.getContactById(contactId);
        await _localDataSource.addToSyncQueue(
          contactId: contactId,
          action: 'remove_tags',
          serverId: contact?.serverId,
          data: {'tags': tags},
        );
      }
    } else {
      // Offline - add to sync queue
      final contact = await _localDataSource.getContactById(contactId);
      await _localDataSource.addToSyncQueue(
        contactId: contactId,
        action: 'remove_tags',
        serverId: contact?.serverId,
        data: {'tags': tags},
      );
    }

    return updatedContact;
  }

  @override
  Future<void> syncContacts() async {
    if (!await _isOnline()) return;

    // Pull contacts from server and merge with local
    try {
      final serverContacts = await _remoteDataSource.getContacts();
      
      // Extract and sync new locations from server contacts
      await _syncLocationsFromServerContacts(serverContacts);
      
      final localContacts = await _localDataSource.getAllContacts();
      
      // Merge server contacts with local contacts
      await _mergeContacts(serverContacts, localContacts);
    } catch (e) {
      // Sync failed - continue with local data
    }
  }

  /// Extracts new locations from server contacts and adds them to local database.
  /// 
  /// Process:
  /// 1. Extract all tags from server contacts
  /// 2. Filter out known role tags and 'member' tag
  /// 3. Any remaining tags = new locations
  /// 4. Add to local database if not already exists
  Future<void> _syncLocationsFromServerContacts(List<Map<String, dynamic>> serverContacts) async {
    if (_locationService == null) return;
    
    // Known tags to exclude (roles + member)
    const excludedTags = {
      'member',
      'pastor',
      'protocol',
      'worshiper',
      'usher',
      'financier',
      'servant',
    };
    
    // Extract all unique tags from server contacts
    final allTags = <String>{};
    for (final contact in serverContacts) {
      final tags = _extractTagsFromContact(contact);
      allTags.addAll(tags);
    }
    
    // Filter to get only potential new locations
    final potentialLocations = allTags.difference(excludedTags);
    
    // Get existing locations to avoid duplicates
    final existingLocations = await _locationService.getAllLocations();
    final existingValues = existingLocations.map((loc) => loc.value.toLowerCase()).toSet();
    final existingDisplayNames = existingLocations.map((loc) => _normalizeForComparison(loc.displayName)).toSet();
    
    // Add new locations that don't exist yet
    for (final locationValue in potentialLocations) {
      // Normalize the value for comparison
      final normalizedValue = _normalizeLocationValue(locationValue);
      final displayName = _capitalize(locationValue);
      final normalizedDisplayName = _normalizeForComparison(displayName);
      
      // Skip if already exists (by value or display name)
      if (existingValues.contains(normalizedValue) || 
          existingDisplayNames.contains(normalizedDisplayName)) {
        continue;
      }
      
      try {
        await _locationService.addLocation(
          value: normalizedValue,
          displayName: displayName,
          colorValue: 0xFF9E9E9E, // Default gray color
        );
      } catch (e) {
        // Location might already exist (race condition), ignore
      }
    }
  }

  /// Normalize a location value for consistent storage.
  /// Converts to lowercase and replaces spaces/underscores with underscores.
  /// Example: "Pretoria East" → "pretoria_east"
  String _normalizeLocationValue(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[\s-]+'), '_')  // Replace spaces/dashes with underscore
        .replaceAll(RegExp(r'[^a-z0-9_]'), ''); // Remove special chars
  }

  /// Normalize a string for comparison (case-insensitive, ignore spaces/underscores).
  String _normalizeForComparison(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_-]+'), '');
  }

  /// Extract tags from a server contact's metadata
  List<String> _extractTagsFromContact(Map<String, dynamic> contact) {
    final tags = <String>{};
    
    // Try to get tags from metadata
    final metadata = contact['metadata'];
    if (metadata != null) {
      if (metadata is String && metadata.isNotEmpty) {
        try {
          final decoded = jsonDecode(metadata);
          if (decoded is Map && decoded.containsKey('tags')) {
            final tagList = decoded['tags'];
            if (tagList is List) {
              for (final tag in tagList) {
                tags.add(tag.toString().toLowerCase());
              }
            }
          }
        } catch (_) {
          // Invalid JSON, ignore
        }
      } else if (metadata is Map) {
        // Direct map format
        if (metadata.containsKey('tags')) {
          final tagList = metadata['tags'];
          if (tagList is List) {
            for (final tag in tagList) {
              tags.add(tag.toString().toLowerCase());
            }
          }
        }
      }
    }
    
    // Also check for 'tags' field directly on contact
    if (contact.containsKey('tags')) {
      final tagList = contact['tags'];
      if (tagList is List) {
        for (final tag in tagList) {
          tags.add(tag.toString().toLowerCase());
        }
      }
    }
    
    return tags.toList();
  }

  /// Capitalize a string
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }

  @override
  Future<Map<String, dynamic>> importVcfFile(String filePath) async {
    if (!await _isOnline()) {
      throw Exception('Cannot import VCF file while offline. Please check your internet connection.');
    }

    // Send VCF file to server
    final result = await _remoteDataSource.importVcfFile(filePath);
    
    // Optionally, sync contacts after import to get the new contacts locally
    // This ensures the local database is in sync with the server
    try {
      await syncContacts();
    } catch (e) {
      // Ignore sync errors - the import was successful on the server
    }
    
    return result;
  }

  /// Merges server contacts with local contacts.
  /// 
  /// Merge strategy:
  /// - Contacts only on server (new) → create them locally
  /// - Contacts only locally → keep them (may be pending sync)
  /// - Contacts on both (by serverId) → update local with server data if synced
  /// - Contacts with pending local changes (not synced) → keep local version
  Future<void> _mergeContacts(
    List<Map<String, dynamic>> serverContacts,
    List<Contact> localContacts,
  ) async {
    // Build lookup maps for efficient matching
    final localByServerId = <int, Contact>{};
    final localByPhone = <String, Contact>{};
    
    for (final local in localContacts) {
      // Index by serverId if available
      if (local.serverId != null) {
        localByServerId[local.serverId!] = local;
      }
      // Also index by phone for matching new contacts
      localByPhone[local.phone] = local;
    }

    // Process each server contact
    for (final serverContact in serverContacts) {
      final serverId = serverContact['id'] as int?;
      if (serverId == null) continue;

      final serverPhone = serverContact['phone'] as String?;
      final serverName = serverContact['name'] as String?;
      final serverMetadata = serverContact['metadata_'] as String?;

      // Check if we already have this contact locally by serverId
      final existingByServerId = localByServerId[serverId];

      if (existingByServerId != null) {
        // Contact exists locally - check if we should update
        if (existingByServerId.isSynced) {
          // Local is synced, update with server data (server takes precedence)
          await _localDataSource.updateContactFields(
            id: existingByServerId.id,
            name: serverName,
            phone: serverPhone,
            tags: _extractTagsFromMetadata(serverMetadata),
          );
          await _localDataSource.markAsSynced(existingByServerId.id, serverId);
        } else {
          // Local has pending changes, keep local version
          // But update the serverId so future syncs work correctly
          await _localDataSource.markAsSynced(existingByServerId.id, serverId);
        }
      } else {
        // New contact from server - check if it exists by phone
        final existingByPhone = serverPhone != null ? localByPhone[serverPhone] : null;

        if (existingByPhone != null) {
          // Contact exists locally by phone but without serverId
          // Update it with server data
          await _localDataSource.updateContactFields(
            id: existingByPhone.id,
            name: serverName,
            phone: serverPhone,
            tags: _extractTagsFromMetadata(serverMetadata),
          );
          await _localDataSource.markAsSynced(existingByPhone.id, serverId);
        } else {
          // Completely new contact - create it locally
          final tags = _extractTagsFromMetadata(serverMetadata);
          final isMember = tags.contains('member');
          final location = tags.where((t) => 
            t != 'member' && ContactLocations.validLocations.contains(t)
          ).firstOrNull;

          final created = await _localDataSource.createContact(
            phone: serverPhone ?? '',
            name: serverName,
            metadata: tags.isNotEmpty ? {'tags': tags} : null,
            isMember: isMember,
            location: location,
          );

          // Mark as synced with server ID
          await _localDataSource.markAsSynced(created.id, serverId);
        }
      }
    }
  }

  /// Extract tags from server metadata JSON
  List<String> _extractTagsFromMetadata(String? metadata) {
    if (metadata == null || metadata.isEmpty) return [];
    try {
      // Metadata from server might be already parsed or a string
      if (metadata.startsWith('{')) {
        final Map<String, dynamic> meta = 
          Map<String, dynamic>.from(_parseJson(metadata));
        if (meta.containsKey('tags') && meta['tags'] is List) {
          return (meta['tags'] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      // Invalid JSON, return empty
    }
    return [];
  }

  /// Parse JSON string safely
  dynamic _parseJson(String jsonString) {
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      return {};
    }
  }

  /// Check if device is online
  /// Simplified check - just check for connectivity, don't require server health check
  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = !connectivityResult.contains(ConnectivityResult.none);
      debugPrint('[Contact Repository] Online check: $isConnected (connectivity: $connectivityResult)');
      return isConnected;
    } catch (e) {
      debugPrint('[Contact Repository] Online check failed: $e');
      return false;
    }
  }
}
