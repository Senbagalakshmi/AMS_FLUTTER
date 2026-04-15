import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PaginatedResponse {
  final List<Map<String, dynamic>> items;
  final int totalElements;

  PaginatedResponse({
    required this.items,
    required this.totalElements,
  });
}

class ApiService {
  // 🔥 IMPORTANT: change if needed
  // Use 10.0.2.2 for Android Emulator, localhost for Web/Windows/iOS
  static const String baseUrl = "http://localhost:8080/api";
  String? _token;

  void updateToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  // ================= GET =================
  Future<PaginatedResponse?> getProgramMaster({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/programs?page=$page&size=$size"),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        List<Map<String, dynamic>> items = [];
        int total = 0;

        if (data is List) {
          items = List<Map<String, dynamic>>.from(data);
          total = items.length;
        } else if (data is Map) {
          items = List<Map<String, dynamic>>.from(data['content'] ?? data['items'] ?? []);
          total = data['totalElements'] ?? data['total'] ?? items.length;
        }

        return PaginatedResponse(
          items: items,
          totalElements: total,
        );
      } else {
        print("GET ERROR: ${response.body}");
      }
    } catch (e) {
      print("GET EXCEPTION: $e");
    }
    return null;
  }

  // ================= CREATE =================
  Future<bool> createProgram(Map<String, dynamic> data, String user) async {
    try {
      // Safety truncation for VARCHAR(15) columns
      String truncate15(dynamic val) {
        String s = val?.toString() ?? '';
        return s.length > 15 ? s.substring(0, 15) : s;
      }

      final bodyData = {
        "orgcode": data['orgcode'] ?? 50,
        "pgmId": truncate15(data['programId']),
        "descn": truncate15(data['programDescription']),
        "module": int.tryParse(data['moduleCd']?.toString() ?? '0'),
        "subModule": int.tryParse(data['subModuleCd']?.toString() ?? '0') ?? 0,        "pgmClass": data['programClass'] == 'T' ? 2 : 1,
        "status": data['status'],
        "remarks": truncate15(data['remarks']),
        "edate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "primaryKey": truncate15(data['programId']),
        "euser": truncate15(user)
      };

      print("--- PAYLOAD LENGTH DEBUG ---");
      bodyData.forEach((key, value) {
        print("$key: '${value.toString()}' (length: ${value.toString().length})");
      });
      print("----------------------------");

      final body = jsonEncode(bodyData);

      print("CREATE POST Body: $body");

      final response = await http.post(
        Uri.parse("$baseUrl/programs"),
        headers: _headers,
        body: body,
      );

      print("CREATE Status Code: ${response.statusCode}");
      print("CREATE Response: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("CREATE ERROR: $e");
      return false;
    }
  }

  // ================= UPDATE =================
  Future<bool> updateProgram(Map<String, dynamic> data, String user) async {
    try {
      String truncate15(dynamic val) {
        String s = val?.toString() ?? '';
        return s.length > 15 ? s.substring(0, 15) : s;
      }

       final bodyData = {
        "pgmId": truncate15(data['programId']),   
        "orgcode": data['orgcode'],               
        "descn": truncate15(data['programDescription']) ,
        "module": int.tryParse(data['moduleCd']?.toString() ?? '0'),
        "subModule": int.tryParse(data['subModuleCd']?.toString() ?? '0') ?? 0,
        "pgmClass": data['programClass'] == 'T' ? 2 : 1,
        "status": data['status'],
        "remarks": truncate15(data['remarks']),
        "cuser": truncate15(user)
      };
        final body = jsonEncode(bodyData);

      print("UPDATE PUT Body: $body");

      final response = await http.put(
        Uri.parse("$baseUrl/programs"),
        headers: _headers,
        body: body,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("UPDATE ERROR: $e");
      return false;
    }
  }

  // ================= DELETE =================
  Future<bool> deleteProgram(String id, String orgcode, String user) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/programs/$id?orgcode=$orgcode&user=$user"),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print("DELETE ERROR: $e");
      return false;
    }
  }
  Future<List<Map<String, dynamic>>> getModules() async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/programs/modules"),  
      headers: _headers,
    );

    print("Modules API status: ${response.statusCode}");
    print("Modules API body: ${response.body}");

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
  } catch (e) {
    print("Error fetching modules: $e");
  }
  return [];
}

  Future<List<Map<String, dynamic>>> getSubModules(String moduleId) async {
    try {
      // Try first endpoint: /submodules
      String url = "$baseUrl/modules/$moduleId/submodules";
      print("Trying submodules endpoint: $url");
      var response = await http.get(Uri.parse(url), headers: _headers);
      
      // Fallback if 404 or empty
      if (response.statusCode != 200 || response.body == "[]") {
         url = "$baseUrl/modules/$moduleId/subs";
         print("Falling back to subs endpoint: $url");
         response = await http.get(Uri.parse(url), headers: _headers);
      }

      print("Submodules Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<Map<String, dynamic>>((item) {
          final rawItem = Map<String, dynamic>.from(item);
          
          // Prioritize 'sub' in ID detection
          String smId = (rawItem['sub_moduleid'] ?? rawItem['subModuleId'] ?? rawItem['submoduleid'] ?? '').toString();
          if (smId.isEmpty || smId == "null") {
             // Search for keys containing both 'sub' and 'id'
             final subIdKey = rawItem.keys.firstWhere((k) => k.toLowerCase().contains('sub') && k.toLowerCase().contains('id'), orElse: () => '');
             if (subIdKey.isNotEmpty) {
                 smId = rawItem[subIdKey].toString();
             } else {
                 smId = (rawItem['id'] ?? '').toString();
             }
          }

          // Prioritize 'sub' in Name detection
          String smName = (rawItem['sub_modulename'] ?? rawItem['subModuleName'] ?? rawItem['submodulename'] ?? '').toString();
          if (smName.isEmpty || smName == "null") {
             final subNameKey = rawItem.keys.firstWhere((k) => k.toLowerCase().contains('sub') && (k.toLowerCase().contains('name') || k.toLowerCase().contains('descn')), orElse: () => '');
             if (subNameKey.isNotEmpty) {
                 smName = rawItem[subNameKey].toString();
             } else {
                 smName = (rawItem['name'] ?? rawItem['descn'] ?? '').toString();
             }
          }
          
          final displayLabel = (smId.isNotEmpty && smId != "null") ? "$smId - $smName" : smName;
          
          return {
            ...rawItem,
            'id': smId,
            'subModuleId': smId,
            'display': displayLabel,
          };
        }).toList();
      }
    } catch (e) {
      print("Error fetching submodules: $e");
    }
    return [];
  }
}

// ✅ Global instance
final apiService = ApiService();