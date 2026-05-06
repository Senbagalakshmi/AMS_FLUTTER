import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 1. WELCOME HEADER
            _buildWelcomeHeader(),
            const SizedBox(height: 32),

            // 🔹 2. KPI TOP ROW
            _buildKPIRow(),
            const SizedBox(height: 32),

            // 🔹 3. MAIN DASHBOARD AREA (Split Layout)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT SIDE (Charts & Activity)
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      _buildActivityChart(),
                      const SizedBox(height: 24),
                      _buildAuthWatchlist(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // RIGHT SIDE (Quick Actions & Stats)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildResourceStatus(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy').format(now);
    final dayStr = DateFormat('EEEE').format(now);

    String displayName = widget.userName ?? 'Administrator';
    if (displayName.contains('@')) {
      displayName = displayName.split('@').first;
    }
    // Capitalize first letter
    if (displayName.isNotEmpty) {
      displayName = displayName[0].toUpperCase() + displayName.substring(1);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $displayName!',
              style: bodyStyle(
                  size: 26, weight: FontWeight.w900, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              'Here is what’s happening in your system today.',
              style: bodyStyle(size: 14, color: AppColors.ink3),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 16, color: AppColors.ink2),
              const SizedBox(width: 10),
              Text(
                '$dayStr, $dateStr',
                style: bodyStyle(
                    size: 13, weight: FontWeight.w700, color: AppColors.ink2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKPIRow() {
    final String pendingTrend =
        widget.authQueueCount > 0 ? 'Pending' : 'All clear';

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          _kpiCard(
            'Pending Approvals',
            widget.authQueueCount.toString(),
            Icons.pending_actions_rounded,
            AppColors.tBlue,
            pendingTrend,
          ),
          _kpiCard('System Security', '98%', Icons.security_rounded,
              AppColors.green, 'Healthy'),
          _kpiCard('Active Sessions', '45', Icons.people_alt_rounded,
              AppColors.amber, '-5% vs yesterday'),
          _kpiCard('Queue Status', 'Normal', Icons.sync_rounded, AppColors.ink3,
              'All synced'),
          _kpiCard('Total Users', widget.totalUsers > 0 ? widget.totalUsers.toString() : '-',
              Icons.groups_rounded, AppColors.tBlue, 'Registered'),
        ],
      ),
    );
  }

  Widget _kpiCard(
      String title, String val, IconData icon, Color color, String trend) {
    // Determine trend text color
    Color trendColor;
    if (trend.contains('+')) {
      trendColor = AppColors.green;
    } else if (trend == 'Healthy' || trend == 'All clear') {
      trendColor = AppColors.green;
    } else {
      trendColor = AppColors.ink4;
    }

    return SizedBox(
      width: 210,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
                Icon(icon, color: color, size: 24),
                Text(
                  trend,
                  style: bodyStyle(
                      size: 10, weight: FontWeight.w800, color: trendColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              val,
              style: bodyStyle(
                size: 28,
                weight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(title,
                style: bodyStyle(
                    size: 13, color: AppColors.ink3, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Authorization Volume (Last 7 Days)',
                  style: bodyStyle(size: 16, weight: FontWeight.w800)),
              const Icon(Icons.more_horiz_rounded, color: AppColors.ink3),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _bar(40, 'Mon'),
                _bar(65, 'Tue'),
                _bar(50, 'Wed'),
                _bar(85, 'Thu'),
                _bar(60, 'Fri'),
                _bar(20, 'Sat'),
                _bar(15, 'Sun'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double h, String day) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          height: h * 1.5,
          width: 30,
          decoration: BoxDecoration(
            color: h > 60
                ? AppColors.tBlue
                : AppColors.tBlue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Text(day,
            style: monoStyle(
                size: 10, color: AppColors.ink4, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildAuthWatchlist() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Policy Compliance Watchlist',
              style: bodyStyle(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 24),
          _watchlistTile(
              'User Authorization',
              'High priority security audit required',
              AppColors.red,
              'nontranauth'),
          _watchlistTile('GL Master Entries', '3 new unmapped accounts found',
              AppColors.amber, 'GL-MST'),
          _watchlistTile('System Config', 'Version 2.4.1 deployment healthy',
              AppColors.green, 'AUTHCTL'),
        ],
      ),
    );
  }

  Widget _watchlistTile(String label, String sub, Color color, String progId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
              height: 32,
              width: 4,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: bodyStyle(size: 14, weight: FontWeight.w700)),
                Text(sub, style: bodyStyle(size: 12, color: AppColors.ink3)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (progId == 'nontranauth') {
                widget.onProceed('AUTH'); // or specific route if available
              } else {
                widget.onSelect(progId);
              }
            },
            child: Text('View',
                style: bodyStyle(
                    size: 12, color: AppColors.tBlue, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions',
              style: bodyStyle(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 20),
          _actionBtn(Icons.add_moderator_rounded, 'New User Gate', 'MASTERS'),
          _actionBtn(Icons.account_tree_rounded, 'Configure GL', 'GL'),
          _actionBtn(
              Icons.receipt_long_rounded, 'Post Transactions', 'TRANSACTIONS'),
          _actionBtn(Icons.verified_user_rounded, 'Audit Logs', 'AUTH'),
          _actionBtn(Icons.settings_input_composite_rounded, 'System Settings',
              'CONFIG'),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, String cat) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onProceed(cat),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border2),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.tBlue),
              const SizedBox(width: 12),
              Text(label,
                  style: bodyStyle(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.ink2)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.ink4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceStatus() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.tBlue.withValues(alpha: 0.8),
          AppColors.tBlueDk
        ]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.tBlue.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 20),
          const Text('System Resource',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text('92.4% Optimal',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
              value: 0.92,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(Colors.white)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
