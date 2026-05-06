import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'api_service.dart';

class UserService {

  static Future<Map<String, dynamic>?> getUserProfile() async {
    Map<String, dynamic>? cachedUser;
    if (kIsWeb) {
      try {
        final userDataStr = html.window.sessionStorage['user_data'];
        if (userDataStr != null && userDataStr.isNotEmpty) {
          cachedUser = json.decode(userDataStr);
        }
      } catch (e) {
        print("Session storage parse error: $e");
      }
    }

    String? token = apiService.token;
    
    if (kIsWeb) {
      final childToken = html.window.sessionStorage['child_token'];
      if (childToken != null && childToken.isNotEmpty) {
        token = childToken;
      }
    }

    try {
      final url = "${ApiService.baseUrl}/users/profile";
      print("🌐 Fetching Profile from: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print("📥 Profile Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("❌ Profile Error Body: ${response.body}");
      }
    } catch (e) {
      print("API Profile Request Failed: $e");
    }

    // Fallback to cache if API fails
    return cachedUser;
  }
}