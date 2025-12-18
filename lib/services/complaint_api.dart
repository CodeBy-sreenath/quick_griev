import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
       'http://localhost:3000/api/complaint';

  static Future<Map<String, dynamic>> submitComplaint({
    required String userId,
    required String complaintText,
    required String language,
    String? imageUrl,
    String? voiceText,
    String? location,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user-complaint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'complaintText': complaintText,
        'language': language,
        'imageUrl': imageUrl,
        'voiceText': voiceText,
        'location': location,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getComplaintHistory(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/complaints/$userId'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
          jsonDecode(response.body)['complaints']);
    }
    return [];
  }
}
