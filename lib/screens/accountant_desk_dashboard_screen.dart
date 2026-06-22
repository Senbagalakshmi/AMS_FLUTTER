import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../screens/submenu_dashboard_screen.dart';
import '../utils/responsive.dart';
import '../services/journal_api_service.dart';
import '../services/report_api_service.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'package:intl/intl.dart';

class AccountantDeskDashboardScreen extends StatefulWidget {
  final List<SubmenuItem> items;
  final void Function(String screen, String? prog) onNavigate;
  final VoidCallback onBack;
  final String? userName;

  const AccountantDeskDashboardScreen({
    super.key,
    required this.items,
    required this.onNavigate,
    required this.onBack,
    this.userName,
  });

  @override
  State<AccountantDeskDashboardScreen> createState() =>
      _AccountantDeskDashboardScreenState();
}

class _AccountantDeskDashboardScreenState
    extends State<AccountantDeskDashboardScreen> {
  final JournalApiService _journalApiService = JournalApiService();
  final ReportApiService _reportApiService = ReportApiService();

  int _journalCount = 0;
  int _coaCount = 0;
  int _pendingApprovals = 0;
  int _unreconciledAccounts = 0;
  double _taxLiability = 0;
  String _taxPeriodLabel = '';
  List<Map<String, dynamic>> _recentJournals = [];
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _topAccounts = [];
  List<Map<String, dynamic>> _chartData = [];
  String _chartDateRange = '';
  bool _isLoading = true;

  // bumped every time fresh data lands, so staggered/entrance animations
  // (bars, counters, list rows) replay instead of staying frozen at final state
  int _contentRevision = 0;

  static const _monthLabels = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final currentDate = DateFormat('yyyy-MM-dd').format(now);

      final monthDates = List.generate(5, (i) {
        final month = DateTime(now.year, now.month - (4 - i), 1);
        return DateTime(month.year, month.month + 1, 0);
      });

      final monthlyPlFutures = monthDates
          .map((d) => _reportApiService.getFinancialReport(
                reportType: 'PL',
                date: DateFormat('yyyy-MM-dd').format(d),
              ))
          .toList();

      final results = await Future.wait([
        _journalApiService.getJournals(),
        _reportApiService.getChartOfAccounts(),
        apiService.getAuthQueue(page: 0, size: 100),
        _reportApiService.getFinancialReport(
            reportType: 'TB', date: currentDate),
        _reportApiService.getFinancialReport(
            reportType: 'BS', date: currentDate),
        ...monthlyPlFutures,
      ]);

      final journals = results[0] as List<Map<String, dynamic>>?;
      final coa = results[1] as List<Map<String, dynamic>>?;
      final authQueue = results[2] as PaginatedResult<AuthRecord>?;
      final tbData = results[3] as List<Map<String, dynamic>>?;
      final bsData = results[4] as List<Map<String, dynamic>>?;
      final monthlyPl = <List<Map<String, dynamic>>?>[];
      for (var i = 5; i < results.length; i++) {
        monthlyPl.add(results[i] as List<Map<String, dynamic>>?);
      }

      if (mounted) {
        setState(() {
          final sortedJournals = _sortedJournals(journals ?? []);
          _recentJournals = sortedJournals.take(5).toList();
          _journalCount = journals?.length ?? 0;
          _coaCount = coa?.length ?? 0;
          _pendingApprovals = authQueue?.totalElements ?? 0;
          _unreconciledAccounts = _countUnreconciled(tbData, coa);
          _taxLiability = _calculateTaxLiability(bsData);
          _taxPeriodLabel = _buildTaxPeriodLabel(now);
          _recentActivity = _buildActivityFeedData(
            sortedJournals,
            authQueue?.items ?? [],
          );
          _topAccounts = _buildTopAccounts(coa ?? []);
          _chartData = _buildChartData(monthlyPl, monthDates);
          _chartDateRange = monthDates.isEmpty
              ? ''
              : '${_monthLabels[monthDates.first.month - 1]} - ${_monthLabels[monthDates.last.month - 1]}';
          _isLoading = false;
          _contentRevision++;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _parseAmount(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0.0;
  }

  List<Map<String, dynamic>> _sortedJournals(
      List<Map<String, dynamic>> journals) {
    final sorted = List<Map<String, dynamic>>.from(journals);
    sorted.sort((a, b) {
      final da = DateTime.tryParse(a['trandate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(b['trandate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return sorted;
  }

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr.split(' ').first;

    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _initialsFromName(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  List<Map<String, dynamic>> _buildActivityFeedData(
    List<Map<String, dynamic>> journals,
    List<AuthRecord> authItems,
  ) {
    final activities = <Map<String, dynamic>>[];

    for (final j in journals.take(5)) {
      final narration = j['narration']?.toString().trim() ?? '';
      activities.add({
        'icon': Icons.description_rounded,
        'color': const Color(0xFF0EA5E9),
        'title': narration.isNotEmpty
            ? narration
            : 'Journal #${j['tranid'] ?? '—'} posted',
        'time': _formatRelativeTime(j['trandate']?.toString()),
      });
    }

    for (final auth in authItems.take(3)) {
      final remarks = auth.displayRemarks.trim();
      activities.add({
        'icon': Icons.pending_actions_rounded,
        'color': const Color(0xFF6366F1),
        'title': remarks.isNotEmpty
            ? remarks
            : 'Pending approval: ${auth.programId}',
        'time': _formatRelativeTime(auth.eDate),
      });
    }

    return activities.take(5).toList();
  }

  List<Map<String, dynamic>> _buildTopAccounts(
      List<Map<String, dynamic>> coa) {
    final fmt = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      customPattern: '\u00A4#,##0.00',
    );

    final withBalance = coa.where((acc) {
      final balance = _parseAmount(acc['balance']);
      return balance.abs() > 0;
    }).toList();

    withBalance.sort((a, b) {
      final ba = _parseAmount(a['balance']).abs();
      final bb = _parseAmount(b['balance']).abs();
      return bb.compareTo(ba);
    });

    return withBalance.take(4).map((acc) {
      final name = acc['accountName']?.toString() ?? 'Unknown';
      final balance = _parseAmount(acc['balance']);
      final type = acc['accountType']?.toString() ?? '—';

      Color statusColor;
      String status;
      if (balance > 0) {
        status = 'Debit balance';
        statusColor = const Color(0xFF64748B);
      } else if (balance < 0) {
        status = 'Credit balance';
        statusColor = const Color(0xFFF59E0B);
      } else {
        status = 'Zero balance';
        statusColor = const Color(0xFF64748B);
      }

      return {
        'initials': _initialsFromName(name),
        'name': name,
        'terms': type,
        'amount': fmt.format(balance.abs()),
        'status': status,
        'statusColor': statusColor,
      };
    }).toList();
  }

  int _countUnreconciled(
    List<Map<String, dynamic>>? tbData,
    List<Map<String, dynamic>>? coa,
  ) {
    if (tbData != null) {
      final bothSides = tbData.where((acc) {
        final dr = _parseAmount(acc['debit']);
        final cr = _parseAmount(acc['credit']);
        return dr > 0 && cr > 0;
      }).length;
      if (bothSides > 0) return bothSides;
    }

    return coa
            ?.where((acc) => _parseAmount(acc['balance']).abs() > 0)
            .length ??
        0;
  }

  double _calculateTaxLiability(List<Map<String, dynamic>>? bsData) {
    if (bsData == null) return 0;

    double taxTotal = 0;
    for (final item in bsData) {
      final name = (item['account_name'] ??
              item['accountname'] ??
              item['glname'] ??
              '')
          .toString()
          .toLowerCase();
      final type = (item['gltype'] ?? '').toString().toUpperCase();
      final amount = _parseAmount(item['amount']);
      if (type == 'LIABILITY' &&
          (name.contains('tax') ||
              name.contains('gst') ||
              name.contains('tds'))) {
        taxTotal += amount;
      }
    }
    if (taxTotal > 0) return taxTotal;

    double liabilities = 0;
    for (final item in bsData) {
      if ((item['gltype'] ?? '').toString().toUpperCase() == 'LIABILITY') {
        liabilities += _parseAmount(item['amount']);
      }
    }
    return liabilities;
  }

  String _buildTaxPeriodLabel(DateTime now) {
    final quarter = ((now.month - 1) ~/ 3) + 1;
    return 'Estimated for Q$quarter ${now.year}';
  }

  List<Map<String, dynamic>> _buildChartData(
    List<List<Map<String, dynamic>>?> monthlyPl,
    List<DateTime> monthDates,
  ) {
    final raw = <Map<String, dynamic>>[];
    double maxVal = 0;

    for (var i = 0; i < monthlyPl.length; i++) {
      double income = 0;
      double expense = 0;
      final pl = monthlyPl[i];
      if (pl != null) {
        for (final item in pl) {
          final amount = _parseAmount(item['amount']);
          final type = (item['gltype'] ?? '').toString().toUpperCase();
          if (type == 'INCOME') {
            income += amount;
          } else if (type == 'EXPENSE') {
            expense += amount;
          }
        }
      }
      maxVal = [maxVal, income, expense].reduce((a, b) => a > b ? a : b);
      raw.add({
        'month': _monthLabels[monthDates[i].month - 1],
        'revenue': income,
        'expense': expense,
      });
    }

    if (maxVal <= 0) {
      return raw
          .map((r) => {
                'month': r['month'],
                'revenue': 0.0,
                'expense': 0.0,
              })
          .toList();
    }

    return raw
        .map((r) => {
              'month': r['month'],
              'revenue': (r['revenue'] as double) / maxVal,
              'expense': (r['expense'] as double) / maxVal,
            })
        .toList();
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      customPattern: '\u00A4#,##0.00',
    ).format(value);
  }

  TextStyle bodyStyle({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.black,
    double? height,
  }) =>
      TextStyle(
          fontSize: size, fontWeight: weight, color: color, height: height);

  TextStyle monoStyle({
    double size = 11,
    FontWeight weight = FontWeight.w700,
    Color color = Colors.grey,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFamily: 'monospace',
        letterSpacing: letterSpacing,
      );

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER — outer padding + header inner padding = scroll padding (32 desktop / 16 mobile)
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 0 : 16,
              20,
              isMobile ? 0 : 16,
              10,
            ),
            child: AmsIdentityHeader(
              title: 'Accountant Desk',
              subtitle: '',
              badges: [
                AmsBadge(
                  label: '${widget.items.length} MODULES',
                  color: const Color(0xFF6366F1),
                  background: const Color(0xFFEEF2FF),
                ),
              ],
              accentColor: AppColors.tBlue,
              accentLt: AppColors.tBlueLt,
              accentMd: AppColors.tBlueMd,
              onBack: widget.onBack,
            ),
          ),

          // MAIN
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _isLoading
                  ? const Center(
                      key: ValueKey('loading'),
                      child: CircularProgressIndicator(),
                    )
                  : SingleChildScrollView(
                      key: ValueKey('content-$_contentRevision'),
                      padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 32, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Stats row
                          _buildStatsRow(isMobile),
                          const SizedBox(height: 24),

                          // 2. Financial Overview + Needs Attention / Tax
                          isMobile
                              ? Column(children: [
                                  _FadeSlideIn(
                                    index: 3,
                                    child: _buildFinancialOverviewCard(),
                                  ),
                                  const SizedBox(height: 16),
                                  _FadeSlideIn(
                                    index: 4,
                                    child: _buildRightColumn(),
                                  ),
                                ])
                              : IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                          flex: 3,
                                          child: _FadeSlideIn(
                                              index: 3,
                                              child:
                                                  _buildFinancialOverviewCard())),
                                      const SizedBox(width: 16),
                                      Expanded(
                                          flex: 2,
                                          child: _FadeSlideIn(
                                              index: 4,
                                              child: _buildRightColumn(
                                                  stretch: true))),
                                    ],
                                  ),
                                ),
                          const SizedBox(height: 24),

                          // 3. Activity + Clients
                          isMobile
                              ? Column(children: [
                                  _FadeSlideIn(
                                    index: 5,
                                    child: _buildActivityFeed(),
                                  ),
                                  const SizedBox(height: 16),
                                  _FadeSlideIn(
                                    index: 6,
                                    child: _buildClientQuickView(),
                                  ),
                                ])
                              : IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                          child: _FadeSlideIn(
                                              index: 5,
                                              child: _buildActivityFeed(
                                                  stretch: true))),
                                      const SizedBox(width: 16),
                                      Expanded(
                                          child: _FadeSlideIn(
                                              index: 6,
                                              child: _buildClientQuickView(
                                                  stretch: true))),
                                    ],
                                  ),
                                ),
                          const SizedBox(height: 24),

                          // 4. Module cards
                          _buildQuickLaunchGrid(isMobile),
                          const SizedBox(height: 24),

                          // 5. Recent Journal Postings
                          _FadeSlideIn(
                            index: 12,
                            child: _buildRecentJournalsCard(isMobile),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow(bool isMobile) {
    final cards = [
      _StatCard(
        title: 'Journals Posted',
        value: _journalCount.toString(),
        numericTarget: _journalCount,
        icon: Icons.description_rounded,
        color: const Color(0xFF4F46E5),
        onTap: () => widget.onNavigate('nontran', 'GL-JRN'),
      ),
      _StatCard(
        title: 'Chart of Accounts',
        value: _coaCount.toString(),
        numericTarget: _coaCount,
        icon: Icons.list_alt_rounded,
        color: const Color(0xFF0EA5E9),
        onTap: () => widget.onNavigate('nontran', 'RPT-COA'),
      ),
      _StatCard(
        title: 'Reports',
        value: 'Available',
        valueColor: const Color(0xFF10B981),
        icon: Icons.pie_chart_rounded,
        color: const Color(0xFF10B981),
        onTap: () => widget.onNavigate('submenu_dashboard', 'REPORTS'),
      ),
    ];

    if (isMobile) {
      return Column(
          children: cards
              .asMap()
              .entries
              .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FadeSlideIn(index: e.key, child: e.value)))
              .toList());
    }
    return Row(
      children: cards.asMap().entries.map((entry) {
        final isLast = entry.key == cards.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 16),
            child: _FadeSlideIn(index: entry.key, child: entry.value),
          ),
        );
      }).toList(),
    );
  }

  // ── Financial Overview Bar Chart ─────────────────────────────────────────────
  Widget _buildFinancialOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Financial Overview',
                  style: bodyStyle(
                      size: 15,
                      weight: FontWeight.w700,
                      color: const Color(0xFF0F172A))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(_chartDateRange.isEmpty ? '—' : _chartDateRange,
                    style: monoStyle(size: 11, color: const Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bar chart
          SizedBox(
            height: 160,
            child: _chartData.isEmpty
                ? Center(
                    child: Text(
                      'No financial data available',
                      style: bodyStyle(color: const Color(0xFF64748B)),
                    ),
                  )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _chartData.asMap().entries.map((e) {
                final d = e.value;
                return _BarGroup(
                  key: ValueKey('bar-${e.key}-$_contentRevision'),
                  month: d['month'],
                  revenueRatio: d['revenue'],
                  expenseRatio: d['expense'],
                  maxHeight: 130,
                  index: e.key,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            children: [
              _LegendDot(color: const Color(0xFF4F46E5), label: 'Revenue'),
              const SizedBox(width: 20),
              _LegendDot(color: const Color(0xFF7DD3FC), label: 'Expenses'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Right column: Needs Attention + Tax Liability ────────────────────────────
  Widget _buildRightColumn({bool stretch = false}) {
    final needsAttention = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Needs Attention',
              style: bodyStyle(
                  size: 15,
                  weight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _AttentionRow(
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF6366F1),
            iconBg: const Color(0xFFEEF2FF),
            label: 'Pending Approvals',
            badge: '$_pendingApprovals',
            badgeColor: const Color(0xFF6366F1),
          ),
          const SizedBox(height: 10),
          _AttentionRow(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFFEF4444),
            iconBg: const Color(0xFFFEF2F2),
            label: 'Accounts with Balance',
            badge: '$_unreconciledAccounts',
            badgeColor: const Color(0xFFEF4444),
          ),
        ],
      ),
    );

    final taxLiability = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calculate_rounded,
                    size: 22, color: Color(0xFF0EA5E9)),
              ),
              const SizedBox(width: 12),
              Text('Estimated Tax Liability',
                  style: bodyStyle(
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          _CountUpCurrency(
            key: ValueKey('tax-$_contentRevision'),
            target: _taxLiability,
            formatter: _formatCurrency,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(_taxPeriodLabel,
              style: bodyStyle(size: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  widget.onNavigate('submenu_dashboard', 'REPORTS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View Breakdown',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (stretch) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: needsAttention),
          const SizedBox(height: 16),
          Expanded(child: taxLiability),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        needsAttention,
        const SizedBox(height: 16),
        taxLiability,
      ],
    );
  }

  // ── Recent Activity Feed ─────────────────────────────────────────────────────
  Widget _buildActivityFeed({bool stretch = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity Feed',
                  style: bodyStyle(
                      size: 15,
                      weight: FontWeight.w700,
                      color: const Color(0xFF0F172A))),
              const Icon(Icons.more_vert_rounded,
                  color: Color(0xFF94A3B8), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentActivity.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No recent activity found.',
                  style: bodyStyle(color: const Color(0xFF64748B)),
                ),
              ),
            )
          else
            ..._recentActivity.asMap().entries.map((e) => _FadeSlideIn(
                  index: e.key,
                  child: _ActivityRow(
                    icon: e.value['icon'],
                    color: e.value['color'],
                    title: e.value['title'],
                    time: e.value['time'],
                  ),
                )),
        ],
      ),
    );
  }

  // ── Client Quick-View ────────────────────────────────────────────────────────
  Widget _buildClientQuickView({bool stretch = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Account Quick-View',
                  style: bodyStyle(
                      size: 15,
                      weight: FontWeight.w700,
                      color: const Color(0xFF0F172A))),
              TextButton(
                onPressed: () => widget.onNavigate('nontran', 'RPT-COA'),
                child: const Text('View All',
                    style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_topAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No accounts with balance found.',
                  style: bodyStyle(color: const Color(0xFF64748B)),
                ),
              ),
            )
          else
            ..._topAccounts.asMap().entries.map((e) => _FadeSlideIn(
                  index: e.key,
                  child: _ClientRow(
                    initials: e.value['initials'],
                    name: e.value['name'],
                    terms: e.value['terms'],
                    amount: e.value['amount'],
                    status: e.value['status'],
                    statusColor: e.value['statusColor'],
                  ),
                )),
        ],
      ),
    );
  }

  SubmenuItem _displayItem(SubmenuItem item) {
    if (item.programId == 'GL-JRN') {
      return item.copyWith(metric: '$_journalCount Posted');
    }
    if (item.programId == 'RPT-COA') {
      return item.copyWith(metric: '$_coaCount Active');
    }
    return item;
  }

  // ── Module cards ─────────────────────────────────────────────────────────────
  Widget _buildQuickLaunchGrid(bool isMobile) {
    if (isMobile) {
      return Column(
        children: widget.items
            .asMap()
            .entries
            .map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    height: 220,
                    child: _FadeSlideIn(
                      index: entry.key + 7,
                      child: _LaunchCard(
                        item: _displayItem(entry.value),
                        onTap: () => widget.onNavigate(
                            entry.value.screen, entry.value.programId),
                      ),
                    ),
                  ),
                ))
            .toList(),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.items.asMap().entries.map((entry) {
          final item = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: item == widget.items.last ? 0 : 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 240),
                child: _FadeSlideIn(
                  index: entry.key + 7,
                  child: _LaunchCard(
                    item: _displayItem(item),
                    onTap: () =>
                        widget.onNavigate(item.screen, item.programId),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // ── Recent Journal Postings ──────────────────────────────────────────────────
  Widget _buildRecentJournalsCard(bool isMobile) {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Recent Journal Postings',
                      style: bodyStyle(
                          size: 15,
                          weight: FontWeight.w700,
                          color: const Color(0xFF0F172A))),
                  const Icon(Icons.filter_list_rounded,
                      size: 20, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _recentJournals.isEmpty
          ? SizedBox(
              height: 220,
              child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1.5),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          size: 32, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 16),
                    Text('No journal postings found.',
                        style: bodyStyle(color: const Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => widget.onNavigate('nontran', 'GL-JRN'),
                      child: const Text('Create your first entry',
                          style: TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                constraints: BoxConstraints(minWidth: isMobile ? 500 : 800),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(4),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                    4: FlexColumnWidth(2),
                  },
                  border: TableBorder(
                    horizontalInside:
                        const BorderSide(color: Color(0xFFF1F5F9), width: 1),
                  ),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFE2E8F0), width: 1.5)),
                      ),
                      children: [
                        _th('DATE'),
                        _th('NARRATION'),
                        _th('TRAN ID'),
                        _th('TOTAL DEBIT', alignRight: true),
                        _th('TOTAL CREDIT', alignRight: true),
                      ],
                    ),
                    ..._recentJournals.take(5).map((j) {
                      final debit =
                          (j['totaldebit'] as num?)?.toDouble() ?? 0.0;
                      final credit =
                          (j['totalcredit'] as num?)?.toDouble() ?? 0.0;
                      final fmt = NumberFormat.currency(
                          symbol: '₹',
                          decimalDigits: 2,
                          customPattern: '\u00A4#,##0.00');

                      return TableRow(
                        decoration: const BoxDecoration(color: Colors.white),
                        children: [
                          _td(Text(
                            j['trandate']?.toString().split(' ').first ?? '—',
                            style: monoStyle(
                                size: 11.5,
                                weight: FontWeight.w700,
                                color: const Color(0xFF334155)),
                          )),
                          _td(Text(
                            j['narration']?.toString() ?? '—',
                            style: bodyStyle(
                                size: 13.5, color: const Color(0xFF1E293B)),
                          )),
                          _td(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${j['tranid'] ?? '—'}',
                              style: monoStyle(
                                  size: 11.5, color: const Color(0xFF475569)),
                            ),
                          )),
                          _td(Text(fmt.format(debit),
                              style:
                                  monoStyle(size: 12, color: AppColors.ink)),
                              alignRight: true),
                          _td(Text(fmt.format(credit),
                              style:
                                  monoStyle(size: 12, color: AppColors.ink)),
                              alignRight: true),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _th(String label, {bool alignRight = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Align(
          alignment:
              alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              )),
        ),
      );

  static Widget _td(Widget child, {bool alignRight = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Align(
          alignment:
              alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: child,
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animation helper widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Generic staggered fade + slide-up entrance wrapper.
/// Wrap any widget with this and give it an `index` to get a
/// nice cascading "appear one after another" effect on screen load.
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration stagger;

  const _FadeSlideIn({
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 55),
    super.key,
  });

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.stagger * widget.index, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Animates a currency value counting up from 0 to its target.
class _CountUpCurrency extends StatelessWidget {
  final double target;
  final String Function(double) formatter;
  final TextStyle style;

  const _CountUpCurrency({
    required this.target,
    required this.formatter,
    required this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Text(formatter(value), style: style),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Two-bar group (revenue + expense) for one month — bars grow from zero
/// in a staggered cascade across the months when the chart first appears.
class _BarGroup extends StatefulWidget {
  final String month;
  final double revenueRatio;
  final double expenseRatio;
  final double maxHeight;
  final int index;

  const _BarGroup({
    required this.month,
    required this.revenueRatio,
    required this.expenseRatio,
    required this.maxHeight,
    this.index = 0,
    super.key,
  });

  @override
  State<_BarGroup> createState() => _BarGroupState();
}

class _BarGroupState extends State<_BarGroup> {
  bool _grown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 90 * widget.index + 150), () {
      if (mounted) setState(() => _grown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final revenueH = _grown ? (widget.revenueRatio * widget.maxHeight).clamp(0.0, double.infinity) : 0.0;
    final expenseH = _grown ? (widget.expenseRatio * widget.maxHeight).clamp(0.0, double.infinity) : 0.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bar(height: revenueH, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 4),
            _Bar(height: expenseH, color: const Color(0xFF7DD3FC)),
          ],
        ),
        const SizedBox(height: 8),
        Text(widget.month,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8))),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    final safeHeight = height.clamp(0.0, double.infinity);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: safeHeight),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, h, child) => Container(
        width: 18,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500)),
    ]);
  }
}

