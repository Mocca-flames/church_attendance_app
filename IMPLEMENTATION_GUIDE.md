# Implementation Guide - Church Attendance App

This guide provides step-by-step instructions for completing the app implementation.

---

## 🎯 Current Status

✅ **Completed:**
- Project structure
- Smart enums (ServiceType, ContactStatus, ScenarioStatus, UserRole, SyncStatus)
- Drift database schema with all tables
- Domain models (User, Contact, Attendance, Scenario) with Freezed
- Network layer (DioClient, API constants)
- SyncManager for offline-first functionality
- Repository interfaces

⏳ **Remaining:**
- Data sources implementations
- Repository implementations  
- Riverpod providers
- UI screens and widgets
- Backend endpoints

---

## 📋 Implementation Checklist

### **Phase 1: Backend Setup** (Do this first!)

- [ ] Add `'servant'` role to User model in backend
- [ ] Create Attendance, Scenario, ScenarioTask models in backend
- [ ] Run database migration (Alembic)
- [ ] Create `app/routers/attendance.py` with all endpoints
- [ ] Create `app/routers/scenarios.py` with all endpoints
- [ ] Register routers in `app/main.py`
- [ ] Test endpoints with curl or Postman

**Refer to README.md sections:**
- "Step 2: Create New Models"
- "Step 4: Create API Endpoints"

---

### **Phase 2: Flutter Code Generation**

```bash
cd church_attendance_app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `*.freezed.dart` files (Freezed models)
- `*.g.dart` files (JSON serialization)
- `database.g.dart` (Drift database)

---

### **Phase 3: Data Sources** (Repository Pattern)

#### **3.1 Contact Data Sources**

**File: `lib/features/contacts/data/datasources/contact_local_datasource.dart`**

```dart
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/core/enums/contact_status.dart';

class ContactLocalDataSource {
  final AppDatabase _db;

  ContactLocalDataSource(this._db);

  Future<List<Contact>> getAllContacts() async {
    final entities = await _db.getAllContacts();
    return entities
        .where((e) => !e.isDeleted)
        .map((e) => _entityToModel(e))
        .toList();
  }

  Future<Contact?> getContactById(int id) async {
    final entity = await _db.getContactById(id);
    return entity != null ? _entityToModel(entity) : null;
  }

  Future<Contact?> getContactByPhone(String phone) async {
    final entity = await _db.getContactByPhone(phone);
    return entity != null ? _entityToModel(entity) : null;
  }

  Future<List<Contact>> searchContacts(String query) async {
    final entities = await _db.searchContacts(query);
    return entities.map((e) => _entityToModel(e)).toList();
  }

  Future<List<Contact>> getContactsByTag(String tag) async {
    final entities = await _db.getContactsByTag(tag);
    return entities.map((e) => _entityToModel(e)).toList();
  }

  Future<Contact> createContact(Contact contact) async {
    final id = await _db.insertContact(
      ContactsCompanion(
        name: Value(contact.name),
        phone: Value(contact.phone),
        status: Value(contact.status.backendValue),
        optOutSms: Value(contact.optOutSms),
        optOutWhatsapp: Value(contact.optOutWhatsapp),
        metadata: Value(contact.metadata),
        isSynced: const Value(false),
      ),
    );

    final created = await _db.getContactById(id);
    return _entityToModel(created!);
  }

  Future<Contact> updateContact(Contact contact) async {
    await _db.updateContact(
      ContactsCompanion(
        id: Value(contact.id),
        serverId: Value(contact.serverId),
        name: Value(contact.name),
        phone: Value(contact.phone),
        status: Value(contact.status.backendValue),
        optOutSms: Value(contact.optOutSms),
        optOutWhatsapp: Value(contact.optOutWhatsapp),
        metadata: Value(contact.metadata),
        isSynced: const Value(false),
      ),
    );

    final updated = await _db.getContactById(contact.id);
    return _entityToModel(updated!);
  }

