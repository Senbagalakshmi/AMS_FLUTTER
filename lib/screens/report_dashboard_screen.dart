import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../data.dart';
import '../screens/submenu_dashboard_screen.dart';
import '../utils/responsive.dart';
import '../services/report_api_service.dart';
import 'package:fl_chart/fl_chart.dart';
 
class ReportDashboardScreen extends StatefulWidget {
  final List<SubmenuItem> items;
  final String? userName;
  final VoidCallback onBack;
  final void Function(String screen, String? prog) onNavigate;
 
  const ReportDashboardScreen({
    super.key,
    required this.items,
    this.userName,
    required this.onBack,
    required this.onNavigate,
  });
 
  @override
  State<ReportDashboardScreen> createState() => _ReportDashboardScreenState();
}
 
class _ReportDashboardScreenState extends State<ReportDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ReportApiService _reportApiService = ReportApiService();
  bool _loading = true;
 
  double _netProfit = 0.0;
  double _trialBalanceValue = 0.0;
  bool _isTbBalanced = true;
  double _totalAssets = 0.0;
  double _totalLiabilities = 0.0;
 
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _loadDashboardData();
  }
 
  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
 
    try {
      final results = await Future.wait([
        _reportApiService.getFinancialReport(reportType: "PL", date: currentDate),
        _reportApiService.getFinancialReport(reportType: "BS", date: currentDate),
        _reportApiService.getFinancialReport(reportType: "TB", date: currentDate),
      ]);
 
      final plData = results[0];
      final bsData = results[1];
      final tbData = results[2];
 
      // 1. PL: Net Profit
      double incomeTotal = 0;
      double expenseTotal = 0;
      if (plData != null) {
        for (var item in plData) {
          final rawAmount = item['amount'] ?? 0;
          final amount = (rawAmount is num)
              ? rawAmount.toDouble()
              : double.tryParse(rawAmount.toString()) ?? 0.0;
          final type = (item['gltype'] ?? '').toString().toUpperCase();
          if (type == 'INCOME') {
            incomeTotal += amount;
          } else if (type == 'EXPENSE') {
            expenseTotal += amount;
          }
        }
      }
      _netProfit = incomeTotal - expenseTotal;
 
      // 2. BS: Assets and Liabilities
      double assetsTotal = 0;
      double liabilitiesTotal = 0;
      if (bsData != null) {
        for (var item in bsData) {
          final rawAmount = item['amount'] ?? 0;
          final amount = (rawAmount is num)
              ? rawAmount.toDouble()
              : double.tryParse(rawAmount.toString()) ?? 0.0;
          final type = (item['gltype'] ?? '').toString().toUpperCase();
          if (type == 'ASSET') {
            assetsTotal += amount;
          } else if (type == 'LIABILITY') {
            liabilitiesTotal += amount;
          }
        }
      }
      _totalAssets = assetsTotal;
      _totalLiabilities = liabilitiesTotal;
 
      // 3. TB: Trial Balance Value & isBalanced
      double dr = 0;
      double cr = 0;
      if (tbData != null) {
        for (var acc in tbData) {
          dr += (acc['debit'] ?? 0).toDouble();
          cr += (acc['credit'] ?? 0).toDouble();
        }
      }
      _trialBalanceValue = dr;
      _isTbBalanced = (dr == cr);
    } catch (e) {
      print('Error fetching report dashboard data: $e');
    }
 
    if (mounted) {
      setState(() => _loading = false);
    }
  }
 
  String _formatCompactAmount(double value) {
    final double absVal = value.abs();
    final String sign = value < 0 ? '-' : '';
    if (absVal >= 10000000) {
      final double cr = absVal / 10000000;
      return '$sign₹${cr.toStringAsFixed(2)}Cr';
    } else if (absVal >= 100000) {
      final double lakh = absVal / 100000;
      return '$sign₹${lakh.toStringAsFixed(2)}L';
    } else {
      final currencyFormatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      );
      return currencyFormatter.format(value);
    }
  }
 
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
 
  // ================= TEXT STYLES =================
  TextStyle headerStyle({
    double size = 22,
    Color color = Colors.black,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }
 
  TextStyle bodyStyle({
    double size = 14,
    Color color = Colors.black,
    FontWeight weight = FontWeight.w500,
    double? height,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }
 
  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day.toString().padLeft(2, '0')}, ${now.year}';
  }
 
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
 
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          Expanded(
            child: FadeTransition(
              opacity: _animationController,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 30,
                  vertical: 24,
                ),
                child: _buildDashboard(isMobile),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  // ================= HEADER =================
  Widget _buildHeader(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: const Border(
          bottom: BorderSide(color: AppColors.border2, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 30,
        vertical: 18,
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.border2,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onBack,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.tBlue,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Financial Reports',
                      style: headerStyle(
                        size: isMobile ? 20 : 26,
                        color: AppColors.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.items.length} Modules',
                        style: bodyStyle(
                          size: 11,
                          color: AppColors.tBlue,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(Icons.home_outlined, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Home',
                      style: bodyStyle(size: 12, color: Colors.grey[500]!, weight: FontWeight.w600),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 14, color: Colors.grey[400]),
                    Text(
                      'Reports Dashboard',
                      style: bodyStyle(size: 12, color: Colors.grey[700]!, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 16, color: AppColors.tBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Welcome, ${widget.userName ?? "User"}',
                      style: bodyStyle(
                        size: 13,
                        color: AppColors.ink,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 12, color: AppColors.ink3),
                      const SizedBox(width: 6),
                      Text(
                        _getFormattedDate(),
                        style: bodyStyle(
                          size: 11,
                          color: AppColors.ink3,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
 
  // ================= KPI SECTION =================
  Widget _buildKpiSection(bool isMobile) {
    final cards = [
      _InteractiveKpiCard(
        title: "Net Profit",
        value: _formatCompactAmount(_netProfit),
        icon: Icons.trending_up_rounded,
        color: AppColors.green,
        trend: _netProfit >= 0 ? "+12.4%" : "-12.4%",
        isTrendPositive: _netProfit >= 0,
      ),
      _InteractiveKpiCard(
        title: "Trial Balance",
        value: _formatCompactAmount(_trialBalanceValue),
        icon: Icons.balance_rounded,
        color: AppColors.tBlue,
        trend: _isTbBalanced ? "Balanced" : "Unbalanced",
        isTrendPositive: _isTbBalanced,
      ),
      _InteractiveKpiCard(
        title: "Total Assets",
        value: _formatCompactAmount(_totalAssets),
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.amber,
        trend: "+3.2%",
        isTrendPositive: true,
      ),
      _InteractiveKpiCard(
        title: "Liabilities",
        value: _formatCompactAmount(_totalLiabilities),
        icon: Icons.payments_rounded,
        color: AppColors.purple,
        trend: "-1.8%",
        isTrendPositive: false,
      ),
    ];
 
    if (isMobile) {
      return Column(
        children: cards
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: e,
              ),
            )
            .toList(),
      );
    }
 
    return Row(
      children: cards
          .map(
            (e) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: e,
              ),
            ),
          )
          .toList(),
    );
  }
 
  // ================= BAR CHART =================
  Widget _buildBarChart() {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border2, width: 1.5),
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
                  const Text(
                    "Monthly Report Usage",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Report generation counts per month",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.tBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Active",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 35,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppColors.ink.withOpacity(0.95),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} Runs',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 10 != 0) return const SizedBox.shrink();
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        switch (value.toInt()) {
                          case 0:
                            text = 'Mar';
                            break;
                          case 1:
                            text = 'Apr';
                            break;
                          case 2:
                            text = 'May';
                            break;
                          case 3:
                            text = 'Jun';
                            break;
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border2,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: 15,
                        gradient: LinearGradient(
                          colors: [AppColors.tBlue, AppColors.tBlue.withOpacity(0.65)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: 22,
                        gradient: LinearGradient(
                          colors: [AppColors.green, AppColors.green.withOpacity(0.65)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: 18,
                        gradient: LinearGradient(
                          colors: [AppColors.amber, AppColors.amber.withOpacity(0.65)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: 28,
                        gradient: LinearGradient(
                          colors: [AppColors.purple, AppColors.purple.withOpacity(0.65)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  // ================= PIE CHART =================
  Widget _buildLegendItem(String label, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink2,
          ),
        ),
        const Spacer(),
        Text(
          pct,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
 
  Widget _buildPieChart(bool isMobile) {
    final chartWidget = Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            centerSpaceRadius: 55,
            sectionsSpace: 4,
            sections: [
              PieChartSectionData(
                value: 40,
                showTitle: false,
                radius: 16,
                color: AppColors.tBlue,
              ),
              PieChartSectionData(
                value: 30,
                showTitle: false,
                radius: 16,
                color: AppColors.green,
              ),
              PieChartSectionData(
                value: 20,
                showTitle: false,
                radius: 16,
                color: AppColors.amber,
              ),
              PieChartSectionData(
                value: 10,
                showTitle: false,
                radius: 16,
                color: AppColors.purple,
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "1.2K",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            Text(
              "Total Runs",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
 
    final legendWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLegendItem("Profit & Loss", "40%", AppColors.tBlue),
        const SizedBox(height: 10),
        _buildLegendItem("Trial Balance", "30%", AppColors.green),
        const SizedBox(height: 10),
        _buildLegendItem("Balance Sheet", "20%", AppColors.amber),
        const SizedBox(height: 10),
        _buildLegendItem("Other Queries", "10%", AppColors.purple),
      ],
    );
 
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border2, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Report Distribution",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Frequency of report views by type",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isMobile
                ? Column(
                    children: [
                      Expanded(child: chartWidget),
                      const SizedBox(height: 12),
                      legendWidget,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(flex: 3, child: chartWidget),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: legendWidget),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
 
  // ================= DASHBOARD LAYOUT =================
  Widget _buildDashboard(bool isMobile) {
    if (_loading) {
      return const SizedBox(
        height: 400,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.tBlue,
          ),
        ),
      );
    }
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKpiSection(isMobile),
        const SizedBox(height: 24),
        isMobile
            ? Column(
                children: [
                  _buildBarChart(),
                  const SizedBox(height: 24),
                  _buildPieChart(isMobile),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildBarChart()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildPieChart(isMobile)),
                ],
              ),
        const SizedBox(height: 36),
        const Text(
          "Available Reports",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Select a module below to generate financial reports.",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        _buildDetailedView(isMobile),
      ],
    );
  }
 
  // ================= DETAILED REPORTS GRID =================
  Widget _buildDetailedView(bool isMobile) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: widget.items.map((item) {
        return SizedBox(
          width: isMobile ? double.infinity : 300,
          height: 210,
          child: _ReportCard(
            item: item,
            onTap: () {
              widget.onNavigate('nontran', item.programId);
            },
          ),
        );
      }).toList(),
    );
  }
}
 
// ================= INTERACTIVE KPI CARD =================
class _InteractiveKpiCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool isTrendPositive;
 
  const _InteractiveKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.isTrendPositive,
  });
 
  @override
  State<_InteractiveKpiCard> createState() => _InteractiveKpiCardState();
}
 
class _InteractiveKpiCardState extends State<_InteractiveKpiCard> {
  bool _isHovered = false;
 
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -5.0 : 0.0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? widget.color.withOpacity(0.3) : AppColors.border2,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.color.withOpacity(0.12)
                  : Colors.black.withOpacity(0.035),
              blurRadius: _isHovered ? 16 : 12,
              offset: Offset(0, _isHovered ? 6 : 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isHovered ? widget.color : widget.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                widget.icon,
                color: _isHovered ? Colors.white : widget.color,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.isTrendPositive
                              ? AppColors.green.withOpacity(0.1)
                              : AppColors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.trend,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: widget.isTrendPositive ? AppColors.green : AppColors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ================= PREMIUM REPORT CARD =================
class _ReportCard extends StatefulWidget {
  final SubmenuItem item;
  final VoidCallback onTap;
 
  const _ReportCard({
    required this.item,
    required this.onTap,
  });
 
  @override
  State<_ReportCard> createState() => _ReportCardState();
}
 
class _ReportCardState extends State<_ReportCard> {
  bool _isHovered = false;
 
  @override
  Widget build(BuildContext context) {
    Color accentColor = AppColors.tBlue;
    Color lightBgColor = AppColors.tBlueLt;
    if (widget.item.programId == 'RPT-PL') {
      accentColor = AppColors.green;
      lightBgColor = AppColors.greenLt;
    } else if (widget.item.programId == 'RPT-BS') {
      accentColor = AppColors.amber;
      lightBgColor = AppColors.amberLt;
    }
 
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -5.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? accentColor.withOpacity(0.1)
                  : Colors.black.withOpacity(0.025),
              blurRadius: _isHovered ? 16 : 10,
              offset: Offset(0, _isHovered ? 6 : 3),
            ),
          ],
          border: Border.all(
            color: _isHovered ? accentColor.withOpacity(0.3) : AppColors.border2,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            hoverColor: Colors.transparent,
            splashColor: accentColor.withOpacity(0.08),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: lightBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.item.icon,
                          color: accentColor,
                          size: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Text(
                          widget.item.metric ?? 'Report',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.item.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      widget.item.subtitle ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border2, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Generate Report",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.identity()
                          ..translate(_isHovered ? 4.0 : 0.0, 0.0),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: accentColor,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}