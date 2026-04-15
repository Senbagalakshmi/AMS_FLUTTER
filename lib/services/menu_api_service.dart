import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class MenuApiService {
  static const String baseUrl = ApiService.baseUrl;
  String? _token;

  void updateToken(String? newToken) {
    _token = newToken;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

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

  // --- GETTERS ---

  Future<PaginatedResult<Map<String, dynamic>>?> getParentMenus(
      {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/menus/menu'),
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
          Uri.parse('$baseUrl/menus/submenu'),
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
      {int page = 0, int size = 1000}) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/menus/pgm'),
          headers: _headers);
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper for programs list (dropdowns)
  Future<PaginatedResult<Map<String, dynamic>>?> getProgramMaster(
      {int page = 0, int size = 1000}) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/programs'),
          headers: _headers);
      if (response.statusCode == 200) {
        return _parsePaginated(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- MUTATIONS ---

  // Generic wrapper for main.dart or legacy calls
  Future<bool> createMenu(String subType, Map<String, dynamic> data) async {
    if (subType == 'program' || subType == 'menu' || subType == 'parent') {
      return createParentMenu(data);
    } else if (subType == 'submenu') {
      return createSubMenu(data);
    } else if (subType == 'items' || subType == 'pgm_Id') {
      return createMenuProgram(data);
    }
    return false;
  }

  Future<bool> createParentMenu(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/menus/menu'),
        headers: _headers,
        body: jsonEncode({
          'orgCode': data['orgCode'] ?? 50,
          'menuCode': data['menuCode'],
          'menu_Descn': data['menuDescn'],
          'menu_Order': data['menuOrder'],
          'subMenuReq': data['subMenuReq'],
          'parentMenu_PgmId': data['pgmId'],
          'program_Path': data['programPath'],
          'menu_Logo': data['menuLogo'],
          'menu_Location': data['menuLocation'],
          'menu_Status': data['menuStatus'],
          'eUser': data['eUser'],
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createSubMenu(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/menus/submenu'),
        headers: _headers,
        body: jsonEncode({
          'orgCode': data['orgCode'] ?? 50,
          'menuCode': data['menuCode'],
          'subMenuCode': data['subMenuCode'],
          'description': data['description'],
          'menu_Order': data['menuOrder'],
          'subMenu_PgmId': data['subMenuPgmId'],
          'program_Path': data['programPath'],
          'menu_Logo': data['menuLogo'],
          'menu_Status': data['menuStatus'],
          'eUser': data['eUser'],
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createMenuProgram(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/menus/pgm_Id'),
        headers: _headers,
        body: jsonEncode({
          'orgCode': data['orgCode'] ?? 50,
          'menuCode': data['menuCode'],
          'subMenuCode': data['subMenuCode'],
          'pgm_Id': data['pgmId'],
          'description': data['description'],
          'menu_Order': data['menuOrder'],
          'program_Path': data['programPath'],
          'menu_Logo': data['menuLogo'],
          'status': data['status'],
          'eUser': data['eUser'],
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateParentMenu(Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/menus/updatemenu'),
        headers: _headers,
        body: jsonEncode({
          'orgCode': data['orgCode'] ?? 50,
          'menuCode': data['menuCode'],
          'menu_Descn': data['menuDescn'],
          'menu_Order': data['menuOrder'],
          'subMenuReq': data['subMenuReq'],
          'parentMenu_PgmId': data['pgmId'],
          'program_Path': data['programPath'],
          'menu_Logo': data['menuLogo'],
          'menu_Location': data['menuLocation'],
          'menu_Status': data['menuStatus'],
          'cUser': data['eUser'],
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateSubMenu(Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/menus/updateSubMenu'),
        headers: _headers,
        body: jsonEncode({
          'orgCode': data['orgCode'] ?? 50,
          'menuCode': data['menuCode'],
          'subMenuCode': data['subMenuCode'],
          'description': data['description'],
          'menu_Order': data['menuOrder'],
          'subMenu_PgmId': data['subMenuPgmId'],
          'program_Path': data['programPath'],
          'menu_Logo': data['menuLogo'],
          'menu_Status': data['menuStatus'],
          'cUser': data['eUser'],
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMenuProgram(Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/menus/updatepgmId'),
        headers: _headers,
        body: jsonEncode({
          'orgCode': data['orgCode'] ?? 50,
          'menuCode': data['menuCode'],
          'subMenuCode': data['subMenuCode'],
          'pgm_Id': data['pgmId'],
          'description': data['description'],
          'menu_Order': data['menuOrder'],
          'program_Path': data['programPath'],
          'menu_Logo': data['menuLogo'],
          'status': data['status'],
          'cUser': data['eUser'],
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteParentMenu(int menuCode) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/menus/menu/$menuCode'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSubMenu(int subMenuCode) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/menus/submenu/$subMenuCode'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMenuProgram(String pgmId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/menus/$pgmId'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

final menuApiService = MenuApiService();
