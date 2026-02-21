import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/network/api_constants.dart';
import 'package:church_attendance_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

/// Remote data source for contact operations.
/// Handles all API calls to the backend server.
class ContactRemoteDataSource {
  final DioClient _dioClient;

  ContactRemoteDataSource(this._dioClient);

  /// Get all contacts from server
  Future<List<Map<String, dynamic>>> getContacts() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.contacts);
      final data = response.data;
      
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Search contacts on server
  Future<List<Map<String, dynamic>>> searchContacts(String query) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConstants.contactsSearch}$query',
      );
      final data = response.data;
      
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get single contact by ID
  Future<Map<String, dynamic>?> getContactById(int id) async {
    try {
      final endpoint = ApiConstants.contactById.replaceAll('{id}', id.toString());
      final response = await _dioClient.dio.get(endpoint);
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleDioError(e);
    }
  }

  /// Create contact on server
  Future<Map<String, dynamic>> createContact({
    required String phone,
    String? name,
    List<String>? tags,
  }) async {
    try {
      final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(phone);
      if (normalizedPhone == null) {
        throw ArgumentError('Invalid phone number format: $phone');
      }
      
      final requestData = {
        'phone': normalizedPhone,
        if (name != null) 'name': name,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      };
      
      final response = await _dioClient.dio.post(
        ApiConstants.contacts,
        data: requestData,
      );
      
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update contact on server
  Future<Map<String, dynamic>> updateContact({
    required int id,
    String? name,
    String? phone,
  }) async {
    try {
      final endpoint = ApiConstants.contactById.replaceAll('{id}', id.toString());
      
      final requestData = <String, dynamic>{};
      if (name != null) requestData['name'] = name;
      if (phone != null) {
        final normalizedPhone = PhoneUtils.normalizeSouthAfricanPhone(phone);
        if (normalizedPhone != null) {
          requestData['phone'] = normalizedPhone;
        }
      }
      
      final response = await _dioClient.dio.put(
        endpoint,
        data: requestData,
      );
      
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete contact on server
  Future<void> deleteContact(int id) async {
    try {
      final endpoint = ApiConstants.contactById.replaceAll('{id}', id.toString());
      await _dioClient.dio.delete(endpoint);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Add tags to contact on server
  Future<void> addTagsToContact({
    required int id,
    required List<String> tags,
  }) async {
    try {
      final endpoint = ApiConstants.contactTagsAdd.replaceAll('{id}', id.toString());
      await _dioClient.dio.post(
        endpoint,
        data: {'tags': tags},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Remove tags from contact on server
  Future<void> removeTagsFromContact({
    required int id,
    required List<String> tags,
  }) async {
    try {
      final endpoint = ApiConstants.contactTagsRemove.replaceAll('{id}', id.toString());
      await _dioClient.dio.post(
        endpoint,
        data: {'tags': tags},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Set tags on contact (replace all tags)
  Future<void> setTagsOnContact({
    required int id,
    required List<String> tags,
  }) async {
    try {
      final endpoint = ApiConstants.contactTagsSet.replaceAll('{id}', id.toString());
      await _dioClient.dio.put(
        endpoint,
        data: {'tags': tags},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get all available tags from server
  Future<List<String>> getAllTags() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.allTags);
      final data = response.data;
      
      if (data is List) {
        return data.cast<String>();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Import contacts from a VCF file
  Future<Map<String, dynamic>> importVcfFile(String filePath) async {
    try {
      final file = await MultipartFile.fromFile(
        filePath,
        filename: 'contacts.vcf',
      );
      
      final formData = FormData.fromMap({
        'file': file,
      });
      
      final response = await _dioClient.dio.post(
        ApiConstants.importVcfFile,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
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
