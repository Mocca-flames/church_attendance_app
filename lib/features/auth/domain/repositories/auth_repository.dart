import '../models/user.dart';

/// Abstract repository interface for authentication operations.
/// Follows Clean Architecture - defines contracts for data operations.
abstract class AuthRepository {
  /// Authenticate user with email and password.
  /// Returns AuthResponse containing access token and user info.
  Future<AuthResponse> login(String email, String password);

  /// Register a new user with email and password.
  /// Returns AuthResponse containing access token and user info.
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String role,
  });

  /// Get the currently authenticated user.
  /// Returns null if not authenticated.
  Future<User?> getCurrentUser();

  /// Refresh the access token using refresh token.
  Future<AuthResponse> refreshToken(String refreshToken);

  /// Logout the current user and clear tokens.
  Future<void> logout();

  /// Check if user is authenticated (has valid token).
  Future<bool> isAuthenticated();

  /// Save authentication tokens to secure storage.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  });

  /// Clear all stored authentication tokens.
  Future<void> clearTokens();
}
