class ApiEndpoints {
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');

  // Update this path to match your FastAPI route for scheduling/chat
  static const String generateSchedule = '/chat/generate';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  // Events
  static const String addEvent = '/events/add';
}
