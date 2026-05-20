import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/report_api_service.dart';
import '../utils/responsive.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class TrialBalanceScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const TrialBalanceScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  final ReportApiService _apiService = ReportApiService();

  bool _loading = true;

  String _dateRange = 'This Month';

  List<Map<String, dynamic>> _reportData = [];

  double _totalDebit = 0.0;
  double _totalCredit = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    setState(() => _loading = true);

    String dateParam = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final data = await _apiService.getFinancialReport(
      reportType: "TB",
      date: dateParam,
    );

    if (!mounted) return;

    setState(() {
      _reportData = data ?? [];
      _calculateTotals();
      _loading = false;
    });
  }

  // ================= TOTAL CALCULATION =================
  void _calculateTotals() {
    double dr = 0;
    double cr = 0;

    for (var acc in _reportData) {
      dr += (acc['debit'] ?? 0).toDouble();
      cr += (acc['credit'] ?? 0).toDouble();
    }

    _totalDebit = dr;
    _totalCredit = cr;
  }

  // ================= FORMAT AMOUNT =================
  String _formatAmount(double amount) {
    if (amount == 0) return '-';
    return NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  // ================= GET ACCOUNT NAME =================
  String _getAccountName(Map<String, dynamic> acc) {
    if (acc['glname'] != null && acc['glname'].toString().isNotEmpty) return acc['glname'].toString();
    if (acc['gl_name'] != null && acc['gl_name'].toString().isNotEmpty) return acc['gl_name'].toString();
    if (acc['accountName'] != null && acc['accountName'].toString().isNotEmpty) return acc['accountName'].toString();
    if (acc['account_name'] != null && acc['account_name'].toString().isNotEmpty) return acc['account_name'].toString();
    if (acc['name'] != null && acc['name'].toString().isNotEmpty) return acc['name'].toString();
    
    // Debug info: if all else fails, show the keys that are actually present
    return 'Keys: ${acc.keys.join(", ")}';
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // HEADER
          AmsIdentityHeader(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1967D2), // Match the blue from the image
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.balance_rounded, size: 28, color: Colors.white),
            ),
            title: 'Trial Balance',
            subtitle: 'View account balances and verify debit vs credit equality.',
            badges: const [], // Empty badges since we use actions instead
            accentColor: Colors.black, // Title color in image is very dark
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            onBack: widget.onBackToModule,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(label: 'Reports'),
              HeaderBreadcrumb(label: 'Trial Balance'),
            ],
            actions: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(_dateRange),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1967D2),
                  side: const BorderSide(color: Color(0xFF1967D2)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),

          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: Responsive.isMobile(context) ? 12 : 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // TOP BAR
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                "Accounts",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text("Refresh"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1967D2),
                                  side: const BorderSide(color: Color(0xFF1967D2)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              )
                            ],
                          ),
                        ),

                        // TABLE HEADER
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          color: const Color(0xFFF4F7FB),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text("ACCOUNT",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text("DEBIT",
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text("CREDIT",
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),

                        // DATA LIST
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: _reportData.asMap().entries.map((entry) {
                                final acc = entry.value;
                                final isLast = entry.key == _reportData.length - 1;
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 24),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              _getAccountName(acc),
                                              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              _formatAmount(
                                                  (acc['debit'] ?? 0)
                                                      .toDouble()),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              _formatAmount(
                                                  (acc['credit'] ?? 0)
                                                      .toDouble()),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isLast)
                                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // TOTAL
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.border),
                            ),
                            color: Color(0xFFF0F7FF),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                flex: 3,
                                child: Text(
                                  "TOTAL",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  _formatAmount(_totalDebit),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Color(0xFF1E293B)),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  _formatAmount(_totalCredit),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Color(0xFF1E293B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

