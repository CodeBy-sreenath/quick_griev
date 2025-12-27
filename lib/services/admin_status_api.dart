import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminStatusApi {
  static const String baseUrl = "http://localhost:3000/api";

  static Future<void> updateComplaintStatus({
    required String complaintId,
    required String message,
    required String status,
    required String department,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/status/admin/complaints/$complaintId/status',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "message": message,
        "status": status,
        "department": department,
      }),
    );

    // 🛡️ Safety check
    if (!response.headers['content-type']!
        .contains('application/json')) {
      throw Exception("Server did not return JSON");
    }

    final data = jsonDecode(response.body);

    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update status');
    }
  }
}
