# VCF Share Intent Implementation Plan

## ✅ IMPLEMENTATION COMPLETED

### What Was Done:
1. **MethodChannel with Polling**: Implemented a polling-based approach (every 500ms) to avoid race conditions
2. **No external packages**: Removed `receive_sharing_intent` due to JVM compatibility issues
3. **No VCF parsing in Dart**: Server handles VCF parsing via existing `importVcfFile()`
4. **Reuses existing infrastructure**: Uses same import method as FilePicker

### Files Created/Modified:
- ✅ `android/app/src/main/AndroidManifest.xml` - Added VCF intent filters
- ✅ `android/app/src/main/kotlin/.../MainActivity.kt` - Native intent handling
- ✅ `lib/core/services/vcf_sharing_service.dart` - MethodChannel service
- ✅ `lib/features/contacts/presentation/providers/vcf_share_intent_provider.dart` - Riverpod provider
- ✅ `lib/features/contacts/presentation/widgets/vcf_import_dialog.dart` - Reusable dialogs
- ✅ `lib/features/contacts/presentation/widgets/vcf_share_intent_handler.dart` - Handler widget
- ✅ `lib/main.dart` - Added handler wrapper

---

## Overview
This document outlines the implementation strategy for handling VCF file sharing directly into the Attendance app when the app is not running in the foreground. Users will be able to share VCF contacts from their system contacts app, and our app will receive the intent, parse the VCF, show a preview, and allow direct upload to the server.

## Current State Analysis

### Existing Infrastructure
The project already has:
- **Contact feature** with domain models, providers, and screens
- **VCF import functionality** in `contact_list_screen.dart` using `FilePicker`
- **Provider-based state management** with Riverpod
- **Server upload endpoint**: Already implemented via `contactNotifierProvider.notifier.importVcfFile(filePath)`
- **Result handling**: Import result dialog with success/fail counts and errors
- **File picker integration**: Using `file_picker` package

### Current Import Flow
```
FilePicker → File Selection → Dialog Loading → importVcfFile() → Result Dialog
```

### New Share Intent Flow (SIMPLIFIED)
```
System Share Intent → App Launch/Wake → importVcfFile() → Result Dialog
```
**Note**: No VCF parsing in Dart - server handles parsing and validation

---

## Architecture Blueprint

### System-Level Flow
```
┌─────────────────────────────────────────────────────────────────┐
│                         USER ACTION                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ User selects VCF in Contacts App → Tap "Share" → Select    ││
│  │ Attendance App from Share Sheet                             ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  ANDROID SYSTEM LAYER                           │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Intent.ACTION_SEND                                          ││
│  │ MIME Type: text/x-vcard, text/vcard, or application/*       ││
│  │ Extra: Intent.EXTRA_STREAM (URI to VCF file)                ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              ANDROID MANIFEST CONFIGURATION                     │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Intent-filter for ACTION_SEND                               ││
│  │ MIME types: text/x-vcard, text/vcard, */*                   ││
│  │ Launch mode: singleTask (prevent multiple instances)        ││
│  │ exported: true (required for system sharing)                ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                KOTLIN NATIVE LAYER                              │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ MainActivity.onCreate() → handleIntent()                    ││
│  │ OR                                                           ││
│  │ MainActivity.onNewIntent() → handleIntent() (if app running)││
│  │                                                              ││
│  │ ContentResolver + openInputStream() to read URI             ││
│  │ Copy to app cache directory (scoped storage compliant)      ││
│  │ Pass file path via MethodChannel to Dart                    ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER DART LAYER                           │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ 1. Poll MethodChannel for shared VCF path (every 500ms)     ││
│  │ 2. Show confirmation dialog (filename)                       ││
│  │ 3. Upload via existing contactNotifierProvider              ││
│  │ 4. Show ImportResultDialog (reuse existing)                 ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Dependencies & Setup

### 1.1 Add Required Packages

Update `pubspec.yaml`:
```yaml
dependencies:
  # Existing
  flutter_riverpod: ^2.x.x
  dio: ^5.4.0
  file_picker: ^5.x.x
  
  # NEW: No additional packages needed (using MethodChannel)
