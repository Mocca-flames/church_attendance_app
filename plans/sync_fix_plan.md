# Sync Fix Plan: Contact Pull Not Working

## Problem Summary
When the device comes online (or user triggers Remote/Online Sync), no requests are made to the server to pull contacts. The app only syncs pending local items TO the server but never fetches contacts FROM the server.

## Root Cause
In `lib/core/sync/sync_manager_provider.dart`, the `_triggerAutoSync()` method (lines 85-91) only calls `syncAll()` which pushes local pending items to the server. It does NOT call `pullContacts()` to fetch contacts from the server.

## Fix Plan

### Step 1: Update `_triggerAutoSync()` to pull contacts from server
**File:** `lib/core/sync/sync_manager_provider.dart`
**Location:** Lines 85-91

**Current Code:**
```dart
Future<void> _triggerAutoSync() async {
  try {
    // Sync pending items when coming online
    await ref.read(syncStatusProvider.notifier).syncAll();
  } catch (e) {
    // Silently fail - will retry later
  }
}
```

**Fixed Code:**
```dart
Future<void> _triggerAutoSync() async {
  try {
    // Pull fresh contacts from server when coming online
    await ref.read(syncStatusProvider.notifier).pullContacts();
    // Also sync pending items to server
    await ref.read(syncStatusProvider.notifier).syncAll();
  } catch (e) {
    // Silently fail - will retry later
  }
}
```

### Step 2: Verify SyncStatusNotifier has pullContacts method
The `SyncStatusNotifier` class already has a `pullContacts()` method (lines 215-257 in sync_manager_provider.dart), so no changes needed here.

### Step 3: Consider adding user feedback
- The sync status indicator should show "Syncing..." when pulling contacts
- Progress updates are already handled in `pullContacts()` method

## Implementation Notes

1. **Order of operations**: Pull contacts FIRST, then sync pending items. This ensures:
   - Latest contacts from server are available locally
   - Any local changes can then be pushed to server

2. **Error handling**: Both methods have their own error handling, so wrapping them in try-catch is appropriate

3. **UI Feedback**: The `SyncStatusNotifier.pullContacts()` already updates state with progress information, so the UI will show sync progress

## Additional Considerations

### Option A: Pull Only Contacts (Recommended for this fix)
Just add the `pullContacts()` call as described above.

### Option B: Add a "Force Pull" parameter
Could add a parameter to control whether to force a full sync or use incremental sync:
```dart
Future<void> _triggerAutoSync({bool forceFullSync = false}) async {
  await ref.read(syncStatusProvider.notifier).pullContacts(forceFullSync: forceFullSync);
  await ref.read(syncStatusProvider.notifier).syncAll();
}
```

### Option C: Check if pull is needed first
Could check if contacts actually need pulling before triggering:
```dart
final needsSync = await ref.read(contactsNeedSyncProvider.future);
if (needsSync) {
  await ref.read(syncStatusProvider.notifier).pullContacts();
}
```

## Files to Modify
- `lib/core/sync/sync_manager_provider.dart` - Lines 85-91

## Testing Checklist
- [ ] Test when device transitions from offline to online
- [ ] Test manual sync trigger
- [ ] Verify server requests are made (check network tab/logs)
- [ ] Verify contacts are updated in local database
- [ ] Verify UI shows appropriate sync status
