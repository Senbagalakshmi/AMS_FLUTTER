import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  
  String? _token;

  void updateToken(String? newToken) {
    _token = newToken;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['jwt'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, Auth101Config>?> getAuthConfigs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/authctl/list'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final Map<String, Auth101Config> configs = {};
        for (var item in data) {
          final cfg = Auth101Config(
            id: item['programId'] ?? '',
            name: item['programId'] ?? '',
            approvalReq: item['approvalReq'] == 1,
            isTran: item['isTranPgm'] == 1,
            levels: (item['authLevels'] as List?)?.length ?? 1,
            preApproveProc: item['preApproveProc'] == 1,
            preExecMethod: item['preExecMethod']?.toString(),
            preProcessName: item['preProcessName'],
            postApproveProc: item['postApproveProc'] == 1,
            postExecMethod: item['postExecMethod']?.toString(),
            postProcessName: item['postProcessName'],
          );
          configs[cfg.id] = cfg;
        }
        return configs;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<List<AuthRecord>?> getAuthQueue() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/queue'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AuthRecord.fromJson(json)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
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

  Future<List<Map<String, dynamic>>?> getRoles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/roles'),
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

  Future<List<Map<String, dynamic>>?> getUserRoleAssigns() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user-roles'), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) { return null; }
  }

  Future<List<Map<String, dynamic>>?> getModules() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/modules'), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) { return null; }
  }

  Future<List<Map<String, dynamic>>?> getMenus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/menus'), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) { return null; }
  }

  Future<bool> processAuth(String authSl, String action, int level, String userId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/$action/$authSl?level=$level&userId=$userId'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Administrative CRUD ---

  Future<bool> createUser(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createRole(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/roles'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createModule(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/modules'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createMenu(String subType, Map<String, dynamic> data) async {
    try {
      // subType could be 'program', 'parent', 'sub', 'link'
      final path = subType == 'program' ? 'programs' : subType;
      final res = await http.post(
        Uri.parse('$baseUrl/menus/$path'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> assignUserRole(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/user-roles'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createAuthConfig(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/authctl/create'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

final apiService = ApiService();
