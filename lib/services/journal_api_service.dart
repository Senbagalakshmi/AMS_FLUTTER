import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class JournalApiService {
  // ─────────────────────────────────────────
  // JOURNAL ENTRY API CALLS
  // ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>?> getJournals() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/journal"),
        headers: apiService.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('JournalApiService.getJournals Error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getJournalDetails(int orgCode, String date, int tranId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/journal/details?orgCode=$orgCode&tranDate=$date&tranId=$tranId"),
        headers: apiService.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('JournalApiService.getJournalDetails Error: $e');
      return null;
    }
  }

  Future<bool> saveJournal(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/journal"),
        headers: apiService.headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('JournalApiService.saveJournal Error: $e');
      return false;
    }
  }
}

final journalApiService = JournalApiService();