```

**Note**: Using native MethodChannel instead of external packages to avoid compatibility issues

**Why these packages?**
- `receive_sharing_intent`: Handles Android intents (NOTE: Removed due to JVM compatibility - using MethodChannel instead)
- No VCF parsing package needed - server handles parsing
- `path_provider`: Access app cache directory for temp files

### 1.2 Run Pub Get
```bash
flutter pub get
```

---

## Phase 2: Android Native Configuration

### 2.1 Update AndroidManifest.xml

**File**: `android/app/src/main/AndroidManifest.xml`

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTask"
    android:windowSoftInputMode="adjustResize">
    
    <!-- Existing intent filter for launcher -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
    
    <!-- NEW: Intent filter for VCF sharing (single file) -->
    <intent-filter>
        <action android:name="android.intent.action.SEND" />
        <category android:name="android.intent.category.DEFAULT" />
        <!-- VCF MIME types -->
        <data android:mimeType="text/x-vcard" />
        <data android:mimeType="text/vcard" />
        <data android:mimeType="text/plain" />
        <!-- Fallback for files without proper MIME type -->
        <data android:mimeType="application/octet-stream" />
    </intent-filter>
    
    <!-- OPTIONAL: Intent filter for multiple VCF files -->
    <intent-filter>
        <action android:name="android.intent.action.SEND_MULTIPLE" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="text/x-vcard" />
        <data android:mimeType="text/vcard" />
    </intent-filter>
    
    <meta-data
        android:name="flutterEmbedding"
        android:value="2" />
</activity>
```

**Key Attributes Explained:**
- `android:exported="true"`: Allows system share sheet to find and launch our app
- `android:launchMode="singleTask"`: Prevents multiple app instances when sharing while app is running
- `SEND` action: Single file sharing
- `SEND_MULTIPLE` action: Multiple files (optional, handle later)

### 2.2 Update MainActivity.kt

**File**: `android/app/src/main/kotlin/com/your_company/attendance/MainActivity.kt`

```kotlin
package com.example.attendance

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.attendance/shared_data"
    private var sharedVcfPath: String? = null
    private var pendingVcfPath: String? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Flutter calls this to check if we have a pending shared VCF
                    "getSharedVcfPath" -> {
                        val path = sharedVcfPath
                        sharedVcfPath = null  // Clear after reading
                        result.success(path)
                    }
                    else -> result.notImplemented()
                }
            }
        
        // Handle intent from cold start or new intent
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // When app is already running and user shares a file
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_SEND) {
            val type = intent.type
            
            // Verify it's a text-based MIME type (VCF files)
            if (type != null && (
                type.startsWith("text/") || 
                type == "application/octet-stream" ||
                type.startsWith("*")
            )) {
                val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM)
                }
                
                uri?.let {
                    val path = copyUriToCache(it)
                    if (path != null) {
                        pendingVcfPath = path
                        sharedVcfPath = path
                        // Send to Flutter if engine is ready
                        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                            MethodChannel(messenger, CHANNEL).invokeMethod(
                                "onVcfShared",
                                mapOf("path" to path)
                            )
                        }
                    }
                }
            }
        }
    }

    private fun copyUriToCache(uri: Uri): String? {
        return try {
            // Use ContentResolver to read the file from URI
            contentResolver.openInputStream(uri)?.use { input ->
                // Create a temporary file in app's cache directory
                val tempFile = File(cacheDir, "shared_vcf_${System.currentTimeMillis()}.vcf")
                tempFile.outputStream().use { output ->
                    input.copyTo(output)
                }
                return tempFile.absolutePath
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
```

**Key Points:**
- `CHANNEL = "com.attendance/shared_data"`: Must match the Dart side channel
- `handleIntent()`: Called both on app launch and when already running
- `copyUriToCache()`: Uses `ContentResolver` (Android 10+ scoped storage compliant)
- Two-way communication: Kotlin can call Flutter methods, and Dart can poll for shared path

---

## Phase 3: Flutter/Dart Implementation

### 3.1 Create Sharing Service

**File**: `lib/core/services/vcf_sharing_service.dart`

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:vcf_dart/vcf_dart.dart';
import 'package:path_provider/path_provider.dart';

class VcfSharingService {
  static const String _channel = 'com.attendance/shared_data';
  static final MethodChannel _methodChannel = MethodChannel(_channel);
  
