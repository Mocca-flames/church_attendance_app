import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/features/contacts/data/datasources/contact_local_datasource.dart';
import 'package:church_attendance_app/features/contacts/data/datasources/contact_remote_datasource.dart';
import 'package:church_attendance_app/features/contacts/data/repositories/contact_repository_impl.dart';
import 'package:church_attendance_app/features/contacts/domain/models/contact.dart';
import 'package:church_attendance_app/features/contacts/domain/repositories/contact_repository.dart';
import 'package:church_attendance_app/main.dart';

/// Provider for ContactLocalDataSource
final contactLocalDataSourceProvider = Provider<ContactLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return ContactLocalDataSource(database);
});

/// Provider for ContactRemoteDataSource
final contactRemoteDataSourceProvider = Provider<ContactRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ContactRemoteDataSource(dioClient);
});

/// Provider for ContactRepository
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  final localDataSource = ref.watch(contactLocalDataSourceProvider);
  final remoteDataSource = ref.watch(contactRemoteDataSourceProvider);
  final dioClient = ref.watch(dioClientProvider);
  return ContactRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
    dioClient: dioClient,
  );
});

/// Contact state for managing CRUD operations
class ContactState {
  final bool isLoading;
  final Contact? selectedContact;
  final String? error;
  final bool isDeleting;
  final bool isSaving;
  final bool isSyncing;
  final String? syncError;
  final bool isImportingVcf;
  final Map<String, dynamic>? vcfImportResult;
  final List<Contact> recentContacts;

  const ContactState({
    this.isLoading = false,
    this.selectedContact,
    this.error,
    this.isDeleting = false,
    this.isSaving = false,
    this.isSyncing = false,
    this.syncError,
    this.isImportingVcf = false,
    this.vcfImportResult,
    this.recentContacts = const [],
  });

  ContactState copyWith({
    bool? isLoading,
    Contact? selectedContact,
    String? error,
    bool? isDeleting,
    bool? isSaving,
    bool? isSyncing,
    String? syncError,
    bool? isImportingVcf,
    Map<String, dynamic>? vcfImportResult,
    List<Contact>? recentContacts,
    bool clearError = false,
    bool clearSelectedContact = false,
    bool clearVcfImportResult = false,
    bool clearSyncError = false,
  }) {
    return ContactState(
      isLoading: isLoading ?? this.isLoading,
      selectedContact: clearSelectedContact ? null : (selectedContact ?? this.selectedContact),
      error: clearError ? null : (error ?? this.error),
      isDeleting: isDeleting ?? this.isDeleting,
      isSaving: isSaving ?? this.isSaving,
      isSyncing: isSyncing ?? this.isSyncing,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
      isImportingVcf: isImportingVcf ?? this.isImportingVcf,
      vcfImportResult: clearVcfImportResult ? null : (vcfImportResult ?? this.vcfImportResult),
      recentContacts: recentContacts ?? this.recentContacts,
    );
  }
}

/// Contact state notifier for managing contact operations
class ContactNotifier extends Notifier<ContactState> {
  late final ContactRepository _repository;

  @override
  ContactState build() {
    _repository = ref.watch(contactRepositoryProvider);
    return const ContactState();
  }

  /// Load a contact by ID
  Future<Contact?> loadContact(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final contact = await _repository.getContactById(id);
      state = state.copyWith(
        isLoading: false,
        selectedContact: contact,
      );
      return contact;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Create a new contact with Optimistic UI
  /// Returns the optimistic contact immediately while syncing in background
  Future<Contact?> createContact({
    required String phone,
    String? name,
    bool isMember = false,
    String? location,
  }) async {
    // Build tags list
    final List<String> tags = [];
    if (isMember) {
      tags.add('member');
    }
    if (location != null && location.isNotEmpty) {
      tags.add(location.toLowerCase());
    }

    // Create optimistic contact with a temporary ID (use timestamp for uniqueness)
    final now = DateTime.now();
    final optimisticContact = Contact(
      id: now.millisecondsSinceEpoch, // Temporary ID for optimistic UI
      createdAt: now,
      phone: phone,
      name: name,
      metadata: tags.isNotEmpty ? '{"tags":${tags.map((t) => '"$t"').toList()}}' : null,
      isSynced: false, // Mark as not synced for background sync
    );

    // Immediately update UI with optimistic data (no loading state)
    state = state.copyWith(
      isSaving: false,
      isSyncing: true,
      selectedContact: optimisticContact,
      recentContacts: [optimisticContact, ...state.recentContacts],
      clearError: true,
    );

    // Run actual repository call in background
    _repository.createContact(optimisticContact).then((created) {
      // On success: replace optimistic contact with actual data from DB
      final updatedContacts = state.recentContacts.map((c) {
        if (c.id == optimisticContact.id) {
          return created;
        }
        return c;
      }).toList();

      state = state.copyWith(
        isSyncing: false,
        selectedContact: created,
        recentContacts: updatedContacts,
      );
    }).catchError((error) {
      // On error: show subtle sync error but keep optimistic data in UI
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Sync pending: $error',
      );
    });

    // Return optimistic contact immediately
    return optimisticContact;
  }

