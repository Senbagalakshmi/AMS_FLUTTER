import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'api_service.dart'; // ApiService.baseUrl + apiService singleton

class UserMappingModel {
  final int orgCode;
  final String userScd;
  final int prodCode;
  final int accessCd;
  final String status; // "1" = active, "0" = inactive
  final String? eUser;
  final String? eDate;
  final String? aUser;
  final String? aDate;
  final String? cUser;
  final String? cDate;

  const UserMappingModel({
    required this.orgCode,
    required this.userScd,
    required this.prodCode,
    required this.accessCd,
    required this.status,
    this.eUser,
    this.eDate,
    this.aUser,
    this.aDate,
    this.cUser,
    this.cDate,
  });

  // ── JSON → Model ─────────────────────────────────────────────────────────
  factory UserMappingModel.fromJson(Map<String, dynamic> json) {
    // Helper: extract int from various key-casings
    int _int(List<String> keys, [int fallback = 0]) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) return int.tryParse(v.toString()) ?? fallback;
      }
      return fallback;
    }

    String _str(List<String> keys, [String fallback = '']) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) return v.toString();
      }
      return fallback;
    }

    return UserMappingModel(
      orgCode: _int(['orgCode', 'orgcode', 'ORGCODE'], 50),
      userScd: _str(['userScd', 'userscd', 'USERSCD', 'userCode', 'usercode']),
      prodCode: _int(['prodCode', 'prodcode', 'PRODCODE']),
      accessCd: _int(['accessCd', 'accesscd', 'ACCESSCD']),
      status: _str(['status', 'STATUS'], '1'),
      eUser: json['eUser']?.toString() ?? json['euser']?.toString(),
      eDate: json['eDate']?.toString() ?? json['edate']?.toString(),
      aUser: json['aUser']?.toString() ?? json['auser']?.toString(),
      aDate: json['aDate']?.toString() ?? json['adate']?.toString(),
      cUser: json['cUser']?.toString() ?? json['cuser']?.toString(),
      cDate: json['cDate']?.toString() ?? json['cdate']?.toString(),
    );
  }

  // ── Model → JSON (for POST / PUT) ────────────────────────────────────────
  Map<String, dynamic> toJson({String? currentUser}) {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return {
      'orgCode': orgCode,
      'userScd': userScd,
      'prodCode': prodCode,
      'accessCd': accessCd,
      'status': status,
      'eUser': currentUser ?? eUser ?? 'ADMIN',
      'eDate': eDate ?? now,
      'aUser': aUser,
      'aDate': aDate,
      'cUser': cUser,
      'cDate': cDate,
    };
  }

  // ── Screen-friendly Map (keys match UserAccessScreen _formData) ───────────
  Map<String, dynamic> toScreenMap() => {
        'orgCode': orgCode,
        'userCode': userScd, // screen uses 'userCode'
        'productCode': prodCode.toString(),
        'accessCode': accessCd.toString(),
        'status': int.tryParse(status) ?? 1,
      };
}

class UserMappingService {
  // Base endpoint — appended to ApiService.baseUrl
  static const String _path = '/user-mapping';

  String get _baseUrl => '${ApiService.baseUrl}$_path';
  Map<String, String> get _headers => apiService.headers;

  // ── GET all  →  GET /api/user-mapping ────────────────────────────────────
  Future<List<UserMappingModel>> getAll() async {
    try {
      final res = await http.get(Uri.parse(_baseUrl), headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((e) => UserMappingModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _log('getAll', res);
      return [];
    } catch (e) {
      _err('getAll', e);
      return [];
    }
  }

  // ── GET by userScd  →  GET /api/user-mapping/{userScd} ───────────────────
  Future<List<UserMappingModel>> getByUserScd(String userScd) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/$userScd'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data
            .map((e) => UserMappingModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _log('getByUserScd', res);
      return [];
    } catch (e) {
      _err('getByUserScd', e);
      return [];
    }
  }

  // ── CREATE  →  POST /api/user-mapping ────────────────────────────────────
  // Backend sets orgCode = 50 if null, then routes through authProcedureService
  Future<bool> create(UserMappingModel model, {String? currentUser}) async {
    try {
      final body = model.toJson(currentUser: currentUser);
      final res = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) return true;
      _log('create', res);
      return false;
    } catch (e) {
      _err('create', e);
      return false;
    }
  }

  // ── UPDATE  →  PUT /api/user-mapping ─────────────────────────────────────
  // WHERE ORGCODE = ? AND USERSCD = ?
  Future<bool> update(UserMappingModel model, {String? currentUser}) async {
    try {
      final body = model.toJson(currentUser: currentUser);
      final res = await http.put(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) return true;
      _log('update', res);
      return false;
    } catch (e) {
      _err('update', e);
      return false;
    }
  }

  // ── DELETE  →  DELETE /api/user-mapping/{userScd} ────────────────────────
  Future<bool> delete(String userScd) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/$userScd'),
        headers: _headers,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) return true;
      _log('delete', res);
      return false;
    } catch (e) {
      _err('delete', e);
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _log(String fn, http.Response res) =>
      print('⚠️ UserMappingService.$fn: HTTP ${res.statusCode} — ${res.body}');

  void _err(String fn, Object e) => print('❌ UserMappingService.$fn error: $e');
}

/// Singleton — import this anywhere: `import 'user_mapping_service.dart';`
final userMappingService = UserMappingService();
