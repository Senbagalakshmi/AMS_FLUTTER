import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../screens/submenu_dashboard_screen.dart';
import '../utils/responsive.dart';
import '../services/journal_api_service.dart';
import '../services/report_api_service.dart';
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
  State<AccountantDeskDashboardScreen> createState() => _AccountantDeskDashboardScreenState();
}

class _AccountantDeskDashboardScreenState extends State<AccountantDeskDashboardScreen> {
  final JournalApiService _journalApiService = JournalApiService();
  final ReportApiService _reportApiService = ReportApiService();

  int _journalCount = 0;
  int _coaCount = 0;
  List<Map<String, dynamic>> _recentJournals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final journals = await _journalApiService.getJournals();
      final coa = await _reportApiService.getChartOfAccounts();

      if (mounted) {
        setState(() {
          _recentJournals = journals ?? [];
          _journalCount = journals?.length ?? 0;
          _coaCount = coa?.length ?? 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TextStyle bodyStyle({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.black,
    double? height,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  TextStyle monoStyle({
    double size = 11,
    FontWeight weight = FontWeight.w700,
    Color color = Colors.grey,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFamily: 'monospace',
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🔹 HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: AmsIdentityHeader(
              icon: const Icon(
                Icons.calculate_rounded,
                size: 28,
                color: AppColors.tBlue,
              ),
              title: 'Accountant Desk',
              subtitle: 'Manage financial ledgers, post journal entries, and view account listings.',
              badges: [
                AmsBadge(label: '${widget.items.length} Modules'),
              ],
              accentColor: AppColors.tBlue,
              accentLt: AppColors.tBlueLt,
              accentMd: AppColors.tBlueMd,
              breadcrumbs: [
                HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
                HeaderBreadcrumb(label: 'Accountant Desk'),
              ],
              onBack: widget.onBack,
            ),
          ),

          // 🔹 MAIN VIEW
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 32,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. STATS ROW
                        _buildStatsRow(isMobile),
                        const SizedBox(height: 28),

                        // 2. QUICK ACTIONS / SCENARIOS
                        Text(
                          'QUICK LAUNCH MODULES',
                          style: monoStyle(
                            size: 11,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildQuickLaunchGrid(isMobile),
                        const SizedBox(height: 28),

                        // 3. RECENT ACTIVITY TABLE
                        _buildRecentJournalsCard(isMobile),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isMobile) {
    final cards = [
      _StatCard(
        title: 'Journals Posted',
        value: _journalCount.toString(),
        icon: Icons.description_rounded,
        color: const Color(0xFF4F46E5), // Indigo
        // onTap: () => widget.onNavigate('list', 'GL-JRN'),
      ),
      _StatCard(
        title: 'Chart of Accounts',
        value: _coaCount.toString(),
        icon: Icons.list_alt_rounded,
        color: const Color(0xFF0EA5E9), // Sky Blue
        // onTap: () => widget.onNavigate('list', 'RPT-COA'),
      ),
      _StatCard(
        title: 'Reports',
        value: 'Available',
        icon: Icons.pie_chart_rounded,
        color: const Color(0xFF10B981), // Emerald
        onTap: () => widget.onNavigate('submenu_dashboard', 'REPORTS'),
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: c,
                ))
            .toList(),
      );
    }

    return Row(
      children: cards
          .map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: c,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildQuickLaunchGrid(bool isMobile) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: widget.items.map((item) {
        return SizedBox(
          width: isMobile ? double.infinity : 260,
          height: isMobile ? 220 : 260,
          child: _LaunchCard(
            item: item,
            onTap: () => widget.onNavigate(item.screen, item.programId),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentJournalsCard(bool isMobile) {
    return AmsCard(
      headLeft: Row(
        children: [
          const Icon(Icons.history_rounded, size: 18, color: AppColors.tBlue),
          const SizedBox(width: 8),
          Text(
            'Recent Journal Postings',
            style: bodyStyle(size: 14, weight: FontWeight.w700, color: AppColors.ink),
          ),
        ],
      ),
      child: _recentJournals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  'No journal postings found.',
                  style: bodyStyle(color: const Color(0xFF64748B)),
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
                    horizontalInside: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
                  ),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
                      ),
                      children: [
                        _th('DATE'),
                        _th('NARRATION'),
                        _th('TRAN ID'),
                        _th('TOTAL DEBIT'),
                        _th('TOTAL CREDIT'),
                      ],
                    ),
                    ..._recentJournals.take(5).map((j) {
                      final debit = (j['totaldebit'] as num?)?.toDouble() ?? 0.0;
                      final credit = (j['totalcredit'] as num?)?.toDouble() ?? 0.0;
                      final fmt = NumberFormat.currency(
                          symbol: '₹', decimalDigits: 2, customPattern: '\u00A4#,##0.00');

                      return TableRow(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        children: [
                          _td(Text(
                            j['trandate']?.toString().split(' ').first ?? '—',
                            style: monoStyle(size: 11.5, weight: FontWeight.w700, color: const Color(0xFF334155)),
                          )),
                          _td(Text(
                            j['narration']?.toString() ?? '—',
                            style: bodyStyle(size: 13.5, color: const Color(0xFF1E293B)),
                          )),
                          _td(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${j['tranid'] ?? '—'}',
                              style: monoStyle(size: 11.5, color: const Color(0xFF475569)),
                            ),
                          )),
                          _td(Text(
                            fmt.format(debit),
                            style: monoStyle(size: 12, color: AppColors.ink),
                          )),
                          _td(Text(
                            fmt.format(credit),
                            style: monoStyle(size: 12, color: AppColors.ink),
                          )),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  static Widget _th(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Widget _td(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: child,
    );
  }
}

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
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
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? widget.color.withOpacity(0.4) : const Color(0xFFF1F5F9),
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
        child: Row(
          children: [
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
                        colors: [widget.color.withOpacity(0.12), widget.color.withOpacity(0.06)],
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
              child: Icon(
                widget.icon,
                color: _isHovered ? Colors.white : widget.color,
                size: 26,
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
                      color: _isHovered ? widget.color : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? AppColors.tBlue.withOpacity(0.5) : const Color(0xFFF1F5F9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered 
                    ? AppColors.tBlue.withOpacity(0.08) 
                    : const Color(0xFF0F172A).withOpacity(0.03),
                blurRadius: _isHovered ? 24 : 16,
                offset: _isHovered ? const Offset(0, 12) : const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _isHovered 
                          ? const LinearGradient(
                              colors: [AppColors.tBlue, Color(0xFF1E40AF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [AppColors.tBlue.withOpacity(0.08), AppColors.tBlue.withOpacity(0.04)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isHovered ? [
                        BoxShadow(
                          color: AppColors.tBlue.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Icon(
                      widget.item.icon,
                      size: 28,
                      color: _isHovered ? Colors.white : AppColors.tBlue,
                    ),
                  ),
                  if (widget.item.metric != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isHovered ? AppColors.tBlue.withOpacity(0.08) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _isHovered ? AppColors.tBlue.withOpacity(0.2) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        widget.item.metric!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isHovered ? AppColors.tBlue : const Color(0xFF475569),
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                widget.item.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.item.subtitle ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      widget.item.programId,
                      style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (widget.item.trend != null)
                    Text(
                      widget.item.trend!,
                      style: const TextStyle(
                        fontSize: 10, 
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w700,
                      ),
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
