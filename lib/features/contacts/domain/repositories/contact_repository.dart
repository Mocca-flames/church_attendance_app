

import '../models/contact.dart';

abstract class ContactRepository {
  /// Get all contacts from local database
  Future<List<Contact>> getAllContacts();

  /// Get contact by ID
  Future<Contact?> getContactById(int id);

  /// Get contact by phone number
  Future<Contact?> getContactByPhone(String phone);

  /// Search contacts by name or phone
  Future<List<Contact>> searchContacts(String query);

  /// Get contacts by tag
  Future<List<Contact>> getContactsByTag(String tag);

  /// Create new contact (saves locally and adds to sync queue)
  Future<Contact> createContact(Contact contact);

  /// Update existing contact (saves locally and adds to sync queue)
  Future<Contact> updateContact(Contact contact);

  /// Delete contact (soft delete locally and adds to sync queue)
  Future<void> deleteContact(int id);

  /// Get all unique tags across all contacts
  Future<List<String>> getAllTags();

  /// Add tags to a contact
  Future<Contact> addTagsToContact(int contactId, List<String> tags);

  /// Remove tags from a contact
  Future<Contact> removeTagsFromContact(int contactId, List<String> tags);

  /// Import contacts from a VCF file
  Future<Map<String, dynamic>> importVcfFile(String filePath);

  /// Sync contacts with server
  Future<void> syncContacts();
}