  /// Update an existing contact with Optimistic UI
  /// Immediately updates UI with modified contact data while syncing in background
  Future<Contact?> updateContact(Contact contact) async {
    // Store the previous contact for rollback on error
    final previousContact = state.selectedContact;
    final previousContacts = state.recentContacts;

    // Immediately update UI with the modified contact data
    final updatedContact = contact.copyWith(isSynced: false);
    state = state.copyWith(
      isSaving: false,
      isSyncing: true,
      selectedContact: updatedContact,
      recentContacts: state.recentContacts.map((c) {
        if (c.id == contact.id) {
          return updatedContact;
        }
        return c;
      }).toList(),
      clearError: true,
    );

    // Run repository call in background
    _repository.updateContact(contact).then((updated) {
      // On success: update with actual data from DB
      final updatedContacts = state.recentContacts.map((c) {
        if (c.id == contact.id) {
          return updated;
        }
        return c;
      }).toList();

      state = state.copyWith(
        isSyncing: false,
        selectedContact: updated,
        recentContacts: updatedContacts,
      );
    }).catchError((error) {
      // On error: show subtle sync error but keep optimistic data in UI
      // Optionally: rollback to previous contact
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Sync pending: $error',
        selectedContact: previousContact,
        recentContacts: previousContacts,
      );
    });

    // Return optimistic contact immediately
    return updatedContact;
  }

  /// Delete a contact (soft delete) with Optimistic UI
  /// Immediately removes contact from UI while syncing in background
  Future<bool> deleteContact(int id) async {
    // Store the deleted contact for potential restore on error
    final deletedContact = state.recentContacts.where((c) => c.id == id).firstOrNull;
    final previousContacts = state.recentContacts;

    // Immediately remove contact from UI list
    state = state.copyWith(
      isDeleting: false,
      isSyncing: true,
      recentContacts: state.recentContacts.where((c) => c.id != id).toList(),
      clearSelectedContact: state.selectedContact?.id == id,
      clearError: true,
    );

    // Run repository call in background
    final completer = Completer<bool>();
    
    _repository.deleteContact(id).then((_) {
      // On success: complete without restoring
      state = state.copyWith(
        isSyncing: false,
      );
      completer.complete(true);
    }).catchError((error) {
      // On error: show subtle sync error and restore the contact
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Sync pending: $error',
        recentContacts: deletedContact != null 
            ? [...previousContacts] 
            : state.recentContacts,
        selectedContact: deletedContact,
      );
      completer.complete(false);
    });

    return true; // Return optimistic success immediately
  }

  /// Add tags to a contact with Optimistic UI
  /// Immediately updates UI with tag changes while syncing in background
  Future<Contact?> addTags(int contactId, List<String> tags) async {
    // Store the previous contact for potential rollback on error
    final previousContact = state.selectedContact;

    // Get current contact from recent contacts or selected contact
    final currentContact = state.recentContacts.where((c) => c.id == contactId).firstOrNull 
        ?? state.selectedContact;
    
    if (currentContact == null) return null;

    // Immediately update UI with optimistic tag changes
    final existingTags = currentContact.tags;
    final newTags = {...existingTags, ...tags}.toList();
    final newMetadata = newTags.isNotEmpty 
        ? '{"tags":${newTags.map((t) => '"$t"').toList()}}' 
        : null;
    
    final optimisticContact = currentContact.copyWith(
      metadata: newMetadata,
      isSynced: false,
    );

    state = state.copyWith(
      isSaving: false,
      isSyncing: true,
      selectedContact: optimisticContact,
      recentContacts: state.recentContacts.map((c) {
        if (c.id == contactId) {
          return optimisticContact;
        }
        return c;
      }).toList(),
      clearError: true,
    );

    // Run repository call in background
    _repository.addTagsToContact(contactId, tags).then((updated) {
      // On success: update with actual data from DB
      final updatedContacts = state.recentContacts.map((c) {
        if (c.id == contactId) {
          return updated;
        }
        return c;
      }).toList();

      state = state.copyWith(
        isSyncing: false,
        selectedContact: updated,
        recentContacts: updatedContacts,
      );
    }).catchError((error) {
      // On error: show subtle sync error but keep optimistic data in UI
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Sync pending: $error',
        selectedContact: previousContact,
      );
    });

    return optimisticContact;
  }

  /// Remove tags from a contact with Optimistic UI
  /// Immediately updates UI with tag changes while syncing in background
  Future<Contact?> removeTags(int contactId, List<String> tags) async {
    // Store the previous contact for potential rollback on error
    final previousContact = state.selectedContact;

    // Get current contact from recent contacts or selected contact
    final currentContact = state.recentContacts.where((c) => c.id == contactId).firstOrNull 
        ?? state.selectedContact;
    
    if (currentContact == null) return null;

    // Immediately update UI with optimistic tag changes
    final existingTags = currentContact.tags;
    final newTags = existingTags.where((t) => !tags.contains(t)).toList();
    final newMetadata = newTags.isNotEmpty 
        ? '{"tags":${newTags.map((t) => '"$t"').toList()}}' 
        : null;
    
    final optimisticContact = currentContact.copyWith(
      metadata: newMetadata,
      isSynced: false,
    );

    state = state.copyWith(
      isSaving: false,
      isSyncing: true,
      selectedContact: optimisticContact,
      recentContacts: state.recentContacts.map((c) {
        if (c.id == contactId) {
          return optimisticContact;
        }
        return c;
      }).toList(),
      clearError: true,
    );

    // Run repository call in background
    _repository.removeTagsFromContact(contactId, tags).then((updated) {
      // On success: update with actual data from DB
      final updatedContacts = state.recentContacts.map((c) {
        if (c.id == contactId) {
          return updated;
        }
        return c;
      }).toList();

      state = state.copyWith(
        isSyncing: false,
        selectedContact: updated,
        recentContacts: updatedContacts,
      );
    }).catchError((error) {
      // On error: show subtle sync error but keep optimistic data in UI
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Sync pending: $error',
        selectedContact: previousContact,
      );
    });

    return optimisticContact;
  }

  /// Import contacts from a VCF file
  Future<Map<String, dynamic>?> importVcfFile(String filePath) async {
    state = state.copyWith(isImportingVcf: true, clearError: true, clearVcfImportResult: true);
    
    try {
      final result = await _repository.importVcfFile(filePath);
      
      state = state.copyWith(
        isImportingVcf: false,
        vcfImportResult: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isImportingVcf: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear sync error
  void clearSyncError() {
    state = state.copyWith(clearSyncError: true);
  }

  /// Clear selected contact
  void clearSelectedContact() {
    state = state.copyWith(clearSelectedContact: true);
  }
}

/// Provider for ContactNotifier
final contactNotifierProvider = NotifierProvider<ContactNotifier, ContactState>(() {
  return ContactNotifier();
});

/// Contact list provider
final contactListProvider = FutureProvider<List<Contact>>((ref) async {
  final repository = ref.watch(contactRepositoryProvider);
  return repository.getAllContacts();
});

/// Contact by ID provider
final contactByIdProvider = FutureProvider.family<Contact?, int>((ref, id) async {
  final repository = ref.watch(contactRepositoryProvider);
  return repository.getContactById(id);
});

/// Contact search state
class ContactSearchState {
  final String query;
  final List<Contact> results;
  final bool isLoading;
  final String? error;

  const ContactSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  ContactSearchState copyWith({
    String? query,
    List<Contact>? results,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ContactSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Contact search notifier
class ContactSearchNotifier extends Notifier<ContactSearchState> {
  Timer? _debounceTimer;
  
  @override
  ContactSearchState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const ContactSearchState();
  }

  /// Search contacts with debounce
  Future<void> search(String query) async {
    _debounceTimer?.cancel();
    state = state.copyWith(query: query, clearError: true);

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final repository = ref.read(contactRepositoryProvider);
        final results = await repository.searchContacts(query.trim());
        if (state.query == query) {
          state = state.copyWith(results: results, isLoading: false);
        }
      } catch (e) {
        if (state.query == query) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to search contacts: $e',
          );
        }
      }
    });
  }

  /// Clear search
  void clear() {
    _debounceTimer?.cancel();
    state = const ContactSearchState();
  }
}

