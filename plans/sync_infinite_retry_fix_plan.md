# Sync Infinite Retry Fix - Root Cause Analysis & Solution

## Problem Summary

The sync system appears to retry indefinitely, but actually failed sync items are **stuck forever** in the database with status='failed' and never get processed again.

## Root Cause

### The Bug in `getPendingSyncItems()` 

In [`lib/core/database/database.dart`](lib/core/database/database.dart:539-543):

```dart
Future<List<SyncQueueEntity>> getPendingSyncItems() {
  return (select(syncQueue)
        ..where((t) => t.status.equals('pending')))  // ⚠️ Only fetches 'pending' status
        .get();
}
```

### The Flow That Causes the Stuck Items

1. **First sync cycle:**
   - Item has `status='pending'` → **FETCHED** ✓
   - Sync fails (e.g., 404 error)
   - Status updated to `status='failed'`, retryCount becomes 1

2. **Second sync cycle:**
   - Query only fetches `status='pending'` 
   - The failed item has `status='failed'` → **NOT INCLUDED** ❌

3. **Result:** The item stays in database forever with status='failed', never retried, never deleted.

### Why It Appears as "Endless Retry"

- The user sees the pending count never reaches zero
- New failed items keep getting added to the queue
- The old failed items just sit there forever
- It **looks** like endless retries but items are actually just stuck

## Solution

### Fix 1: Query Both 'pending' AND 'failed' Items

**File:** `lib/core/database/database.dart`  
**Method:** `getPendingSyncItems()`  
**Change:** Fetch items with status='pending' OR status='failed'

```dart
Future<List<SyncQueueEntity>> getPendingSyncItems() {
  return (select(syncQueue)
        ..where((t) => t.status.isIn(['pending', 'failed']))  // Include failed items for retry
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .get();
}
```

### Fix 2: Handle 404 Errors - Delete Immediately

For 404 "Not Found" errors (like deleting a contact that doesn't exist on server), the item should be **deleted immediately** since the resource doesn't exist on the server - retrying won't help.

**File:** `lib/core/sync/sync_manager.dart`  
**Location:** In the catch block of `syncAll()` method

### Fix 3: Handle ApiException from Dio

The DioClient converts DioException to ApiException. Need to check for both types when detecting 404 errors.

### Fix 4: Handle Orphaned Sync Items

When a contact is deleted locally but a sync queue item still exists (update/delete action), the sync will fail with 404. Now we detect this and delete the orphaned sync item immediately.

## Additional Edge Cases Handled

| Edge Case | Before | After |
|-----------|--------|-------|
| DELETE /contacts/1 returns 404 | Retried forever (stuck) | Deleted immediately ✓ |
| ApiException with 404 status | Not detected as 404 | Detected and deleted immediately ✓ |
| Contact deleted locally, sync item exists | Skipped silently, retried forever | Throws error, caught and deleted immediately ✓ |
| Network timeout | Stays as 'failed' forever | Retried up to 3 times then deleted ✓ |
| 400 Bad Request | Retried up to 3x then deleted | Retried up to 3x then deleted ✓ |
| Successful sync | Deleted immediately | Deleted immediately ✓ |

## Files Modified

1. **`lib/core/database/database.dart`** - Line 541-543
   - Changed status filter to include both 'pending' and 'failed'

2. **`lib/core/sync/sync_manager.dart`** - Multiple locations
   - Lines 85-122: Added 404 and local-not-found detection
   - Lines 240-260: Improved orphaned sync item handling

## Testing Checklist

- [x] Test 404 error on DELETE - should be deleted immediately (no retries)
- [x] Test 404 error on PUT - should be deleted immediately
- [x] Test network failure - should retry 3 times then delete
- [x] Test successful sync - item should be deleted
- [x] Verify failed items are now included in sync queries
- [x] Verify pending count goes to zero after all items processed
- [x] Handle ApiException (converted from DioException) for 404 detection
- [x] Handle orphaned sync items when local contact is deleted