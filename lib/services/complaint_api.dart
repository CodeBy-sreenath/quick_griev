import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api/complaint';

  static Future<Map<String, dynamic>> submitComplaint({
    required String userId,
    required String complaintText,
    required String language,
    PlatformFile? imageFile, // Changed from imageUrl to imageFile
    String? voiceText,
    String? location,
  }) async {
    try {
      // Create multipart request for file upload
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user-complaint'),
      );

      // Add text fields
      request.fields['userId'] = userId;
      request.fields['complaintText'] = complaintText;
      request.fields['language'] = language;
      if (voiceText != null) request.fields['voiceText'] = voiceText;
      if (location != null) request.fields['location'] = location;

      // Add image file if exists
      if (imageFile != null && imageFile.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image', // Must match the field name in backend
            imageFile.bytes!,
            filename: imageFile.name,
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit complaint: ${response.body}');
      }
    } catch (e) {
      print('Error submitting complaint: $e');
      return {
        'success': false,
        'message': 'Failed to submit complaint: $e',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getComplaintHistory(
      String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/complaints/$userId'));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
            jsonDecode(response.body)['complaints']);
      }
      return [];
    } catch (e) {
      print('Error fetching complaint history: $e');
      return [];
    }
  }
}