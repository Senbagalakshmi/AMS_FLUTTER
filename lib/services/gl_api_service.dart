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

  // ─────────────────────────────────────────
  // GL ATTRIBUTE API CALLS
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>?> getAllGlAttributes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/gl-attributes'),
        headers: apiService.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  /// GL102 LIST
  Future<List<Map<String, dynamic>>?> getGlList() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/gl-branch/gl102/list"),
        headers: apiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }

    } catch (e) {
      print(e);
    }
    return null;
  }
  /// GL104 - ALLOWED BRANCHES
  Future<List<Map<String, dynamic>>?> getGl104List() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/gl-branch"),
        headers: apiService.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<bool> saveAllowedBranch(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/gl-branch"),
        headers: apiService.headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> updateAllowedBranch(Map<String, dynamic> payload) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/gl-branch"),
        headers: apiService.headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> deleteAllowedBranch(int orgCode, int glNo) async {
  try {
    final response = await http.delete(
      Uri.parse("${ApiService.baseUrl}/gl-branch/$orgCode/$glNo"),
      headers: apiService.headers,
    );
    return response.statusCode == 200 || response.statusCode == 204;
  } catch (e) {
    print(e);
    return false;
  }
}

  Future<bool> updateGlCategory(int glAttCd, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiService.baseUrl}/gl-attributes/$glAttCd'),
        headers: apiService.headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────
  // GL SEGMENTS API CALLS
  // ─────────────────────────────────────────

  /// GET /api/gl-segments →
  Future<List<Map<String, dynamic>>?> getAllGlSegments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/gl-segments'),
        headers: apiService.headers,
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

  /// GET /api/gl-segments/{glNo} →
  Future<List<Map<String, dynamic>>?> getGlSegmentsByGlNo(int glNo) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/gl-segments/$glNo'),
        headers: apiService.headers,
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

  /// POST /api/gl-segments →
  Future<bool> createGlSegment(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/gl-segments'),
        headers: apiService.headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// PUT /api/gl-segments →
  Future<bool> updateGlSegment(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/gl-segments'),
        headers: apiService.headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// DELETE /api/gl-segments/{glNo} →
  Future<bool> deleteGlSegment(int glNo) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/gl-segments/$glNo'),
        headers: apiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
