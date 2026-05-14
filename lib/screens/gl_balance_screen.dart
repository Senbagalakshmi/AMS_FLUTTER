import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/gl_api_service.dart';
import 'package:intl/intl.dart';
import '../utils/responsive.dart';

class GLBalanceScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const GLBalanceScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<GLBalanceScreen> createState() => _GLBalanceScreenState();
}

class _GLBalanceScreenState extends State<GLBalanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GLApiService _apiService = GLApiService();
  
  bool _loading = false;
  String _searchQuery = '';
  
  // Data lists for each tab
  List<Map<String, dynamic>> _currentBalances = [];
  List<Map<String, dynamic>> _dateWiseBalances = [];
  List<Map<String, dynamic>> _yearlyBalances = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    // Mocking data for now as per the tables GL001, GL002, GL003
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      setState(() {
        _currentBalances = [
          {'ORGCODE': 50, 'GLNO': 101001, 'BRNCD': 1, 'CURR': 'INR', 'BAL': 1500000.00, 'BCURR': 'INR', 'BCBAL': 1500000.00, 'EUSER': 'ADMIN', 'EDATE': '2026-04-24'},
          {'ORGCODE': 50, 'GLNO': 101002, 'BRNCD': 1, 'CURR': 'USD', 'BAL': 5000.00, 'BCURR': 'INR', 'BCBAL': 415000.00, 'EUSER': 'ADMIN', 'EDATE': '2026-04-24'},
        ];
        _dateWiseBalances = [
          {'ORGCODE': 50, 'GLNO': 101001, 'BRNCD': 1, 'BALDATE': '2026-04-23', 'CURR': 'INR', 'BAL': 1480000.00, 'BCURR': 'INR', 'BCBAL': 1480000.00},
          {'ORGCODE': 50, 'GLNO': 101001, 'BRNCD': 1, 'BALDATE': '2026-04-22', 'CURR': 'INR', 'BAL': 1450000.00, 'BCURR': 'INR', 'BCBAL': 1450000.00},
        ];
        _yearlyBalances = [
          {'ORGCODE': 50, 'GLNO': 101001, 'BRNCD': 1, 'YEAR': 2024, 'CURR': 'INR', 'OPBAL': 1200000.00, 'CLBAL': 1500000.00, 'BCURR': 'INR'},
          {'ORGCODE': 50, 'GLNO': 101001, 'BRNCD': 1, 'YEAR': 2023, 'CURR': 'INR', 'OPBAL': 1000000.00, 'CLBAL': 1200000.00, 'BCURR': 'INR'},
        ];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.account_balance_rounded, size: 28, color: AppColors.tBlue),
            title: 'GL Balance Inquiry',
            subtitle: 'Monitor real-time and historical financial ledger balances',
            badges: [
              AmsBadge(label: '${_currentBalances.length} Active Accounts', color: AppColors.green),
            ],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            onBack: widget.onBackToModule,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(label: 'GL Module', onTap: widget.onBackToModule),
              HeaderBreadcrumb(label: 'GL Balance'),
            ],
          ),
          
          Expanded(
            child: Container(
              margin: EdgeInsets.all(Responsive.isMobile(context) ? 12 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  // Tab Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final isMobile = Responsive.isMobile(context);
                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              labelColor: AppColors.tBlue,
                              unselectedLabelColor: AppColors.ink3,
                              indicatorColor: AppColors.tBlue,
                              indicatorWeight: 3,
                              labelStyle: bodyStyle(weight: FontWeight.w700, size: 13),
                              tabs: const [
                                Tab(text: 'Current Balance'),
                                Tab(text: 'History'),
                                Tab(text: 'Yearly Summary'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AmsTextInput(
                                    placeholder: 'Search GL No...',
                                    icon: Icons.search_rounded,
                                    onChanged: (v) => setState(() => _searchQuery = v),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AmsButton(
                                  label: '',
                                  icon: Icons.refresh_rounded,
                                  variant: AmsButtonVariant.outline,
                                  onPressed: _loadData,
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: AppColors.tBlue,
                            unselectedLabelColor: AppColors.ink3,
                            indicatorColor: AppColors.tBlue,
                            indicatorWeight: 3,
                            labelStyle: bodyStyle(weight: FontWeight.w700, size: 14),
                            tabs: const [
                              Tab(text: 'Current Balance (GL001)'),
                              Tab(text: 'Date-wise History (GL002)'),
                              Tab(text: 'Yearly Summary (GL003)'),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 250,
                            child: AmsTextInput(
                              placeholder: 'Search GL No...',
                              icon: Icons.search_rounded,
                              onChanged: (v) => setState(() => _searchQuery = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AmsButton(
                            label: 'Refresh',
                            icon: Icons.refresh_rounded,
                            variant: AmsButtonVariant.outline,
                            onPressed: _loadData,
                          ),
                        ],
                      );
                    }),
                  ),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCurrentTab(),
                        _buildDateWiseTab(),
                        _buildYearlyTab(),
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

  Widget _buildCurrentTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    
    final filtered = _currentBalances.where((e) => e['GLNO'].toString().contains(_searchQuery)).toList();

    return AmsPaginatedView<Map<String, dynamic>>(
      items: filtered,
      shrinkWrap: true,
      builder: (context, currentItems) => AmsAuthTable(
        headers: const ['Org', 'GL No', 'Branch', 'Curr', 'Balance', 'Base Curr', 'Base Balance', 'User', 'Last Update'],
        rows: currentItems.map((item) => TableRow(
          children: [
            _cell(Text(item['ORGCODE'].toString(), style: monoStyle())),
            _cell(Text(item['GLNO'].toString(), style: bodyStyle(weight: FontWeight.w700))),
            _cell(Text(item['BRNCD'].toString(), style: bodyStyle())),
            _cell(Center(child: AmsBadge(label: item['CURR'], color: AppColors.tBlue))),
            _cell(Text(NumberFormat.currency(symbol: '').format(item['BAL']), style: bodyStyle(weight: FontWeight.w800, color: AppColors.ink))),
            _cell(Text(item['BCURR'], style: bodyStyle())),
            _cell(Text(NumberFormat.currency(symbol: '').format(item['BCBAL']), style: bodyStyle(weight: FontWeight.w600))),
            _cell(Text(item['EUSER'], style: bodyStyle(size: 11))),
            _cell(Text(item['EDATE'], style: bodyStyle(size: 10, color: AppColors.ink4))),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildDateWiseTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    
    final filtered = _dateWiseBalances.where((e) => e['GLNO'].toString().contains(_searchQuery)).toList();

    return AmsPaginatedView<Map<String, dynamic>>(
      items: filtered,
      shrinkWrap: true,
      builder: (context, currentItems) => AmsAuthTable(
        headers: const ['Date', 'GL No', 'Branch', 'Currency', 'Balance', 'Base Balance'],
        rows: currentItems.map((item) => TableRow(
          children: [
            _cell(Text(item['BALDATE'], style: monoStyle(color: AppColors.tBlue, weight: FontWeight.w700))),
            _cell(Text(item['GLNO'].toString(), style: bodyStyle(weight: FontWeight.bold))),
            _cell(Text(item['BRNCD'].toString(), style: bodyStyle())),
            _cell(Text(item['CURR'], style: bodyStyle())),
            _cell(Text(NumberFormat.currency(symbol: '').format(item['BAL']), style: bodyStyle(weight: FontWeight.w700))),
            _cell(Text(NumberFormat.currency(symbol: '').format(item['BCBAL']), style: bodyStyle())),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildYearlyTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    
    final filtered = _yearlyBalances.where((e) => e['GLNO'].toString().contains(_searchQuery)).toList();

    return AmsPaginatedView<Map<String, dynamic>>(
      items: filtered,
      shrinkWrap: true,
      builder: (context, currentItems) => AmsAuthTable(
        headers: const ['Year', 'GL No', 'Branch', 'Opening Bal', 'Closing Bal', 'Currency'],
        rows: currentItems.map((item) => TableRow(
          children: [
            _cell(Center(child: AmsBadge(label: item['YEAR'].toString(), color: AppColors.amber))),
            _cell(Text(item['GLNO'].toString(), style: bodyStyle(weight: FontWeight.bold))),
            _cell(Text(item['BRNCD'].toString(), style: bodyStyle())),
            _cell(Text(NumberFormat.currency(symbol: '').format(item['OPBAL']), style: bodyStyle(color: AppColors.ink2))),
            _cell(Text(NumberFormat.currency(symbol: '').format(item['CLBAL']), style: bodyStyle(weight: FontWeight.w800, color: AppColors.ink))),
            _cell(Text(item['CURR'], style: bodyStyle())),
          ],
        )).toList(),
      ),
    );
  }

  Widget _cell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: child,
    );
  }
}
