import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'submenu_dashboard_screen.dart';
import '../utils/responsive.dart';
import '../theme.dart';
import '../services/api_service.dart';

class MasterDashboardScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? userName;
  final List<SubmenuItem> items;
  final void Function(String, String?)? onNavigate;

  const MasterDashboardScreen({
    super.key,
    this.onBack,
    this.userName,
    this.items = const [],
    this.onNavigate,
  });

  @override
  State<MasterDashboardScreen> createState() => _MasterDashboardScreenState();
}

class _MasterDashboardScreenState extends State<MasterDashboardScreen> {
  SubmenuItem? _hoveredModule;
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _newUsers = 0;
  int _pendingApprovals = 0;
  bool _isLoading = true;

  // bumped whenever fresh KPI data lands, so count-up animations replay
  int _kpiRevision = 0;

  @override
  void initState() {
    super.initState();
    _fetchDynamicData();
  }

  Future<void> _fetchDynamicData() async {
    try {
      final res = await apiService.getUsers(page: 0, size: 100);
      if (res != null) {
        if (mounted) {
          setState(() {
            _totalUsers = res.totalElements;
            final active = res.items.where((u) => u['userStat'] == 'A' || u['status'] == 'Active' || u['userStat'] == 'Active').length;
            _activeUsers = active > 0 ? active : (_totalUsers * 0.9).round();
            _newUsers = (_totalUsers * 0.05).round(); // Estimated if missing created date API
            _isLoading = false;
            _kpiRevision++;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }

      final authRes = await apiService.getAuthQueue(page: 0, size: 1);
      if (authRes != null && mounted) {
        setState(() {
          _pendingApprovals = authRes.totalElements;
          _kpiRevision++;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grayish-blue background from image
      body: Stack(
        children: [
          const Positioned.fill(child: _AnimatedBackgroundBlobs()),
          SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FadeSlideIn(
                  index: 0,
                  child: Row(
                    children: [
                      Text(
                        'Master Dashboard',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C2434),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const _LiveBadge(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. KPI Cards Row
                if (isMobile)
                  Column(
                    children: [
                      _FadeSlideIn(index: 1, child: _buildKpiCard(Icons.people_alt_outlined, const Color(0xFF3C50E0), 'Total Users', '12.5%', true, numericValue: _isLoading ? null : _totalUsers)),
                      const SizedBox(height: 16),
                      _FadeSlideIn(index: 2, child: _buildKpiCard(Icons.verified_user_outlined, const Color(0xFF10B981), 'Active Users', '5.2%', true, numericValue: _isLoading ? null : _activeUsers)),
                      const SizedBox(height: 16),
                      _FadeSlideIn(index: 3, child: _buildKpiCard(Icons.person_add_alt_1_outlined, const Color(0xFFFFA70B), 'New Users (This Week)', '8.1%', true, numericValue: _isLoading ? null : _newUsers)),
                      const SizedBox(height: 16),
                      _FadeSlideIn(index: 4, child: _buildKpiCard(Icons.pending_actions_outlined, const Color(0xFFEF4444), 'Pending Approvals', '2.4%', false, numericValue: _isLoading ? null : _pendingApprovals, urgent: !_isLoading && _pendingApprovals > 0)),
                    ],
                  )
                else if (isTablet)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _FadeSlideIn(index: 1, child: _buildKpiCard(Icons.people_alt_outlined, const Color(0xFF3C50E0), 'Total Users', '12.5%', true, numericValue: _isLoading ? null : _totalUsers))),
                          const SizedBox(width: 16),
                          Expanded(child: _FadeSlideIn(index: 2, child: _buildKpiCard(Icons.verified_user_outlined, const Color(0xFF10B981), 'Active Users', '5.2%', true, numericValue: _isLoading ? null : _activeUsers))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _FadeSlideIn(index: 3, child: _buildKpiCard(Icons.person_add_alt_1_outlined, const Color(0xFFFFA70B), 'New Users (This Week)', '8.1%', true, numericValue: _isLoading ? null : _newUsers))),
                          const SizedBox(width: 16),
                          Expanded(child: _FadeSlideIn(index: 4, child: _buildKpiCard(Icons.pending_actions_outlined, const Color(0xFFEF4444), 'Pending Approvals', '2.4%', false, numericValue: _isLoading ? null : _pendingApprovals, urgent: !_isLoading && _pendingApprovals > 0))),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: _FadeSlideIn(index: 1, child: _buildKpiCard(Icons.people_alt_outlined, const Color(0xFF3C50E0), 'Total Users', '12.5%', true, numericValue: _isLoading ? null : _totalUsers))),
                      const SizedBox(width: 24),
                      Expanded(child: _FadeSlideIn(index: 2, child: _buildKpiCard(Icons.verified_user_outlined, const Color(0xFF10B981), 'Active Users', '5.2%', true, numericValue: _isLoading ? null : _activeUsers))),
                      const SizedBox(width: 24),
                      Expanded(child: _FadeSlideIn(index: 3, child: _buildKpiCard(Icons.person_add_alt_1_outlined, const Color(0xFFFFA70B), 'New Users (This Week)', '8.1%', true, numericValue: _isLoading ? null : _newUsers))),
                      const SizedBox(width: 24),
                      Expanded(child: _FadeSlideIn(index: 4, child: _buildKpiCard(Icons.pending_actions_outlined, const Color(0xFFEF4444), 'Pending Approvals', '2.4%', false, numericValue: _isLoading ? null : _pendingApprovals, urgent: !_isLoading && _pendingApprovals > 0))),
                    ],
                  ),

                const SizedBox(height: 48),

                // 2. COMMAND CENTER ROW (Flanked by Secondary Charts on Desktop)
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _FadeSlideIn(index: 5, child: _buildMonthlyUserCreationTrendLineChart())),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _FadeSlideIn(index: 5, child: const _CommandCenterHeading()),
                            const SizedBox(height: 40),
                            _FadeSlideIn(index: 6, child: _buildModulesGrid(isMobile)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: _FadeSlideIn(index: 5, child: _buildRoleDistributionPieChart())),
                    ],
                  )
                else if (isTablet)
                  Column(
                    children: [
                      _FadeSlideIn(index: 5, child: const _CommandCenterHeading()),
                      const SizedBox(height: 32),
                      _FadeSlideIn(index: 6, child: _buildModulesGrid(isMobile)),
                      const SizedBox(height: 48),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _FadeSlideIn(index: 7, child: _buildMonthlyUserCreationTrendLineChart())),
                          const SizedBox(width: 24),
                          Expanded(child: _FadeSlideIn(index: 7, child: _buildRoleDistributionPieChart())),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _FadeSlideIn(index: 5, child: const _CommandCenterHeading()),
                      const SizedBox(height: 32),
                      _FadeSlideIn(index: 6, child: _buildModulesGrid(isMobile)),
                      const SizedBox(height: 48),
                      _FadeSlideIn(index: 7, child: _buildMonthlyUserCreationTrendLineChart()),
                      const SizedBox(height: 24),
                      _FadeSlideIn(index: 8, child: _buildRoleDistributionPieChart()),
                    ],
                  ),
                const SizedBox(height: 32),
                _FadeSlideIn(index: 9, child: _buildBranchWiseUsersBarChart()),
                const SizedBox(height: 32),
                _FadeSlideIn(index: 10, child: _buildRecentActivities()),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(IconData icon, Color color, String label, String percentage, bool isPositive, {int? numericValue, bool urgent = false}) {
    return _KpiCard(
      icon: icon,
      color: color,
      label: label,
      percentage: percentage,
      isPositive: isPositive,
      numericValue: numericValue,
      revision: _kpiRevision,
      urgent: urgent,
    );
  }

  Widget _buildDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BreathingDot(color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchWiseUsersBarChart() {
    final rawGroups = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 65, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 15, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 45, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 10, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 80, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 20, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 55, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 5, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 70, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 25, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 90, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 10, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 40, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 15, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
    ];

    return _GlowCard(
      accentColor: const Color(0xFF3C50E0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Branch-wise Users',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C2434),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildDropdown('All Branches'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendDot(const Color(0xFF3C50E0), 'Active Users'),
              _buildLegendDot(const Color(0xFF00B4D8), 'Inactive Users'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: _ChartGrowIn(
              duration: const Duration(milliseconds: 900),
              builder: (progress) => BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: progress > 0.95,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => const Color(0xFF1C2434),
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = rodIndex == 0 ? 'Active' : 'Inactive';
                        return BarTooltipItem(
                          '$label: ${rod.toY.round()}',
                          GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const branches = ['BR-01', 'BR-02', 'BR-03', 'BR-04', 'BR-05', 'BR-06', 'BR-07'];
                          if (value.toInt() >= 0 && value.toInt() < branches.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                branches[value.toInt()],
                                style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == 100) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _scaleBarGroups(rawGroups, progress),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<BarChartGroupData> _scaleBarGroups(List<BarChartGroupData> groups, double progress) {
    return groups
        .map((g) => BarChartGroupData(
              x: g.x,
              barRods: g.barRods
                  .map((r) => BarChartRodData(
                        toY: r.toY * progress,
                        color: r.color,
                        width: r.width,
                        borderRadius: r.borderRadius,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: const Color(0xFFF8FAFC),
                        ),
                      ))
                  .toList(),
            ))
        .toList();
  }

  Widget _buildMonthlyUserCreationTrendLineChart() {
    const rawSpots = [
      FlSpot(0, 12), FlSpot(1, 15), FlSpot(2, 8), FlSpot(3, 20), FlSpot(4, 25), FlSpot(5, 18),
      FlSpot(6, 30), FlSpot(7, 35), FlSpot(8, 28), FlSpot(9, 45), FlSpot(10, 38), FlSpot(11, 48),
    ];

    return _GlowCard(
      accentColor: const Color(0xFF3C50E0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'User Creation Trend',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C2434),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildDropdown('This Year'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: _AnimatedLineChart(spots: rawSpots),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDistributionPieChart() {
    return _GlowCard(
      accentColor: const Color(0xFF8B5CF6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Role Distribution',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C2434),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildDropdown('All Orgs'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: _AnimatedPieChart(),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendDot(const Color(0xFF3C50E0), 'Staff'),
              _buildLegendDot(const Color(0xFF00B4D8), 'Manager'),
              _buildLegendDot(const Color(0xFF8B5CF6), 'Admin'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      {'title': 'New User Created', 'desc': 'Admin created a new user profile for BR-01', 'time': '2 mins ago', 'icon': Icons.person_add, 'color': const Color(0xFF10B981)},
      {'title': 'Role Permissions Updated', 'desc': 'Manager role permissions modified in HQ', 'time': '1 hour ago', 'icon': Icons.security, 'color': const Color(0xFF3C50E0)},
      {'title': 'Password Reset Requested', 'desc': 'User requested a password reset link', 'time': '3 hours ago', 'icon': Icons.lock_reset, 'color': const Color(0xFFF59E0B)},
      {'title': 'System Backup Completed', 'desc': 'Automated daily backup completed successfully', 'time': '5 hours ago', 'icon': Icons.cloud_done, 'color': const Color(0xFF00B4D8)},
      {'title': 'Failed Login Attempt', 'desc': 'Multiple failed login attempts detected from IP 192.168.1.5', 'time': '1 day ago', 'icon': Icons.error_outline, 'color': const Color(0xFFEF4444)},
    ];

    return _GlowCard(
      accentColor: const Color(0xFF10B981),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2434),
            ),
          ),
          const SizedBox(height: 24),
          ...activities.asMap().entries.map((entry) {
            final activity = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _FadeSlideIn(
                index: entry.key,
                stagger: const Duration(milliseconds: 80),
                child: _ActivityRow(
                  title: activity['title'] as String,
                  desc: activity['desc'] as String,
                  time: activity['time'] as String,
                  icon: activity['icon'] as IconData,
                  color: activity['color'] as Color,
                  isNew: entry.key == 0,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModulesGrid(bool isMobile) {
    return _ProtractorModules(
      items: widget.items,
      onNavigate: widget.onNavigate,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animation helper widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Generic staggered fade + slide-up entrance wrapper.
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration stagger;

  const _FadeSlideIn({
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 70),
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
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.05),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Small reusable fade-in after a fixed delay (not index-based).
class _DelayedFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _DelayedFade({required this.child, this.delay = const Duration(milliseconds: 400)});

  @override
  State<_DelayedFade> createState() => _DelayedFadeState();
}

class _DelayedFadeState extends State<_DelayedFade> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: widget.child,
    );
  }
}

/// Runs a one-shot 0->1 progress animation once when first built, and
/// rebuilds [builder] on every tick — used to make fl_chart bars/lines/
/// pie slices grow in from nothing instead of popping in fully drawn.
class _ChartGrowIn extends StatelessWidget {
  final Widget Function(double progress) builder;
  final Duration duration;
  final Curve curve;

  const _ChartGrowIn({
    required this.builder,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, progress, child) => builder(progress),
    );
  }
}

/// Drifting, slowly-pulsing soft color blobs painted behind the whole page
/// for a bit of ambient life. Kept very low-opacity so it never competes
/// with foreground content.
class _AnimatedBackgroundBlobs extends StatefulWidget {
  const _AnimatedBackgroundBlobs();

  @override
  State<_AnimatedBackgroundBlobs> createState() => _AnimatedBackgroundBlobsState();
}

class _AnimatedBackgroundBlobsState extends State<_AnimatedBackgroundBlobs> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value * 2 * math.pi;
          return Stack(
            children: [
              Positioned(
                top: -80 + 30 * math.sin(t),
                left: -60 + 40 * math.cos(t * 0.8),
                child: _blob(280, const Color(0xFF3C50E0).withValues(alpha: 0.06)),
              ),
              Positioned(
                bottom: -100 + 35 * math.cos(t * 0.6),
                right: -80 + 30 * math.sin(t * 0.9),
                child: _blob(320, const Color(0xFF8B5CF6).withValues(alpha: 0.05)),
              ),
              Positioned(
                top: 260 + 25 * math.sin(t * 1.2),
                right: 40 + 20 * math.cos(t),
                child: _blob(200, const Color(0xFF00B4D8).withValues(alpha: 0.05)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Small "Live" chip with a pulsing green dot — sits next to the page title.
class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DelayedFade(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                opacity: 0.5 + 0.5 * _controller.value,
                child: child,
              ),
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'LIVE',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF10B981), letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Command Center" section heading with an elastic-growing accent bar.
class _CommandCenterHeading extends StatelessWidget {
  const _CommandCenterHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Container(
            width: 6,
            height: 28 * v.clamp(0, 1),
            decoration: BoxDecoration(color: const Color(0xFF3C50E0), borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Text('Command Center', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF1C2434))),
      ],
    );
  }
}

/// White card wrapper with a thin animated gradient sweep along the top
/// edge — a subtle "scanning" accent that loops continuously.
class _GlowCard extends StatefulWidget {
  final Widget child;
  final Color accentColor;
  const _GlowCard({required this.child, required this.accentColor});

  @override
  State<_GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<_GlowCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 2.5,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => CustomPaint(
                painter: _SweepPainter(progress: _controller.value, color: widget.accentColor),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(24), child: widget.child),
        ],
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  final double progress;
  final Color color;
  _SweepPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment(-1.5 + progress * 3, 0),
        end: Alignment(-0.5 + progress * 3, 0),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Legend dot that gently breathes (scale pulse) to feel a little alive.
class _BreathingDot extends StatefulWidget {
  final Color color;
  const _BreathingDot({required this.color});

  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Continuously pulsing little notification dot — used to flag urgent KPIs.
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t).clamp(0, 1),
                child: Container(
                  width: 16 * t + 6,
                  height: 16 * t + 6,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// KPI card — count-up numbers, hover lift, breathing icon glow ring,
/// bouncing trend arrow, skeleton pulse while loading, and an optional
/// pulsing "urgent" dot for things like pending approvals.
class _KpiCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String percentage;
  final bool isPositive;
  final int? numericValue;
  final int revision;
  final bool urgent;

  const _KpiCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.percentage,
    required this.isPositive,
    required this.numericValue,
    required this.revision,
    this.urgent = false,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> with TickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _glowController;
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  String _formatValue(int v) => NumberFormat('#,##0').format(v);

  @override
  Widget build(BuildContext context) {
    final loading = widget.numericValue == null;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? widget.color.withValues(alpha: 0.35) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? widget.color.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.05),
              blurRadius: _isHovered ? 20 : 10,
              offset: _isHovered ? const Offset(0, 10) : const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) => Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.18 + 0.14 * _glowController.value),
                          blurRadius: 14 + 8 * _glowController.value,
                          spreadRadius: 1 + 2 * _glowController.value,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                if (widget.urgent)
                  const Positioned(top: -2, right: -2, child: _PulsingDot(color: Color(0xFFEF4444))),
              ],
            ),
            const SizedBox(height: 24),
            loading
                ? const _SkeletonBar(width: 64, height: 24)
                : TweenAnimationBuilder<int>(
                    key: ValueKey('${widget.revision}-${widget.numericValue}'),
                    tween: IntTween(begin: 0, end: widget.numericValue),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) => Text(
                      _formatValue(v),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C2434),
                      ),
                    ),
                  ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isHovered ? widget.color : const Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.percentage,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedBuilder(
                      animation: _bounceController,
                      builder: (context, child) {
                        final dy = widget.isPositive ? -2 * _bounceController.value : 2 * _bounceController.value;
                        return Transform.translate(offset: Offset(0, dy), child: child);
                      },
                      child: Icon(
                        widget.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: widget.isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsing grey skeleton placeholder shown while a KPI value is loading.
class _SkeletonBar extends StatefulWidget {
  final double width;
  final double height;
  const _SkeletonBar({required this.width, required this.height});

  @override
  State<_SkeletonBar> createState() => _SkeletonBarState();
}

class _SkeletonBarState extends State<_SkeletonBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/// Activity feed row with a soft hover highlight + slide-right nudge.
/// The most recent item can show a small pulsing "NEW" chip.
class _ActivityRow extends StatefulWidget {
  final String title;
  final String desc;
  final String time;
  final IconData icon;
  final Color color;
  final bool isNew;

  const _ActivityRow({
    required this.title,
    required this.desc,
    required this.time,
    required this.icon,
    required this.color,
    this.isNew = false,
  });

  @override
  State<_ActivityRow> createState() => _ActivityRowState();
}

class _ActivityRowState extends State<_ActivityRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        transform: Matrix4.identity()..translate(_isHovered ? 4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF8FAFC) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: _isHovered ? 0.18 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C2434),
                        ),
                      ),
                      if (widget.isNew) ...[
                        const SizedBox(width: 8),
                        const _NewChip(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.desc,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.time,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pulsing "NEW" chip for the most recent activity item.
class _NewChip extends StatefulWidget {
  const _NewChip();

  @override
  State<_NewChip> createState() => _NewChipState();
}

class _NewChipState extends State<_NewChip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(opacity: 0.6 + 0.4 * _controller.value, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'NEW',
          style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF10B981), letterSpacing: 0.4),
        ),
      ),
    );
  }
}

/// Line chart that draws itself in on first build, then keeps its end-point
/// dots gently pulsing, plus interactive tooltips on hover/tap.
class _AnimatedLineChart extends StatefulWidget {
  final List<FlSpot> spots;
  const _AnimatedLineChart({required this.spots});

  @override
  State<_AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<_AnimatedLineChart> with TickerProviderStateMixin {
  late final AnimationController _drawController;
  late final AnimationController _pulseController;
  late final Animation<double> _draw;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _draw = CurvedAnimation(parent: _drawController, curve: Curves.easeOutCubic);
    _pulse = Tween<double>(begin: 3.5, end: 5.5).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _drawController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_draw, _pulse]),
      builder: (context, _) {
        final progress = _draw.value;
        final dotRadius = _pulse.value;
        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: const Color(0xFFE2E8F0),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: progress > 0.95,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => const Color(0xFF1C2434),
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) => touchedSpots
                    .map((s) => LineTooltipItem(
                          '${s.y.round()} users',
                          GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        ))
                    .toList(),
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    if (value.toInt() >= 0 && value.toInt() < 12) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          months[value.toInt()],
                          style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                        ),
                      );
                    }
                    return const Text('');
                  },
                  interval: 1,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 10,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 11,
            minY: 0,
            maxY: 50,
            lineBarsData: [
              LineChartBarData(
                spots: widget.spots.map((s) => FlSpot(s.x, s.y * progress)).toList(),
                isCurved: true,
                color: const Color(0xFF3C50E0),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: progress > 0.85,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: dotRadius,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: const Color(0xFF3C50E0),
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3C50E0).withValues(alpha: 0.2 * progress),
                      const Color(0xFF3C50E0).withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pie chart that grows in, supports touch highlight of a slice, and shows
/// an animated total in the donut hole.
class _AnimatedPieChart extends StatefulWidget {
  @override
  State<_AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<_AnimatedPieChart> {
  int? _touchedIndex;

  static const _sections = [
    {'color': Color(0xFF3C50E0), 'value': 50.0},
    {'color': Color(0xFF00B4D8), 'value': 35.0},
    {'color': Color(0xFF8B5CF6), 'value': 15.0},
  ];

  @override
  Widget build(BuildContext context) {
    return _ChartGrowIn(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (progress) => Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 70,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                enabled: progress > 0.95,
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                    setState(() => _touchedIndex = null);
                    return;
                  }
                  setState(() => _touchedIndex = response.touchedSection!.touchedSectionIndex);
                },
              ),
              sections: List.generate(_sections.length, (i) {
                final s = _sections[i];
                final isTouched = i == _touchedIndex;
                const baseRadius = 20.0;
                final clampedProgress = progress.clamp(0.0, 1.0);
                return PieChartSectionData(
                  color: s['color'] as Color,
                  value: s['value'] as double,
                  title: progress > 0.8 ? '${(s['value'] as double).round()}%' : '',
                  radius: (isTouched ? baseRadius + 8 : baseRadius) * clampedProgress,
                  titleStyle: GoogleFonts.outfit(
                    fontSize: isTouched ? 12 : 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
          _DelayedFade(
            delay: const Duration(milliseconds: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('100%', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1C2434))),
                Text('Total Roles', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtractorModules extends StatefulWidget {
  final List<SubmenuItem> items;
  final Function(String, String)? onNavigate;

  const _ProtractorModules({required this.items, this.onNavigate});

  @override
  State<_ProtractorModules> createState() => _ProtractorModulesState();
}

class _ProtractorModulesState extends State<_ProtractorModules> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  Timer? _scrollDebounce;
  double _dragAccumulator = 0.0;
  bool _entranceDone = false;
  late final AnimationController _selectedGlowController;

  @override
  void initState() {
    super.initState();
    _selectedGlowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _entranceDone = true);
    });
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _selectedGlowController.dispose();
    super.dispose();
  }

  void _selectIndex(int index) {
    if (index < 0 || index >= widget.items.length) return;
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(event, (PointerSignalEvent e) {
        if (e is PointerScrollEvent) {
          double delta = e.scrollDelta.dy != 0 ? e.scrollDelta.dy : e.scrollDelta.dx;
          if (delta == 0) return;

          if (_scrollDebounce?.isActive ?? false) return;
          _scrollDebounce = Timer(const Duration(milliseconds: 150), () {});

          // Scroll down/right -> move selection to the right (increase index)
          int newIndex = _selectedIndex + (delta > 0 ? 1 : -1);
          _selectIndex(newIndex);
        }
      });
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragAccumulator += details.primaryDelta!;
    int jumps = (_dragAccumulator / 30).truncate(); // 30 pixels per jump

    if (jumps != 0) {
      // Swiping right (positive delta) -> implies dragging items right -> selection moves left
      int newIndex = _selectedIndex - jumps;

      // Clamp index so it doesn't go out of bounds on the fixed arc
      if (newIndex >= 0 && newIndex < widget.items.length) {
        if (newIndex != _selectedIndex) {
          _selectIndex(newIndex);
        }
        _dragAccumulator -= jumps * 30;
      } else {
        // Hit the end, clear accumulator so it doesn't build up resistance
        _dragAccumulator = 0.0;
      }
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _dragAccumulator = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);

        final double iconSelectedSize = isMobile ? 48.0 : 64.0; // Slightly smaller icons for a tighter look
        final double iconBaseSize = isMobile ? 36.0 : 48.0;

        // Use the actual available width from its parent container (LayoutBuilder), not the full screen width
        double availableWidth = constraints.maxWidth;

        // Subtract space for the icons themselves and some margin
        availableWidth -= (iconSelectedSize + 32);

        // Clamp maximum size so it doesn't look gigantic on large screens
        if (availableWidth > 550) availableWidth = 550;
        if (availableWidth < 250) availableWidth = 250;

        // Radius dynamically adjusts
        final double radius = availableWidth / 2;

        // Center panel scales proportionally
        final double centerDetailsRadius = isMobile ? radius * 0.75 : radius * 0.65;

        // Offset to ensure the bottom items are not cut off and are perfectly centered
        final double bottomOffset = iconSelectedSize / 2;

        final double containerWidth = availableWidth + iconSelectedSize;
        final double containerHeight = radius + iconSelectedSize;

        return AnimatedOpacity(
          opacity: _entranceDone ? 1 : 0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: _entranceDone ? 1 : 0.92,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            child: SizedBox(
          width: containerWidth,
          height: containerHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The fixed protractor dial items
              ...List.generate(widget.items.length, (index) {
                final item = widget.items[index];
                final isSelected = _selectedIndex == index;

                // Base angles range from pi (left, index 0) to 0 (right, index 8)
                double step = widget.items.length > 1 ? math.pi / (widget.items.length - 1) : 0;
                double baseAngle = math.pi - (index * step);

                double size = isSelected ? iconSelectedSize : iconBaseSize;

                // Calculate exact positioning to ensure centers align perfectly on the arc
                double centerX = containerWidth / 2;
                double left = centerX + (radius * math.cos(baseAngle)) - (size / 2);
                double bottom = (radius * math.sin(baseAngle)) + bottomOffset - (size / 2);

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  left: left,
                  bottom: bottom,
                  child: _DialPop(
                    delay: Duration(milliseconds: 40 * index),
                    child: GestureDetector(
                      onTap: () => _selectIndex(index),
                      child: AnimatedBuilder(
                        animation: _selectedGlowController,
                        builder: (context, child) {
                          final glow = isSelected ? _selectedGlowController.value : 0.0;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF3C50E0) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? const Color(0xFF3C50E0).withValues(alpha: 0.35 + 0.2 * glow)
                                      : Colors.black.withValues(alpha: 0.1),
                                  blurRadius: isSelected ? 14 + 8 * glow : 5,
                                  spreadRadius: isSelected ? 1 + 2 * glow : 0,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: Icon(
                          item.icon,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          size: isSelected ? (isMobile ? 24 : 32) : (isMobile ? 18 : 24),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // The Center "Protractor" Details
              Positioned(
                left: (containerWidth / 2) - centerDetailsRadius,
                bottom: bottomOffset,
                child: Listener(
                  onPointerSignal: _onPointerSignal,
                  child: GestureDetector(
                    onHorizontalDragUpdate: _onHorizontalDragUpdate,
                    onHorizontalDragEnd: _onHorizontalDragEnd,
                    child: Container(
                      width: centerDetailsRadius * 2,
                      height: centerDetailsRadius, // Semi-circle dome
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(centerDetailsRadius),
                        topRight: Radius.circular(centerDetailsRadius),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3C50E0).withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomCenter,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOut,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: _buildCenterDetails(
                            widget.items[_selectedIndex],
                            isMobile,
                            key: ValueKey(_selectedIndex),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _buildCenterDetails(SubmenuItem item, bool isMobile, {Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min, // Ensures it only takes the required height
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Spacer removed because of MainAxisSize.min
        SizedBox(height: isMobile ? 12 : 24),
        Text(
          item.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 16 : 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C2434),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.programId,
          style: GoogleFonts.robotoMono(
            fontSize: isMobile ? 10 : 12,
            color: const Color(0xFF64748B),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniStat('Orgs', '12', isMobile),
            SizedBox(width: isMobile ? 8 : 16),
            Container(width: 1, height: isMobile ? 20 : 30, color: const Color(0xFFE2E8F0)),
            SizedBox(width: isMobile ? 8 : 16),
            _buildMiniStat('Records', '24k', isMobile),
            SizedBox(width: isMobile ? 8 : 16),
            Container(width: 1, height: isMobile ? 20 : 30, color: const Color(0xFFE2E8F0)),
            SizedBox(width: isMobile ? 8 : 16),
            _buildMiniStat('Status', 'Active', isMobile),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 20),
        _PulseButton(
          onPressed: () {
            if (widget.onNavigate != null) {
              widget.onNavigate!(item.screen, item.programId);
            }
          },
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 16 : 20),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, bool isMobile) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 14 : 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3C50E0),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isMobile ? 10 : 12,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

/// Small per-dial entrance pop used for each module icon on the arc.
class _DialPop extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _DialPop({required this.child, this.delay = Duration.zero});

  @override
  State<_DialPop> createState() => _DialPopState();
}

class _DialPopState extends State<_DialPop> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: const Duration(milliseconds: 280),
        child: widget.child,
      ),
    );
  }
}

/// Launch button with a subtle continuous pulse so the call-to-action
/// in the center "protractor" panel keeps drawing the eye gently.
class _PulseButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isMobile;

  const _PulseButton({required this.onPressed, required this.isMobile});

  @override
  State<_PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<_PulseButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.035).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    return ScaleTransition(
      scale: _scale,
      child: ElevatedButton.icon(
        onPressed: widget.onPressed,
        icon: Icon(Icons.rocket_launch, size: isMobile ? 14 : 18),
        label: Text('Launch Module', style: GoogleFonts.outfit(fontSize: isMobile ? 12 : 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3C50E0),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: isMobile ? 10 : 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}