  static Future<String?> getSharedVcfPath() async {
    try {
      final String? path = await _methodChannel.invokeMethod('getSharedVcfPath');
      return path;
    } catch (e) {
      print('Error getting shared VCF path: $e');
      return null;
    }
  }

  /// Parse VCF file and return list of parsed contact data
  static Future<VcfParseResult> parseVcfFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return VcfParseResult(
          success: false,
          contacts: [],
          error: 'File not found: $filePath',
        );
      }

      final content = await file.readAsString();
      final vcf = Vcf.parse(content);

      final contacts = <VcfContact>[];
      final errors = <String>[];

      for (int i = 0; i < vcf.vCards.length; i++) {
        final vCard = vcf.vCards[i];
        try {
          final name = vCard.formattedName?.value ?? 
                       vCard.name?.value ?? 
                       'Unknown Contact';
          
          // Extract first phone number
          final phone = vCard.telephones.isNotEmpty 
              ? vCard.telephones.first.value 
              : null;
          
          // Extract first email
          final email = vCard.emails.isNotEmpty 
              ? vCard.emails.first.value 
              : null;

          // Only add if we have at least a name
          if (name.isNotEmpty) {
            contacts.add(VcfContact(
              name: name,
              phoneNumbers: vCard.telephones.map((t) => t.value).toList(),
              emails: vCard.emails.map((e) => e.value).toList(),
              organization: vCard.organization?.value,
            ));
          } else {
            errors.add('Contact #${i + 1}: Missing name');
          }
        } catch (e) {
          errors.add('Contact #${i + 1}: ${e.toString()}');
        }
      }

      return VcfParseResult(
        success: contacts.isNotEmpty,
        contacts: contacts,
        error: errors.isNotEmpty ? errors.join('\n') : null,
      );
    } catch (e) {
      return VcfParseResult(
        success: false,
        contacts: [],
        error: 'Failed to parse VCF: ${e.toString()}',
      );
    }
  }

  /// Clean up temporary VCF file
  static Future<void> cleanupTempFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error cleaning up temp file: $e');
    }
  }
}

class VcfContact {
  final String name;
  final List<String> phoneNumbers;
  final List<String> emails;
  final String? organization;

  VcfContact({
    required this.name,
    required this.phoneNumbers,
    required this.emails,
    this.organization,
  });

  String get firstPhone => phoneNumbers.isNotEmpty ? phoneNumbers.first : '';
  String get firstEmail => emails.isNotEmpty ? emails.first : '';
}

class VcfParseResult {
  final bool success;
  final List<VcfContact> contacts;
  final String? error;

  VcfParseResult({
    required this.success,
    required this.contacts,
    this.error,
  });

  int get validContactCount => contacts.length;
}
```

### 3.2 Create Share Intent Provider

**File**: `lib/features/contacts/presentation/providers/vcf_share_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/services/vcf_sharing_service.dart';

class VcfShareState {
  final String? vcfPath;
  final VcfParseResult? parseResult;
  final bool isLoading;
  final String? error;

  const VcfShareState({
    this.vcfPath,
    this.parseResult,
    this.isLoading = false,
    this.error,
  });

  VcfShareState copyWith({
    String? vcfPath,
    VcfParseResult? parseResult,
    bool? isLoading,
    String? error,
  }) {
    return VcfShareState(
      vcfPath: vcfPath ?? this.vcfPath,
      parseResult: parseResult ?? this.parseResult,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class VcfShareNotifier extends StateNotifier<VcfShareState> {
  VcfShareNotifier() : super(const VcfShareState());

  /// Check if app was launched with a shared VCF file
  Future<void> checkForSharedVcf() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final path = await VcfSharingService.getSharedVcfPath();
      
      if (path != null) {
        state = state.copyWith(vcfPath: path);
        await parseVcf(path);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check for shared VCF: $e',
      );
    }
  }

  /// Parse the VCF file
  Future<void> parseVcf(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await VcfSharingService.parseVcfFile(filePath);
      state = state.copyWith(parseResult: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to parse VCF: $e',
      );
    }
  }

  /// Clear share state (when user cancels or completes)
  Future<void> clearShareState() async {
    if (state.vcfPath != null) {
      await VcfSharingService.cleanupTempFile(state.vcfPath!);
    }
    state = const VcfShareState();
  }
}

