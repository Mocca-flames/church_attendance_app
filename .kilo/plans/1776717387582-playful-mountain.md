# Bulk Attendance Deletion Implementation Plan

## Overview
Integrate bulk deletion into Attendance History Screen using the new DELETE /attendance/ endpoint. Allows filtering by date range, service type, and contact to correct marking mistakes.

## Files to Modify

### 1. API Constants
**File**: `lib/core/network/api_constants.dart`
- Add new constant: `static const String attendanceDeleteFiltered = '/attendance/';`

### 2. Repository Interface
**File**: `lib/features/attendance/domain/repositories/attendance_repository.dart`
- Add method: `Future<int> deleteAttendanceFiltered({DateTime? date, DateTime? dateFrom, DateTime? dateTo, ServiceType? serviceType, int? contactId});`
- Returns count of deleted records.

### 3. Remote Data Source
**File**: `lib/features/attendance/data/datasources/attendance_remote_datasource.dart`
- Implement `deleteAttendanceFiltered`:
  - Build query parameters from filters
  - Send DELETE request to `/attendance/` with query params
  - Handle `DioException` appropriately
  - Return deleted count from response (handle both `{'deleted_count': N}` and plain integer responses)

### 4. Local Data Source
**File**: `lib/features/attendance/data/datasources/attendance_local_datasource.dart`
- Add `deleteAttendancesByIds(List<int> ids)` for bulk local deletion.
- Add helper to get attendance IDs matching filters:
  - `Future<List<int>> getAttendanceIdsByFilter({DateTime? date, DateTime? dateFrom, DateTime? dateTo, ServiceType? serviceType, int? contactId});`
- These methods will be used by repository to manage local state and sync queue.

### 5. Repository Implementation
**File**: `lib/features/attendance/data/repositories/attendance_repository_impl.dart`
- Implement `deleteAttendanceFiltered`:
  1. Query local DB for matching attendance records using the filters
  2. Collect their IDs and server IDs
  3. If online:
     - Call remote `deleteAttendanceFiltered` with same filters
     - On success: delete locally by IDs, and clean up any pending sync queue create items for those IDs
     - On failure: for each record with valid serverId (>0), add to sync queue as delete action
  4. If offline:
     - For each record with valid serverId (>0), add to sync queue as delete action
  5. Delete locally by IDs (regardless of sync status)
  6. Clean up sync queue create items for deleted IDs
  7. Return number of records deleted locally
- Ensure `serverId == 0` records (duplicates) are only deleted locally without remote sync.

### 6. Provider State
**File**: `lib/features/attendance/presentation/providers/attendance_history_provider.dart`
- Extend `AttendanceHistoryState`:
  - Add `final int? selectedContactId;` (nullable)
  - Add `final String? selectedContactName;` for UI display
- Update `copyWith` to include new fields with `clearSelectedContact` flag
- Update `build()` initial state to include `selectedContactId: null, selectedContactName: null`
- Add method `Future<void> deleteAttendanceFiltered({required BuildContext context, required DateTime? date, required DateTime? dateFrom, required DateTime? dateTo, required ServiceType? serviceType, required int? contactId, required String? contactName})`:
  - Show confirmation dialog with filter summary and record count
  - Call repository method
  - On success: show success snackbar and reload attendances via `loadAttendances()`
  - On error: display error message

### 7. UI Screen
**File**: `lib/features/attendance/presentation/screens/attendance_history_screen.dart`
- Add state variables: (already managed by provider, no local state needed)
- Update AppBar:
  - Add action button `IconButton` with `Icons.delete` icon for bulk delete
  - On pressed: call `_handleBulkDelete()`
- Add contact filter UI:
  - Below date selector, add a filter bar with:
    - Service type filter button (existing) — show selected or "All"
    - Contact filter button (new) — show selected contact name or "Select Contact"
    - Clear filters button (X) appears when any filter (service type or contact) is active
