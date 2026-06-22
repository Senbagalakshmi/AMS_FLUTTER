import 'package:flutter/material.dart';
import 'dart:math';
import '../theme.dart';
import '../models/models.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import '../services/org_api_service.dart';
import 'package:intl/intl.dart';

class ProgramListScreen extends StatefulWidget {
  final Map<String, Auth101Config> authConfigs;
  final List<String> tranPrograms;
  final List<String> nonTranPrograms;
  final void Function(String prog) onSelect;
  final void Function(String route) onProceed;
  final VoidCallback onBack;
  final String? userName;
  final int authQueueCount;
  final int totalUsers;

  const ProgramListScreen({
    super.key,
    required this.authConfigs,
    required this.tranPrograms,
    required this.nonTranPrograms,
    required this.onSelect,
    required this.onProceed,
    required this.onBack,
    this.userName,
    this.authQueueCount = 0,
    this.totalUsers = 0,
  });

  @override
  State<ProgramListScreen> createState() => _ProgramListScreenState();
}

class _ProgramListScreenState extends State<ProgramListScreen> {
  bool _isLoading = true;
  int _totalAuthQueue = 0;
  int _processedToday = 0;
  int _glCategories = 0;
  int _glMasters = 0;
  int _totalUsersCount = 0;
  int _totalOrgCount = 0;
  int _totalCoaCount = 0;
  List<AuthRecord> _recentAuthItems = [];
  // Dynamic metrics
  List<int> _weeklyData = [42, 78, 91, 65, 83, 24, 11]; // Fallback
  List<MapEntry<String, int>> _topPrograms = [];
  List<int> _coaDistribution = [30, 25, 15, 20, 10]; // Fallback

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        apiService.getAuthQueue(size: 500),
        apiService.getAllGlCategories(size: 1),
        apiService.getAllGlMasters(
            size: 1000), // Get enough masters to analyze distribution
        apiService.getUsers(size: 1),
        apiService.getChartOfAccountsReport(),
        orgApiService.getAllOrganisations(size: 1),
      ]);

      final authResult = results[0] as PaginatedResult<AuthRecord>?;
      final catResult = results[1] as PaginatedResult<Map<String, dynamic>>?;
      final mastResult = results[2] as PaginatedResult<Map<String, dynamic>>?;
      final usrResult = results[3] as PaginatedResult<Map<String, dynamic>>?;
      final coaReport =
          results.length > 4 ? results[4] as List<Map<String, dynamic>>? : null;
      final orgResult = results.length > 5
          ? results[5] as PaginatedResult<Map<String, dynamic>>?
          : null;

      final allItems = authResult?.items ?? [];
      final processed = allItems
          .where((r) =>
              r.flUser != null && r.flUser!.isNotEmpty && r.flUser != '0')
          .length;

      // 1. Dynamic Top Programs & Weekly Activity
      Map<String, int> progMap = {};
      List<int> weekCounts = [0, 0, 0, 0, 0, 0, 0];
      for (var item in allItems) {
        progMap[item.programId] = (progMap[item.programId] ?? 0) + 1;
        try {
          final dt = DateTime.parse(item.eDate);
          weekCounts[dt.weekday - 1]++;
        } catch (_) {}
      }
      var sortedProgs = progMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // 2. Dynamic Chart of Accounts Distribution
      int ast = 0, lib = 0, equ = 0, rev = 0, exp = 0;
      if (coaReport != null) {
        for (var item in coaReport) {
          final allValues = item.values.join(' ').toLowerCase();
          final glStr = item['accountNumber']?.toString() ??
              item['glNo']?.toString() ??
              item['account_number']?.toString() ??
              '';
          int glNo = int.tryParse(glStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

          if (allValues.contains('asset') || (glNo >= 1000 && glNo < 2000))
            ast++;
          else if (allValues.contains('liab') || (glNo >= 2000 && glNo < 3000))
            lib++;
          else if (allValues.contains('equi') || (glNo >= 3000 && glNo < 4000))
            equ++;
          else if (allValues.contains('inc') ||
              allValues.contains('rev') ||
              (glNo >= 4000 && glNo < 5000))
            rev++;
          else if (allValues.contains('exp') || (glNo >= 5000 && glNo < 6000))
            exp++;
        }
      } else {
        final mastersList = mastResult?.items ?? [];
        for (var gl in mastersList) {
          int glNo = int.tryParse(gl['glNo']?.toString() ?? '0') ?? 0;
          if (glNo >= 1000 && glNo < 2000)
            ast++;
          else if (glNo >= 2000 && glNo < 3000)
            lib++;
          else if (glNo >= 3000 && glNo < 4000)
            equ++;
          else if (glNo >= 4000 && glNo < 5000)
            rev++;
          else if (glNo >= 5000 && glNo < 6000) exp++;
        }
      }
      int totalGl = ast + lib + equ + rev + exp;
      if (totalGl == 0) totalGl = 1;

      if (mounted) {
        setState(() {
          _totalAuthQueue = authResult?.totalElements ?? widget.authQueueCount;
          _processedToday = processed;
          _glCategories = catResult?.totalElements ?? 0;
          _glMasters = mastResult?.totalElements ?? 0;
          _totalUsersCount = usrResult?.totalElements ?? widget.totalUsers;
          _totalOrgCount = orgResult?.totalElements ?? 0;
          _totalCoaCount = coaReport?.length ?? _glMasters;
          _recentAuthItems = allItems.take(5).toList();

          if (weekCounts.any((c) => c > 0)) _weeklyData = weekCounts;
          _topPrograms = sortedProgs.take(3).toList();

          if (coaReport != null || mastResult?.items != null) {
            if (totalGl > 1 ||
                (totalGl == 1 && (ast + lib + equ + rev + exp > 0))) {
              _coaDistribution = [
                (ast / totalGl * 100).toInt(),
                (lib / totalGl * 100).toInt(),
                (equ / totalGl * 100).toInt(),
                (rev / totalGl * 100).toInt(),
                (exp / totalGl * 100).toInt(),
              ];
            } else {
              _coaDistribution = [0, 0, 0, 0, 0];
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _displayName {
    String n = widget.userName ?? 'Administrator';
    if (n.contains('@')) n = n.split('@').first;
    if (n.isNotEmpty) n = n[0].toUpperCase() + n.substring(1);
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeroHeader(isMobile),
              Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiRow(isMobile),
                    const SizedBox(height: 24),
                    // Chart of Accounts row
                    _buildChartOfAccountsOverview(isMobile),
                    const SizedBox(height: 24),
                    isMobile
                        ? Column(children: [
                            _buildQuickActions(),
                            const SizedBox(height: 16),
                            _buildTopPrograms(),
                            const SizedBox(height: 16),
                            _buildAuthByType(),
                            const SizedBox(height: 16),
                            _buildWeeklyActivity(),
                            const SizedBox(height: 16),
                            _buildAuthVolume(),
                            const SizedBox(height: 16),
                            _buildRecentQueue(),
                          ])
                        : Column(children: [
                            // Row 1: Quick Actions + Top Programs + Auth By Type + System Overview
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                      flex: 4, child: _buildQuickActions()),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 4, child: _buildTopPrograms()),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 3, child: _buildAuthByType()),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      flex: 3,
                                      child: _buildFinancialExposure()),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Row 2: Auth Volume + Recent Queue + Weekly Activity
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 5, child: _buildAuthVolume()),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 4, child: _buildRecentQueue()),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      flex: 3, child: _buildWeeklyActivity()),
                                ],
                              ),
                            ),
                          ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(bool isMobile) {
    final pending = _isLoading ? '—' : '$_totalAuthQueue';
    final processed = _isLoading ? '—' : '$_processedToday';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1C5E), Color(0xFF1A237E), Color(0xFF1E2B5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _FloatingFinanceBackground()),
          Padding(
            padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 32, 28, isMobile ? 16 : 32, 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _greetingBlock(pending, processed, isMobile)),
                if (!isMobile) _dateBlock(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBlock() {
    final now = DateTime.now();
    final dayFormat = DateFormat('dd');
    final monthFormat = DateFormat('MMM yyyy');
    final dayNameFormat = DateFormat('EEEE');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dayNameFormat.format(now).toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                monthFormat.format(now).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            height: 34,
            width: 1.5,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 16),
          Text(
            dayFormat.format(now),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _greetingBlock(String pending, String processed, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Text(
            '$_greeting, $_displayName !',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 20 : 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome back! Here is your system overview for today.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Wrap(
        //   spacing: 6,
        //   runSpacing: 6,
        //   children: [
        //     _infoBadge(Icons.inbox_rounded, '$pending pending',
        //         const Color(0xFFFBBF24)),
        //     _infoBadge(Icons.check_circle_rounded, '$processed processed',
        //         const Color(0xFF34D399)),
        //     _infoBadge(Icons.category_rounded, '$_glCategories categories',
        //         const Color(0xFF818CF8)),
        //   ],
        // ),
      ],
    );
  }

  Widget _infoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildKpiRow(bool isMobile) {
    final cards = [
      _KpiData(
          'Total Auth Queue',
          '$_totalAuthQueue',
          Icons.inbox_rounded,
          const Color(0xFF6366F1),
          '+18% vs last week',
          () => widget.onProceed('AUTH')),
      // _KpiData(
      //     'Organisations',
      //     '$_totalOrgCount',
      //     Icons.business_rounded,
      //     const Color(0xFFF59E0B),
      //     'registered orgs',
      //     () => widget.onSelect('ORG-CRT')),
      _KpiData(
          'Chart of Accounts',
          '$_totalCoaCount',
          Icons.account_tree_rounded,
          const Color(0xFFF59E0B),
          'total accounts',
          () => widget.onSelect('RPT-COA')),
      _KpiData('GL Categories', '$_glCategories', Icons.category_rounded,
          const Color(0xFF3B82F6), 'configured', () => widget.onProceed('GL')),
      // _KpiData(
      //     'Total Users',
      //     '$_totalUsersCount',
      //     Icons.group_rounded,
      //     const Color(0xFFEC4899),
      //     'registered',
      //     () => widget.onProceed('MASTERS')),
      _KpiData(
          'Reports',
          'Available',
          Icons.pie_chart_rounded,
          const Color(0xFF10B981),
          'view all reports',
          () => widget.onProceed('REPORTS'))
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: _KpiCard(data: c, isLoading: _isLoading),
          ),
        )).toList(),
      );
    }

    return Row(
      children: cards.map((c) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: c != cards.last ? 16 : 0),
          child: _KpiCard(data: c, isLoading: _isLoading),
        ),
      )).toList(),
    );
  }

  Widget _buildAuthVolume() {
    final int maxWeekly =
        _weeklyData.isEmpty ? 100 : _weeklyData.reduce((a, b) => a > b ? a : b);
    final int finalMax = maxWeekly == 0 ? 1 : maxWeekly;

    return _DashCard(
      title: 'Authorization Volume',
      subtitle: 'FY 2025-26',
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < _weeklyData.length; i++)
              _BarItem(
                value: _weeklyData[i],
                maxVal: finalMax,
                label: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                isHighlight: i == 2,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthByType() {
    final total = _totalAuthQueue == 0 ? 1 : _totalAuthQueue;
    final processed = _processedToday;
    final pending = total - processed;
    return _DashCard(
      title: 'Auth by Type',
      subtitle: "Today's breakdown",
      child: Column(
        children: [
          const SizedBox(height: 8),
          _DonutRing(
            segments: [
              _DonutSeg(processed / total, const Color(0xFF6366F1)),
              _DonutSeg(pending / total, const Color(0xFF10B981)),
            ],
            centerLabel: '$_totalAuthQueue',
            centerSub: 'Total',
          ),
          const SizedBox(height: 12),
          _legend(const Color(0xFF6366F1), 'Processed'),
          const SizedBox(height: 4),
          _legend(const Color(0xFF10B981), 'Pending'),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildWeeklyActivity() {
    return _DashCard(
      title: 'Weekly Activity',
      subtitle: 'Auth volume by day',
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_weeklyData.length, (i) {
              final v = _weeklyData[i];
              final max = _weeklyData.reduce((a, b) => a > b ? a : b);
              final frac = max == 0 ? 0.0 : (v / max);
              return Column(
                children: [
                  Text('$v',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    height: 36,
                    width: 28,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                          const Color(0xFF1E2B5E).withValues(alpha: 0.3),
                          const Color(0xFF1E2B5E),
                          frac),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                      style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w700)),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Low',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('→',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('High',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentQueue() {
    return _DashCard(
      title: 'Recent Auth Queue',
      subtitle: 'Latest pending items',
      action: TextButton(
        onPressed: () => widget.onProceed('AUTH'),
        child: const Text('View All',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w700)),
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()))
          : _recentAuthItems.isEmpty
              ? _emptyState()
              : Column(
                  children: [
                    _queueHeader(),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ..._recentAuthItems.map((r) => _queueRow(r)),
                  ],
                ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 40, color: Color(0xFFCBD5E1)),
            SizedBox(height: 8),
            Text('No pending items',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _queueHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: const [
          Expanded(
              flex: 3,
              child: Text('AUTH SL',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5))),
          Expanded(
              flex: 3,
              child: Text('PROGRAM',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5))),
          Expanded(
              flex: 2,
              child: Text('STATUS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5))),
        ],
      ),
    );
  }

  Widget _queueRow(AuthRecord r) {
    final isPending = r.flUser == null || r.flUser == '0' || r.flUser!.isEmpty;
    final statusColor =
        isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final statusLabel = isPending ? 'Pending' : 'In Review';
    return InkWell(
      onTap: () => widget.onProceed('AUTH'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(r.authSl,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2B5E))),
            ),
            Expanded(
              flex: 3,
              child: Text(r.programId.isNotEmpty ? r.programId : '-',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialExposure() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF1E2B5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Overview',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Live metrics',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 20),
          _darkStat(
              'Auth Queue', '$_totalAuthQueue items', const Color(0xFF818CF8)),
          const SizedBox(height: 14),
          _darkStat('GL Categories', '$_glCategories configured',
              const Color(0xFF34D399)),
          const SizedBox(height: 14),
          _darkStat(
              'GL Masters', '$_glMasters ledgers', const Color(0xFFFBBF24)),
          const SizedBox(height: 14),
          _darkStat('Total Users', '$_totalUsersCount registered',
              const Color(0xFFF472B6)),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _fetchDashboardData,
              icon: const Icon(Icons.refresh_rounded,
                  size: 16, color: Colors.white70),
              label: const Text('Refresh Data',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkStat(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // ── Chart of Accounts Overview ───────────────────────────────────────────
  Widget _buildChartOfAccountsOverview(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chart of Accounts Structure',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B1628))),
          const SizedBox(height: 4),
          const Text('Primary ledger distribution across categories',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 24),

          // Segmented Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (_coaDistribution[0] > 0)
                  Expanded(
                      flex: _coaDistribution[0],
                      child: Container(
                          height: 12,
                          color: const Color(0xFF3B82F6))), // Assets
                if (_coaDistribution[1] > 0)
                  Expanded(
                      flex: _coaDistribution[1],
                      child: Container(
                          height: 12,
                          color: const Color(0xFFF59E0B))), // Liabilities
                if (_coaDistribution[2] > 0)
                  Expanded(
                      flex: _coaDistribution[2],
                      child: Container(
                          height: 12,
                          color: const Color(0xFF8B5CF6))), // Equity
                if (_coaDistribution[3] > 0)
                  Expanded(
                      flex: _coaDistribution[3],
                      child: Container(
                          height: 12,
                          color: const Color(0xFF10B981))), // Income
                if (_coaDistribution[4] > 0)
                  Expanded(
                      flex: _coaDistribution[4],
                      child: Container(
                          height: 12,
                          color: const Color(0xFFEF4444))), // Expenses
                if (_coaDistribution.every((v) => v == 0))
                  Expanded(
                      flex: 1,
                      child: Container(
                          height: 12,
                          color: const Color(0xFFE2E8F0))), // Empty State
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Legends
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _coaLegend(
                  'Assets', '${_coaDistribution[0]}%', const Color(0xFF3B82F6)),
              _coaLegend('Liabilities', '${_coaDistribution[1]}%',
                  const Color(0xFFF59E0B)),
              _coaLegend(
                  'Equity', '${_coaDistribution[2]}%', const Color(0xFF8B5CF6)),
              _coaLegend(
                  'Income', '${_coaDistribution[3]}%', const Color(0xFF10B981)),
              _coaLegend('Expenses', '${_coaDistribution[4]}%',
                  const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coaLegend(String title, String range, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B1628))),
            Text(range,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }

  // ── Quick Actions ────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _ActionItem(Icons.security_rounded, 'Auth Queue', 'Review pending items',
          const Color(0xFF6366F1), () => widget.onProceed('AUTH')),
      _ActionItem(Icons.account_balance_rounded, 'GL Module', 'Manage ledgers',
          const Color(0xFF10B981), () => widget.onProceed('GL')),
      _ActionItem(
          Icons.account_tree_rounded,
          'Chart of Accounts',
          'View ledger hierarchy',
          const Color(0xFF8B5CF6),
          () => widget.onSelect('RPT-COA')),
      _ActionItem(Icons.people_rounded, 'Masters', 'Users & roles',
          const Color(0xFF3B82F6), () => widget.onProceed('MASTERS')),
      _ActionItem(Icons.description_rounded, 'Journals', 'Post transactions',
          const Color(0xFFF59E0B), () => widget.onSelect('GL-JRN')),
      _ActionItem(Icons.bar_chart_rounded, 'Reports', 'Financial reports',
          const Color(0xFFEC4899), () => widget.onProceed('REPORTS')),
    ];
    return _DashCard(
      title: 'Quick Actions',
      subtitle: 'Navigate to modules',
      child: Column(
        children: actions.map((a) => _actionTile(a)).toList(),
      ),
    );
  }

  Widget _actionTile(_ActionItem a) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: a.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: a.color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: a.color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: a.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(a.icon, size: 16, color: a.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.label,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B1628))),
                    Text(a.sub,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: a.color),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Programs ─────────────────────────────────────────────
  Widget _buildTopPrograms() {
    // Count program occurrences in auth queue
    final Map<String, int> counts = {};
    for (final r in _recentAuthItems) {
      if (r.programId.isNotEmpty) {
        counts[r.programId] = (counts[r.programId] ?? 0) + 1;
      }
    }
    // If no data, show placeholder
    final List<MapEntry<String, int>> sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final displayItems = sorted.isNotEmpty
        ? sorted.take(5).toList()
        : [
            const MapEntry('GL-MST', 12),
            const MapEntry('GL-CAT', 8),
            const MapEntry('ORG-CRT', 5),
            const MapEntry('BRN-CRT', 3),
            const MapEntry('USR-CRT', 2),
          ];

    final maxVal = displayItems.isEmpty ? 1 : displayItems.first.value;
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];

    return _DashCard(
      title: 'Top Programs',
      subtitle: sorted.isNotEmpty ? 'This week' : 'Placeholder data',
      child: Column(
        children: displayItems.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final frac = maxVal == 0 ? 0.0 : e.value / maxVal;
          final color = colors[i % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text(e.key,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B1628))),
                    ]),
                    Text('${e.value}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: frac.toDouble(),
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────────────────────────────────────
// KPI Data Model
// ──────────────────────────────────────────
class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final VoidCallback? onTap;
  _KpiData(
      this.title, this.value, this.icon, this.color, this.trend, this.onTap);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  final bool isLoading;
  const _KpiCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isLoading ? '...' : data.value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B1628))),
                Text(data.title,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(data.trend,
                    style: TextStyle(
                        fontSize: 10,
                        color: data.color,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );

    if (data.onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: data.onTap, child: card),
      );
    }
    return card;
  }
}

