import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ Use localhost for Flutter Web
  static const String baseUrl = "http://localhost:3000/api";

  static Future<Map<String, dynamic>> adminLogin({
    required String department,
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'department': department,
        'username': username,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }
}
