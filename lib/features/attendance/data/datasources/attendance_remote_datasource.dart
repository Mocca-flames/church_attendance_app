import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/service_type.dart';
import 'package:church_attendance_app/core/network/api_constants.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:church_attendance_app/features/attendance/domain/models/attendance.dart';
import 'package:dio/dio.dart';

/// Remote data source for attendance operations.
/// Handles all API calls to the backend server.
class AttendanceRemoteDataSource {
  final DioClient _dioClient;

  AttendanceRemoteDataSource(this._dioClient);

  /// Records attendance on the server.
  /// 
  /// Phone number is normalized to +27XXXXXXXXX format before sending.
  /// Returns the created attendance record with server ID.
  Future<Attendance> recordAttendance({
    required int contactId,
    required String phone,
    required ServiceType serviceType,
    required DateTime serviceDate,
    required int recordedBy,
  }) async {
    final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(phone);
    if (normalizedPhone == null) {
      throw ArgumentError('Invalid phone number format: $phone');
    }
    
    try {
      final requestData = {
        'contact_id': contactId,
        'phone': normalizedPhone,
        'service_type': serviceType.backendValue,
        'service_date': serviceDate.toUtc().toIso8601String(),
        'recorded_by': recordedBy,
      };
      
      // Debug: Log the request details
      print('╔═══════════════════════════════════════════════════════════');
      print('║ RECORD ATTENDANCE REQUEST');
      print('╠═══════════════════════════════════════════════════════════');
      print('║ contact_id: $contactId');
      print('║ phone: $normalizedPhone');
      print('║ service_type: ${serviceType.backendValue}');
      print('║ service_date: ${serviceDate.toUtc().toIso8601String()}');
      print('║ recorded_by: $recordedBy');
      print('╚═══════════════════════════════════════════════════════════');
      
      final response = await _dioClient.dio.post(
        ApiConstants.attendanceRecord,
        data: requestData,
      );

      print('╔═══════════════════════════════════════════════════════════');
      print('║ RECORD ATTENDANCE RESPONSE');
      print('╠═══════════════════════════════════════════════════════════');
      print('║ Status: ${response.statusCode}');
      print('║ Data: ${response.data}');
      print('╚═══════════════════════════════════════════════════════════');

      return Attendance.fromJson(response.data);
    } on DioException catch (e) {
      print('╔═══════════════════════════════════════════════════════════');
      print('║ RECORD ATTENDANCE ERROR');
      print('╠═══════════════════════════════════════════════════════════');
      print('║ Type: ${e.type}');
      print('║ Message: ${e.message}');
      if (e.response != null) {
        print('║ Status: ${e.response?.statusCode}');
        print('║ Data: ${e.response?.data}');
      }
      print('╚═══════════════════════════════════════════════════════════');
      
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['detail'] ?? 'Bad request';
        throw AttendanceRemoteException(message);
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw const AttendanceRemoteException(
          'Network error',
          isNetworkError: true,
        );
      }
      rethrow;
    }
  }

  /// Gets attendance records from the server.
  Future<List<Attendance>> getAttendanceRecords({
    DateTime? dateFrom,
    DateTime? dateTo,
    ServiceType? serviceType,
    int? contactId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toUtc().toIso8601String();
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toUtc().toIso8601String();
      }
      if (serviceType != null) {
        queryParams['service_type'] = serviceType.backendValue;
      }
      if (contactId != null) {
        queryParams['contact_id'] = contactId;
      }

      // Debug: Log the request details
      print('╔═══════════════════════════════════════════════════════════');
      print('║ GET ATTENDANCE RECORDS REQUEST');
      print('╠═══════════════════════════════════════════════════════════');
      print('║ Endpoint: ${ApiConstants.attendances}');
      print('║ Query Params: $queryParams');
      print('╚═══════════════════════════════════════════════════════════');

      final response = await _dioClient.dio.get(
        ApiConstants.attendances,
        queryParameters: queryParams,
      );

      print('╔═══════════════════════════════════════════════════════════');
      print('║ GET ATTENDANCE RECORDS RESPONSE');
      print('╠═══════════════════════════════════════════════════════════');
      print('║ Status: ${response.statusCode}');
      print('║ Data Length: ${(response.data as List).length}');
      print('║ Data: ${response.data}');
      print('╚═══════════════════════════════════════════════════════════');

      final List<dynamic> data = response.data;
      return data.map((json) => Attendance.fromJson(json)).toList();
    } on DioException catch (e) {
      print('╔═══════════════════════════════════════════════════════════');
      print('║ GET ATTENDANCE RECORDS ERROR');
      print('╠═══════════════════════════════════════════════════════════');
      print('║ Type: ${e.type}');
      print('║ Message: ${e.message}');
      if (e.response != null) {
        print('║ Status: ${e.response?.statusCode}');
        print('║ Data: ${e.response?.data}');
      }
      print('╚═══════════════════════════════════════════════════════════');
      
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw const AttendanceRemoteException(
          'Network error',
          isNetworkError: true,
        );
      }
      rethrow;
    }
  }

  /// Gets attendance records for a specific contact from the server.
  Future<List<Attendance>> getContactAttendance(int contactId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.attendanceByContactId.replaceAll('{id}', contactId.toString()),
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Attendance.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw const AttendanceRemoteException(
          'Network error',
          isNetworkError: true,
        );
      }
      rethrow;
    }
  }

  /// Gets attendance summary from the server.
  Future<Map<String, dynamic>> getAttendanceSummary({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toUtc().toIso8601String();
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toUtc().toIso8601String();
      }

      final response = await _dioClient.dio.get(
        ApiConstants.attendanceSummary,
        queryParameters: queryParams,
      );

      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw const AttendanceRemoteException(
          'Network error',
          isNetworkError: true,
        );
      }
      rethrow;
    }
  }

  /// Deletes an attendance record from the server.
  Future<void> deleteAttendance(int attendanceId) async {
    try {
      await _dioClient.dio.delete(
        ApiConstants.attendanceById.replaceAll('{id}', attendanceId.toString()),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw const AttendanceRemoteException(
          'Network error',
          isNetworkError: true,
        );
      }
      rethrow;
    }
  }

  /// Creates a contact on the server.
  /// 
  /// Phone number is normalized to +27XXXXXXXXX format before sending.
  /// Returns the created contact with server ID.
  Future<Map<String, dynamic>> createContact({
    required String phone,
    required String name,
    List<String>? tags,
  }) async {
    final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(phone);
    if (normalizedPhone == null) {
      throw ArgumentError('Invalid phone number format: $phone');
    }
    
    try {
      final requestData = {
        'phone': normalizedPhone,
        'name': name,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      };

      // Debug: Log the request details
      print('╔═══════════════════════════════════════════════════════════');
      print('║ CREATE CONTACT REQUEST');
      print('╠═══════════════════════════════════════════════════════════');
      print('║ Endpoint: ${ApiConstants.contacts}');
      print('║ phone: $normalizedPhone');
      print('║ name: $name');
      print('║ tags: $tags');
      print('╚═══════════════════════════════════════════════════════════');

      final response = await _dioClient.dio.post(
        ApiConstants.contacts,
        data: requestData,
      );

      print('╔═══════════════════════════════════════════════════════════');
      print('║ CREATE CONTACT RESPONSE');
      print('╠═══════════════════════════════════════════════════════════');
      print('║ Status: ${response.statusCode}');
      print('║ Data: ${response.data}');
      print('╚═══════════════════════════════════════════════════════════');

      return response.data;
    } on DioException catch (e) {
      print('╔═══════════════════════════════════════════════════════════');
      print('║ CREATE CONTACT ERROR');
      print('╠═══════════════════════════════════════════════════════════');
      print('║ Type: ${e.type}');
      print('║ Message: ${e.message}');
      if (e.response != null) {
        print('║ Status: ${e.response?.statusCode}');
        print('║ Data: ${e.response?.data}');
      }
      print('╚═══════════════════════════════════════════════════════════');
      
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['detail'] ?? 'Bad request';
        throw AttendanceRemoteException(message);
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw const AttendanceRemoteException(
          'Network error',
          isNetworkError: true,
        );
      }
      rethrow;
    }
  }
}

/// Exception for remote attendance operations.
class AttendanceRemoteException implements Exception {
  final String message;
  final bool isNetworkError;

  const AttendanceRemoteException(
    this.message, {
    this.isNetworkError = false,
  });

  @override
  String toString() => 'AttendanceRemoteException: $message';
}
