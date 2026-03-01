import 'dart:io';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ==============================================================================
// TABLE DEFINITIONS
// ==============================================================================

@DataClassName('UserEntity')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().withLength(min: 1, max: 255)();
  TextColumn get passwordHash => text()();
  TextColumn get role => text()(); // 'super_admin', 'secretary', 'it_admin', 'servant'
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ContactEntity')
class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()(); // Backend ID
  TextColumn get name => text().nullable()();
  TextColumn get phone => text().withLength(min: 1, max: 20)();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get optOutSms => boolean().withDefault(const Constant(false))();
  BoolColumn get optOutWhatsapp => boolean().withDefault(const Constant(false))();
  TextColumn get metadata => text().nullable()(); // JSON string
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('AttendanceEntity')
class Attendances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()(); // Backend ID
  IntColumn get contactId => integer()();
  TextColumn get phone => text()();
  TextColumn get serviceType => text()(); // 'Sunday', 'Tuesday', 'Special Event'
  DateTimeColumn get serviceDate => dateTime()();
  IntColumn get recordedBy => integer()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

@DataClassName('ScenarioEntity')
class Scenarios extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()(); // Backend ID
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get filterTags => text()(); // JSON array ['kanana', 'member']
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get createdBy => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('ScenarioTaskEntity')
class ScenarioTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()(); // Backend ID
  IntColumn get scenarioId => integer()();
  IntColumn get contactId => integer()();
  TextColumn get phone => text()();
  TextColumn get name => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get completedBy => integer().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
}

@DataClassName('SyncQueueEntity')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'contact', 'attendance', 'scenario', 'scenario_task'
  TextColumn get action => text()(); // 'create', 'update', 'delete'
  IntColumn get localId => integer()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get data => text()(); // JSON payload
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}

/// Table for storing church locations/areas
/// Allows dynamic addition of locations without code changes
@DataClassName('LocationEntity')
class Locations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get value => text().withLength(min: 1, max: 50)(); // Unique identifier (e.g., 'kanana')
  TextColumn get displayName => text().withLength(min: 1, max: 100)(); // Display name (e.g., 'Kanana')
  IntColumn get colorValue => integer().withDefault(const Constant(0xFFF44336))(); // Color as int
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))(); // For manual sorting
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ==============================================================================
// DATABASE CLASS
// ==============================================================================

/// Helper class that combines attendance with contact name
class AttendanceWithContact {
  final AttendanceEntity attendance;
  final String? contactName;

  AttendanceWithContact({
    required this.attendance,
    this.contactName,
  });

  /// Returns the display name - contact name if available, otherwise phone
  String get displayName => contactName ?? attendance.phone;
}

