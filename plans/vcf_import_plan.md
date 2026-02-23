# VCF File Import Implementation Plan

## Overview
Implement `POST /contacts/import-vcf-file` endpoint to allow users to upload VCF (vCard) files to import contacts to the server.

## Requirements
- Upload VCF file as multipart form data to server
- Server processes VCF and imports contacts
- Optionally save imported contacts locally
- Display import results (success count, failed count, errors)

## Architecture

### Data Flow
```
UI (File Picker) 
  → ContactProvider.importVcfFile()
  → ContactRepository.importVcfFile()
  → ContactRemoteDataSource.importVcfFile()
  → Server POST /contacts/import-vcf-file
```

### Files to Modify

#### 1. API Constants (`lib/core/network/api_constants.dart`)
Add new endpoint constant:
```dart
static const String importVcfFile = '/contacts/import-vcf-file';
```

#### 2. Remote Data Source (`lib/features/contacts/data/datasources/contact_remote_datasource.dart`)
Add new method:
```dart
/// Import contacts from VCF file
Future<Map<String, dynamic>> importVcfFile(String filePath) async {
  // Use FormData for multipart file upload
  // Return import result from server
}
```

#### 3. Repository Interface (`lib/features/contacts/domain/repositories/contact_repository.dart`)
Add new method signature:
```dart
/// Import contacts from VCF file
Future<VcfImportResult> importVcfFile(String filePath);
```

#### 4. Repository Implementation (`lib/features/contacts/data/repositories/contact_repository_impl.dart`)
Add new method:
```dart
@Override
Future<VcfImportResult> importVcfFile(String filePath) async {
  // Call remote data source
  // Optionally save contacts locally
  // Return result
}
```

#### 5. Contact Provider (`lib/features/contacts/presentation/providers/contact_provider.dart`)
Add new state and methods:
```dart
// Add VcfImportState
class VcfImportState {
  final bool isImporting;
  final VcfImportResult? result;
  final String? error;
}

// Add importVcfFile method to ContactNotifier
Future<VcfImportResult?> importVcfFile(String filePath) async
```

#### 6. UI Component
Create import button and file picker in contacts screen.

## New Data Models

### VcfImportResult
```dart
class VcfImportResult {
  final bool success;
  final int importedCount;
  final int failedCount;
  final List<String> errors;
}
```

## UI Design
- Floating Action Button (FAB) or menu option in contacts screen
- Opens file picker (use `file_picker` package)
- Shows progress indicator during upload
- Displays result dialog with import summary
- Refreshes contact list after successful import

## Dependencies
- `file_picker: ^8.0.0+` - For selecting VCF files

## Implementation Sequence

1. Add API constant
2. Add remote data source method
3. Add repository interface method
4. Add repository implementation
5. Add provider state and methods
6. Update pubspec.yaml with file_picker
7. Create UI components
8. Test integration
