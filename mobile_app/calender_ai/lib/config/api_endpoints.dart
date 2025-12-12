class ApiEndpoints {
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');

  static const String addEvent = '/events/add';
  static String getUserEvents(String userId) => '/events/$userId';
  static const String updateEvent = '/events/update';
  static String deleteEvent(String userId, int eventIndex) => '/events/$userId/$eventIndex';
  
  // AI scheduling
  static const String generateSchedule = '/chat/generate';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
}

