# Church Attendance App - Project Structure

## 📁 Complete Folder Structure

```
church_attendance_app/
├── lib/
│   ├── main.dart                          # App entry point
│   │
│   ├── core/
│   │   ├── database/
│   │   │   ├── database.dart              # Drift database schema
│   │   │   └── database.g.dart            # Generated Drift code
│   │   │
│   │   ├── network/
│   │   │   ├── api_constants.dart         # API endpoints & config
│   │   │   └── dio_client.dart            # HTTP client with interceptors
│   │   │
│   │   ├── sync/
│   │   │   └── sync_manager.dart          # Offline-first sync logic
│   │   │
│   │   ├── enums/
│   │   │   ├── service_type.dart          # Sunday, Tuesday, Special Event
│   │   │   ├── contact_status.dart        # Active, Inactive, Lead, Customer
│   │   │   ├── scenario_status.dart       # Active, Completed
│   │   │   ├── sync_status.dart           # Pending, Syncing, Synced, Failed
│   │   │   └── user_role.dart             # Super Admin, Secretary, IT Admin, Servant
│   │   │
│   │   └── utils/
│   │       ├── constants.dart             # App-wide constants
│   │       └── helpers.dart               # Helper functions
│   │
│   ├── features/
│   │   │
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── auth_local_datasource.dart
│   │   │   │   │   └── auth_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   ├── user.dart          # User model with Freezed
│   │   │   │   │   ├── user.freezed.dart
│   │   │   │   │   └── user.g.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository.dart
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── auth_provider.dart # Riverpod auth state
│   │   │       ├── screens/
│   │   │       │   ├── login_screen.dart
│   │   │       │   └── register_screen.dart
│   │   │       └── widgets/
│   │   │           ├── login_form.dart
│   │   │           └── auth_text_field.dart
│   │   │
│   │   ├── contacts/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── contact_local_datasource.dart
│   │   │   │   │   └── contact_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── contact_repository_impl.dart
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   ├── contact.dart       # Contact model with Freezed
│   │   │   │   │   ├── contact.freezed.dart
│   │   │   │   │   └── contact.g.dart
│   │   │   │   └── repositories/
│   │   │   │       └── contact_repository.dart
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── contact_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── contacts_list_screen.dart
│   │   │       │   ├── contact_detail_screen.dart
│   │   │       │   └── contact_form_screen.dart
│   │   │       └── widgets/
│   │   │           ├── contact_card.dart
│   │   │           ├── contact_qr_code.dart
│   │   │           └── tag_chip.dart
│   │   │
│   │   ├── attendance/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── attendance_local_datasource.dart
│   │   │   │   │   └── attendance_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── attendance_repository_impl.dart
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   ├── attendance.dart    # Attendance model with Freezed
│   │   │   │   │   ├── attendance.freezed.dart
│   │   │   │   │   └── attendance.g.dart
│   │   │   │   └── repositories/
│   │   │   │       └── attendance_repository.dart
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── attendance_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── qr_scanner_screen.dart
│   │   │       │   ├── attendance_list_screen.dart
│   │   │       │   └── attendance_report_screen.dart
│   │   │       └── widgets/
│   │   │           ├── service_type_selector.dart
│   │   │           └── attendance_card.dart
│   │   │
│   │   ├── scenarios/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── scenario_local_datasource.dart
│   │   │   │   │   └── scenario_remote_datasource.dart
│   │   │   │   └── repositories/
│   │   │   │       └── scenario_repository_impl.dart
│   │   │   │
│   │   │   ├── domain/
│   │   │   │   ├── models/
│   │   │   │   │   ├── scenario.dart      # Scenario models with Freezed
│   │   │   │   │   ├── scenario.freezed.dart
│   │   │   │   │   └── scenario.g.dart
│   │   │   │   └── repositories/
│   │   │   │       └── scenario_repository.dart
│   │   │   │
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── scenario_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── scenarios_list_screen.dart
│   │   │       │   ├── scenario_detail_screen.dart
│   │   │       │   └── scenario_form_screen.dart
│   │   │       └── widgets/
│   │   │           ├── scenario_card.dart
│   │   │           ├── task_item.dart
│   │   │           └── progress_indicator.dart
│   │   │
│   │   └── home/
│   │       └── presentation/
│   │           ├── screens/
│   │           │   └── home_screen.dart    # Main dashboard
│   │           └── widgets/
│   │               ├── sync_status_widget.dart
│   │               └── stats_card.dart
│   │
│   └── generated/                          # Generated files from build_runner
│
├── test/                                    # Unit & widget tests
│   └── ...
│
├── android/                                 # Android-specific config
│   ├── app/
│   │   └── build.gradle                    # Android build config
│   └── ...
│
├── pubspec.yaml                            # Dependencies
├── analysis_options.yaml                   # Linter rules
└── README.md                               # Project documentation
```

