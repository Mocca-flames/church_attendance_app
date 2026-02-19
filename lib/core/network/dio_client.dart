import 'package:dio/dio.dart';
import 'package:church_attendance_app/core/network/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Dio HTTP Client for the Church Attendance API.
/// Provides convenient methods for all API endpoints defined in ENDPOINTS.md.
class DioClient {
  late Dio _dio;
  final Logger _logger = Logger();

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to all requests
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          print('DEBUG DIO: access_token from prefs: ${token != null ? "[PRESENT]" : "[NULL]"}');
          if (token != null) {
            print('DEBUG DIO: Token value: ${token.substring(0, 20)}...');
            options.headers['Authorization'] = 'Bearer $token';
            print('DEBUG DIO: Added Bearer token to request: ${options.method} ${options.path}');
            print('DEBUG DIO: Request headers: ${options.headers}');
          } else {
            print('DEBUG DIO: NO TOKEN - Request will be unauthenticated: ${options.method} ${options.path}');
          }

          // Detailed request logging for debugging
          _logger.d('═══════════════════════════════════════════════════════════');
          _logger.d('🌐 REQUEST START');
          _logger.d('═══════════════════════════════════════════════════════════');
          _logger.d('METHOD: ${options.method}');
          _logger.d('PATH: ${options.path}');
          _logger.d('FULL URL: ${options.uri}');
          _logger.d('HEADERS: ${options.headers}');
          if (options.queryParameters.isNotEmpty) {
            _logger.d('QUERY PARAMS: ${options.queryParameters}');
          }
          if (options.data != null) {
            _logger.d('REQUEST BODY: ${options.data}');
          }
          _logger.d('═══════════════════════════════════════════════════════════');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Detailed response logging for debugging
          _logger.d('═══════════════════════════════════════════════════════════');
          _logger.d('✅ RESPONSE RECEIVED');
          _logger.d('═══════════════════════════════════════════════════════════');
          _logger.d('STATUS: ${response.statusCode} ${response.statusMessage}');
          _logger.d('PATH: ${response.requestOptions.path}');
          _logger.d('HEADERS: ${response.headers}');
          if (response.data != null) {
            _logger.d('RESPONSE BODY: ${response.data}');
          }
          _logger.d('═══════════════════════════════════════════════════════════');
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Detailed error logging for debugging
          _logger.e('═══════════════════════════════════════════════════════════');
          _logger.e('❌ ERROR OCCURRED');
          _logger.e('═══════════════════════════════════════════════════════════');
          _logger.e('ERROR TYPE: ${error.type}');
          _logger.e('ERROR MESSAGE: ${error.message}');
          _logger.e('PATH: ${error.requestOptions.path}');
          _logger.e('FULL URL: ${error.requestOptions.uri}');
          if (error.response != null) {
            _logger.e('STATUS: ${error.response?.statusCode} ${error.response?.statusMessage}');
            _logger.e('RESPONSE DATA: ${error.response?.data}');
            _logger.e('RESPONSE HEADERS: ${error.response?.headers}');
          }
          _logger.e('═══════════════════════════════════════════════════════════');

          // Handle 401 Unauthorized - Token expired
          if (error.response?.statusCode == 401) {
            
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
          }

