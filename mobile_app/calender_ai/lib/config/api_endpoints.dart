class ApiEndpoints {
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');

  // AI scheduling
  static const String generateSchedule = '/chat/generate';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
}

