import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../config/app_config.dart';

class PaginatedResult<T> {
  final List<T> items;
  final int totalElements;

  PaginatedResult({required this.items, required this.totalElements});
}

class ApiService {
  /// Finance backend base URL — read from config.json via AppConfig.
  /// Static so other services can access it as ApiService.baseUrl.
  static String get baseUrl => AppConfig.instance.baseUrl;
  String? _token;

  void updateToken(String? newToken) {
    _token = newToken;
  }

  String? get token => _token;
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Map<String, String> get headers => _headers;

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
          int parsedLevels = 1;
          if (item['authLevels'] is num) {
            parsedLevels = (item['authLevels'] as num).toInt();
          } else if (item['authLevels'] is List) {
            parsedLevels = (item['authLevels'] as List).length;
          }
          final cfg = Auth101Config(
            id: item['programId']?.toString() ?? '',
            name: item['programId']?.toString() ?? '',
            approvalReq:
                item['approvalReq'] == 1 || item['approvalReq'] == true,
            isTran: item['isTranPgm'] == 1 || item['isTranPgm'] == true,
            levels: parsedLevels,
            preApproveProc:
                item['preApproveProc'] == 1 || item['preApproveProc'] == true,
            preExecMethod: item['preExecMethod']?.toString(),
            preProcessName: item['preProcessName']?.toString(),
            postApproveProc:
                item['postApproveProc'] == 1 || item['postApproveProc'] == true,
            postExecMethod: item['postExecMethod']?.toString(),
            postProcessName: item['postProcessName']?.toString(),
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

  Future<PaginatedResult<AuthRecord>?> getAuthQueue(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/queue?page=$page&size=$size'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return PaginatedResult(
            items: decoded.map((e) => AuthRecord.fromJson(e)).toList(),
            totalElements: decoded.length,
          );
        } else if (decoded is Map && decoded.containsKey('content')) {
          final List<dynamic> content = decoded['content'] ?? [];
          return PaginatedResult(
            items: content.map((e) => AuthRecord.fromJson(e)).toList(),
            totalElements: decoded['totalElements'] ?? content.length,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>?> getUsers(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users?page=$page&size=$size'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>?> getRoles(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/access?page=$page&size=$size'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>?> getUserRoleAssigns(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/user-roles?page=$page&size=$size'),
          headers: _headers);
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>?> getModules(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/modules?page=$page&size=$size'),
          headers: _headers);
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSubModules(String moduleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/modules/$moduleId/subs'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error fetching submodules: $e');
    }
    return [];
  }

  Future<PaginatedResult<Map<String, dynamic>>?> getMenus(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/menus?page=$page&size=$size'),
          headers: _headers);
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>?> getProgramMaster(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/menus/programs?page=$page&size=$size'),
          headers: _headers);
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>?> getParentMenus(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/menus/parent?page=$page&size=$size'),
          headers: _headers);
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>?> getSubMenus(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/menus/submenu?page=$page&size=$size'),
          headers: _headers);
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PaginatedResult<Map<String, dynamic>>?> getMenuPrograms(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/menus/items?page=$page&size=$size'),
          headers: _headers);
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> processAuth(
      String authSl, String action, int level, String userId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/$action/$authSl?level=$level&userId=$userId'),
        headers: _headers,
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestCorrection(
      String authSl, int level, String userId, String remarks) async {
    try {
      final res = await http.post(
        Uri.parse(
            '$baseUrl/auth/correction/$authSl?level=$level&userId=$userId&remarks=${Uri.encodeComponent(remarks)}'),
        headers: _headers,
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<int> updateAuthLock(String authSl, String userId) async {
    try {
      print('🔒 Sending lock request for AuthSl: $authSl (User: $userId)');
      final res = await http.post(
        Uri.parse('$baseUrl/auth/lock/$authSl?userId=$userId'),
        headers: _headers,
      );
      print('🔓 Lock response: ${res.statusCode}');
      return res.statusCode;
    } catch (e) {
      print('❌ Lock error: $e');
      return 500;
    }
  }

  // --- Administrative CRUD ---

  Future<bool> createUser(Map<String, dynamic> data) async {
    try {
      if (data['isUpdate'] == true ||
          data.containsKey('usersCd') ||
          data.containsKey('userScd')) {
        return updateUser(data);
      }
      final res = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createRole(Map<String, dynamic> data) async {
    try {
      // if (data['isUpdate'] == true || data.containsKey('accessCd')) {
      //   return updateRole(data);
      // }
      final res = await http.post(
        Uri.parse('$baseUrl/access'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRole(Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/access'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUser(Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createModule(Map<String, dynamic> data) async {
    try {
      if (data['isUpdate'] == true ||
          data.containsKey('moduleId') ||
          data.containsKey('module_id') ||
          data.containsKey('moduleid')) {
        return updateModule(data);
      }
      final res = await http.post(
        Uri.parse('$baseUrl/modules'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createMenu(String subType, Map<String, dynamic> data) async {
    try {
      final path = subType == 'program' ? 'programs' : subType;
      final res = await http.post(
        Uri.parse('$baseUrl/menus/$path'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createProgramMaster(Map<String, dynamic> data) =>
      createMenu('program', data);
  Future<bool> createParentMenu(Map<String, dynamic> data) =>
      createMenu('parent', data);
  Future<bool> createSubMenu(Map<String, dynamic> data) =>
      createMenu('submenu', data);
  Future<bool> createMenuProgram(Map<String, dynamic> data) =>
      createMenu('items', data);

  Future<bool> assignUserRole(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/user-roles'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
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
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // --- GL Category ---

  Future<PaginatedResult<Map<String, dynamic>>?> getAllGlCategories(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gl-category?page=$page&size=$size'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getGlCategoryById(int glCatCd) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gl-category/$glCatCd'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print("getGlCategoryById error: $e");
      return null;
    }
  }

  Future<bool> createGlCategory(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/gl-category'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteGlCategory(int glCatCd) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/gl-category/$glCatCd'),
        headers: _headers,
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateGlCategory(int glCatCd, Map<String, dynamic> data) async {
    try {
      print('🚀 Updating GL Category $glCatCd with data: ${jsonEncode(data)}');
      final res = await http.put(
        Uri.parse('$baseUrl/gl-category'),
        headers: _headers,
        body: jsonEncode(data),
      );
      print('📥 Response Code: ${res.statusCode}');
      if (res.body.isNotEmpty) print('📥 Response Body: ${res.body}');
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('❌ updateGlCategory error: $e');
      return false;
    }
  }

  // --- GL Master ---

  Future<PaginatedResult<Map<String, dynamic>>?> getAllGlMasters(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gl-master?page=$page&size=$size'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getGlMasterByGlNo(int glNo) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gl-master/$glNo'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print("getGlMasterByGlNo error: $e");
      return null;
    }
  }

  Future<bool> createGlMaster(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/gl-master'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print("createGlMaster error: $e");
      return false;
    }
  }

  Future<bool> updateGlMaster(Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/gl-master'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print("updateGlMaster error: $e");
      return false;
    }
  }

  Future<bool> deleteGlMaster(int glNo) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/gl-master/$glNo'),
        headers: _headers,
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print("deleteGlMaster error: $e");
      return false;
    }
  }

  Future<bool> deleteAccess(int orgCode, int accessCd) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/access/$orgCode/$accessCd'),
        headers: _headers,
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(int orgCode, String usersCd) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/users/$orgCode/$usersCd'),
        headers: _headers,
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteModule(String moduleCd) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/modules/$moduleCd'),
        headers: _headers,
      );
      if (res.statusCode == 200) return true;
      print('Delete failed: ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }

  Future<bool> updateModule(Map<String, dynamic> data) async {
    try {
      final mappedData = Map<String, dynamic>.from(data);

      // Module Name mapping
      if (data.containsKey('modName')) {
        mappedData['moduleName'] = data['modName'];
        mappedData['modulename'] = data['modName'];
      }
      // Sub Module flag mapping
      if (data.containsKey('subModule')) {
        mappedData['subModuleRequired'] = data['subModule'];
        mappedData['sub_module'] = data['subModule'];
        mappedData['submodule'] = data['subModule'];
      }
      // Organisation Code mapping
      if (data.containsKey('orgCode')) {
        mappedData['orgcode'] = data['orgCode'];
      }

      // Module ID Identification (Check various possible keys)
      final rawMid = data['modCd'] ??
          data['moduleId'] ??
          data['module_id'] ??
          data['moduleid'] ??
          data['modcd'];
      final midInt = int.tryParse(rawMid.toString()) ?? 0;

      if (midInt != 0) {
        mappedData['moduleId'] = midInt;
        mappedData['module_id'] = midInt;
        mappedData['moduleid'] = midInt;
        mappedData['modcd'] = midInt;
        mappedData['modCd'] = midInt;
      }

      final res = await http.put(
        Uri.parse('$baseUrl/modules'),
        headers: _headers,
        body: jsonEncode(mappedData),
      );

      // Handle sub-modules if present
      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          midInt != 0 &&
          data.containsKey('subModules')) {
        try {
          final List<dynamic> subs = data['subModules'];
          for (var sm in subs) {
            if (sm is Map<String, dynamic>) {
              await updateSubModule(midInt.toString(), sm);
            }
          }
        } catch (e) {
          print('Sub-module update error (continuing): $e');
        }
      }

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Update error: $e');
      return false;
    }
  }

  Future<bool> updateSubModule(
      String moduleId, Map<String, dynamic> data) async {
    try {
      final mappedData = Map<String, dynamic>.from(data);

      // 1. Map Organisation Code
      if (data.containsKey('orgCode')) {
        mappedData['orgcode'] = data['orgCode'];
      }

      // 2. Map Module ID
      mappedData['moduleId'] = int.tryParse(moduleId) ?? 0;
      mappedData['module_id'] = int.tryParse(moduleId) ?? 0;

      // 3. Map Sub Module Name (Aggressively overwrite all variants)
      if (data.containsKey('subModuleName')) {
        final newName = data['subModuleName'];
        mappedData['subModuleName'] = newName;
        mappedData['sub_modulename'] = newName;
        mappedData['sub_module_name'] = newName;
        mappedData['SUB_MODULENAME'] =
            newName; // Direct match for DB column case
        mappedData['submodulename'] = newName;
      }

      // 4. Map Sub Module ID
      final rawSmid = data['subModuleId'] ??
          data['sub_moduleid'] ??
          data['submodule_id'] ??
          data['SUB_MODULEID'] ??
          data['submoduleid'];
      if (rawSmid != null) {
        final smid = int.tryParse(rawSmid.toString()) ?? 0;
        mappedData['subModuleId'] = smid;
        mappedData['sub_moduleid'] = smid;
        mappedData['submodule_id'] = smid;
        mappedData['SUB_MODULEID'] = smid; // Direct match for DB column case
        mappedData['submoduleid'] = smid;
      }

      final res = await http.put(
        Uri.parse('$baseUrl/modules/$moduleId/subs'),
        headers: _headers,
        body: jsonEncode(mappedData),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  // ── SSO: Exchange mother token → child token ──────────────────────────────
  // AM endpoint: POST <amBaseUrl>/exchange/exchange-token  (from config.json)
  //   Header : Authorization: Bearer <mother_token>
  //   Body   : { "productCode": <int> }
  Future<Map<String, dynamic>?> exchangeToken(String motherToken) async {
    try {
      final amBaseUrl = AppConfig.instance.amBaseUrl;
      final productCode = AppConfig.instance.productCode;

      final res = await http.post(
        Uri.parse('$amBaseUrl/exchange/exchange-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $motherToken',
        },
        body: jsonEncode({'productCode': productCode}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      print('⚠️ exchangeToken: HTTP ${res.statusCode} — ${res.body}');
      return null;
    } catch (e) {
      print('❌ exchangeToken error: $e');
      return null;
    }
  }

  // ── Get full user profile after SSO exchange ───────────────────────────────
  // AM endpoint: GET <amBaseUrl>/user/get-user/?userCode=<userCode>&orgCode=<orgCode>
  //   Header: Authorization: Bearer <child_token>
  Future<Map<String, dynamic>?> getUserDetails(int userCode, int orgCode) async {
    try {
      final amBaseUrl = AppConfig.instance.amBaseUrl;
      final url = '$amBaseUrl/user/get-user/?userCode=$userCode&orgCode=$orgCode';
      print('🌐 GET $url');

      final res = await http.get(
        Uri.parse(url),
        headers: _headers, // includes Authorization: Bearer <child_token>
      );

      print('🔍 get-user status: ${res.statusCode}');
      print('🔍 get-user response: ${res.body}');

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      print('⚠️ getUserDetails: HTTP ${res.statusCode} — ${res.body}');
      return null;
    } catch (e) {
      print('❌ getUserDetails error: $e');
      return null;
    }
  }
}

final apiService = ApiService();
