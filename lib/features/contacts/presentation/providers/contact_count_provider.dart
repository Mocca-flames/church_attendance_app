import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/main.dart';

/// Provider for getting the count of contacts stored locally for offline use.
/// 
/// This helps users verify that their local database has been populated
/// with contacts for offline search functionality.
/// 
/// Usage:
/// ```dart
/// final contactCount = ref.watch(offlineContactCountProvider);
/// ```
final offlineContactCountProvider = FutureProvider<int>((ref) async {
  final database = ref.watch(databaseProvider);
  final contacts = await database.getAllContacts();
  return contacts.length;
});

/// Provider for getting contact count with metadata like last updated.
/// This provides more detailed information about the offline contact store.
final offlineContactStoreInfoProvider = FutureProvider<ContactStoreInfo>((ref) async {
  final database = ref.watch(databaseProvider);
  final contacts = await database.getAllContacts();
  
  // Count members vs non-members
  int memberCount = 0;
  for (final contact in contacts) {
    if (contact.metadata != null && contact.metadata!.contains('"member"')) {
      memberCount++;
    }
  }
  
  return ContactStoreInfo(
    totalCount: contacts.length,
    memberCount: memberCount,
    lastUpdated: contacts.isNotEmpty 
        ? contacts.map((c) => c.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
        : null,
  );
});

/// Information about the offline contact store.
class ContactStoreInfo {
  final int totalCount;
  final int memberCount;
  final DateTime? lastUpdated;

  const ContactStoreInfo({
    required this.totalCount,
    required this.memberCount,
    this.lastUpdated,
  });

  String get displayText {
    if (totalCount == 0) {
      return 'No contacts offline';
    }
    return '$totalCount contacts ($memberCount members)';
  }
}