---

## 🎯 File Responsibilities

### **Core Layer**

| File | Purpose |
|------|---------|
| `database.dart` | Drift database schema, tables, and queries |
| `dio_client.dart` | HTTP client with auth interceptors |
| `sync_manager.dart` | Offline-first sync orchestration |
| `service_type.dart` | Smart enum for service types |
| `contact_status.dart` | Smart enum for contact statuses |
| `scenario_status.dart` | Smart enum for scenario statuses |
| `sync_status.dart` | Smart enum for sync states |
| `user_role.dart` | Smart enum for user roles |

### **Feature Layer (Auth)**

| File | Purpose |
|------|---------|
| `user.dart` | User & AuthResponse models (Freezed) |
| `auth_repository.dart` | Abstract auth repository interface |
| `auth_repository_impl.dart` | Concrete implementation with datasources |
| `auth_local_datasource.dart` | Local storage (SharedPreferences, Drift) |
| `auth_remote_datasource.dart` | Remote API calls (login, register) |
| `auth_provider.dart` | Riverpod state management for auth |
| `login_screen.dart` | Login UI |

### **Feature Layer (Contacts)**

| File | Purpose |
|------|---------|
| `contact.dart` | Contact model with tag helpers |
| `contact_repository.dart` | Abstract repository interface |
| `contact_local_datasource.dart` | Drift queries for contacts |
| `contact_remote_datasource.dart` | API calls for contacts |
| `contact_provider.dart` | Riverpod state for contacts CRUD |
| `contacts_list_screen.dart` | List view with search/filter |
| `contact_form_screen.dart` | Add/edit contact form |
| `contact_qr_code.dart` | QR code generation widget |

### **Feature Layer (Attendance)**

| File | Purpose |
|------|---------|
| `attendance.dart` | Attendance model |
| `attendance_repository.dart` | Abstract repository interface |
| `attendance_local_datasource.dart` | Drift queries for attendance |
| `attendance_remote_datasource.dart` | API calls for attendance |
| `attendance_provider.dart` | Riverpod state for attendance |
| `qr_scanner_screen.dart` | QR code scanner for check-in |
| `attendance_list_screen.dart` | View attendance records |

### **Feature Layer (Scenarios)**

| File | Purpose |
|------|---------|
| `scenario.dart` | Scenario & ScenarioTask models |
| `scenario_repository.dart` | Abstract repository interface |
| `scenario_local_datasource.dart` | Drift queries for scenarios |
| `scenario_remote_datasource.dart` | API calls for scenarios |
| `scenario_provider.dart` | Riverpod state for scenarios |
| `scenarios_list_screen.dart` | List of scenarios (active/completed) |
| `scenario_detail_screen.dart` | Task list with completion tracking |

---

## 🔄 Data Flow

### **Offline-First Pattern**

```
User Action
    ↓
Presentation (Provider)
    ↓
Repository
    ├─→ Local Datasource (Drift) ───→ Save locally
    │                                  ↓
    │                                  Add to SyncQueue
    │                                  ↓
    └─→ Remote Datasource (API) ←────── Sync when online
```

### **Read Flow**

```
User Request
    ↓
Provider
    ↓
Repository
    ↓
Local Datasource (Drift)
    ↓
Return data from SQLite
```

### **Write Flow**

```
User Action (Create/Update/Delete)
    ↓
Provider
    ↓
Repository
    ├─→ Save to Local DB immediately
    └─→ Add to SyncQueue
            ↓
        SyncManager (when online)
            ↓
        Remote API
            ↓
        Update local with server ID
```

---

## 🛠️ Code Generation Commands

```bash
# Generate all code (Freezed, JSON, Drift)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs

# Clean generated files
flutter pub run build_runner clean
```

---

## 📝 Next Implementation Steps

1. ✅ Project structure created
2. ✅ Core enums with smart behavior
3. ✅ Database schema (Drift)
4. ✅ Domain models (Freezed)
5. ✅ Network layer (Dio)
6. ✅ Sync manager
7. ⏳ **Implement repositories** (data layer)
8. ⏳ **Implement providers** (Riverpod state)
9. ⏳ **Build UI screens** (presentation)
10. ⏳ **Test offline sync**

---

**Ready to continue with repository implementations!** 🚀
