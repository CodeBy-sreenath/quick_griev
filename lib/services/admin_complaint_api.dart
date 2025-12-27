import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminApi {
  static const String baseUrl = "http://localhost:3000/api";

  static Future<List<dynamic>> getDepartmentComplaints(String department) async {
    final response = await http.get(
      Uri.parse('$baseUrl/complaint/department/$department'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Server error');
    }

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      return data['complaints'];
    } else {
      throw Exception(data['message'] ?? 'Failed to load complaints');
    }
  }
}
