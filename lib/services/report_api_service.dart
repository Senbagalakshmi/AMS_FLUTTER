import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ReportApiService {

  final ApiService apiService = ApiService();

  Future<List<Map<String, dynamic>>?> getFinancialReport({
    required String reportType,
    required String date,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/reports/financial-report'
        '?reportType=$reportType&date=$date',
      );

      final response = await http.get(
        uri,
        headers: apiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('getFinancialReport Error: $e');
    }

    return null;
  }

  Future<List<Map<String, dynamic>>?> getTrialBalance(String date) {
    return getFinancialReport(
      reportType: "TB",
      date: date,
    );
  }

  Future<List<Map<String, dynamic>>?> getProfitLoss(String date) {
    return getFinancialReport(
      reportType: "PL",
      date: date,
    );
  }

  Future<List<Map<String, dynamic>>?> getBalanceSheet(String date) {
    return getFinancialReport(
      reportType: "BS",
      date: date,
    );
  }

  // ✅ FIXED: Now inside class + correct baseUrl usage
  Future<dynamic> getChartOfAccounts() async {
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/chart-of-accounts',
      );

      final response = await http.get(
        uri,
        headers: apiService.headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Failed to load chart of accounts: ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("getChartOfAccounts Error: $e");
    }
  }
}