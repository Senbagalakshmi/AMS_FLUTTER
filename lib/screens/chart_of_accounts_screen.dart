import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/report_api_service.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../utils/responsive.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const ChartOfAccountsScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    required this.userName,
  });

  @override
  _ChartOfAccountsScreenState createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportApiService _apiService = ReportApiService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _allAccounts = [];
  
  final List<String> _tabs = [
    'All Accounts',
    'Asset',
    'Liability',
    'Equity',
    'Income',
    'Expense'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    setState(() {}); // Re-render the table below based on selected tab
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getChartOfAccounts();
    if (mounted) {
      setState(() {
        _allAccounts = data ?? [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredAccounts {
    final selectedTab = _tabs[_tabController.index];
    if (selectedTab == 'All Accounts') {
      return _allAccounts;
    }
    // Filter by GLCATNAME which usually contains "Asset", "Liability", etc.
    return _allAccounts.where((acc) {
      final type = (acc['accountType'] as String?)?.toLowerCase() ?? '';
      return type.contains(selectedTab.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header matches GL Balance & Trial Balance
          AmsIdentityHeader(
            icon: const Icon(Icons.list_alt_rounded, size: 28, color: AppColors.tBlue),
            title: 'Chart of Accounts',
            subtitle: 'View your organized listing of all accounts in the general ledger.',
            badges: const [],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            onBack: widget.onBackToModule,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(label: 'Transactions', onTap: widget.onBackToModule),
              HeaderBreadcrumb(label: 'Reports'),
              HeaderBreadcrumb(label: 'Chart of Accounts'),
            ],
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border,
                    width: 1.0,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.tBlue,
                unselectedLabelColor: AppColors.ink3,
                indicatorColor: AppColors.tBlue,
                indicatorWeight: 3.0,
                labelStyle: bodyStyle(
                  size: 14,
                  weight: FontWeight.w700,
                ),
                unselectedLabelStyle: bodyStyle(
                  size: 14,
                  weight: FontWeight.w500,
                ),
                tabs: _tabs.map((t) => Tab(text: t, height: 48)).toList(),
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    margin: EdgeInsets.all(Responsive.isMobile(context) ? 12 : 24),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dynamic Title & Filter Button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _tabs[_tabController.index].toUpperCase(),
                                style: bodyStyle(
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              AmsButton(
                                label: 'Filters',
                                icon: Icons.filter_list,
                                variant: AmsButtonVariant.outline,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                        // Data Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.border, width: 1.0),
                            ),
                            color: Color(0xFFF8FAFC),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: _buildColHeader('ACCOUNT / PARENT ACCOUNT')),
                              Expanded(flex: 1, child: _buildColHeader('ACCOUNT NUMBER')),
                              Expanded(flex: 2, child: _buildColHeader('ACCOUNT TYPE / SUB TYPE')),
                              Expanded(flex: 1, child: _buildColHeader('BALANCE', alignRight: true)),
                            ],
                          ),
                        ),
                        // Data List
                        Expanded(
                          child: _filteredAccounts.isEmpty
                              ? const Center(child: Text('No accounts found in this category.'))
                              : ListView.separated(
                                  itemCount: _filteredAccounts.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                                  itemBuilder: (context, index) {
                                    final acc = _filteredAccounts[index];
                                    return _buildAccountRow(acc);
                                  },
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

  Widget _buildColHeader(String title, {bool alignRight = false}) {
    return Text(
      title,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: monoStyle(
        size: 11,
        weight: FontWeight.w700,
        color: AppColors.ink3,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAccountRow(Map<String, dynamic> acc) {
    final formatCurrency = NumberFormat.currency(symbol: 'Rs.', decimalDigits: 2, customPattern: '\u00A4#,##0.00');
    final balance = (acc['balance'] as num?)?.toDouble() ?? 0.0;
    final currency = acc['currency'] ?? 'INR';
    final isNegative = balance < 0;

    return InkWell(
      onHover: (hovering) {
        // Optional: add a subtle hover effect state if desired.
      },
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Account Name
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.purple.shade200),
                      color: Colors.purple.shade50,
                    ),
                    child: Center(
                      child: Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      acc['accountName']?.toString() ?? '',
                      style: bodyStyle(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Account Number
            Expanded(
              flex: 1,
              child: Text(
                acc['accountNumber']?.toString() ?? '',
                style: bodyStyle(
                  size: 14,
                  weight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            // Account Type
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    acc['accountType']?.toString() ?? '',
                    style: bodyStyle(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Standard Account',
                    style: bodyStyle(
                      size: 12,
                      weight: FontWeight.w400,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
            // Balance
            Expanded(
              flex: 1,
              child: Text(
                '${formatCurrency.format(balance.abs())} $currency',
                textAlign: TextAlign.right,
                style: bodyStyle(
                  size: 14,
                  weight: FontWeight.w600,
                  color: isNegative ? Colors.red.shade700 : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