/// Row inside "Needs Attention"
class _AttentionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String badge;
  final Color badgeColor;

  const _AttentionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B)))),
        // Animated count-up badge so the number doesn't just snap into place
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: int.tryParse(badge) ?? 0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$value',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

/// Single row in the activity feed
class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String time;

  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(time,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }
}

/// Single client row
class _ClientRow extends StatelessWidget {
  final String initials;
  final String name;
  final String terms;
  final String amount;
  final String status;
  final Color statusColor;

  const _ClientRow({
    required this.initials,
    required this.name,
    required this.terms,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        // Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(initials,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B))),
            Text(terms,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500)),
          ]),
        ),
        SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A))),
              Text(status,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Existing _StatCard, _LaunchCard (now with count-up + entrance polish) ──

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color? valueColor;
  final VoidCallback? onTap;
  final int? numericTarget;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.valueColor,
    this.onTap,
    this.numericTarget,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withOpacity(0.4)
                  : const Color(0xFFF1F5F9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.color.withOpacity(0.1)
                    : const Color(0xFF0F172A).withOpacity(0.03),
                blurRadius: _isHovered ? 24 : 16,
                offset: _isHovered ? const Offset(0, 12) : const Offset(0, 4),
              )
            ],
          ),
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.015 : 1.0),
          transformAlignment: Alignment.center,
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: _isHovered
                    ? LinearGradient(
                        colors: [widget.color, widget.color.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          widget.color.withOpacity(0.12),
                          widget.color.withOpacity(0.06)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: AnimatedRotation(
                turns: _isHovered ? 0.02 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.icon,
                  color: _isHovered ? Colors.white : widget.color,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          _isHovered ? widget.color : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  widget.numericTarget != null
                      ? TweenAnimationBuilder<int>(
                          key: ValueKey(widget.numericTarget),
                          tween:
                              IntTween(begin: 0, end: widget.numericTarget!),
                          duration: const Duration(milliseconds: 850),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Text(
                            '$value',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color:
                                  widget.valueColor ?? const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        )
                      : Text(
                          widget.value,
                          style: TextStyle(
                            fontSize: widget.value == 'Available' ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            color: widget.valueColor ?? const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LaunchCard extends StatefulWidget {
  final SubmenuItem item;
  final VoidCallback onTap;

  const _LaunchCard({required this.item, required this.onTap});

  @override
  State<_LaunchCard> createState() => _LaunchCardState();
}

class _LaunchCardState extends State<_LaunchCard> {
  bool _isHovered = false;

  Color get _accentColor => widget.item.programId == 'GL-JRN'
      ? const Color(0xFF6366F1)
      : const Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(22),
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -3.0 : 0.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? _accentColor.withOpacity(0.5)
                  : const Color(0xFFF1F5F9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? _accentColor.withOpacity(0.08)
                    : const Color(0xFF0F172A).withOpacity(0.03),
                blurRadius: _isHovered ? 24 : 16,
                offset: _isHovered ? const Offset(0, 12) : const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _isHovered
                          ? LinearGradient(
                              colors: [_accentColor, _accentColor.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                _accentColor.withOpacity(0.12),
                                _accentColor.withOpacity(0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: _accentColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: AnimatedScale(
                      scale: _isHovered ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(widget.item.icon,
                          size: 28,
                          color: _isHovered ? Colors.white : _accentColor),
                    ),
                  ),
                  if (widget.item.metric != null)
                    _ModuleBadge(label: widget.item.metric!),
                ],
              ),
              const Spacer(),
              Text(widget.item.label,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 6),
              Text(
                widget.item.subtitle ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(widget.item.programId,
                        style: const TextStyle(
                            fontSize: 9,
                            fontFamily: 'monospace',
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700)),
                  ),
                  if (widget.item.trend != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedRotation(
                          turns: _isHovered && widget.item.trend == 'Daily'
                              ? 1
                              : 0,
                          duration: const Duration(milliseconds: 500),
                          child: Icon(
                            widget.item.trend == 'Daily'
                                ? Icons.sync_rounded
                                : Icons.check_circle_rounded,
                            size: 12,
                            color: widget.item.trend == 'Daily'
                                ? const Color(0xFF64748B)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(widget.item.trend!,
                            style: TextStyle(
                                fontSize: 10,
                                color: widget.item.trend == 'Daily'
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF16A34A),
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleBadge extends StatelessWidget {
  final String label;

  const _ModuleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final isNew = label.toLowerCase() == 'new';
    final color = isNew ? const Color(0xFF6366F1) : const Color(0xFF10B981);
    final bg = isNew ? const Color(0xFFEEF2FF) : const Color(0xFFECFDF5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}