final vcfShareProvider = 
    StateNotifierProvider<VcfShareNotifier, VcfShareState>((ref) {
  return VcfShareNotifier();
});
```

### 3.3 Create Share Preview Screen

**File**: `lib/features/contacts/screens/vcf_share_preview_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/vcf_share_provider.dart';

class VcfSharePreviewScreen extends ConsumerWidget {
  const VcfSharePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareState = ref.watch(vcfShareProvider);
    final parseResult = shareState.parseResult;

    if (shareState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Importing Contacts'),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: 16),
              Text('Parsing VCF file...'),
            ],
          ),
        ),
      );
    }

    if (shareState.error != null || parseResult == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Import Error'),
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[300],
                ),
                const SizedBox(height: AppDimens.paddingM),
                Text(
                  'Failed to import contacts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppDimens.paddingS),
                Text(
                  shareState.error ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDimens.paddingL),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(vcfShareProvider.notifier).clearShareState();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Contacts'),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await ref.read(vcfShareProvider.notifier).clearShareState();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Summary section
          Container(
            color: AppColors.primary.withValues(alpha: 0.05),
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimens.paddingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      label: 'Contacts Found',
                      value: parseResult.validContactCount.toString(),
                      color: Colors.green,
                    ),
                    if (parseResult.error != null)
                      _buildStatCard(
                        label: 'Issues',
                        value: parseResult.error?.split('\n').length.toString() ?? '0',
                        color: Colors.orange,
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Contacts list
          Expanded(
            child: parseResult.validContactCount > 0
                ? ListView.separated(
                    padding: const EdgeInsets.all(AppDimens.paddingM),
                    itemCount: parseResult.validContactCount,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final contact = parseResult.contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            contact.name.characters.first.toUpperCase(),
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                        title: Text(contact.name),
                        subtitle: contact.firstPhone.isNotEmpty
                            ? Text(contact.firstPhone)
                            : (contact.firstEmail.isNotEmpty
                                ? Text(contact.firstEmail)
                                : null),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: AppDimens.paddingM),
                        Text(
                          'No valid contacts found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
          ),
          // Error details section
          if (parseResult.error != null)
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border(
                  top: BorderSide(color: Colors.orange.withValues(alpha: 0.2)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Import Issues',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    parseResult.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(vcfShareProvider.notifier).clearShareState();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: ElevatedButton(
                onPressed: parseResult.validContactCount > 0
                    ? () => _handleUpload(context, ref, parseResult)
                    : null,
                child: const Text('Import Contacts'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _handleUpload(
    BuildContext context,
    WidgetRef ref,
    VcfParseResult parseResult,
  ) async {
    final shareState = ref.read(vcfShareProvider);
    if (shareState.vcfPath == null) return;

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 20),
              Text('Importing contacts...'),
            ],
          ),
        ),
      );
    }

    // Upload via existing contact provider
    final importResult = await ref
        .read(contactNotifierProvider.notifier)
        .importVcfFile(shareState.vcfPath!);

    if (context.mounted) Navigator.of(context).pop();

    if (importResult != null && context.mounted) {
      // Clean up
      await ref.read(vcfShareProvider.notifier).clearShareState();
      
      // Show result dialog (reuse existing one from contact_list_screen)
      _showImportResultDialog(context, importResult);
      
      // Navigate back after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) Navigator.of(context).pop();
      });
    } else if (context.mounted) {
      final error = ref.read(contactNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to import VCF file'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showImportResultDialog(BuildContext context, Map<String, dynamic> result) {
    final success = result['success'] as bool? ?? false;
    final importedCount = result['imported_count'] as int? ?? 0;
    final failedCount = result['failed_count'] as int? ?? 0;
    final errors = (result['errors'] as List<dynamic>?)?.cast<String>() ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              color: success ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              success ? 'Import Complete' : 'Import Issues',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultRow('Imported', '$importedCount', Colors.green),
              if (failedCount > 0) ...[
                const SizedBox(height: 8),
                _buildResultRow('Failed', '$failedCount', Colors.red),
              ],
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors
                        .map((error) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $error', style: const TextStyle(fontSize: 12)),
                        ))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
```

### 3.4 Update Main.dart to Check for Share Intent

**File**: `lib/main.dart` (modify the home screen initialization)

Add this in your `_MyAppState` or main widget build method:

```dart
@override
void initState() {
  super.initState();
  _checkForSharedVcf();
}

void _checkForSharedVcf() {
  // Check if app was launched with a shared VCF file
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ref = context.read<ProviderContainer>();
    ref.read(vcfShareProvider.notifier).checkForSharedVcf().then((value) {
      final shareState = ref.read(vcfShareProvider);
      if (shareState.vcfPath != null && shareState.parseResult != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const VcfSharePreviewScreen(),
          ),
        );
      }
    });
  });
}
```

Or use a more elegant approach with a consumer widget wrapper:

```dart
class HomeScreenWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to vcfShareProvider to detect when app is launched with share intent
    final shareState = ref.watch(vcfShareProvider);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shareState.vcfPath != null && 
          shareState.parseResult != null && 
          !shareState.isLoading) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const VcfSharePreviewScreen(),
          ),
        );
      }
    });

    return const HomeScreen();
  }
}
```

---

## Phase 4: Integration Points

### 4.1 Reuse Existing Infrastructure

The implementation leverages existing providers and screens:

| Component | Location | How It's Reused |
|-----------|----------|-----------------|
| Import Upload | `contactNotifierProvider` | VcfSharePreviewScreen calls `.importVcfFile()` |
| Result Dialog | `contact_list_screen.dart` | Extracted logic into `_showImportResultDialog()` |
| Contact Model | `features/contacts/domain/models/` | Used for type-safety |
| AppColors | `core/constants/app_constants.dart` | Consistent theming |

### 4.2 Method Channel Flow Diagram

```
App Launch / New Intent (Android)
         ↓