  Future<void> deleteContact(int id) async {
    await _db.softDeleteContact(id);
  }

  Future<List<String>> getAllTags() async {
    final contacts = await getAllContacts();
    final allTags = <String>{};
    
    for (final contact in contacts) {
      allTags.addAll(contact.tags);
    }
    
    return allTags.toList()..sort();
  }

  Future<Contact> addTagsToContact(int contactId, List<String> tags) async {
    final contact = await getContactById(contactId);
    if (contact == null) throw Exception('Contact not found');

    final currentTags = contact.tags;
    final updatedTags = {...currentTags, ...tags}.toList();
    final metadata = jsonEncode({'tags': updatedTags});

    return updateContact(contact.copyWith(metadata: metadata));
  }

  Future<Contact> removeTagsFromContact(int contactId, List<String> tags) async {
    final contact = await getContactById(contactId);
    if (contact == null) throw Exception('Contact not found');

    final currentTags = contact.tags;
    final updatedTags = currentTags.where((tag) => !tags.contains(tag)).toList();
    final metadata = jsonEncode({'tags': updatedTags});

    return updateContact(contact.copyWith(metadata: metadata));
  }

  // Helper: Convert entity to model
  Contact _entityToModel(ContactEntity entity) {
    return Contact(
      id: entity.id,
      serverId: entity.serverId,
      name: entity.name,
      phone: entity.phone,
      status: ContactStatus.fromBackend(entity.status),
      optOutSms: entity.optOutSms,
      optOutWhatsapp: entity.optOutWhatsapp,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      isSynced: entity.isSynced,
      isDeleted: entity.isDeleted,
    );
  }
}
```

**File: `lib/features/contacts/data/datasources/contact_remote_datasource.dart`**

```dart
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:church_attendance_app/core/network/api_constants.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';

class ContactRemoteDataSource {
  final DioClient _client;

  ContactRemoteDataSource(this._client);

  Future<List<Contact>> getAllContacts() async {
    final response = await _client.get(ApiConstants.contacts);
    final List<dynamic> data = response.data;
    return data.map((json) => Contact.fromJson(json)).toList();
  }

  Future<Contact> createContact(Contact contact) async {
    final response = await _client.post(
      ApiConstants.contacts,
      data: {
        'name': contact.name,
        'phone': contact.phone,
        'status': contact.status.backendValue,
        'opt_out_sms': contact.optOutSms,
        'opt_out_whatsapp': contact.optOutWhatsapp,
        'metadata_': contact.metadata,
      },
    );
    return Contact.fromJson(response.data);
  }

  Future<Contact> updateContact(Contact contact) async {
    final response = await _client.put(
      ApiConstants.contactById.replaceAll('{id}', contact.serverId.toString()),
      data: {
        'name': contact.name,
        'phone': contact.phone,
        'status': contact.status.backendValue,
        'opt_out_sms': contact.optOutSms,
        'opt_out_whatsapp': contact.optOutWhatsapp,
        'metadata_': contact.metadata,
      },
    );
    return Contact.fromJson(response.data);
  }

  Future<void> deleteContact(int serverId) async {
    await _client.delete(
      ApiConstants.contactById.replaceAll('{id}', serverId.toString()),
    );
  }