          return handler.next(error);
        },
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => _logger.d(obj),
    ));
  }

  Dio get dio => _dio;

  // ============================================================
  // Generic HTTP Methods
  // ============================================================

  /// Generic GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generic DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // Authentication Endpoints
  // ============================================================

  /// POST /auth/login
  /// Authenticates a user and returns an access token.
  /// Uses form-urlencoded content type as per backend API spec.
  Future<Response> login({
    required String username,
    required String password,
  }) async {
    return post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
  }

  /// POST /auth/register
  /// Registers a new user.
  Future<Response> register({
    required String email,
    required String password,
    required String role,
    bool isActive = true,
  }) async {
    return post(
      ApiConstants.register,
      data: {
        'email': email,
        'password': password,
        'role': role,
        'is_active': isActive,
      },
    );
  }

  /// POST /auth/refresh
  /// Refreshes an access token using a refresh token.
  Future<Response> refreshToken({
    required String refreshToken,
  }) async {
    return post(
      ApiConstants.refresh,
      data: {'refresh_token': refreshToken},
    );
  }

  /// GET /auth/me
  /// Returns the currently authenticated user's information.
  Future<Response> getCurrentUser() async {
    return get(ApiConstants.me);
  }

  // ============================================================
  // Attendance Endpoints
  // ============================================================

  /// POST /attendance/record
  /// Records attendance for a contact.
  Future<Response> recordAttendance({
    required int contactId,
    required String phone,
    required String serviceType,
    required String serviceDate,
    required int recordedBy,
  }) async {
    return post(
      ApiConstants.attendanceRecord,
      data: {
        'contact_id': contactId,
        'phone': phone,
        'service_type': serviceType,
        'service_date': serviceDate,
        'recorded_by': recordedBy,
      },
    );
  }

  /// GET /attendance/records
  /// Retrieves attendance records with optional filters.
  Future<Response> getAttendanceRecords({
    String? dateFrom,
    String? dateTo,
    String? serviceType,
    int? contactId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (dateFrom != null) queryParams['date_from'] = dateFrom;
    if (dateTo != null) queryParams['date_to'] = dateTo;
    if (serviceType != null) queryParams['service_type'] = serviceType;
    if (contactId != null) queryParams['contact_id'] = contactId;

    return get(
      ApiConstants.attendances,
      queryParameters: queryParams,
    );
  }

  /// GET /attendance/summary
  /// Gets attendance summary statistics.
  Future<Response> getAttendanceSummary({
    String? dateFrom,
    String? dateTo,
  }) async {
    final queryParams = <String, dynamic>{};
    if (dateFrom != null) queryParams['date_from'] = dateFrom;
    if (dateTo != null) queryParams['date_to'] = dateTo;

    return get(
      ApiConstants.attendanceSummary,
      queryParameters: queryParams,
    );
  }

  /// GET /attendance/contacts/{contact_id}
  /// Gets all attendance records for a specific contact.
  Future<Response> getContactAttendance(int contactId) async {
    final path = ApiConstants.attendanceByContactId.replaceAll('{id}', contactId.toString());
    return get(path);
  }

  /// DELETE /attendance/{attendance_id}
  /// Deletes an attendance record.
  Future<Response> deleteAttendance(int attendanceId) async {
    final path = ApiConstants.attendanceById.replaceAll('{id}', attendanceId.toString());
    return delete(path);
  }

  // ============================================================
  // Scenario Endpoints
  // ============================================================

  /// POST /scenarios/
  /// Creates a new scenario and automatically generates tasks.
  Future<Response> createScenario({
    required String name,
    required String description,
    required List<String> filterTags,
    required int createdBy,
  }) async {
    return post(
      ApiConstants.scenarios,
      data: {
        'name': name,
        'description': description,
        'filter_tags': filterTags,
        'created_by': createdBy,
      },
    );
  }

  /// GET /scenarios/
  /// Retrieves all scenarios with optional status filter.
  Future<Response> getScenarios({String? status}) async {
    return get(
      ApiConstants.scenarios,
      queryParameters: status != null ? {'status': status} : null,
    );
  }

  /// GET /scenarios/{scenario_id}
  /// Gets a single scenario by ID.
  Future<Response> getScenario(int scenarioId) async {
    final path = ApiConstants.scenarioById.replaceAll('{id}', scenarioId.toString());
    return get(path);
  }

  /// GET /scenarios/{scenario_id}/tasks
  /// Gets all tasks for a scenario.
  Future<Response> getScenarioTasks(int scenarioId) async {
    final path = ApiConstants.scenarioTasks.replaceAll('{id}', scenarioId.toString());
    return get(path);
  }

  /// GET /scenarios/{scenario_id}/statistics
  /// Gets statistics for a scenario.
  Future<Response> getScenarioStatistics(int scenarioId) async {
    final path = ApiConstants.scenarioStatistics.replaceAll('{id}', scenarioId.toString());
    return get(path);
  }

  /// PUT /scenarios/{scenario_id}/tasks/{task_id}/complete
  /// Marks a task as completed.
  Future<Response> completeTask(int scenarioId, int taskId) async {
    final path = ApiConstants.scenarioTaskComplete
        .replaceAll('{id}', scenarioId.toString())
        .replaceAll('{taskId}', taskId.toString());
    return put(path);
  }

  /// PUT /scenarios/{scenario_id}
  /// Updates a scenario (e.g., to mark as completed).
  Future<Response> updateScenario(int scenarioId, Map<String, dynamic> data) async {
    final path = ApiConstants.scenarioById.replaceAll('{id}', scenarioId.toString());
    return put(path, data: data);
  }

  // ============================================================
  // Contact Endpoints
  // ============================================================

  /// GET /contacts/
  /// Retrieves all contacts.
  Future<Response> getContacts({Map<String, dynamic>? queryParams}) async {
    return get(
      ApiConstants.contacts,
      queryParameters: queryParams,
    );
  }

  /// POST /contacts/
  /// Creates a new contact.
  Future<Response> createContact({
    required String phone,
    required String name,
    List<String>? tags,
  }) async {
    return post(
      ApiConstants.contacts,
      data: {
        'phone': phone,
        'name': name,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      },
    );
  }

  /// GET /contacts/{id}
  /// Gets a contact by ID.
  Future<Response> getContact(int contactId) async {
    final path = ApiConstants.contactById.replaceAll('{id}', contactId.toString());
    return get(path);
  }

  /// PUT /contacts/{id}
  /// Updates a contact.
  Future<Response> updateContact(int contactId, Map<String, dynamic> data) async {
    final path = ApiConstants.contactById.replaceAll('{id}', contactId.toString());
    return put(path, data: data);
  }

  // ============================================================
  // Error Handling
  // ============================================================

  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timeout. Please check your internet.',
          statusCode: null,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final detail = error.response?.data?['detail'] ?? 'Server error occurred';
        return ApiException(
          detail.toString(),
          statusCode: statusCode,
          data: error.response?.data,
        );
      case DioExceptionType.cancel:
        return ApiException(
          'Request was cancelled',
          statusCode: null,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'Network error. Please check your connection.',
          statusCode: null,
        );
      default:
        return ApiException(
          'Network error. Please check your connection.',
          statusCode: null,
        );
    }
  }
}