// ──────────────────────────────────────────
// Bar chart item
// ──────────────────────────────────────────
class _BarItem extends StatelessWidget {
  final int value;
  final int maxVal;
  final String label;
  final bool isHighlight;
  const _BarItem(
      {required this.value,
      required this.maxVal,
      required this.label,
      this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    final frac = maxVal == 0 ? 0.0 : (value / maxVal);
    final double h = frac * 140.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$value',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isHighlight
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutQuart,
          height: h,
          width: 28,
          decoration: BoxDecoration(
            color: isHighlight
                ? const Color(0xFF6366F1)
                : const Color(0xFF1E2B5E).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ──────────────────────────────────────────
// Simple Donut Ring
// ──────────────────────────────────────────
class _DonutSeg {
  final double fraction;
  final Color color;
  _DonutSeg(this.fraction, this.color);
}

class _DonutRing extends StatelessWidget {
  final List<_DonutSeg> segments;
  final String centerLabel;
  final String centerSub;
  const _DonutRing(
      {required this.segments,
      required this.centerLabel,
      required this.centerSub});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(130, 130),
            painter: _DonutPainter(segments),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerLabel,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B1628))),
              Text(centerSub,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSeg> segments;
  _DonutPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeW = 14.0;
    double start = -1.5707963267948966;
    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.color
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      final sweep = seg.fraction * 6.283185307179586;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
          sweep - 0.05, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

// ──────────────────────────────────────────
// Dashboard Card wrapper
// ──────────────────────────────────────────
class _DashCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;
  const _DashCard(
      {required this.title,
      required this.subtitle,
      required this.child,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0B1628))),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Helper data classes
// ──────────────────────────────────────────

class _ActionItem {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem(this.icon, this.label, this.sub, this.color, this.onTap);
}

// ──────────────────────────────────────────
// Gauge arc painter for SLA section
// ──────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double value; // 0.0 – 1.0
  final Color color;
  const _GaugePainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeW / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.356, // 135 deg in radians
      4.712, // 270 deg sweep
      false,
      bgPaint,
    );

