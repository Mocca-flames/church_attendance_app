# Sync Retry Limit & Cleanup Plan

## Problem Summary

When the device comes online after being offline, the app attempts to sync pending items to the server. While 200 OK responses work correctly, 400 Bad Request errors cause the app to retry endlessly without ever deleting the failed sync queue items. This creates an infinite loop of failed sync attempts.

## Root Cause Analysis

In `lib/core/sync/sync_manager.dart`, the `syncAll()` method (lines 59-102):

1. Iterates through all pending sync items
2. Attempts to sync each item
3. On failure: increments `retryCount` and updates the item status to "failed"
4. **PROBLEM**: There is NO maximum retry limit check - items keep retrying forever

```dart
// Current code at lines 74-91
for (final item in pendingItems) {
  try {
    await _syncItem(item);
    await _db.deleteSyncQueueItem(item.id);
    syncedCount++;
  } catch (e) {
    _logger.e('Failed to sync item ${item.id}', error: e);
    await _db.updateSyncQueueItem(
      SyncQueueCompanion(
        id: Value(item.id),
        status: const Value('failed'),
        errorMessage: Value(e.toString()),
        retryCount: Value(item.retryCount + 1),  // Always increments
        lastAttemptAt: Value(DateTime.now()),
      ),
    );
    failedCount++;
  }
}
```

## Solution Plan

### Step 1: Add Max Retry Constant

**File:** `lib/core/sync/sync_manager.dart`
**Location:** After line 28 (after `_lastSyncKey`)

```dart
// Maximum number of retry attempts before giving up and deleting the sync queue item
static const int _maxRetryCount = 3;
```

### Step 2: Modify syncAll() to Check Retry Count

**File:** `lib/core/sync/sync_manager.dart`
**Location:** Lines 74-91

**Current Code:**
```dart
} catch (e) {
  _logger.e('Failed to sync item ${item.id}', error: e);
  await _db.updateSyncQueueItem(
    SyncQueueCompanion(
      id: Value(item.id),
      status: const Value('failed'),
      errorMessage: Value(e.toString()),
      retryCount: Value(item.retryCount + 1),
      lastAttemptAt: Value(DateTime.now()),
    ),
  );
  failedCount++;
}
```

**New Code:**
```dart
} catch (e) {
  final newRetryCount = item.retryCount + 1;
  _logger.e('Failed to sync item ${item.id} (attempt $newRetryCount/$_maxRetryCount)', error: e);
  
  // Check if we've exceeded max retries - delete the sync queue item instead of keeping it
  if (newRetryCount >= _maxRetryCount) {
    _logger.w('Max retry count exceeded for item ${item.id}, deleting from sync queue');
    
    // Delete the sync queue item to stop infinite retries
    await _db.deleteSyncQueueItem(item.id);
    
    // Optionally log failed item details for debugging
    _logger.i('Deleted sync queue item - entityType=${item.entityType}, localId=${item.localId}, action=${item.action}');
  } else {
    // Update retry count and status for next attempt
    await _db.updateSyncQueueItem(
      SyncQueueCompanion(
        id: Value(item.id),
        status: const Value('failed'),
        errorMessage: Value(e.toString()),
        retryCount: Value(newRetryCount),
        lastAttemptAt: Value(DateTime.now()),
      ),
    );
  }
  failedCount++;
}
```

### Step 3: Handle 400 Errors Specifically (Optional Enhancement)

For more targeted handling of 400 errors (which are likely corrupt/invalid data), we can add specific detection:

**File:** `lib/core/sync/sync_manager.dart`
**Location:** In the catch block above, add 400-specific handling:

```dart
} catch (e) {
  final newRetryCount = item.retryCount + 1;
  _logger.e('Failed to sync item ${item.id} (attempt $newRetryCount/$_maxRetryCount)', error: e);
  
  // Detect 400 Bad Request errors - these are likely corrupt/invalid data
  // that should be deleted after fewer retries
  final isBadRequest = e is DioException && e.response?.statusCode == 400;
  
  // For 400 errors, delete immediately after 2 retries (faster cleanup)
  final effectiveMaxRetries = isBadRequest ? 2 : _maxRetryCount;
  
  if (newRetryCount >= effectiveMaxRetries) {
    _logger.w('Max retry count exceeded for item ${item.id} (statusCode=${isBadRequest ? '400' : 'other'}), deleting from sync queue');
    await _db.deleteSyncQueueItem(item.id);
    _logger.i('Deleted sync queue item - entityType=${item.entityType}, localId=${item.localId}, action=${item.action}, error=$e');
  } else {
    await _db.updateSyncQueueItem(
      SyncQueueCompanion(
        id: Value(item.id),
        status: const Value('failed'),
        errorMessage: Value(e.toString()),
        retryCount: Value(newRetryCount),
        lastAttemptAt: Value(DateTime.now()),
      ),
    );
  }
  failedCount++;
}
```

Note: This is an optional enhancement. The main fix in Step 2 handles all errors uniformly.

## Implementation Notes

1. **Why delete only the sync queue item, not local data?**
   - The local contact/attendance data may already exist on the server (95% of the time per user's assumption)
   - Deleting local data would cause data loss unnecessarily
   - The sync queue item is just a "pending sync" marker, not the actual data

2. **Error categorization:**
   - 400 Bad Request: Likely invalid/corrupt data → delete after 2 retries (faster)
   - Other errors (network, server issues): Could be temporary → delete after 3 retries

3. **Logging:**
   - Add clear log messages when items are deleted so developers can track issues
   - Include entity type, local ID, and action in delete logs for debugging

## Files to Modify

- `lib/core/sync/sync_manager.dart`

## Testing Checklist

- [ ] Test sync with a 400 error - verify it retries up to limit then deletes
- [ ] Test sync with network error - verify it retries up to limit then deletes
- [ ] Verify no infinite retry loop occurs
- [ ] Check logs show correct retry count and delete messages
- [ ] Verify successful syncs still work correctly (200 OK)
- [ ] Test coming online after offline with pending items