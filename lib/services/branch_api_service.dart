import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class BranchApiService {
  static const String _path = '/branches';

  Future<PaginatedResult<Map<String, dynamic>>?> getBranches(
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

  Future<bool> createBranch(Map<String, dynamic> data) async {
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

  Future<bool> updateBranch(Map<String, dynamic> data) async {
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

  Future<bool> deleteBranch(int branchCd) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}$_path/$branchCd'),
        headers: apiService.headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

final branchApiService = BranchApiService();
