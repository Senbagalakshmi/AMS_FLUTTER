import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
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
  int _totalUsers = 1250;
  int _activeUsers = 1120;
  int _newUsers = 45;
  int _pendingApprovals = 12;
  bool _isLoading = true;

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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Master Dashboard',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C2434),
              ),
            ),
            const SizedBox(height: 24),

            // 1. KPI Cards Row
            if (isMobile)
              Column(
                children: [
                  _buildKpiCard(Icons.people_alt_outlined, const Color(0xFF3C50E0), _isLoading ? '...' : '$_totalUsers', 'Total Users', '12.5%', true),
                  const SizedBox(height: 16),
                  _buildKpiCard(Icons.verified_user_outlined, const Color(0xFF10B981), _isLoading ? '...' : '$_activeUsers', 'Active Users', '5.2%', true),
                  const SizedBox(height: 16),
                  _buildKpiCard(Icons.person_add_alt_1_outlined, const Color(0xFFFFA70B), _isLoading ? '...' : '$_newUsers', 'New Users (This Week)', '8.1%', true),
                  const SizedBox(height: 16),
                  _buildKpiCard(Icons.pending_actions_outlined, const Color(0xFFEF4444), _isLoading ? '...' : '$_pendingApprovals', 'Pending Approvals', '2.4%', false),
                ],
              )
            else if (isTablet)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildKpiCard(Icons.people_alt_outlined, const Color(0xFF3C50E0), _isLoading ? '...' : '$_totalUsers', 'Total Users', '12.5%', true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildKpiCard(Icons.verified_user_outlined, const Color(0xFF10B981), _isLoading ? '...' : '$_activeUsers', 'Active Users', '5.2%', true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildKpiCard(Icons.person_add_alt_1_outlined, const Color(0xFFFFA70B), _isLoading ? '...' : '$_newUsers', 'New Users (This Week)', '8.1%', true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildKpiCard(Icons.pending_actions_outlined, const Color(0xFFEF4444), _isLoading ? '...' : '$_pendingApprovals', 'Pending Approvals', '2.4%', false)),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildKpiCard(Icons.people_alt_outlined, const Color(0xFF3C50E0), _isLoading ? '...' : '$_totalUsers', 'Total Users', '12.5%', true)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildKpiCard(Icons.verified_user_outlined, const Color(0xFF10B981), _isLoading ? '...' : '$_activeUsers', 'Active Users', '5.2%', true)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildKpiCard(Icons.person_add_alt_1_outlined, const Color(0xFFFFA70B), _isLoading ? '...' : '$_newUsers', 'New Users (This Week)', '8.1%', true)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildKpiCard(Icons.pending_actions_outlined, const Color(0xFFEF4444), _isLoading ? '...' : '$_pendingApprovals', 'Pending Approvals', '2.4%', false)),
                ],
              ),
              
            const SizedBox(height: 48),
            
            // 2. COMMAND CENTER ROW (Flanked by Secondary Charts on Desktop)
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildMonthlyUserCreationTrendLineChart()),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 6, height: 28, decoration: BoxDecoration(color: const Color(0xFF3C50E0), borderRadius: BorderRadius.circular(4))),
                            const SizedBox(width: 12),
                            Text('Command Center', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF1C2434))),
                          ],
                        ),
                        const SizedBox(height: 40),
                        _buildModulesGrid(isMobile),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(flex: 3, child: _buildRoleDistributionPieChart()),
                ],
              )
            else if (isTablet)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 6, height: 28, decoration: BoxDecoration(color: const Color(0xFF3C50E0), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 12),
                      Text('Command Center', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF1C2434))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildModulesGrid(isMobile),
                  const SizedBox(height: 48),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildMonthlyUserCreationTrendLineChart()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildRoleDistributionPieChart()),
                    ],
                  ),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 6, height: 28, decoration: BoxDecoration(color: const Color(0xFF3C50E0), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 12),
                      Text('Command Center', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF1C2434))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildModulesGrid(isMobile),
                  const SizedBox(height: 48),
                  _buildMonthlyUserCreationTrendLineChart(),
                  const SizedBox(height: 24),
                  _buildRoleDistributionPieChart(),
                ],
              ),
            const SizedBox(height: 32),
            _buildBranchWiseUsersBarChart(),
            const SizedBox(height: 32),
            _buildRecentActivities(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(IconData icon, Color color, String value, String label, String percentage, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C2434),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
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
                    percentage,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(24),
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
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
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
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 65, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 15, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 45, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 10, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 80, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 20, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 55, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 5, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 70, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 25, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 90, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 10, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 40, color: const Color(0xFF3C50E0), width: 12, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: 15, color: const Color(0xFF00B4D8), width: 12, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyUserCreationTrendLineChart() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            child: LineChart(
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
                    spots: const [
                      FlSpot(0, 12), FlSpot(1, 15), FlSpot(2, 8), FlSpot(3, 20), FlSpot(4, 25), FlSpot(5, 18),
                      FlSpot(6, 30), FlSpot(7, 35), FlSpot(8, 28), FlSpot(9, 45), FlSpot(10, 38), FlSpot(11, 48),
                    ],
                    isCurved: true,
                    color: const Color(0xFF3C50E0), // Blue
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
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
                          const Color(0xFF3C50E0).withValues(alpha: 0.2),
                          const Color(0xFF3C50E0).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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

  Widget _buildRoleDistributionPieChart() {
    return Container(
      padding: const EdgeInsets.all(24),
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
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 70,
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(
                    color: const Color(0xFF3C50E0),
                    value: 50,
                    title: '50%',
                    radius: 20,
                    titleStyle: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFF00B4D8),
                    value: 35,
                    title: '35%',
                    radius: 20,
                    titleStyle: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFF8B5CF6),
                    value: 15,
                    title: '15%',
                    radius: 20,
                    titleStyle: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
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

    return Container(
      padding: const EdgeInsets.all(24),
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
          ...activities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (activity['color'] as Color).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      color: activity['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1C2434),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity['desc'] as String,
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
                    activity['time'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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

class _ProtractorModules extends StatefulWidget {
  final List<SubmenuItem> items;
  final Function(String, String)? onNavigate;

  const _ProtractorModules({required this.items, this.onNavigate});

  @override
  State<_ProtractorModules> createState() => _ProtractorModulesState();
}

class _ProtractorModulesState extends State<_ProtractorModules> {
  int _selectedIndex = 0;
  Timer? _scrollDebounce;
  double _dragAccumulator = 0.0;

  @override
  void dispose() {
    _scrollDebounce?.cancel();
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

        return Container(
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
                  child: GestureDetector(
                    onTap: () => _selectIndex(index),
                    child: AnimatedContainer(
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
                            color: isSelected ? const Color(0xFF3C50E0).withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                            blurRadius: isSelected ? 15 : 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        item.icon,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                        size: isSelected ? (isMobile ? 24 : 32) : (isMobile ? 18 : 24),
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
                        child: _buildCenterDetails(widget.items[_selectedIndex], isMobile),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    );
  }

  Widget _buildCenterDetails(SubmenuItem item, bool isMobile) {
    return Column(
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
        ElevatedButton.icon(
          onPressed: () {
            if (widget.onNavigate != null) {
              widget.onNavigate!(item.screen, item.programId);
            }
          },
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
