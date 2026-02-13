class ApiConstants {
  // Base URL - Update this with your actual backend URL
  static const String baseUrl = 'http://your-api-url';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';

  // Contact Endpoints
  static const String contacts = '/contacts/';
  static const String contactById = '/contacts/{id}';
  static const String contactTags = '/contacts/{id}/tags';
  static const String contactTagsAdd = '/contacts/{id}/tags/add';
  static const String contactTagsRemove = '/contacts/{id}/tags/remove';
  static const String allTags = '/contacts/tags/all';

  // Attendance Endpoints
  static const String attendances = '/attendance/records';
  static const String attendanceRecord = '/attendance/record';
  static const String attendanceSummary = '/attendance/summary';

  // Scenario Endpoints
  static const String scenarios = '/scenarios/';
  static const String scenarioById = '/scenarios/{id}';
  static const String scenarioTaskComplete = '/scenarios/{id}/tasks/{taskId}/complete';

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
