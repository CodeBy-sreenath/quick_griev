import 'dart:convert';
import 'package:http/http.dart' as http;

class StatusApi {
  static const String baseUrl = "http://localhost:3000/api/status";

  static Future<List<dynamic>> getComplaintUpdates(String complaintId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/complaints/$complaintId/status'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['updates'];
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch updates');
    }
  }
}