- Implement `_handleBulkDelete()`:
  - Read current state (dateFrom, dateTo, selectedServiceType, selectedContactId)
  - Determine if single day or range for display
  - Call provider's `deleteAttendanceFiltered` passing all filters
- Implement `_showContactPicker()`:
  - Use `showSearch` or `showDialog` with `ContactSearchProvider`
  - Select contact → set `selectedContactId` and `selectedContactName` via provider
  - Trigger `loadAttendances()` to refresh list
- Add a method to clear contact filter: sets `selectedContactId = null`
- Update `loadAttendances()` call to include contact filter:
  - The existing call already passes only date and service type; extend repository to support contact filter for history fetching as well.
- Also need to update `getAttendanceHistory` in repository to support contact filter.

**Change**: Extend `AttendanceRepository.getAttendanceHistory` to accept optional `contactId` parameter and propagate to local data source. Then provider's `loadAttendances` will pass `state.selectedContactId` to the query.

### 8. Local Data Source (additional)
**File**: `lib/features/attendance/data/datasources/attendance_local_datasource.dart`
- Extend `getAttendanceHistory` to accept `contactId` filter:
  - Join attendances with contacts, add WHERE condition on `contactId` when provided
- Implement `getAttendanceIdsByFilter` to efficiently fetch IDs matching given filters (reuse logic from `getAttendanceHistory` but return only IDs)
- Implement `deleteAttendancesByIds(List<int> ids)` using Drift's `delete(...).where(...).go()` with `in_` filter.

### 9. Database (optional optimization)
**File**: `lib/core/database/database.dart`
- May add index on `contactId` in attendances table if not already present (check existing). Typically foreign key column might not be indexed; but for performance, keep as is for now.

## Implementation Order

1. **Layer 3 (Data) first**:
   - Add API constant
   - Extend repository interface
   - Add remote bulk delete method
   - Extend local data source (getAttendanceIds, deleteAttendancesByIds, update getAttendanceHistory for contact filter)
   - Implement repository bulk delete method
2. **Layer 2 (Provider)**:
   - Extend state with contact filter fields
   - Add deleteAttendanceFiltered notifier method
   - Update loadAttendances to include contactId filter
3. **Layer 1 (UI)**:
   - Add contact filter button & clear UI
   - Add bulk delete action button
   - Implement contact picker dialog using contact search infrastructure
   - Implement confirmation dialog for deletion
   - Display selected contact as chip/tag

## Sync & Offline Behavior

- Online: Remote deletion attempted immediately; local reflects immediately.
- Offline: Delete operations queued for later sync. Local records removed instantly to reflect UI state.
- After sync resumes, queued deletes execute in batch.
- Ensures no stray records reappear after sync.

## Edge Cases & Validation

- Prevent deletion when no filters applied? The endpoint allows deleting all; but UI should warn strongly if date range wide or no filters. Show count in confirmation.
- Single-day date uses `date` param; range uses `date_from`/`date_to` — replicate logic from PDF export.
- Service type filter maps to backend value.
- Contact filter shows only active contacts (non-deleted).
- After deletion, recalc service type counts correctly.

## Additional Considerations

- Update `getAttendanceHistory` in all layers to support `contactId` so that filtering by contact also affects the displayed list.
- Ensure UI updates correctly when contact filter is active (summary cards reflect filtered counts).
- The confirmation dialog should display "You are about to delete X attendance records for [Contact Name] on [date/range] [service type]".
- Use `mounted` checks after async calls to avoid setState after dispose.

## Testing Checklist

- Verify remote call payload includes correct query params.
- Test offline: deletion queued and applied after coming online.
- Test with no filters: count matches all records.
- Test with contact filter: only that contact's records deleted.
- Test with date range: records within range deleted.
- Test with service type: only matching service type deleted.
- Test that summary cards update after deletion.
- Test that long-press single delete still works.
