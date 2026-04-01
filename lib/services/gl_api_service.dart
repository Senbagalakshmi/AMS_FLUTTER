import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class GLApiService {

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

  //GL ATTRIBUTE API CALLS

 Future<List<Map<String, dynamic>>?> getAllGlAttributes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gl-attributes'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

    Future<bool> updateGlCategory(int glAttCd, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/gl-attributes/$glAttCd'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}