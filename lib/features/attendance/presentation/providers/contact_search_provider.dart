
import 'dart:async';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for contact search functionality.
class ContactSearchState {
  final String query;
  final List<ContactEntity> results;
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
    List<ContactEntity>? results,
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

/// Notifier for managing contact search state.
/// 
/// Features:
/// - Debounced search (300ms delay)
/// - Local database queries only (no API calls)
/// - Searches both name and phone fields
class ContactSearchNotifier extends Notifier<ContactSearchState> {
  late final AppDatabase _database;
  Timer? _debounceTimer;

  @override
  ContactSearchState build() {
    _database = ref.watch(databaseProvider);
    
    // Register cleanup on dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    
    return const ContactSearchState();
  }

  /// Search contacts with debouncing.
  /// Queries local database only - no API calls for instant results.
  void search(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update query immediately for UI feedback
    state = state.copyWith(query: query, clearError: true);

    // If query is empty, clear results
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    // Show loading state
    state = state.copyWith(isLoading: true);

    // Debounce search (300ms delay)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        // Query local database - NO API CALLS!
        final results = await _database.searchContacts(query.trim());
        
        // Only update if query hasn't changed during search
        if (state.query == query) {
          state = state.copyWith(
            results: results,
            isLoading: false,
          );
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

  /// Clear search results.
  void clear() {
    _debounceTimer?.cancel();
    state = const ContactSearchState();
  }
}

/// Provider for contact search functionality.
/// 
/// Usage:
/// ```dart
/// final searchState = ref.watch(contactSearchProvider);
/// ref.read(contactSearchProvider.notifier).search('john');
/// ```
final contactSearchProvider =
    NotifierProvider<ContactSearchNotifier, ContactSearchState>(() {
  return ContactSearchNotifier();
});

/// Provider for getting a specific contact by ID.
final contactByIdProvider = FutureProvider.family<ContactEntity?, int>((ref, id) async {
  final database = ref.watch(databaseProvider);
  return await database.getContactById(id);
});

/// Provider for checking if a contact is already marked for a service today.
/// 
/// Returns a map of contact IDs to their attendance status for the given service and date.
final attendanceStatusProvider = FutureProvider.family<Map<int, bool>, AttendanceCheckParams>((ref, params) async {
  final database = ref.watch(databaseProvider);
  final attendances = await database.getAllAttendances();
  
  final Map<int, bool> statusMap = {};
  
  for (final attendance in attendances) {
    // Check if attendance is for today and the specified service
    final isToday = _isSameDay(attendance.serviceDate, params.serviceDate);
    final isSameService = attendance.serviceType == params.serviceType.backendValue;
    
    if (isToday && isSameService) {
      statusMap[attendance.contactId] = true;
    }
  }
  
  return statusMap;
});

/// Parameters for checking attendance status.
class AttendanceCheckParams {
  final DateTime serviceDate;
  final dynamic serviceType; // ServiceType - using dynamic to avoid import

  const AttendanceCheckParams({
    required this.serviceDate,
    required this.serviceType,
  });
}

/// Helper function to check if two dates are the same day.
bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
