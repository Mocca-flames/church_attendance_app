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
  final bool isImportingVcf;
  final Map<String, dynamic>? vcfImportResult;

  const ContactState({
    this.isLoading = false,
    this.selectedContact,
    this.error,
    this.isDeleting = false,
    this.isSaving = false,
    this.isImportingVcf = false,
    this.vcfImportResult,
  });

  ContactState copyWith({
    bool? isLoading,
    Contact? selectedContact,
    String? error,
    bool? isDeleting,
    bool? isSaving,
    bool? isImportingVcf,
    Map<String, dynamic>? vcfImportResult,
    bool clearError = false,
    bool clearSelectedContact = false,
    bool clearVcfImportResult = false,
  }) {
    return ContactState(
      isLoading: isLoading ?? this.isLoading,
      selectedContact: clearSelectedContact ? null : (selectedContact ?? this.selectedContact),
      error: clearError ? null : (error ?? this.error),
      isDeleting: isDeleting ?? this.isDeleting,
      isSaving: isSaving ?? this.isSaving,
      isImportingVcf: isImportingVcf ?? this.isImportingVcf,
      vcfImportResult: clearVcfImportResult ? null : (vcfImportResult ?? this.vcfImportResult),
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

  /// Create a new contact
  Future<Contact?> createContact({
    required String phone,
    String? name,
    bool isMember = false,
    String? location,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      // Build tags list
      final List<String> tags = [];
      if (isMember) {
        tags.add('member');
      }
      if (location != null && location.isNotEmpty) {
        tags.add(location.toLowerCase());
      }

      final contact = Contact(
        id: 0,
        createdAt: DateTime.now(),
        phone: phone,
        name: name,
        metadata: tags.isNotEmpty ? '{"tags":${tags.map((t) => '"$t"').toList()}}' : null,
      );

      final created = await _repository.createContact(contact);
      
      state = state.copyWith(
        isSaving: false,
        selectedContact: created,
      );
      return created;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Update an existing contact
  Future<Contact?> updateContact(Contact contact) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final updated = await _repository.updateContact(contact);
      
      state = state.copyWith(
        isSaving: false,
        selectedContact: updated,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Delete a contact (soft delete)
  Future<bool> deleteContact(int id) async {
    state = state.copyWith(isDeleting: true, clearError: true);
    
    try {
      await _repository.deleteContact(id);
      
      state = state.copyWith(
        isDeleting: false,
        clearSelectedContact: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Add tags to a contact
  Future<Contact?> addTags(int contactId, List<String> tags) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final updated = await _repository.addTagsToContact(contactId, tags);
      
      state = state.copyWith(
        isSaving: false,
        selectedContact: updated,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Remove tags from a contact
  Future<Contact?> removeTags(int contactId, List<String> tags) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final updated = await _repository.removeTagsFromContact(contactId, tags);
      
      state = state.copyWith(
        isSaving: false,
        selectedContact: updated,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return null;
    }
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
