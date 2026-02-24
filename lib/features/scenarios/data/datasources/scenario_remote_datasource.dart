import 'package:church_attendance_app/core/network/api_constants.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

/// Remote data source for scenario operations.
/// Handles all API calls to the backend server.
class ScenarioRemoteDataSource {
  final DioClient _dioClient;

  ScenarioRemoteDataSource(this._dioClient);

  /// Get all scenarios from server
  Future<List<Map<String, dynamic>>> getScenarios() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.scenarios);
      final data = response.data;
      
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get single scenario by ID
  Future<Map<String, dynamic>?> getScenarioById(int id) async {
    try {
      final endpoint = ApiConstants.scenarioById.replaceAll('{id}', id.toString());
      final response = await _dioClient.dio.get(endpoint);
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleDioError(e);
    }
  }

  /// Create scenario on server
  Future<Map<String, dynamic>> createScenario({
    required String name,
    required List<String> filterTags,
    required int createdBy,
    String? description,
  }) async {
    try {
      final requestData = {
        'name': name,
        'filter_tags': filterTags,
        'created_by': createdBy,
        if (description != null) 'description': description,
      };
      
      final response = await _dioClient.dio.post(
        ApiConstants.scenarios,
        data: requestData,
      );
      
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update scenario on server
  Future<Map<String, dynamic>> updateScenario({
    required int id,
    String? name,
    List<String>? filterTags,
    String? description,
    String? status,
  }) async {
    try {
      final endpoint = ApiConstants.scenarioById.replaceAll('{id}', id.toString());
      
      final requestData = <String, dynamic>{};
      if (name != null) requestData['name'] = name;
      if (filterTags != null) requestData['filter_tags'] = filterTags;
      if (description != null) requestData['description'] = description;
      if (status != null) requestData['status'] = status;
      
      final response = await _dioClient.dio.put(
        endpoint,
        data: requestData,
      );
      
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete scenario on server
  Future<void> deleteScenario(int id) async {
    try {
      final endpoint = ApiConstants.scenarioDelete.replaceAll('{id}', id.toString());
      await _dioClient.dio.delete(endpoint);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get tasks for a scenario
  Future<List<Map<String, dynamic>>> getScenarioTasks(int scenarioId) async {
    try {
      final endpoint = ApiConstants.scenarioTasks.replaceAll('{id}', scenarioId.toString());
      final response = await _dioClient.dio.get(endpoint);
      final data = response.data;
      
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Complete a task on server
  Future<Map<String, dynamic>> completeTask({
    required int scenarioId,
    required int taskId,
    required int completedBy,
  }) async {
    try {
      final endpoint = ApiConstants.scenarioTaskComplete
          .replaceAll('{id}', scenarioId.toString())
          .replaceAll('{taskId}', taskId.toString());
      
      final response = await _dioClient.dio.post(
        endpoint,
        data: {'completed_by': completedBy},
      );
      
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get scenario statistics
  Future<Map<String, dynamic>> getScenarioStatistics(int scenarioId) async {
    try {
      final endpoint = ApiConstants.scenarioStatistics.replaceAll('{id}', scenarioId.toString());
      final response = await _dioClient.dio.get(endpoint);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to friendly exceptions
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please try again.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['detail'] ?? 'Server error';
        return Exception('Error $statusCode: $message');
      default:
        return Exception('An unexpected error occurred.');
    }
  }
}
