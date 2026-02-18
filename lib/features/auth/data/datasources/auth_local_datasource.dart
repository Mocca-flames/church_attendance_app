import 'package:shared_preferences/shared_preferences.dart';
import 'package:church_attendance_app/core/database/database.dart';
import 'package:church_attendance_app/core/enums/user_role.dart';
import 'package:church_attendance_app/features/auth/domain/models/user.dart';
import 'package:drift/drift.dart';

/// Local data source for authentication.
/// Handles token storage and user data persistence locally.
class AuthLocalDataSource {
  final AppDatabase _db;
  
  // SharedPreferences keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';

  AuthLocalDataSource(this._db);

  /// Save authentication tokens to local storage.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  /// Get the stored access token.
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Get the stored refresh token.
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Clear all stored authentication tokens.
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
  }

  /// Check if user has valid tokens.
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Save user data locally after successful login.
  Future<void> saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, user.id);
    await prefs.setString(_userEmailKey, user.email);
    await prefs.setString(_userRoleKey, user.role.backendValue);
    
    // Also save to local database
    await _db.clearUsers();
    await _db.insertUser(
      UsersCompanion(
        id: Value(user.id),
        email: Value(user.email),
        passwordHash: const Value(''), // Don't store password locally
        role: Value(user.role.backendValue),
        isActive: Value(user.isActive),
        createdAt: Value(user.createdAt),
      ),
    );
  }

  /// Get the current user from local storage.
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    final userEmail = prefs.getString(_userEmailKey);
    final userRoleStr = prefs.getString(_userRoleKey);
    
    if (userId == null || userEmail == null || userRoleStr == null) {
      return null;
    }

    // Try to get from database first
    final userEntity = await _db.getCurrentUser();
    if (userEntity != null) {
      return User(
        id: userEntity.id,
        email: userEntity.email,
        role: UserRole.fromBackend(userEntity.role),
        isActive: userEntity.isActive,
        createdAt: userEntity.createdAt,
      );
    }

    // Fallback to SharedPreferences data
    return User(
      id: userId,
      email: userEmail,
      role: UserRole.fromBackend(userRoleStr),
      isActive: true,
      createdAt: DateTime.now(),
    );
  }
}
