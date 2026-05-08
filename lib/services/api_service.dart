import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static const bool isWeb = bool.fromEnvironment('dart.library.js_util');
  static const String baseUrl = isWeb ? "http://localhost:8000" : "https://pillzy.onrender.com";

  static Future<String?> uploadImage(String filePath, {List<int>? bytes}) async {
    try {
      final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/upload-image"));
      if (isWeb && bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'upload.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      debugPrint("Upload Exception: $e");
      return null;
    }
  }

  static Future<bool> addMedicine({
    required String name,
    required String dosage,
    required String time,
    required String userId,
    String frequency = "",
    List<dynamic> times = const [],
    String photo = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add-medicine"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "dosage": dosage,
          "time": time,
          "user_id": userId,
          "frequency": frequency,
          "times": times,
          "photo": photo,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> verifyFace({required String email, required String imagePath, List<int>? bytes}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/verify-face"));
      request.fields['email'] = email;
      
      if (isWeb && bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'verify.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', imagePath));
      }
      
      var response = await request.send();
      if (response.statusCode == 200) {
        var resBody = await response.stream.bytesToString();
        return jsonDecode(resBody);
      }
      return null;
    } catch (e) {
      debugPrint("Verify Face Exception: $e");
      return null;
    }
  }

  static Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update-profile"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(profileData),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Update Profile Exception: $e");
      return false;
    }
  }

  static Future<bool> updateMedicine({
    required String medId,
    required String name,
    required String dosage,
    required String time,
    required String userId,
    String frequency = "",
    List<dynamic> times = const [],
    String photo = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update-medicine/$medId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "dosage": dosage,
          "time": time,
          "user_id": userId,
          "frequency": frequency,
          "times": times,
          "photo": photo,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Update Medicine Exception: $e");
      return false;
    }
  }

  static Future<bool> deleteMedicine(String medId) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/delete-medicine/$medId"));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete Medicine Exception: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getMedicines(String userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get-medicines/$userId"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['medicines'];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Exception: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> registerUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Register Exception: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> loginUser(String email, String dob) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "dob": dob}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'];
      }
      return null;
    } catch (e) {
      debugPrint("Login Exception: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update-profile"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Update Exception: $e");
      return null;
    }
  }

  static Future<bool> logAdherence({
    required String userId,
    required String medicineId,
    required String medicineName,
    required String status, // 'taken' or 'missed'
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/log-adherence"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "medicine_id": medicineId,
          "medicine_name": medicineName,
          "status": status,
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Log Adherence Exception: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getProgress(String userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get-progress/$userId"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['history'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint("Get Progress Exception: $e");
      return [];
    }
  }
}
