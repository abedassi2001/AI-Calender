import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_endpoints.dart';

class GeneratedSchedule {
  final String title;
  final String timeRange;
  final String location;
  final String note;
  final List<String> timeline;

  GeneratedSchedule({
    required this.title,
    required this.timeRange,
    required this.location,
    required this.note,
    required this.timeline,
  });

  factory GeneratedSchedule.fromJson(Map<String, dynamic> json) {
    final List timelineList = json['timeline'] is List ? json['timeline'] : [];
    return GeneratedSchedule(
      title: json['title']?.toString() ?? 'AI Suggestion',
      timeRange: json['time_range']?.toString() ?? 'TBD',
      location: json['location']?.toString() ?? 'Not set',
      note: json['note']?.toString() ?? 'No notes provided',
      timeline: timelineList.map((e) => e.toString()).toList(),
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

    final response = await _client.post(uri, headers: headers, body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }

    throw Exception('Failed to add event: ${response.statusCode} ${response.body}');
  }
}

