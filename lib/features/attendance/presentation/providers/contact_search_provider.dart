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
    ref.onDispose(() => _debounceTimer?.cancel());
    return const ContactSearchState();
  }

  void search(String query) {
    _debounceTimer?.cancel();
    state = state.copyWith(query: query, clearError: true);

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _database.searchContacts(query.trim());
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

  void clear() {
    _debounceTimer?.cancel();
    state = const ContactSearchState();
  }
}

/// Provider for contact search functionality.
final contactSearchProvider =
    NotifierProvider<ContactSearchNotifier, ContactSearchState>(() {
  return ContactSearchNotifier();
});

/// Notifier for managing marked contact IDs for the current service.
///
/// Provides reactive state management for tracking which contacts
/// have already been marked as present for the current service.
class MarkedContactIdsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void add(int contactId) {
    state = {...state, contactId};
  }

  void remove(int contactId) {
    state = state.difference({contactId});
  }

  void toggle(int contactId) {
    if (state.contains(contactId)) {
      remove(contactId);
    } else {
      add(contactId);
    }
  }

  void clear() {
    state = {};
  }

  void setAll(Set<int> ids) {
    state = ids;
  }
}

/// Shared reactive set of contact IDs already marked today for the current service.
///
/// This is the single source of truth for "already marked" state.
/// - [AttendanceScreen] writes to it after loading/refreshing from DB.
/// - [ContactResultCard] reads from it and rebuilds instantly when it changes.
/// - No manual setState or prop-drilling of isAlreadyMarked needed.
final markedContactIdsProvider =
    NotifierProvider<MarkedContactIdsNotifier, Set<int>>(() {
  return MarkedContactIdsNotifier();
});

/// Provider for getting a specific contact by ID.
final contactByIdProvider =
    FutureProvider.family<ContactEntity?, int>((ref, id) async {
  final database = ref.watch(databaseProvider);
  return await database.getContactById(id);
});

/// Parameters for checking attendance status.
class AttendanceCheckParams {
  final DateTime serviceDate;
  final dynamic serviceType;

  const AttendanceCheckParams({
    required this.serviceDate,
    required this.serviceType,
  });
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Provider for checking if a contact is already marked for a service today.
final attendanceStatusProvider =
    FutureProvider.family<Map<int, bool>, AttendanceCheckParams>(
        (ref, params) async {
  final database = ref.watch(databaseProvider);
  final attendances = await database.getAllAttendances();

  final Map<int, bool> statusMap = {};
  for (final attendance in attendances) {
    final isToday = _isSameDay(attendance.serviceDate, params.serviceDate);
    final isSameService =
        attendance.serviceType == params.serviceType.backendValue;
    if (isToday && isSameService) {
      statusMap[attendance.contactId] = true;
    }
  }
  return statusMap;
});