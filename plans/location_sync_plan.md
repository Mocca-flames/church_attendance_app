# Plan: Sync New Locations from Server Contacts

## Problem
New locations created on the server need to sync to local devices automatically.

## Solution
When fetching contacts from the server during sync, extract new location tags from contact metadata and auto-create them in the local database.

## How It Works

### 1. Tag Categories
- **Role tags** (ignore): pastor, protocol, worshiper, usher, financier, servant
- **Member tag** (ignore): member  
- **Location tags** (new): Any other tag in metadata

### 2. Sync Flow
```
syncContacts() called
    ↓
Fetch server contacts
    ↓
Extract ALL tags from server contacts
    ↓
Filter: Remove known roles + 'member'
    ↓
Remaining tags = new locations
    ↓
Add to local database (if not exists)
    ↓
Continue with normal contact merge
```

## Implementation

### Changes to `contact_repository_impl.dart`:

1. Add `LocationService` dependency
2. Add helper method to extract new locations
3. Call extraction before merging contacts

### Key Logic:
```dart
// Extract unique tags from server contacts
Set<String> allTags = {};
for (contact in serverContacts) {
  final tags = extractTagsFromMetadata(contact);
  allTags.addAll(tags);
}

// Filter out known roles and member
final knownTags = ['member', 'pastor', 'protocol', 'worshiper', 'usher', 'financier', 'servant'];
final newLocations = allTags.difference(knownTags);

// Add each new location to database
for (locationValue in newLocations) {
  await locationService.addLocation(
    value: locationValue,
    displayName: capitalize(locationValue),
    colorValue: 0xFF9E9E9E, // Default gray
  );
}
```

## Benefits
- ✅ No manual location management needed
- ✅ Works silently in background
- ✅ Minimum code changes required
- ✅ Server is source of truth for new locations
