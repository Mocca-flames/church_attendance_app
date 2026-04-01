import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/main.dart';
import 'package:church_attendance_app/features/home/presentation/providers/dashboard_providers.dart';

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
  // Watch the refresh trigger to rebuild on refresh
  ref.watch(dashboardRefreshTriggerProvider);
  
  final database = ref.watch(databaseProvider);
  // Use getValidContactCount which excludes contacts with failed sync attempts
  // This ensures accurate counting when contacts fail to sync
  return await database.getValidContactCount();
});

/// Provider for getting contact count with metadata like last updated.
/// This provides more detailed information about the offline contact store.
final offlineContactStoreInfoProvider = FutureProvider<ContactStoreInfo>((ref) async {
  // Watch the refresh trigger to rebuild on refresh
  ref.watch(dashboardRefreshTriggerProvider);
  
  final database = ref.watch(databaseProvider);
  // Use getContactsWithSuccessfulSync which excludes contacts with failed sync attempts
  final contacts = await database.getContactsWithSuccessfulSync();
  
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
