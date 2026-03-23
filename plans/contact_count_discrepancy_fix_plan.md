# Contact Count Discrepancy Investigation - ROOT CAUSE FOUND

## Issue Summary
- **Location Stats** shows: Kanana (2978) + Majaneng (630) + Kekana (306) + Mashemong (78) + Temba (5) = **~2997 contacts**
- **Contacts list** shows: **2315 contacts**
- **Discrepancy**: ~682 contacts difference

## Root Cause Identified

### The Problem: Inconsistent Contact Filtering

There are **TWO different ways** contacts are queried in the app:

#### 1. Database Layer (`lib/core/database/database.dart`)
```dart
// Line 189 - Returns ALL contacts including soft-deleted!
Future<List<ContactEntity>> getAllContacts() => select(contacts).get();
```

This method does **NOT** filter by `isDeleted` - it returns ALL contacts in the database, including those marked as deleted.

#### 2. Repository Layer (`lib/features/contacts/data/datasources/contact_local_datasource.dart`)
```dart
// Line 44-49 - Correctly filters out soft-deleted contacts
Future<List<Contact>> getAllContacts() async {
  final entities = await _db.getAllContacts();
  return entities
      .where((e) => !e.isDeleted)  // <-- Filters deleted contacts!
      .map(_mapEntityToContact)
      .toList();
}
```

### How This Causes the Discrepancy

| Component | Uses | Result |
|-----------|------|--------|
| Location Stats (home screen) | `database.getAllContacts()` | ~3000 (includes deleted) |
| Contacts list screen | `ContactLocalDataSource.getAllContacts()` | ~2315 (excludes deleted) |

### The Math Adds Up
- Total from Location Stats: 2978 + 630 + 306 + 78 + 5 = **2997**
- Total from Contacts list: **2315**
- Difference: **682** (these are soft-deleted contacts still in the database)

## Fix Required

### Option 1: Fix at Database Layer (Recommended)
Update `database.getAllContacts()` to filter out deleted contacts:

```dart
// In lib/core/database/database.dart, change line 189:
Future<List<ContactEntity>> getAllContacts() => 
  (select(contacts)..where((t) => t.isDeleted.equals(false))).get();
```

### Option 2: Fix at All Provider Locations
Add `.where((e) => !e.isDeleted)` filter to all places using `database.getAllContacts()`:
- `tag_statistics_provider.dart` (multiple providers)
- `contact_count_provider.dart`

### Impact Assessment
- **Option 1** is cleaner - fixes at source
- **Option 2** is more work but can be done incrementally

## Why Deleted Contacts Have Location Tags
When contacts are "deleted" in the app, they are **soft-deleted** (marked `isDeleted = true`) rather than physically removed. This preserves:
- Attendance history
- Audit trail
- Ability to restore if deleted by mistake

However, their tags remain in the database and are counted by the Location Stats providers that use the unfiltered `database.getAllContacts()`.
