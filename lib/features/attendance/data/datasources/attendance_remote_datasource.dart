import 'dart:typed_data';

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
      
      final response = await _dioClient.dio.post(
        ApiConstants.attendanceRecord,
        data: requestData,
      );


      // Debug: Log each field type before parsing
      final data = response.data as Map<String, dynamic>;
      
      
      // The server returns snake_case keys, but the generated Attendance model
      // expects snake_case keys (contact_id, service_type, service_date, recorded_at)
      // Note: The server returns 'id' as the attendance's server ID. We need to:
      // - Keep 'id' as-is for the Attendance model
      // - Also map it to 'serverId' if needed
      final convertedData = <String, dynamic>{};
      data.forEach((key, value) {
        switch (key) {
          case 'id':
            // Keep 'id' as-is AND also map to 'serverId' for sync purposes
            convertedData['id'] = value;
            convertedData['serverId'] = value;
            break;
          case 'service_type':
            // Convert backend value to enum name
            convertedData['service_type'] = ServiceType.fromBackend(value as String).name;
            break;
          case 'service_date':
            // Ensure service_date is ISO8601 string
            if (value is String) {
              convertedData['service_date'] = value;
            }
            break;
          case 'recorded_at':
            // Ensure recorded_at is ISO8601 string
            if (value is String) {
              convertedData['recorded_at'] = value;
            }
            break;
          default:
            convertedData[key] = value;
        }
      });
      
      try {
        final result = Attendance.fromJson(convertedData);
        return result;
      } catch (e) {
        rethrow;
      }
    } on DioException catch (e) {
      if (e.response != null) {
      }
      
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

      final response = await _dioClient.dio.get(
        ApiConstants.attendances,
        queryParameters: queryParams,
      );


      final List<dynamic> data = response.data;
      return data.map((json) => Attendance.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
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

  /// Downloads attendance PDF from server.
  /// 
  /// [dateFrom] - Start date for filtering (inclusive)
  /// [dateTo] - End date for filtering (inclusive)
  /// [serviceType] - Optional service type filter
  /// [date] - Single date for export (takes priority over dateFrom/dateTo)
  ///           Format: YYYY-MM-DD for entire day in SAST timezone
  Future<Uint8List> downloadAttendancePdf({
    DateTime? dateFrom,
    DateTime? dateTo,
    ServiceType? serviceType,
    DateTime? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      // If date is provided, use it (takes priority)
      // Format: YYYY-MM-DD for entire day in SAST timezone
      if (date != null) {
        queryParams['date'] = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } else {
        // Otherwise use date_from/date_to range
        if (dateFrom != null) {
          queryParams['date_from'] = dateFrom.toUtc().toIso8601String();
        }
        if (dateTo != null) {
          queryParams['date_to'] = dateTo.toUtc().toIso8601String();
        }
      }
      
      if (serviceType != null) {
        queryParams['service_type'] = serviceType.backendValue;
      }

      final response = await _dioClient.dio.get(
        ApiConstants.attendanceExport,
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      return Uint8List.fromList(response.data);
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

      final response = await _dioClient.dio.post(
        ApiConstants.contacts,
        data: requestData,
      );


      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
      }
      
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

  /// Updates a contact on the server.
  Future<Map<String, dynamic>> updateContact({
    required int contactId,
    String? name,
    String? phone,
    String? status,
    bool? optOutSms,
    bool? optOutWhatsapp,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      
      if (name != null) requestData['name'] = name;
      if (phone != null) {
        final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(phone);
        if (normalizedPhone != null) {
          requestData['phone'] = normalizedPhone;
        }
      }
      if (status != null) requestData['status'] = status;
      if (optOutSms != null) requestData['opt_out_sms'] = optOutSms;
      if (optOutWhatsapp != null) requestData['opt_out_whatsapp'] = optOutWhatsapp;

      // Debug: Log the request details

      final response = await _dioClient.dio.put(
        ApiConstants.contactById.replaceAll('{id}', contactId.toString()),
        data: requestData,
      );


      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
      }
      
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

  /// Adds tags to a contact on the server.
  Future<Map<String, dynamic>> addTagsToContact({
    required int contactId,
    required List<String> tags,
  }) async {
    try {
      final requestData = {'tags': tags};

      // Debug: Log the request details

      final response = await _dioClient.dio.post(
        ApiConstants.contactTagsAdd.replaceAll('{id}', contactId.toString()),
        data: requestData,
      );


      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
      }
      
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
