class ApiConstants {
  // Base URL - Update this with your actual backend URL
  // For development, you can use your computer's local IP address
  // e.g., 'http://192.168.1.100:8000' for Android emulator to access localhost
  static const String baseUrl = 'https://8824-102-253-119-16.ngrok-free.app'; // Android emulator localhost

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';

  // Contact Endpoints
  static const String contacts = '/contacts';
  static const String contactById = '/contacts/{id}';
  static const String contactAddList = '/contacts/add-list';
  static const String contactTags = '/contacts/{id}/tags';
  static const String contactTagsAdd = '/contacts/{id}/tags/add';
  static const String contactTagsRemove = '/contacts/{id}/tags/remove';
  static const String contactTagsSet = '/contacts/{id}/tags';
  static const String allTags = '/contacts/tags/all';
  static const String tagStatistics = '/contacts/tags/statistics';
  static const String tagsBulkAdd = '/contacts/tags/bulk-add';
  static const String tagsBulkRemove = '/contacts/tags/bulk-remove';

  // Attendance Endpoints
  static const String attendances = '/attendance/records';
  static const String attendanceRecord = '/attendance/record';
  static const String attendanceSummary = '/attendance/summary';
  static const String attendanceByContactId = '/attendance/contacts/{id}';
  static const String attendanceById = '/attendance/{id}';
  static const String attendanceDelete = '/attendance/{id}';

  // Scenario Endpoints
  static const String scenarios = '/scenarios/';
  static const String scenarioById = '/scenarios/{id}';
  static const String scenarioTasks = '/scenarios/{id}/tasks';
  static const String scenarioStatistics = '/scenarios/{id}/statistics';
  static const String scenarioTaskComplete = '/scenarios/{id}/tasks/{taskId}/complete';
  static const String scenarioDelete = '/scenarios/{id}';

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
