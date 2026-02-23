import 'package:church_attendance_app/features/auth/domain/models/user.dart';
import 'package:church_attendance_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:church_attendance_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:church_attendance_app/features/auth/data/datasources/auth_remote_datasource.dart';

/// Implementation of the AuthRepository.
/// Coordinates between local and remote data sources for authentication.
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<AuthResponse> login(String email, String password) async {
    // Try to login with remote server
    final response = await _remoteDataSource.login(email, password);
    
    // Save tokens locally
    await _localDataSource.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    
    // Save user data if provided
    if (response.user != null) {
      await _localDataSource.saveUserData(response.user!);
    }
    
    return response;
  }

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String role,
  }) async {
    // Register with remote server
    final response = await _remoteDataSource.register(
      email: email,
      password: password,
      role: role,
    );
    
    // Save tokens locally
    await _localDataSource.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    
    // Save user data if provided
    if (response.user != null) {
      await _localDataSource.saveUserData(response.user!);
    }
    
    return response;
  }

  @override
  Future<User?> getCurrentUser() async {
    // First check local storage
    final localUser = await _localDataSource.getCurrentUser();
    if (localUser != null) {
      return localUser;
    }
    
    // If no local user, try to fetch from server
    try {
      final hasToken = await _localDataSource.hasValidToken();
      if (!hasToken) {
        return null;
      }
      
      // Try to get user from server
      final remoteUser = await _remoteDataSource.getCurrentUser();
      await _localDataSource.saveUserData(remoteUser);
      return remoteUser;
    } catch (e) {
      // If server request fails, return null (user will need to login)
      return null;
    }
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await _remoteDataSource.refreshToken(refreshToken);
    
    await _localDataSource.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    
    return response;
  }

  @override
  Future<void> logout() async {
    // Clear all local tokens and user data
    await _localDataSource.clearTokens();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _localDataSource.hasValidToken();
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _localDataSource.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> clearTokens() async {
    await _localDataSource.clearTokens();
  }
}