    // Value arc
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.356,
      4.712 * value.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

// ──────────────────────────────────────────
// Floating Finance Background Animation
// ──────────────────────────────────────────
class _FloatingFinanceBackground extends StatefulWidget {
  const _FloatingFinanceBackground();
  @override
  __FloatingFinanceBackgroundState createState() =>
      __FloatingFinanceBackgroundState();
}

class __FloatingFinanceBackgroundState extends State<_FloatingFinanceBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late List<_FloatingSymbol> _symbols;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 40))
          ..repeat();
    _symbols = List.generate(20, (index) => _FloatingSymbol(_random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: _symbols.map((sym) {
                final double progress =
                    (_controller.value + sym.startOffset) % 1.0;
                final double top =
                    (1.0 - progress) * (constraints.maxHeight + 40);
                final double left = sym.horizontalPos * constraints.maxWidth +
                    (sin(progress * pi * 2 + sym.startOffset) * 30);
                return Positioned(
                  top: top - 20,
                  left: left - 20,
                  child: Opacity(
                    opacity: sin(progress * pi) * 0.15,
                    child: Transform.rotate(
                      angle: progress * pi * 2 * sym.spinSpeed,
                      child: Text(
                        sym.symbol,
                        style: TextStyle(
                          fontSize: sym.size,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _FloatingSymbol {
  late String symbol;
  late double startOffset;
  late double horizontalPos;
  late double size;
  late double spinSpeed;
  final List<String> _options = [
    '₹',
    '\$',
    '€',
    '£',
    '%',
    '¥',
    '📈',
    '📊',
    '₹'
  ];

  _FloatingSymbol(Random rand) {
    symbol = _options[rand.nextInt(_options.length)];
    startOffset = rand.nextDouble();
    horizontalPos = rand.nextDouble();
    size = 18 + rand.nextDouble() * 32;
    spinSpeed = (rand.nextDouble() - 0.5) * 2;
  }
}
