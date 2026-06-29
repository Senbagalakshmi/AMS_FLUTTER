import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

  Future<void> logout() async {
    try {
      final t = _token ?? (kIsWeb ? html.window.sessionStorage['mother_token'] : null);
      if (t != null) {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $t',
          },
        );
      }
    } catch (e) {
      print('Logout API call failed: $e');
    }
    
    _token = null;
    if (kIsWeb) {
      html.window.sessionStorage.clear();
    }
  }

  PaginatedResult<Map<String, dynamic>> _parsePaginated(dynamic decoded) {
    if (decoded is List) {
      // Backend returned a plain array instead of a paginated object.
      // Log a warning so developers can spot inconsistent API responses in runtime logs.
      try {
        print('⚠️ ApiService._parsePaginated: received full-array response (non-paginated). length=${decoded.length}');
      } catch (_) {}
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

  Future<String?> login(String email, String password) async {
    try {
      // ── Step 1: POST /auth/login → get mother_token ───────────────────────
      final loginRes = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':       email,
          'password':    password,
          'productCode': AppConfig.instance.productCode,
        }),
      );

      print('🔑 Login status: ${loginRes.statusCode}');
      print('🔑 Login body: ${loginRes.body}');

      if (loginRes.statusCode != 200) return null;

      final loginData   = jsonDecode(loginRes.body) as Map<String, dynamic>;
      final motherToken = loginData['mother_token'] as String?;
      final userData    = loginData['user']         as Map<String, dynamic>?;

      if (motherToken == null) {
        print('⚠️ No mother_token in login response');
        return null;
      }

      // ── Step 2: POST /am/exchange-token → get child_token ─────────────────
      final host = baseUrl.replaceFirst('/api', '');
      final exchangeRes = await http.post(
        Uri.parse('$host/am/exchange-token'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $motherToken',
        },
        body: jsonEncode({'productCode': AppConfig.instance.productCode}),
      );

      print('🔄 Exchange status: ${exchangeRes.statusCode}');
      print('🔄 Exchange body: ${exchangeRes.body}');

      if (exchangeRes.statusCode != 200) return null;

      final exchangeData = jsonDecode(exchangeRes.body) as Map<String, dynamic>;
      final childToken   = exchangeData['child_token']  as String? ??
                           exchangeData['access_token'] as String? ??
                           exchangeData['token']        as String?;

      if (childToken == null) {
        print('⚠️ No child_token in exchange response');
        return null;
      }

      // ── Update ApiService token so Step 3 call is authenticated ──────────
      updateToken(childToken);

      // ── Step 3: GET /user/get-user → get detailed profile & products ─────
      Map<String, dynamic>? userDetails;
      final userScdRaw = userData?['userScd'] ?? userData?['usersCd'];
      final orgCodeRaw = userData?['orgCode'];
      if (userScdRaw != null) {
        final uCode = userScdRaw.toString() ?? ''; 
        final oCode = orgCodeRaw is int ? orgCodeRaw : int.tryParse(orgCodeRaw?.toString() ?? '0') ?? 0;
        print('👤 Fetching user details (Step 3) for userCode=$uCode, orgCode=$oCode');
        userDetails = await getUserDetails(uCode, oCode);
      } else {
        print('⚠️ No userScd found in login response to fetch user details');
      }

      // Store combined session data for SSO nine-dots navigation
      html.window.sessionStorage['mother_token'] = motherToken;
      html.window.sessionStorage['child_token']  = childToken;

      final finalUser = <String, dynamic>{};
      if (userData != null) {
        finalUser.addAll(Map<String, dynamic>.from(userData));
      }
      if (userDetails != null) {
        finalUser.addAll(userDetails);
      }

      // Ensure products are mapped to session user_data so nine dots works
      if (userDetails != null && userDetails['products'] != null) {
        finalUser['products'] = userDetails['products'];
      } else if (exchangeData['products'] != null) {
        finalUser['products'] = exchangeData['products'];
      } else if (loginData['products'] != null) {
        finalUser['products'] = loginData['products'];
      }

      if (exchangeData['roleType'] != null) {
        finalUser['roleType'] = exchangeData['roleType'];
      }

      html.window.sessionStorage['user_data'] = jsonEncode(finalUser);
      print('💾 Session user_data saved: ${jsonEncode(finalUser)}');

      print('✅ login complete. child_token: ${childToken.substring(0, 20)}...');
      return childToken;
    } catch (e) {
      print('❌ login error: $e');
      return null;
    }
  }

  Future<String?> forgotPasswordRequest(String email) async {
    try {
      final verifyRes = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (verifyRes.statusCode != 200) return null;

      final verifyData = jsonDecode(verifyRes.body);

      final res = await http.post(
        Uri.parse('$baseUrl/auth/generate-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'firstName': verifyData['firstName'],
          'userScd': verifyData['userScd'],
          'orgCode': verifyData['orgCode'],
          'productCode': AppConfig.instance.productCode,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['tokenKey'];
      }
      return null;
    } catch (e) {
      print('Forgot password request error: $e');
      return null;
    }
  }

  Future<bool> forgotPasswordVerify(String tokenKey, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tokenKey': tokenKey, 'otp': otp}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Forgot password verify error: $e');
      return false;
    }
  }

  Future<bool> forgotPasswordReset(
      String tokenKey, String newPassword, String confirmPassword) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tokenKey': tokenKey,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Forgot password reset error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPasswordPolicy() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/auth/get-password-policy'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Get password policy error: $e');
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

            name: (item['description'] ??
                    item['name'] ??
                    item['programId'] ??
                    'Unknown')
                .toString(),
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
            orgCode: (item['orgCode'] ?? item['orgcode']) is num 
                ? (item['orgCode'] ?? item['orgcode']).toInt() 
                : 50,
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
      String authSl, String action, int level, String userId,
      {String? aUser, String? aDate}) async {
    try {
      // Build query params — include aUser & aDate when approving so the
      // backend can stamp them into the target-table record (BRANCH001, etc.)
      String url =
          '$baseUrl/auth/$action/$authSl?level=$level&userId=$userId';
      if (aUser != null && aUser.isNotEmpty) {
        url += '&aUser=${Uri.encodeComponent(aUser)}';
      }
      if (aDate != null && aDate.isNotEmpty) {
        url += '&aDate=${Uri.encodeComponent(aDate)}';
      }
      final res = await http.post(
        Uri.parse(url),
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
      if (data['isUpdate'] == true) {
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
      if (data['isUpdate'] == true) {
        return updateRole(data);
      }
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

  Future<String?> uploadUserPicture(String usersCd, String filename, Uint8List bytes) async {
    try {
      final uri = Uri.parse('$baseUrl/users/$usersCd/picture');
      final request = http.MultipartRequest('POST', uri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      
      String mimeType = 'image/jpeg';
      final ext = filename.toLowerCase();
      if (ext.endsWith('.png')) mimeType = 'image/png';
      else if (ext.endsWith('.gif')) mimeType = 'image/gif';
      else if (ext.endsWith('.webp')) mimeType = 'image/webp';
      
      final splitMime = mimeType.split('/');

      request.files.add(http.MultipartFile.fromBytes(
        'file', // Assuming standard parameter name 'file'
        bytes,
        filename: filename,
        contentType: MediaType(splitMime[0], splitMime[1]),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.trim();
        if (body.startsWith('{')) {
          final decoded = jsonDecode(body);
          return decoded['picture'] ?? decoded['url'] ?? decoded['pictureUrl'] ?? decoded['path'] ?? body;
        }
        return body; 
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<bool> createModule(Map<String, dynamic> data) async {
    try {
      if (data['isUpdate'] == true) {
        return updateModule(data);
      }
      final mappedData = Map<String, dynamic>.from(data);

      // Module Name mapping
      if (data.containsKey('modName')) {
        mappedData['moduleName'] = data['modName'];
        mappedData['modulename'] = data['modName'];
      }
      // Sub Module flag mapping
      if (data.containsKey('subModule')) {
        final val = (data['subModule'] == true || data['subModule'] == 1) ? 1 : 0;
        mappedData['subModuleRequired'] = val;
        mappedData['sub_module'] = val;
        mappedData['submodule'] = val;
      }
      // Organisation Code mapping
      final rawOrg = data['orgcode'] ?? data['orgCode'] ?? data['org_code'];
      if (rawOrg != null) {
        final parsedOrg = int.tryParse(rawOrg.toString());
        if (parsedOrg != null) {
          mappedData['orgcode'] = parsedOrg;
        }
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

      final res = await http.post(
        Uri.parse('$baseUrl/modules'),
        headers: _headers,
        body: jsonEncode(mappedData),
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
      if (data['isUpdate'] == true) {
        return updateAuthConfig(data);
      }
      
      final payload = _normalizeAuthPayload(data);
      
      final res = await http.post(
        Uri.parse('$baseUrl/auth/authctl/create'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      print('AUTHCTL Create response: ${res.statusCode} - ${res.body}');
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('AUTHCTL Create error: $e');
      return false;
    }
  }

  Future<bool> updateAuthConfig(Map<String, dynamic> data) async {
    try {
      final payload = _normalizeAuthPayload(data);
      
      final res = await http.put(
        Uri.parse('$baseUrl/auth/authctl/update'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      print('AUTHCTL Update response: ${res.statusCode} - ${res.body}');
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('AUTHCTL Update error: $e');
      return false;
    }
  }

  Map<String, dynamic> _normalizeAuthPayload(Map<String, dynamic> data) {
    final payload = Map<String, dynamic>.from(data);
    
    // Convert bool to int (Backend requirement)
    final boolKeys = [
      'approvalReq',
      'preApproveProc',
      'postApproveProc',
      'isTran',
      'isTranPgm'
    ];
    
    for (final key in boolKeys) {
      if (payload.containsKey(key)) {
        if (payload[key] == true) {
          payload[key] = 1;
        } else if (payload[key] == false) {
          payload[key] = 0;
        }
      }
    }
    
    // Remove frontend flags
    payload.remove('isUpdate');
    payload.remove('id'); // Usually programId is used
    
    return payload;
  }

  Future<bool> deleteAuthConfig(int orgCode, String programId) async {
  try {
    print('AUTHCTL: Deleting $programId');

    final res = await http.delete(
      Uri.parse('$baseUrl/auth/authctl/delete/$programId/$orgCode'),
      headers: _headers,
    );

    print('AUTHCTL Delete response: ${res.statusCode}');
    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (e) {
    print('AUTHCTL Delete error: $e');
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
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          try {
            print('⚠️ getAllGlCategories: endpoint returned full array -> /gl-category?page=$page&size=$size');
          } catch (_) {}
        }
        return _parsePaginated(decoded);
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

  Future<bool> deleteGlCategory(int orgCode, int glCatCd) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/gl-category/$orgCode/$glCatCd'),
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
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          try {
            print('⚠️ getAllGlMasters: endpoint returned full array -> /gl-master?page=$page&size=$size');
          } catch (_) {}
        }
        return _parsePaginated(decoded);
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

  Future<bool> deleteGlMaster(int orgCode, int glNo) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/gl-master/$orgCode/$glNo'),
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
        Uri.parse('$baseUrl/users/$usersCd?orgcode=$orgCode'),
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
        final val = (data['subModule'] == true || data['subModule'] == 1) ? 1 : 0;
        mappedData['subModuleRequired'] = val;
        mappedData['sub_module'] = val;
        mappedData['submodule'] = val;
      }
      // Organisation Code mapping
      final rawOrg = data['orgcode'] ?? data['orgCode'] ?? data['org_code'];
      if (rawOrg != null) {
        final parsedOrg = int.tryParse(rawOrg.toString());
        if (parsedOrg != null) {
          mappedData['orgcode'] = parsedOrg;
        }
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
      final rawOrg = data['orgcode'] ?? data['orgCode'] ?? data['org_code'];
      if (rawOrg != null) {
        final parsedOrg = int.tryParse(rawOrg.toString());
        if (parsedOrg != null) {
          mappedData['orgcode'] = parsedOrg;
        }
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
  // Endpoint: POST /am/exchange-token (derived from baseUrl)
  //   Header : Authorization: Bearer <mother_token>
  //   Body   : { "productCode": <int> }
  Future<Map<String, dynamic>?> exchangeToken(String motherToken) async {
    try {
      final host = baseUrl.replaceFirst('/api', '');
      final productCode = AppConfig.instance.productCode;

      print('🔄 SSO exchange token calling: $host/am/exchange-token');
      final res = await http.post(
        Uri.parse('$host/am/exchange-token'),
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
  // Endpoint: GET /am/get-user?userCode=<userCode>&orgCode=<orgCode> (uses host without /api)
  //   Header: Authorization: Bearer <child_token>
  Future<Map<String, dynamic>?> getUserDetails(String userCode, int orgCode) async {
    try {
      final host = baseUrl.replaceFirst('/api', '');
      final url = '$host/am/get-user?userCode=$userCode&orgCode=$orgCode';
      print('🌐 Fetching User Details GET $url');

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

  // --- Reports ---
  Future<List<Map<String, dynamic>>?> getChartOfAccountsReport() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/chart-of-accounts'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map) {
          if (decoded['items'] is List) {
             return List<Map<String, dynamic>>.from(decoded['items']);
          } else if (decoded['data'] is List) {
             return List<Map<String, dynamic>>.from(decoded['data']);
          } else if (decoded['content'] is List) {
             return List<Map<String, dynamic>>.from(decoded['content']);
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

final apiService = ApiService();