MainActivity.handleIntent()
         ↓
copyUriToCache() → File path
         ↓
MethodChannel: invokeMethod("onVcfShared", path)
         ↓
Flutter: vcfShareProvider receives notification
         ↓
VcfSharingService.parseVcfFile(path)
         ↓
VcfSharePreviewScreen displays preview
         ↓
User taps "Import Contacts"
         ↓
contactNotifierProvider.importVcfFile()
         ↓
Show ImportResultDialog
         ↓
Navigate back
```

---

## Phase 5: Testing Checklist

### Manual Testing Scenarios

| Scenario | Expected Behavior | Status |
|----------|-------------------|--------|
| **Cold Start Share** | App closed, share VCF → App opens, shows preview | ⬜ |
| **Warm Start Share** | App running, share VCF → onNewIntent triggers, preview shows | ⬜ |
| **Single VCF Share** | Share 1 file → Parse & upload works | ⬜ |
| **Multiple Contacts VCF** | VCF with 50+ contacts → Shows count, preview scrolls | ⬜ |
| **Invalid VCF** | Corrupted VCF file → Shows parse error, no upload | ⬜ |
| **Network Failure** | Offline during upload → Shows error, allows retry | ⬜ |
| **Server Validation Error** | Server rejects contacts → Shows errors array | ⬜ |
| **Cancel Import** | User cancels on preview → Returns to home, temp file deleted | ⬜ |
| **File Cleanup** | After import completes → Temp file removed from cache | ⬜ |
| **Different MIME Types** | Share as text/plain, text/x-vcard, etc. → All work | ⬜ |

### Automated Testing

```dart
// test/features/contacts/services/vcf_sharing_service_test.dart
void main() {
  group('VcfSharingService', () {
    test('parseVcfFile returns correct contact count', () async {
      // Mock VCF file
      final result = await VcfSharingService.parseVcfFile('test.vcf');
      expect(result.success, true);
      expect(result.contacts, isNotEmpty);
    });

    test('parseVcfFile handles invalid VCF gracefully', () async {
      final result = await VcfSharingService.parseVcfFile('invalid.vcf');
      expect(result.success, false);
      expect(result.error, isNotNull);
    });
  });
}
```

---

## Phase 6: Implementation Timeline

| Phase | Tasks | Duration | Owner |
|-------|-------|----------|-------|
| **Phase 1** | Add dependencies to pubspec.yaml | 30 min | Developer |
| **Phase 2** | Update AndroidManifest.xml & MainActivity.kt | 1 hour | Developer |
| **Phase 3** | Create VcfSharingService | 1 hour | Developer |
| **Phase 3** | Create VcfShareProvider & Notifier | 1 hour | Developer |
| **Phase 3** | Create VcfSharePreviewScreen | 1.5 hours | Developer |
| **Phase 3** | Integrate with main.dart | 30 min | Developer |
| **Phase 5** | Manual testing across scenarios | 2 hours | QA/Developer |
| **Phase 5** | Fix bugs & edge cases | 1-2 hours | Developer |
| **Total** | | **~8-9 hours** | |

---

## Key Pitfalls to Avoid

### ❌ Don't
- ❌ Request `READ_EXTERNAL_STORAGE` permission → Use `ContentResolver` with URI instead (Android 10+ compliance)
- ❌ Assume file extensions → Always check MIME type `text/x-vcard` or parse exceptions
- ❌ Parse VCF on main thread with huge files → Use `compute()` or `Isolate` for large files (500+ contacts)
- ❌ Forget to clean up temp files → Delete from cache directory after upload completes
- ❌ Block UI during upload → Always show progress indicator or loading dialog
- ❌ Ignore `onNewIntent()` → App might be running when user shares again
- ❌ Use deprecated Intent getParcelable methods → Check `Build.VERSION.SDK_INT`

### ✅ Do
- ✅ Use `ContentResolver.openInputStream()` for URI reading
- ✅ Verify MIME type before processing
- ✅ Use `vcf_dart` for pure Dart parsing (no native dependencies)
- ✅ Show loading dialogs during parsing and upload
- ✅ Implement error recovery with retry buttons
- ✅ Test with actual VCF files from different sources
- ✅ Handle both `onCreate()` and `onNewIntent()` in MainActivity
- ✅ Use `launchMode="singleTask"` to prevent multiple instances

---

## File Structure Summary

```
lib/
├── core/
│   └── services/
│       └── vcf_sharing_service.dart          [NEW]
│
├── features/
│   └── contacts/
│       ├── presentation/
│       │   └── providers/
│       │       ├── contact_provider.dart      [EXISTING - reuse importVcfFile()]
│       │       └── vcf_share_provider.dart    [NEW]
│       │
│       └── screens/
│           ├── contact_list_screen.dart       [EXISTING]
│           └── vcf_share_preview_screen.dart  [NEW]
│
└── main.dart                                   [MODIFY - add share intent check]

