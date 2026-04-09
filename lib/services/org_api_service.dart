import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class OrgApiService {
  static const String _path = '/organisation';

  Future<PaginatedResult<Map<String, dynamic>>?> getAllOrganisations(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$_path?page=$page&size=$size'),
        headers: apiService.headers,
      );
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  PaginatedResult<Map<String, dynamic>> _parsePaginated(dynamic decoded) {
    if (decoded is List) {
      return PaginatedResult(
        items: decoded.cast<Map<String, dynamic>>(),
        totalElements: decoded.length,
      );
    } else if (decoded is Map && decoded.containsKey('content')) {
      return PaginatedResult(
        items: (decoded['content'] as List).cast<Map<String, dynamic>>(),
        totalElements:
            decoded['totalElements'] ?? (decoded['content'] as List).length,
      );
    }
    return PaginatedResult(items: [], totalElements: 0);
  }

  Future<Map<String, dynamic>?> getOrganisationById(int orgCode) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$_path/$orgCode'),
        headers: apiService.headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createOrganisation(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}$_path'),
        headers: apiService.headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateOrganisation(Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('${ApiService.baseUrl}$_path'),
        headers: apiService.headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteOrganisation(int orgCode) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}$_path/$orgCode'),
        headers: apiService.headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

final orgApiService = OrgApiService();
