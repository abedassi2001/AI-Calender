import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_endpoints.dart';

class AuthResult {
  final String token;
  final Map<String, dynamic>? user;

  AuthResult({required this.token, this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token']?.toString() ?? '',
      user: json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : null,
    );
  }
}

class AuthService {
  final http.Client _client;
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Future<AuthResult> login({required String email, required String password}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.login}');
    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _parseAuthResponse(res);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.register}');
    final res = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _parseAuthResponse(res);
  }

  AuthResult _parseAuthResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return AuthResult.fromJson(data);
    }
    throw Exception('Auth failed (${res.statusCode}): ${res.body}');
  }
}

