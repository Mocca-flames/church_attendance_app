import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/main.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:church_attendance_app/core/sync/sync_manager_provider.dart';
import 'package:church_attendance_app/features/auth/domain/models/user.dart';
import 'package:church_attendance_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:church_attendance_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:church_attendance_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:church_attendance_app/features/auth/data/repositories/auth_repository_impl.dart';

/// Auth state to track authentication status and user data.
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider for DioClient instance
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

/// Provider for AuthLocalDataSource
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final database = ref.watch(databaseProvider);
  return AuthLocalDataSource(database);
});

/// Provider for AuthRemoteDataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(dioClient);
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

/// Auth state notifier for managing authentication state.
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    return const AuthState();
  }

  /// Check if user is already authenticated on app start.
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final isAuthenticated = await _repository.isAuthenticated();
      
      if (isAuthenticated) {
        final user = await _repository.getCurrentUser();
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: user,
        );
      } else {
        state = const AuthState(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Login with email and password.
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final response = await _repository.login(email, password);
      
      // Get user from response or fetch current user
      User? user = response.user;
      user ??= await _repository.getCurrentUser();
      
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: user,
      );
      
      // After successful login, pull contacts to initialize local DB for offline search
      try {
        await ref.read(syncStatusProvider.notifier).pullContacts();
        // Start periodic background sync (24 hours)
        ref.read(periodicSyncProvider.notifier).startPeriodicSync();
      } catch (_) {
        // Ignore sync errors here; UI can show sync status elsewhere
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Register a new user.
  Future<bool> register({
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final response = await _repository.register(
        email: email,
        password: password,
        role: role,
      );
      
      // Get user from response or fetch current user
      User? user = response.user;
      user ??= await _repository.getCurrentUser();
      
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: user,
      );
      // Pull contacts after registration so the app has local data ready
      try {
        await ref.read(syncStatusProvider.notifier).pullContacts();
        // Start periodic background sync
        ref.read(periodicSyncProvider.notifier).startPeriodicSync();
      } catch (_) {}

      return true;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Logout the current user.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _repository.logout();
    } catch (e) {
      // Continue with logout even if server call fails
    }
    
    // Stop periodic sync on logout
    ref.read(periodicSyncProvider.notifier).stopPeriodicSync();
    
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  /// Clear any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for AuthNotifier
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Provider for getting current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Provider for auth loading state
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

/// Provider for auth error
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
