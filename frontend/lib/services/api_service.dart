import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Configured to support build-time dynamic injection using --dart-define=API_BASE_URL=...
  // Fallbacks to localhost for local development
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
  static String? token;

  static Map<String, String> get headers {
    final Map<String, String> h = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  static Future<http.Response> get(String path) async {
    return http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  static Future<http.Response> post(String path, dynamic body) async {
    return http.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> postForm(String path, Map<String, String> body) async {
    final Map<String, String> formHeaders = {
      'Accept': 'application/json',
    };
    if (token != null) {
      formHeaders['Authorization'] = 'Bearer $token';
    }
    return http.post(Uri.parse('$baseUrl$path'), headers: formHeaders, body: body);
  }

  static Future<http.Response> patch(String path, dynamic body) async {
    return http.patch(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> delete(String path) async {
    return http.delete(Uri.parse('$baseUrl$path'), headers: headers);
  }
}