@DriftDatabase(tables: [
  Users,
  Contacts,
  Attendances,
  Scenarios,
  ScenarioTasks,
  SyncQueue,
  Locations,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Add indexes for faster search queries
        await customStatement('CREATE INDEX IF NOT EXISTS idx_contacts_name ON contacts(name)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_contacts_phone ON contacts(phone)');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_contacts_is_deleted ON contacts(is_deleted)');
        // Seed default locations
        await _seedDefaultLocations();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Add indexes on upgrade if they don't exist
        if (from < 2) {
          await m.create(locations);
          await customStatement('CREATE INDEX IF NOT EXISTS idx_contacts_name ON contacts(name)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_contacts_phone ON contacts(phone)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_contacts_is_deleted ON contacts(is_deleted)');
          await _seedDefaultLocations();
        }
      },
    );
  }

  /// Seed default locations on first run
  Future<void> _seedDefaultLocations() async {
    final defaultLocations = [
      LocationsCompanion.insert(value: 'kanana', displayName: 'Kanana', colorValue: const Value(0xFFF44336), sortOrder: const Value(1)),
      LocationsCompanion.insert(value: 'majaneng', displayName: 'Majaneng', colorValue: const Value(0xFFE91E63), sortOrder: const Value(2)),
      LocationsCompanion.insert(value: 'mashemong', displayName: 'Mashemong', colorValue: const Value(0xFF9C27B0), sortOrder: const Value(3)),
      LocationsCompanion.insert(value: 'soshanguve', displayName: 'Soshanguve', colorValue: const Value(0xFF3F51B5), sortOrder: const Value(4)),
      LocationsCompanion.insert(value: 'kekana', displayName: 'Kekana', colorValue: const Value(0xFF2196F3), sortOrder: const Value(5)),
    ];

    for (final location in defaultLocations) {
      await into(locations).insert(location, mode: InsertMode.insertOrIgnore);
    }
  }

  // ==========================================================================
  // CONTACT QUERIES
  // ==========================================================================

  Future<List<ContactEntity>> getAllContacts() => select(contacts).get();

  Future<int> getContactCount() async {
    final result = await select(contacts).get();
    return result.length;
  }

  Future<ContactEntity?> getContactById(int id) =>
      (select(contacts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ContactEntity?> getContactByPhone(String phone) =>
      (select(contacts)..where((t) => t.phone.equals(phone))).getSingleOrNull();

  Future<List<ContactEntity>> getContactsByTag(String tag) {
    return (select(contacts)
          ..where((t) =>
              t.metadata.contains('"$tag"') & t.isDeleted.equals(false)))
        .get();
  }

  /// Get contacts that do NOT have a specific tag (e.g., non-members/visitors)
  /// Uses a custom SQL query to find contacts without the specified tag in their metadata JSON
  Future<List<ContactEntity>> getContactsWithoutTag(String tag) {
    final tagPattern = '%"$tag"%';
    // This query finds contacts where metadata is NULL, empty, or doesn't contain the tag
    return customSelect(
      "SELECT * FROM contacts WHERE is_deleted = 0 AND (metadata IS NULL OR metadata = '' OR metadata NOT LIKE ?",
      variables: [Variable.withString(tagPattern)],
      readsFrom: {contacts},
    ).map((row) => ContactEntity(
      id: row.read<int>('id'),
      serverId: row.readNullable<int>('server_id'),
      name: row.readNullable<String>('name'),
      phone: row.read<String>('phone'),
      status: row.read<String>('status'),
      optOutSms: row.read<bool>('opt_out_sms'),
      optOutWhatsapp: row.read<bool>('opt_out_whatsapp'),
      metadata: row.readNullable<String>('metadata'),
      createdAt: row.read<DateTime>('created_at'),
      isSynced: row.read<bool>('is_synced'),
      isDeleted: row.read<bool>('is_deleted'),
    )).get();
  }

  /// Searches contacts by name or phone number.
  /// Phone numbers are normalized to +27 format for matching.
  Future<List<ContactEntity>> searchContacts(String query) {
    final trimmedQuery = query.trim();
    
    // Normalize phone number if it looks like a complete South African number
    final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(trimmedQuery);
    
    // Extract all digits from query for partial phone matching
    final digitsOnly = trimmedQuery.replaceAll(RegExp(r'\D'), '');
    
    // Handle prefix variations: +27, 27, 0 - strip those prefixes for partial matching
    String searchDigits = digitsOnly;
    if (searchDigits.startsWith('27')) {
      searchDigits = searchDigits.substring(2); // Remove 27 prefix
    } else if (searchDigits.startsWith('0')) {
      searchDigits = searchDigits.substring(1); // Remove 0 prefix
    }
    
    return (select(contacts)
          ..where((t) {
            if (normalizedPhone != null) {
              // If query is a valid complete phone number, search by normalized phone
              // Also search by name for partial matches
              return (t.name.contains(trimmedQuery) | t.phone.contains(normalizedPhone)) &
                  t.isDeleted.equals(false);
            } else if (searchDigits.isNotEmpty) {
              // Partial phone number search - search by name or digits in phone field
              // This handles queries like 082, 27, +27123, etc.
              return (t.name.contains(trimmedQuery) | t.phone.contains(searchDigits)) &
                  t.isDeleted.equals(false);
            } else {
              // Regular search by name or phone
              return (t.name.contains(trimmedQuery) | t.phone.contains(trimmedQuery)) &
                  t.isDeleted.equals(false);
            }
          }))
        .get();
  }

  Future<int> insertContact(ContactsCompanion contact) =>
      into(contacts).insert(contact);

  /// Batch insert multiple contacts efficiently
  Future<void> batchInsertContacts(List<ContactsCompanion> contactsList) async {
    await batch((batch) {
      batch.insertAll(contacts, contactsList);
    });
  }

  /// Batch update multiple contacts efficiently
  Future<void> batchUpdateContacts(List<ContactsCompanion> contactsList) async {
    await batch((batch) {
      for (final contact in contactsList) {
        final serverId = contact.serverId;
        if (serverId.present && serverId.value != null) {
          batch.update(
            contacts,
            contact,
            where: (t) => t.serverId.equals(serverId.value!),
          );
        }
      }
    });
  }

  Future<bool> updateContact(ContactsCompanion contact) =>
      update(contacts).replace(contact);

  /// Updates specific fields of a contact by ID.
  Future<int> updateContactFields({
    required int id,
    int? serverId,
    String? name,
    String? phone,
    String? status,
    bool? optOutSms,
    bool? optOutWhatsapp,
    String? metadata,
    bool? isSynced,
    bool? isDeleted,
  }) {
    final companion = ContactsCompanion(
      id: Value(id),
      serverId: serverId != null ? Value(serverId) : const Value.absent(),
      name: name != null ? Value(name) : const Value.absent(),
      phone: phone != null ? Value(phone) : const Value.absent(),
      status: status != null ? Value(status) : const Value.absent(),
      optOutSms: optOutSms != null ? Value(optOutSms) : const Value.absent(),
      optOutWhatsapp: optOutWhatsapp != null ? Value(optOutWhatsapp) : const Value.absent(),
      metadata: metadata != null ? Value(metadata) : const Value.absent(),
      isSynced: isSynced != null ? Value(isSynced) : const Value.absent(),
      isDeleted: isDeleted != null ? Value(isDeleted) : const Value.absent(),
    );
    return (update(contacts)..where((t) => t.id.equals(id))).write(companion);
  }

  Future<int> deleteContact(int id) =>
      (delete(contacts)..where((t) => t.id.equals(id))).go();

  Future<int> softDeleteContact(int id) {
    return (update(contacts)..where((t) => t.id.equals(id)))
        .write(const ContactsCompanion(isDeleted: Value(true)));
  }

  // ==========================================================================
  // ATTENDANCE QUERIES
  // ==========================================================================

  Future<List<AttendanceEntity>> getAllAttendances() =>
      select(attendances).get();

  Future<List<AttendanceEntity>> getAttendancesByDateRange(
    DateTime from,
    DateTime to,
  ) {
    return (select(attendances)
          ..where((t) =>
              t.serviceDate.isBiggerOrEqualValue(from) &
              t.serviceDate.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.desc(t.serviceDate)]))
        .get();
  }

  Future<List<AttendanceEntity>> getAttendancesByContact(int contactId) {
    return (select(attendances)
          ..where((t) => t.contactId.equals(contactId))
          ..orderBy([(t) => OrderingTerm.desc(t.serviceDate)]))
        .get();
  }

  Future<List<AttendanceEntity>> getAttendancesByServiceType(
      String serviceType) {
    return (select(attendances)
          ..where((t) => t.serviceType.equals(serviceType))
          ..orderBy([(t) => OrderingTerm.desc(t.serviceDate)]))
        .get();
  }

  /// Gets attendances with contact name by joining with contacts table.
  Future<List<AttendanceWithContact>> getAttendancesWithContactsByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final query = select(attendances).join([
      leftOuterJoin(contacts, contacts.id.equalsExp(attendances.contactId)),
    ])
      ..where(attendances.serviceDate.isBiggerOrEqualValue(from) &
          attendances.serviceDate.isSmallerThanValue(to))
      ..orderBy([OrderingTerm.desc(attendances.serviceDate)]);

    final results = await query.get();
    return results.map((row) {
      final attendance = row.readTable(attendances);
      final contact = row.readTableOrNull(contacts);
      return AttendanceWithContact(
        attendance: attendance,
        contactName: contact?.name,
      );
    }).toList();
  }

  /// Gets all attendances with contact name.
  Future<List<AttendanceWithContact>> getAllAttendancesWithContacts() async {
    final query = select(attendances).join([
      leftOuterJoin(contacts, contacts.id.equalsExp(attendances.contactId)),
    ])..orderBy([OrderingTerm.desc(attendances.serviceDate)]);

    final results = await query.get();
    return results.map((row) {
      final attendance = row.readTable(attendances);
      final contact = row.readTableOrNull(contacts);
      return AttendanceWithContact(
        attendance: attendance,
        contactName: contact?.name,
      );
    }).toList();
  }

  /// Gets attendances with contact name filtered by service type.
  Future<List<AttendanceWithContact>> getAttendancesWithContactsByServiceType(
      String serviceType) async {
    final query = select(attendances).join([
      leftOuterJoin(contacts, contacts.id.equalsExp(attendances.contactId)),
    ])
      ..where(attendances.serviceType.equals(serviceType))
      ..orderBy([OrderingTerm.desc(attendances.serviceDate)]);

    final results = await query.get();
    return results.map((row) {
      final attendance = row.readTable(attendances);
      final contact = row.readTableOrNull(contacts);
      return AttendanceWithContact(
        attendance: attendance,
        contactName: contact?.name,
      );
    }).toList();
  }

  Future<AttendanceEntity?> checkAttendanceExists(
    int contactId,
    DateTime serviceDate,
    String serviceType,
  ) {
    // Check if attendance already exists for this contact on this day
    final dateOnly = DateTime(serviceDate.year, serviceDate.month, serviceDate.day);
    final nextDay = dateOnly.add(const Duration(days: 1));
    
    return (select(attendances)
          ..where((t) =>
              t.contactId.equals(contactId) &
              t.serviceType.equals(serviceType) &
              t.serviceDate.isBiggerOrEqualValue(dateOnly) &
              t.serviceDate.isSmallerThanValue(nextDay)))
        .getSingleOrNull();
  }

  Future<int> insertAttendance(AttendancesCompanion attendance) =>
      into(attendances).insert(attendance);

  Future<int> updateAttendance(int id, AttendancesCompanion attendance) {
    return (update(attendances)..where((t) => t.id.equals(id)))
        .write(attendance);
  }

  // ==========================================================================
  // SCENARIO QUERIES
  // ==========================================================================

  Future<List<ScenarioEntity>> getAllScenarios() {
    return (select(scenarios)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<ScenarioEntity>> getScenariosByStatus(String status) {
    return (select(scenarios)
          ..where((t) => t.status.equals(status) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<ScenarioEntity?> getScenarioById(int id) =>
      (select(scenarios)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertScenario(ScenariosCompanion scenario) =>
      into(scenarios).insert(scenario);

  Future<bool> updateScenario(ScenariosCompanion scenario) =>
      update(scenarios).replace(scenario);

  Future<int> deleteScenario(int id) =>
      (update(scenarios)..where((t) => t.id.equals(id)))
          .write(const ScenariosCompanion(isDeleted: Value(true)));

  // ==========================================================================
  // SCENARIO TASK QUERIES
  // ==========================================================================

  Future<List<ScenarioTaskEntity>> getTasksByScenario(int scenarioId) {
    return (select(scenarioTasks)
          ..where((t) => t.scenarioId.equals(scenarioId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<ScenarioTaskEntity?> getTaskById(int id) =>
      (select(scenarioTasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertScenarioTask(ScenarioTasksCompanion task) =>
      into(scenarioTasks).insert(task);

  Future<bool> updateScenarioTask(ScenarioTasksCompanion task) =>
      update(scenarioTasks).replace(task);

  Future<int> deleteScenarioTask(int taskId) =>
      (delete(scenarioTasks)..where((t) => t.id.equals(taskId))).go();

  Future<int> completeTask(int taskId, int completedBy) {
    return (update(scenarioTasks)..where((t) => t.id.equals(taskId))).write(
      ScenarioTasksCompanion(
        isCompleted: const Value(true),
        completedBy: Value(completedBy),
        completedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  Future<int> getCompletedTaskCount(int scenarioId) async {
    final tasks = await getTasksByScenario(scenarioId);
    return tasks.where((t) => t.isCompleted).length;
  }

  Future<int> getTotalTaskCount(int scenarioId) async {
    final tasks = await getTasksByScenario(scenarioId);
    return tasks.length;
  }

  // ==========================================================================
  // SYNC QUEUE QUERIES
  // ==========================================================================

  Future<List<SyncQueueEntity>> getPendingSyncItems() {
    return (select(syncQueue)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<int> insertSyncQueueItem(SyncQueueCompanion item) =>
      into(syncQueue).insert(item);

  Future<bool> updateSyncQueueItem(SyncQueueCompanion item) =>
      update(syncQueue).replace(item);

  Future<int> deleteSyncQueueItem(int id) =>
      (delete(syncQueue)..where((t) => t.id.equals(id))).go();

  /// Clear all items from the sync queue
  Future<int> clearSyncQueue() =>
      delete(syncQueue).go();

  Future<int> getPendingSyncCount() async {
    final items = await getPendingSyncItems();
    return items.length;
  }

  // ==========================================================================
  // USER QUERIES
  // ==========================================================================

  Future<UserEntity?> getCurrentUser() =>
      (select(users)..limit(1)).getSingleOrNull();

  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);

  Future<int> clearUsers() => delete(users).go();

  // ==========================================================================
  // LOCATION QUERIES
  // ==========================================================================

  /// Get all active locations ordered by sort order
  Future<List<LocationEntity>> getAllLocations() {
    return (select(locations)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Get location by value (e.g., 'kanana')
  Future<LocationEntity?> getLocationByValue(String value) {
    return (select(locations)..where((t) => t.value.equals(value)))
        .getSingleOrNull();
  }

  /// Get location by ID
  Future<LocationEntity?> getLocationById(int id) {
    return (select(locations)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new location
  Future<int> insertLocation(LocationsCompanion location) {
    return into(locations).insert(location);
  }

  /// Update a location
  Future<bool> updateLocation(LocationEntity location) {
    return update(locations).replace(location);
  }

  /// Delete (deactivate) a location
  Future<int> deactivateLocation(int id) {
    return (update(locations)..where((t) => t.id.equals(id)))
        .write(const LocationsCompanion(isActive: Value(false)));
  }

  /// Check if location exists by value
  Future<bool> locationExists(String value) async {
    final location = await getLocationByValue(value);
    return location != null;
  }
}

// ==============================================================================
// DATABASE CONNECTION
// ==============================================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'church_attendance.db'));
    return NativeDatabase(file);
  });
}
