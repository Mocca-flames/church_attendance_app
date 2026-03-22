# Church Attendance App

An offline-first Android application for church management, built with Flutter. The app enables churches to track attendance, manage member contacts, and organize task scenarios - all working seamlessly offline with automatic synchronization when connectivity is available.

## Features

### Attendance System
- QR code generation and scanning for member check-ins
- Support for multiple service types (Sunday, Tuesday, Special Events)
- Attendance reporting with filtering capabilities
- Duplicate prevention (one check-in per day per service type)

### Contact Management
- Full CRUD operations for church contacts
- Tag-based filtering and categorization
- QR code display for eligible members
- Search functionality by name or phone number

### Scenario/Task Management
- Create task scenarios targeting specific contact tags
- Generate TODO lists from filtered contacts
- Track task completion with user attribution
- Auto-complete scenarios when all tasks are finished

### Offline-First Synchronization
- Local SQLite database with Drift ORM
- Automatic synchronization when internet is available
- Manual sync option with visual status indicators
- Conflict resolution (server wins strategy)

## Architecture

The app follows Clean Architecture principles with feature-based organization:

- **Core Layer**: Database (Drift), Network (Dio), Synchronization, Utilities
- **Feature Layers**: Auth, Contacts, Attendance, Scenarios - each with Data, Domain, and Presentation sub-layers
- **State Management**: Flutter Riverpod with code generation
- **Data Models**: Freezed for immutable classes with JSON serialization

## Key Dependencies

- **State Management**: flutter_riverpod, riverpod_annotation
- **Code Generation**: freezed, json_serializable
- **Database**: drift, sqlite3_flutter_libs
- **Network**: dio, connectivity_plus
- **QR Codes**: qr_flutter, mobile_scanner

## Setup Instructions

1. Clone the repository and install Flutter dependencies
2. Update the API base URL in the network configuration
3. Run code generation for Freezed, JSON, and Drift
4. Launch the app on an Android device or emulator

## Backend Requirements

The backend requires the following components:

1. **User Roles**: super_admin, secretary, it_admin, servant
2. **Database Models**: Attendance, Scenario, ScenarioTask
3. **API Endpoints**: Attendance recording and reporting, Scenario creation and task management
4. **Migration**: Database migration for new tables

## User Roles

- **super_admin**: Full system access
- **secretary**: Communications and contact management
- **it_admin**: Technical administration
- **servant**: Attendance recording and task completion

## Usage

Servants can log in to scan QR codes for attendance, manage contacts, complete scenario tasks from TODO lists, and sync data when internet is available. The app automatically syncs on startup and provides visual indicators for pending sync operations.

## Notes

- Android-only application
- Offline-first design: all operations work offline and sync when connected
- Contact tags stored in metadata JSON format
- QR codes only generated for contacts where name differs from phone and has 'member' tag
- Duplicate attendance is prevented per service type per day

---

Built with Clean Architecture and Flutter for reliable church management.
