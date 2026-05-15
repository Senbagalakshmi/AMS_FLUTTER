import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class GLApiService {
  // ─────────────────────────────────────────
  // ACCOUNT CACHE
  // ─────────────────────────────────────────

  static Map<String, String> accountCache = {};

  static Future<void> loadAccountCache() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/gl-master?page=0&size=5000"),
        headers: apiService.headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        List<dynamic> rows = [];

        if (decoded is Map && decoded.containsKey('content')) {
          rows = decoded['content'];
        } else if (decoded is List) {
          rows = decoded;
        }

        accountCache.clear();

        for (final item in rows) {
          final acNum = item['acnum']?.toString() ??
              item['acNum']?.toString() ??
              item['glNo']?.toString() ??
              '';

          final acName = item['acname']?.toString() ??
              item['acName']?.toString() ??
              item['gldesc']?.toString() ??
              '';

          if (acNum.isNotEmpty) {
            accountCache[acNum] = acName;
          }
        }
      }
    } catch (e) {
      print("loadAccountCache error: $e");
    }
  }

  // ─────────────────────────────────────────
  // USER PROFILE
  // ─────────────────────────────────────────

  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/users/profile"),
        headers: apiService.headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("getUserProfile error: $e");
    }

    return null;
  }

  // ─────────────────────────────────────────
  // GL ATTRIBUTE API CALLS
  // ─────────────────────────────────────────
  static String get _baseUrl => '${ApiService.baseUrl}/gl-attributes';

  /// GL MASTER LIST //////////////////////////////////
  Future<List<Map<String, dynamic>>?> getGlList() async {
    try {
      // Trying the more standard endpoint first
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/gl-master?page=0&size=1000"),
        headers: apiService.headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        // Handle paginated response (standard in this app)
        if (decoded is Map && decoded.containsKey('content')) {
          final List<dynamic> content = decoded['content'] ?? [];
          return content.cast<Map<String, dynamic>>();
        }

        // Handle direct list response
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }

      // Fallback to the specific gl102 endpoint if above fails or returns nothing
      final fallbackRes = await http.get(
        Uri.parse("${ApiService.baseUrl}/gl-branch/gl102/list"),
        headers: apiService.headers,
      );

      if (fallbackRes.statusCode == 200) {
        final dynamic decoded = jsonDecode(fallbackRes.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }

    } catch (e) {
      print('GLApiService.getGlList Error: $e');
    }
    return null;
  }
  /// GL104 - ALLOWED BRANCHES 
  Future<List<Map<String, dynamic>>> getGl104List() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/gl-branch"),
        headers: apiService.headers,
      );

      if (response.statusCode != 200) {
        return [];
      }

      final dynamic decoded = jsonDecode(response.body);

    // Case 1: API returns List directly
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

    // Case 2: API returns paginated response (VERY COMMON)
      if (decoded is Map && decoded.containsKey("content")) {
        return List<Map<String, dynamic>>.from(decoded["content"]);
      }

      return [];
    } catch (e) {
      print("getGl104List error: $e");
      return [];
    }
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
      print("saveAllowedBranch error: $e");
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
      print("updateAllowedBranch error: $e");
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
      print("deleteAllowedBranch error: $e");
      return false;
    }
  }
