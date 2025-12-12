import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_endpoints.dart';

class GeneratedEvent {
  final String title;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:MM
  final String endTime; // HH:MM
  final String location;
  final String description;

  GeneratedEvent({
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.description = '',
  });

  factory GeneratedEvent.fromJson(Map<String, dynamic> json) {
    return GeneratedEvent(
      title: json['title']?.toString() ?? 'Untitled Event',
      date: json['date']?.toString() ?? DateTime.now().toIso8601String().split('T')[0],
      startTime: json['start_time']?.toString() ?? '12:00',
      endTime: json['end_time']?.toString() ?? '13:00',
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  String get timeRange {
    final start = _formatTime(startTime);
    final end = _formatTime(endTime);
    return '$start – $end';
  }

  String _formatTime(String time) {
    // Convert 24-hour to 12-hour format if needed
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        var hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        return '$hour:${minute.padLeft(2, '0')} $period';
      }
    } catch (e) {
      // Return as-is if parsing fails
    }
    return time;
  }

  String get displayDate {
    try {
      final dateTime = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final eventDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      if (eventDay == today) {
        return 'Today';
      } else if (eventDay == today.add(const Duration(days: 1))) {
        return 'Tomorrow';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[dateTime.month - 1]} ${dateTime.day}';
      }
    } catch (e) {
      return date;
    }
  }
}

class GeneratedSchedule {
  final List<GeneratedEvent> events;
  final String summary;

  GeneratedSchedule({
    required this.events,
    this.summary = '',
  });

  factory GeneratedSchedule.fromJson(Map<String, dynamic> json) {
    final List eventsList = json['events'] is List ? json['events'] : [];
    return GeneratedSchedule(
      events: eventsList.map((e) => GeneratedEvent.fromJson(e as Map<String, dynamic>)).toList(),
      summary: json['summary']?.toString() ?? '',
    );
  }
}

class CalendarService {
  final http.Client _client;
  String? authToken;

  CalendarService({http.Client? client, this.authToken}) : _client = client ?? http.Client();

  Future<GeneratedSchedule> generateSchedule(String prompt) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.generateSchedule}');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };

    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return GeneratedSchedule.fromJson(data);
    }

    throw Exception('Server responded with ${response.statusCode}');
  }

  /// Send a VEVENT string to the backend to create an event for [userId].
  /// Returns true on success, otherwise throws an exception.
  Future<bool> addEvent(String userId, String vevent) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.addEvent}');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };

    final body = jsonEncode({'user_id': userId, 'vevent': vevent});
    print('Adding event for userId: $userId');
    print('Request URL: $uri');
    print('Has auth token: ${authToken != null && authToken!.isNotEmpty}');
    
    final response = await _client.post(uri, headers: headers, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }

    throw Exception('Failed to add event: ${response.statusCode} ${response.body}');
  }

  /// Fetch all events for a user.
  /// Returns a list of event dictionaries.
  Future<List<Map<String, dynamic>>> getUserEvents(String userId) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.getUserEvents(userId)}');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };

    final response = await _client.get(uri, headers: headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => e as Map<String, dynamic>).toList();
    }

    throw Exception('Failed to fetch events: ${response.statusCode} ${response.body}');
  }
}

