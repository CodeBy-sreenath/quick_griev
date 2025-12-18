import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ IMPORTANT: Replace with your actual backend URL
  // For Chrome/Web: use "http://localhost:3000"
  // For Android Emulator: use "http://10.0.2.2:3000"
  // For iOS Simulator: use "http://localhost:3000"
  // For Physical device: use your computer's IP address "http://192.168.x.x:3000"
  static const String baseUrl = "http://localhost:3000/api/users";

  // ---------------- REGISTER ----------------
  static Future<Map<String, dynamic>> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "username": username,
          "email": email,
          "password": password,
        }),
      );

      print("Register Response Status: ${response.statusCode}");
      print("Register Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {"message": error["message"] ?? "Registration failed"};
      }
    } catch (e) {
      print("Register Error: $e");
      return {"message": "Network error: ${e.toString()}"};
    }
  }

  // ---------------- VERIFY EMAIL OTP ----------------
  static Future<Map<String, dynamic>> verifyEmailOtp({
    required String userId,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verify-email-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userId": userId,
          "otp": otp,
        }),
      );

      print("Verify Email OTP Response: ${response.statusCode}");
      print("Verify Email OTP Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {"message": error["message"] ?? "OTP verification failed"};
      }
    } catch (e) {
      print("Verify Email OTP Error: $e");
      return {"message": "Network error: ${e.toString()}"};
    }
  }

  // ---------------- RESEND EMAIL OTP ----------------
  static Future<Map<String, dynamic>> resendEmailOtp({
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/resend-email-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userId": userId,
        }),
      );

      print("Resend OTP Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {"message": error["message"] ?? "Failed to resend OTP"};
      }
    } catch (e) {
      print("Resend OTP Error: $e");
      return {"message": "Network error: ${e.toString()}"};
    }
  }

  // ---------------- LOGIN ----------------
  static Future<Map<String, dynamic>> login({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
        }),
      );

      print("Login Response Status: ${response.statusCode}");
      print("Login Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {"message": error["message"] ?? "Login failed"};
      }
    } catch (e) {
      print("Login Error: $e");
      return {"message": "Network error: ${e.toString()}"};
    }
  }

  // ---------------- VERIFY LOGIN OTP ----------------
  static Future<Map<String, dynamic>> verifyLoginOtp({
    required String userId,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verify-login-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userId": userId,
          "otp": otp,
        }),
      );

      print("Verify Login OTP Response: ${response.statusCode}");
      print("Verify Login OTP Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {"message": error["message"] ?? "OTP verification failed"};
      }
    } catch (e) {
      print("Verify Login OTP Error: $e");
      return {"message": "Network error: ${e.toString()}"};
    }
  }
}