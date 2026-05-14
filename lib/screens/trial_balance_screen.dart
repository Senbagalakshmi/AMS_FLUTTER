import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/report_api_service.dart';

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

  void _calculateTotals() {
    double dr = 0;
    double cr = 0;
    for (var group in _reportData) {
      for (var acc in group['accounts']) {
        dr += (acc['debit'] ?? 0.0);
        cr += (acc['credit'] ?? 0.0);
      }
    }
    _totalDebit = dr;
    _totalCredit = cr;
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    String? dateParam;
    if (_dateRange == 'Today') {
      dateParam = DateFormat('yyyy-MM-dd').format(DateTime.now());
    } else {
      dateParam = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    final data = await _apiService.getTrialBalance(date: dateParam);
    
    if (mounted) {
      setState(() {
        if (data != null) {
          _reportData = data;
        } else {
          _reportData = [];
        }
        _calculateTotals();
        _loading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '-';
    return NumberFormat.currency(symbol: '₹', customPattern: '¤#,##,##0.00').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Header matches GL Balance
          AmsIdentityHeader(
            icon: const Icon(Icons.balance_rounded, size: 28, color: AppColors.tBlue),
            title: 'Trial Balance',
            subtitle: 'View your account balances and verify that total debits equal total credits.',
            badges: [
              AmsBadge(label: _dateRange, color: AppColors.tBlue),
            ],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            onBack: widget.onBackToModule,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(label: 'Transactions', onTap: widget.onBackToModule),
              HeaderBreadcrumb(label: 'Reports'),
              HeaderBreadcrumb(label: 'Trial Balance'),
            ],
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Action / Filter Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: AmsDropdown(
                            items: const ['Today', 'This Week', 'This Month', 'This Quarter', 'This Year', 'Custom'],
                            initialValue: _dateRange,
                            onChanged: (v) {
                              if (v != null) setState(() => _dateRange = v);
                              _loadData();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        AmsButton(
                          label: 'Customize Report',
                          icon: Icons.tune_rounded,
                          variant: AmsButtonVariant.outline,
                          onPressed: () {},
                        ),
                        const Spacer(),
                        AmsButton(
                          label: 'Print',
                          icon: Icons.print_rounded,
                          variant: AmsButtonVariant.ghost,
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                        AmsButton(
                          label: 'Export As',
                          icon: Icons.file_download_outlined,
                          variant: AmsButtonVariant.outline,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // Report Body
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 48),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Report Title
                                Text(
                                  'TRIAL BALANCE',
                                  textAlign: TextAlign.center,
                                  style: bodyStyle(size: 24, weight: FontWeight.w700, color: AppColors.ink),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'As of ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                                  textAlign: TextAlign.center,
                                  style: bodyStyle(size: 14, color: AppColors.ink3),
                                ),
                                const SizedBox(height: 32),

                                // Report Table
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    children: [
                                      // Table Header
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: AppColors.border)),
                                          color: Color(0xFFF8FAFC),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(flex: 3, child: Text('ACCOUNT', style: monoStyle(size: 11, weight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.5))),
                                            Expanded(flex: 1, child: Text('DEBIT', textAlign: TextAlign.right, style: monoStyle(size: 11, weight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.5))),
                                            Expanded(flex: 1, child: Text('CREDIT', textAlign: TextAlign.right, style: monoStyle(size: 11, weight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 0.5))),
                                          ],
                                        ),
                                      ),
                                      
                                      // Groups
                                      ..._reportData.map((group) {
                                        double groupDebit = group['accounts'].fold(0.0, (sum, acc) => sum + acc['debit']);
                                        double groupCredit = group['accounts'].fold(0.0, (sum, acc) => sum + acc['credit']);
                                        
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            // Group Header
                                            Container(
                                              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
                                              child: Text(
                                                group['group'].toUpperCase(),
                                                style: bodyStyle(size: 13, weight: FontWeight.w700, color: AppColors.ink),
                                              ),
                                            ),
                                            // Accounts
                                            ...group['accounts'].map<Widget>((acc) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 3,
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(left: 16),
                                                        child: Text(acc['name'], style: bodyStyle(size: 13, color: AppColors.ink)),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Text(_formatAmount(acc['debit']), textAlign: TextAlign.right, style: bodyStyle(size: 13, color: AppColors.ink)),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Text(_formatAmount(acc['credit']), textAlign: TextAlign.right, style: bodyStyle(size: 13, color: AppColors.ink)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            // Group Total
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                              margin: const EdgeInsets.only(left: 16),
                                              decoration: const BoxDecoration(
                                                border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text('Total for ${group['group']}', style: bodyStyle(size: 12, weight: FontWeight.w600, color: AppColors.ink2)),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: Text(_formatAmount(groupDebit), textAlign: TextAlign.right, style: bodyStyle(size: 13, weight: FontWeight.w600, color: AppColors.ink2)),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: Text(_formatAmount(groupCredit), textAlign: TextAlign.right, style: bodyStyle(size: 13, weight: FontWeight.w600, color: AppColors.ink2)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        );
                                      }),
                                      
                                      // Grand Total
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                        decoration: const BoxDecoration(
                                          border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
                                          color: Color(0xFFF8FAFC),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(flex: 3, child: Text('TOTAL', style: bodyStyle(size: 14, weight: FontWeight.w800, color: AppColors.ink))),
                                            Expanded(flex: 1, child: Text(_formatAmount(_totalDebit), textAlign: TextAlign.right, style: bodyStyle(size: 14, weight: FontWeight.w800, color: AppColors.ink))),
                                            Expanded(flex: 1, child: Text(_formatAmount(_totalCredit), textAlign: TextAlign.right, style: bodyStyle(size: 14, weight: FontWeight.w800, color: AppColors.ink))),
                                          ],
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
            ),
          ),
        ],
      ),
    );
  }
}