android/
└── app/
    └── src/
        ├── main/
        │   ├── AndroidManifest.xml            [MODIFY - add intent-filters]
        │   └── kotlin/.../MainActivity.kt     [MODIFY - add handleIntent()]
        └── ...
```

---

## Success Criteria

✅ **Functional Requirements:**
- User can share VCF files from Android system contacts
- App launches or wakes up to show preview screen
- Preview shows contact count and validation errors
- User can cancel or proceed with import
- Upload uses existing `importVcfFile()` endpoint
- Result dialog reuses existing design

✅ **Quality Requirements:**
- No app crashes on invalid VCF files
- Temp files properly cleaned up
- Network errors handled gracefully
- Permission handling compliant with Android 10+
- Works with different MIME types

✅ **Performance Requirements:**
- VCF parsing completes within 5 seconds (for typical files)
- Upload progress shown for user feedback
- No UI freezing during operations

---

## Future Enhancements

1. **Multiple File Handling**: Support `ACTION_SEND_MULTIPLE` for multiple VCF files
2. **Background Upload**: Use `workmanager` for large files when network is slow
3. **Duplicate Detection**: Check if contacts already exist before upload
4. **Preview Customization**: Allow user to select/deselect individual contacts
5. **iOS Support**: Add similar intent handling for iOS (Share extension)
6. **Scheduled Import**: Queue imports and batch process them
7. **Import History**: Track what was imported and from where

---

## References & Documentation

- [receive_sharing_intent package](https://pub.dev/packages/receive_sharing_intent)
- [vcf_dart package](https://pub.dev/packages/vcf_dart)
- [Android Intent Documentation](https://developer.android.com/reference/android/content/Intent)
- [Android Scoped Storage](https://developer.android.com/about/versions/11/privacy/storage)
- [ContentResolver Documentation](https://developer.android.com/reference/android/content/ContentResolver)
- [Flutter MethodChannel Documentation](https://flutter.dev/docs/development/platform-integration/platform-channels)

