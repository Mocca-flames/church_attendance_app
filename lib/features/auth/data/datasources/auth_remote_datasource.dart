import 'package:dio/dio.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:church_attendance_app/core/network/api_constants.dart';
import 'package:church_attendance_app/core/enums/user_role.dart';
import 'package:church_attendance_app/features/auth/domain/models/user.dart';

/// Remote data source for authentication API calls.
class AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSource(this._client);

  /// Login with email and password.
  /// Uses form-urlencoded content type as per backend API spec.
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _client.post(
        ApiConstants.login,
        data: {
          'username': email, // Backend expects 'username' field
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Register a new user.
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'role': role,
          'is_active': true,
        },
      );

      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current user info from backend.
  Future<User> getCurrentUser() async {
    try {
      final response = await _client.get(ApiConstants.me);
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Refresh access token using refresh token.
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post(
        ApiConstants.refresh,
        data: {
          'refresh_token': refreshToken,
        },
      );

      return _parseAuthResponse(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Parse authentication response from backend.
  AuthResponse _parseAuthResponse(Map<String, dynamic> data) {
    // Handle both response formats:
    // 1. Login response: { access_token, token_type, refresh_token }
    // 2. Register response: { ..., access_token, token_type }
    
    return AuthResponse(
      accessToken: data['access_token'] as String,
      tokenType: data['token_type'] as String? ?? 'bearer',
      refreshToken: data['refresh_token'] as String?,
      user: data['id'] != null 
          ? User(
              id: data['id'] as int,
              email: data['email'] as String,
              role: UserRole.fromBackend(data['role'] as String? ?? 'servant'),
              isActive: data['is_active'] as bool? ?? true,
              createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
            )
          : null,
    );
  }

  /// Handle Dio errors.
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final detail = error.response?.data?['detail'] ?? 'Authentication failed';
        
        if (statusCode == 401) {
          return Exception('Invalid email or password');
        } else if (statusCode == 400) {
          return Exception(detail.toString());
        } else if (statusCode == 409) {
          return Exception('User already exists');
        }
        return Exception(detail.toString());
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      default:
        return Exception('Network error. Please check your connection.');
    }
  }
}
