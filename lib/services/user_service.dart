import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class UserService {

  static Future<Map<String, dynamic>?> getUserProfile() async {

    final response = await http.get(
      Uri.parse("http://localhost:8080/api/users/profile"),
      headers: apiService.headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }

    return null;
  }
}