//////////////////////////////////////////
  Future<bool> updateGlCategory(int glAttCd, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiService.baseUrl}/gl-attributes/$glAttCd'),
        headers: apiService.headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("updateGlCategory error: $e");
      return false;
    }
  }

  // ─────────────────────────────────────────
  // GL SEGMENTS API CALLS
  // ─────────────────────────────────────────

  /// GET /api/gl-segments →
  Future<List<Map<String, dynamic>>> getAllGlSegments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/gl-segments'),
        headers: apiService.headers,
      );

      if (response.statusCode != 200) {
        return [];
      }

      final dynamic decoded = jsonDecode(response.body);

    // Case 1: Direct List response
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

    // Case 2: Paginated response (VERY common in Spring Boot)
      if (decoded is Map && decoded.containsKey('content')) {
        return List<Map<String, dynamic>>.from(decoded['content']);
      }

      return [];
    } catch (e) {
      print("getAllGlSegments error: $e");
      return [];
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
    } catch (e) {
      print("getGlSegmentsByGlNo error: $e");
    }

    return null;
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
      print("createGlSegment error: $e");
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
      print("updateGlSegment error: $e");
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
      print("deleteGlSegment error: $e");
      return false;
    }
  }
   // ── GET ALL GL ATTRIBUTES ──────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllGlAttributes() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: apiService.headers,
      );

      if (response.statusCode != 200) {
        return [];
      }

      final dynamic decoded = jsonDecode(response.body);

    // Case 1: Direct List response
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

    // Case 2: Paginated response (Spring Boot common)
      if (decoded is Map && decoded.containsKey('content')) {
        return List<Map<String, dynamic>>.from(decoded['content']);
      }

      return [];
    } catch (e) {
      print("getAllGlAttributes error: $e");
      return [];
    }
  }

  // ── GET GL ATTRIBUTES BY GL NO ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>?> getGlAttributesByGlNo(int glNo) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$glNo'),
        headers: apiService.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("getGlAttributesByGlNo error: $e");
    }

    return null;
  }

  // ── CREATE GL ATTRIBUTE ────────────────────────────────────────────────
  static Future<bool> createGlAttribute({
    required int orgCode,
    required int glNo,
    required String glAttrid,
    required String glAttrValue,
    required String eUser,
  }) async {
    try {
      final body = {
        "orgCode": orgCode,
        "glNo": glNo,
        "glAttrid": glAttrid,
        "glAttrValue": glAttrValue,
        "eUser": eUser,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: apiService.headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("createGlAttribute error: $e");
      return false;
    }
  }

  // ── UPDATE GL ATTRIBUTE ────────────────────────────────────────────────
  static Future<bool> updateGlAttribute({
    required int orgCode,
    required int glNo,
    required String glAttrid,
    required String glAttrValue,
    required String eUser,
  }) async {
    try {
      final body = {
        "orgCode": orgCode,
        "glNo": glNo,
        "glAttrid": glAttrid,
        "glAttrValue": glAttrValue,
        "eUser": eUser,
      };

      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: apiService.headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("updateGlAttribute error: $e");
      return false;
    }
  }

  // ── DELETE GL ATTRIBUTE BY GL NO ──────────────────────────────────────
  static Future<bool> deleteGlAttribute(int glNo) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$glNo'),
        headers: apiService.headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("deleteGlAttribute error: $e");
      return false;
    }
  }
  /// GL103 - ALLOWED CURRENCY /////////////////////////////////////
  Future<List<Map<String, dynamic>>> getGl103List() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/gl-transcation"),
        headers: apiService.headers,
      );

      if (response.statusCode != 200) {
        return [];
      }

      final dynamic decoded = jsonDecode(response.body);

    // Case 1: Direct List response
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

    // Case 2: Paginated response (Spring Boot common)
      if (decoded is Map && decoded.containsKey('content')) {
        return List<Map<String, dynamic>>.from(decoded['content']);
      }

      return [];
    } catch (e) {
      print("getGl103List error: $e");
      return [];
    }
  }

  Future<bool> saveAllowedCurrency(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/gl-transcation"),
        headers: apiService.headers,
        body: jsonEncode(payload),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("saveAllowedCurrency error: $e");
      return false;
    }
  }

  Future<bool> updateAllowedCurrency(Map<String, dynamic> payload) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/gl-transcation"),
        headers: apiService.headers,
        body: jsonEncode(payload),
      );

      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } catch (e) {
      print("updateAllowedCurrency error: $e");
      return false;
    }
  }

  Future<bool> deleteAllowedCurrency(int orgCode, int glNo) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiService.baseUrl}/gl-transcation/$orgCode/$glNo"),
        headers: apiService.headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("deleteAllowedCurrency error: $e");
      return false;
    }
  }
  //////////////////////////////////
}


