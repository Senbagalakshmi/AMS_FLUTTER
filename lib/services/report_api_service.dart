import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ReportApiService {

  // =========================
  // FINANCIAL REPORTS
  // =========================
  Future<List<Map<String, dynamic>>?> getFinancialReport({
    required String reportType,
    required String date,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/reports/financial-report'
        '?reportType=$reportType&date=$date'
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

  // =========================
  // CHART OF ACCOUNTS (NEW)
  // =========================
  Future<List<Map<String, dynamic>>?> getChartOfAccounts() async {
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/reports/chart-of-accounts'
      );

      final response = await http.get(
        uri,
        headers: apiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('COA Error: ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      print('getChartOfAccounts Error: $e');
    }

    return null;
  }

  // =========================
  // HELPERS
  // =========================
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
}