/// Contact search provider
final contactSearchProvider = NotifierProvider<ContactSearchNotifier, ContactSearchState>(() {
  return ContactSearchNotifier();
});

/// Contact tag filter state
class ContactTagFilterState {
  final String? selectedTag;
  
  const ContactTagFilterState({this.selectedTag});
  
  ContactTagFilterState copyWith({String? selectedTag, bool clear = false}) {
    return ContactTagFilterState(
      selectedTag: clear ? null : (selectedTag ?? this.selectedTag),
    );
  }
}

/// Contact tag filter notifier
class ContactTagFilterNotifier extends Notifier<ContactTagFilterState> {
  @override
  ContactTagFilterState build() => const ContactTagFilterState();
  
  void setTag(String? tag) {
    if (tag == null) {
      state = state.copyWith(clear: true);
    } else {
      state = state.copyWith(selectedTag: tag);
    }
  }
  
  void clear() {
    state = state.copyWith(clear: true);
  }
}

/// Contact tag filter provider
final contactTagFilterProvider = NotifierProvider<ContactTagFilterNotifier, ContactTagFilterState>(() {
  return ContactTagFilterNotifier();
});

/// Filtered contacts by tag
final contactsByTagProvider = FutureProvider.family<List<Contact>, String>((ref, tag) async {
  final repository = ref.watch(contactRepositoryProvider);
  return repository.getContactsByTag(tag);
});

/// Filtered contacts WITHOUT a specific tag (e.g., non-members/visitors)
final contactsWithoutTagProvider = FutureProvider.family<List<Contact>, String>((ref, tag) async {
  final repository = ref.watch(contactRepositoryProvider);
  return repository.getContactsWithoutTag(tag);
});
