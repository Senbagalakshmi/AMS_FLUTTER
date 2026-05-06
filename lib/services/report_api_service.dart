import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ReportApiService {
  Future<List<Map<String, dynamic>>?> getTrialBalance({String? date}) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/reports/trial-balance${date != null ? '?date=$date' : ''}');
      final response = await http.get(uri, headers: apiService.headers);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('ReportApiService.getTrialBalance Error: $e');
    }
    return null;
  }
}