  Future<List<String>> getAllTags() async {
    final response = await _client.get(ApiConstants.allTags);
    return List<String>.from(response.data);
  }
}
```

#### **3.2 Repository Implementation**

**File: `lib/features/contacts/data/repositories/contact_repository_impl.dart`**

```dart
import 'dart:convert';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/domain/repositories/contact_repository.dart';
import 'package:church_attendance_app/features/contacts/data/datasources/contact_local_datasource.dart';
import 'package:church_attendance_app/features/contacts/data/datasources/contact_remote_datasource.dart';
import 'package:drift/drift.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactLocalDataSource _localDataSource;
  final ContactRemoteDataSource _remoteDataSource;
  final AppDatabase _db;

  ContactRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._db,
  );

  @override
  Future<List<Contact>> getAllContacts() => _localDataSource.getAllContacts();

  @override
  Future<Contact?> getContactById(int id) => _localDataSource.getContactById(id);

  @override
  Future<Contact?> getContactByPhone(String phone) =>
      _localDataSource.getContactByPhone(phone);

  @override
  Future<List<Contact>> searchContacts(String query) =>
      _localDataSource.searchContacts(query);

  @override
  Future<List<Contact>> getContactsByTag(String tag) =>
      _localDataSource.getContactsByTag(tag);

  @override
  Future<Contact> createContact(Contact contact) async {
    final created = await _localDataSource.createContact(contact);

    // Add to sync queue
    await _db.insertSyncQueueItem(
      SyncQueueCompanion(
        entityType: const Value('contact'),
        action: const Value('create'),
        localId: Value(created.id),
        data: Value(jsonEncode({
          'name': created.name,
          'phone': created.phone,
          'status': created.status.backendValue,
          'opt_out_sms': created.optOutSms,
          'opt_out_whatsapp': created.optOutWhatsapp,
          'metadata_': created.metadata,
        })),
      ),
    );

    return created;
  }

  @override
  Future<Contact> updateContact(Contact contact) async {
    final updated = await _localDataSource.updateContact(contact);

    // Add to sync queue
    await _db.insertSyncQueueItem(
      SyncQueueCompanion(
        entityType: const Value('contact'),
        action: const Value('update'),
        localId: Value(updated.id),
        serverId: Value(updated.serverId),
        data: Value(jsonEncode({
          'name': updated.name,
          'phone': updated.phone,
          'status': updated.status.backendValue,
          'opt_out_sms': updated.optOutSms,
          'opt_out_whatsapp': updated.optOutWhatsapp,
          'metadata_': updated.metadata,
        })),
      ),
    );

    return updated;
  }

  @override
  Future<void> deleteContact(int id) async {
    final contact = await _localDataSource.getContactById(id);
    if (contact == null) return;

    await _localDataSource.deleteContact(id);

    // Add to sync queue
    if (contact.serverId != null) {
      await _db.insertSyncQueueItem(
        SyncQueueCompanion(
          entityType: const Value('contact'),
          action: const Value('delete'),
          localId: Value(id),
          serverId: Value(contact.serverId),
          data: const Value('{}'),
        ),
      );
    }
  }

  @override
  Future<List<String>> getAllTags() => _localDataSource.getAllTags();

  @override
  Future<Contact> addTagsToContact(int contactId, List<String> tags) =>
      _localDataSource.addTagsToContact(contactId, tags);

  @override
  Future<Contact> removeTagsFromContact(int contactId, List<String> tags) =>
      _localDataSource.removeTagsFromContact(contactId, tags);

  @override
  Future<void> syncContacts() async {
    // Pull contacts from server
    try {
      final remoteContacts = await _remoteDataSource.getAllContacts();
      
      for (final remote in remoteContacts) {
        final existing = await _localDataSource.getContactByPhone(remote.phone);
        
        if (existing == null) {
          await _localDataSource.createContact(remote);
        }
      }
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
}
```

---

### **Phase 4: Riverpod Providers**

**File: `lib/features/contacts/presentation/providers/contact_provider.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:church_attendance_app/main.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/data/datasources/contact_local_datasource.dart';
import 'package:church_attendance_app/features/contacts/data/datasources/contact_remote_datasource.dart';
import 'package:church_attendance_app/features/contacts/data/repositories/contact_repository_impl.dart';

part 'contact_provider.g.dart';

// Providers
@riverpod
ContactLocalDataSource contactLocalDataSource(ContactLocalDataSourceRef ref) {
  return ContactLocalDataSource(ref.watch(databaseProvider));
}

@riverpod
ContactRemoteDataSource contactRemoteDataSource(ContactRemoteDataSourceRef ref) {
  return ContactRemoteDataSource(DioClient());
}

@riverpod
ContactRepositoryImpl contactRepository(ContactRepositoryRef ref) {
  return ContactRepositoryImpl(
    ref.watch(contactLocalDataSourceProvider),
    ref.watch(contactRemoteDataSourceProvider),
    ref.watch(databaseProvider),
  );
}

// State providers
@riverpod
class ContactList extends _$ContactList {
  @override
  Future<List<Contact>> build() async {
    final repo = ref.watch(contactRepositoryProvider);
    return await repo.getAllContacts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.watch(contactRepositoryProvider);
      return await repo.getAllContacts();
    });
  }

  Future<void> createContact(Contact contact) async {
    final repo = ref.watch(contactRepositoryProvider);
    await repo.createContact(contact);
    await refresh();
  }

  Future<void> updateContact(Contact contact) async {
    final repo = ref.watch(contactRepositoryProvider);
    await repo.updateContact(contact);
    await refresh();
  }

  Future<void> deleteContact(int id) async {
    final repo = ref.watch(contactRepositoryProvider);
    await repo.deleteContact(id);
    await refresh();
  }
}

