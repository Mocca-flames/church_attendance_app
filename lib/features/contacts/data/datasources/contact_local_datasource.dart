import 'dart:convert';

import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:drift/drift.dart' as drift;

/// Local data source for contact operations.
/// Handles all local database operations using Drift.
class ContactLocalDataSource {
  final AppDatabase _db;

  ContactLocalDataSource(this._db);

  /// Converts database entity to Contact model with proper key mapping
  Contact? _mapEntityToContact(ContactEntity entity) {
    final json = entity.toJson();
    
    // Database uses 'metadata' but Contact model expects 'metadata_'
    if (json.containsKey('metadata') && !json.containsKey('metadata_')) {
      json['metadata_'] = json.remove('metadata');
    }
    // Convert status to string if it's an int
    if (json.containsKey('status') && json['status'] is int) {
      json['status'] = (json['status'] as int).toString();
    }
    // Convert createdAt from int (epoch ms) to ISO8601 string
    if (json.containsKey('createdAt') && json['createdAt'] is int) {
      final epochMs = json['createdAt'] as int;
      json['createdAt'] = DateTime.fromMillisecondsSinceEpoch(epochMs).toIso8601String();
    }
    // Map createdAt to created_at for Contact model compatibility
    if (json.containsKey('createdAt') && !json.containsKey('created_at')) {
      json['created_at'] = json.remove('createdAt');
    }
    
    try {
      return Contact.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Get all contacts (excluding deleted)
  Future<List<Contact>> getAllContacts() async {
    final entities = await _db.getAllContacts();
    return entities
        .where((e) => !e.isDeleted)
        .map(_mapEntityToContact)
        .whereType<Contact>()
        .toList();
  }

  /// Get contact by ID
  Future<Contact?> getContactById(int id) async {
    final entity = await _db.getContactById(id);
    if (entity == null || entity.isDeleted) return null;
    return _mapEntityToContact(entity);
  }

  /// Get contact by phone number
  Future<Contact?> getContactByPhone(String phone) async {
    final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(phone);
    if (normalizedPhone == null) return null;
    
    final entity = await _db.getContactByPhone(normalizedPhone);
    if (entity == null || entity.isDeleted) return null;
    return _mapEntityToContact(entity);
  }

  /// Search contacts by name or phone
  Future<List<Contact>> searchContacts(String query) async {
    final entities = await _db.searchContacts(query);
    return entities
        .where((e) => !e.isDeleted)
        .map(_mapEntityToContact)
        .whereType<Contact>()
        .toList();
  }

  /// Get contacts by tag
  Future<List<Contact>> getContactsByTag(String tag) async {
    final entities = await _db.getContactsByTag(tag);
    return entities
        .where((e) => !e.isDeleted)
        .map(_mapEntityToContact)
        .whereType<Contact>()
        .toList();
  }

  /// Get contacts that do NOT have a specific tag (e.g., non-members/visitors)
  Future<List<Contact>> getContactsWithoutTag(String tag) async {
    final entities = await _db.getContactsWithoutTag(tag);
    return entities
        .where((e) => !e.isDeleted)
        .map(_mapEntityToContact)
        .whereType<Contact>()
        .toList();
  }

  /// Create new contact
  Future<Contact> createContact({
    required String phone,
    String? name,
    Map<String, dynamic>? metadata,
    bool isMember = false,
    String? location,
  }) async {
    // Build tags list
    final List<String> tags = [];
    if (isMember) {
      tags.add('member');
    }
    if (location != null && location.isNotEmpty) {
      tags.add(location.toLowerCase());
    }
    
    // Create metadata JSON
    String? metadataJson;
    if (tags.isNotEmpty) {
      metadataJson = jsonEncode({'tags': tags});
    }
    
    final companion = ContactsCompanion(
      phone: drift.Value(phone),
      name: name != null ? drift.Value(name) : const drift.Value.absent(),
      metadata: metadataJson != null ? drift.Value(metadataJson) : const drift.Value.absent(),
      status: const drift.Value('active'),
      isSynced: const drift.Value(false),
      isDeleted: const drift.Value(false),
    );
    
    final id = await _db.insertContact(companion);
    return (await getContactById(id))!;
  }

  /// Update existing contact
  Future<Contact> updateContact(Contact contact) async {
    // Build metadata JSON from contact tags
    String? metadataJson;
    if (contact.tags.isNotEmpty) {
      metadataJson = jsonEncode({'tags': contact.tags});
    }
    
    await _db.updateContactFields(
      id: contact.id,
      name: contact.name,
      phone: contact.phone,
      metadata: metadataJson,
      isSynced: false,
    );
    
    return (await getContactById(contact.id))!;
  }

  /// Update contact fields directly
  Future<Contact> updateContactFields({
    required int id,
    String? name,
    String? phone,
    List<String>? tags,
  }) async {
    String? metadataJson;
    if (tags != null && tags.isNotEmpty) {
      metadataJson = jsonEncode({'tags': tags});
    }
    
    await _db.updateContactFields(
      id: id,
      name: name,
      phone: phone,
      metadata: metadataJson,
      isSynced: false,
    );
    
    return (await getContactById(id))!;
  }

  /// Soft delete a contact
  Future<void> softDeleteContact(int id) async {
    await _db.softDeleteContact(id);
  }

  /// Restore a soft-deleted contact
  Future<void> restoreContact(int id) async {
    await _db.updateContactFields(
      id: id,
      isDeleted: false,
      isSynced: false,
    );
  }

  /// Permanently delete a contact
  Future<void> permanentlyDeleteContact(int id) async {
    await _db.deleteContact(id);
  }

  /// Add tags to a contact
  Future<Contact> addTagsToContact(int contactId, List<String> tagsToAdd) async {
    final contact = await getContactById(contactId);
    if (contact == null) {
      throw Exception('Contact not found');
    }
    
    final currentTags = contact.tags.toSet();
    currentTags.addAll(tagsToAdd);
    
    return updateContactFields(
      id: contactId,
      tags: currentTags.toList(),
    );
  }

  /// Remove tags from a contact
  Future<Contact> removeTagsFromContact(int contactId, List<String> tagsToRemove) async {
    final contact = await getContactById(contactId);
    if (contact == null) {
      throw Exception('Contact not found');
    }
    
    final currentTags = contact.tags.toSet();
    currentTags.removeAll(tagsToRemove);
    
    return updateContactFields(
      id: contactId,
      tags: currentTags.toList(),
    );
  }

  /// Get all unique tags across all contacts
  Future<List<String>> getAllTags() async {
    final contacts = await getAllContacts();
    final tags = <String>{};
    for (final contact in contacts) {
      tags.addAll(contact.tags);
    }
    return tags.toList()..sort();
  }

  /// Add contact to sync queue for server sync
  /// [serverId] is required for update/delete actions to know which server record to update
  Future<void> addToSyncQueue({
    required int contactId,
    required String action,
    Map<String, dynamic>? data,
    int? serverId, // NEW: Include serverId for update/delete operations
  }) async {
    final companion = SyncQueueCompanion(
      entityType: const drift.Value('contact'),
      action: drift.Value(action),
      localId: drift.Value(contactId),
      serverId: serverId != null ? drift.Value(serverId) : const drift.Value.absent(),
      data: drift.Value(jsonEncode(data ?? {})),
      status: const drift.Value('pending'),
    );
    await _db.insertSyncQueueItem(companion);
  }

  /// Mark contact as synced
  Future<void> markAsSynced(int contactId, int serverId) async {
    await _db.updateContactFields(
      id: contactId,
      serverId: serverId,
      isSynced: true,
    );
  }
}