@riverpod
Future<List<String>> allTags(AllTagsRef ref) async {
  final repo = ref.watch(contactRepositoryProvider);
  return await repo.getAllTags();
}
```

---

### **Phase 5: UI Screens**

Implement screens in this order:

1. **Login Screen** (`lib/features/auth/presentation/screens/login_screen.dart`)
2. **Home Screen** (`lib/features/home/presentation/screens/home_screen.dart`)
3. **Contacts List** (`lib/features/contacts/presentation/screens/contacts_list_screen.dart`)
4. **Contact Form** (`lib/features/contacts/presentation/screens/contact_form_screen.dart`)
5. **QR Scanner** (`lib/features/attendance/presentation/screens/qr_scanner_screen.dart`)
6. **Scenarios List** (`lib/features/scenarios/presentation/screens/scenarios_list_screen.dart`)

---

### **Phase 6: Testing**

```bash
# Run code generation
flutter pub run build_runner build

# Run the app
flutter run

# Test offline functionality
# 1. Turn off wifi/mobile data
# 2. Create contacts, record attendance
# 3. Turn on internet
# 4. Trigger manual sync
# 5. Verify data synced to backend
```

---

## 🔑 Key Implementation Patterns

### **1. Freezed Models**
```dart
@freezed
class Contact with _$Contact {
  const factory Contact({
    required int id,
    required String phone,
    // ... fields
  }) = _Contact;

  factory Contact.fromJson(Map<String, dynamic> json) => _$ContactFromJson(json);
}
```

### **2. Repository Pattern**
```dart
// Interface
abstract class ContactRepository {
  Future<List<Contact>> getAllContacts();
}

// Implementation
class ContactRepositoryImpl implements ContactRepository {
  final LocalDataSource _local;
  final RemoteDataSource _remote;
  
  @override
  Future<List<Contact>> getAllContacts() => _local.getAllContacts();
}
```

### **3. Riverpod Providers**
```dart
@riverpod
class ContactList extends _$ContactList {
  @override
  Future<List<Contact>> build() async {
    return await ref.watch(contactRepositoryProvider).getAllContacts();
  }
}
```

### **4. Smart Enums**
```dart
ServiceType.sunday.backendValue    // 'Sunday'
ServiceType.sunday.displayName     // 'Sunday Service'
ServiceType.sunday.icon            // Icons.church
```

---

## 📌 Important Notes

1. **Always use smart enums** for UI rendering and backend communication
2. **Never skip sync queue** when doing create/update/delete
3. **Test offline-first** thoroughly - it's the main feature
4. **Handle errors gracefully** - show user-friendly messages
5. **Use Riverpod's AsyncValue** for loading/error states

---

**Next: Start with Phase 1 (Backend Setup), then proceed sequentially!** 🚀
