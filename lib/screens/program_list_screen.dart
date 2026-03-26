import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class ProgramListScreen extends StatefulWidget {
  final Map<String, Auth101Config> authConfigs;
  final List<String> tranPrograms;
  final List<String> nonTranPrograms;
  final void Function(String prog) onSelect;
  final void Function(String route) onProceed;
  final VoidCallback onBack;
  final String? userName;

  const ProgramListScreen({
    super.key,
    required this.authConfigs,
    required this.tranPrograms,
    required this.nonTranPrograms,
    required this.onSelect,
    required this.onProceed,
    required this.onBack,
    this.userName,
  });

  @override
  State<ProgramListScreen> createState() => _ProgramListScreenState();
}

class _ProgramListScreenState extends State<ProgramListScreen> {
  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 🔹 HEADER (Full width)
          Text(
            'GENERAL',
            style: bodyStyle(
              size: 22,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quick snapshot of system metrics and active operations.',
            style: bodyStyle(size: 13, color: AppColors.ink3),
          ),

          const SizedBox(height: 70),

          // 🔹 ONLY GRID IS CENTERED
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount =
                      constraints.maxWidth > 900 ? 4 :
                      constraints.maxWidth > 600 ? 2 : 1;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.25,
                    children: [
                      _buildDetailContainer(
                        title: 'Master Details',
                        icon: Icons.storage_rounded,
                        color: AppColors.tBlue,
                        metrics: [
                          _MetricInfo('Total Records', '24,592'),
                          _MetricInfo('Sync Status', 'Up to date'),
                          _MetricInfo('Last Updated', '12 mins ago'),
                        ],
                      ),
                      _buildDetailContainer(
                        title: 'GL Details',
                        icon: Icons.account_balance_rounded,
                        color: AppColors.nTeal,
                        metrics: [
                          _MetricInfo('Active Ledgers', '142'),
                          _MetricInfo('Unmapped AC', '3'),
                          _MetricInfo('Reconciliation', 'Pending'),
                        ],
                      ),
                      _buildDetailContainer(
                        title: 'Configuration',
                        icon: Icons.settings_suggest_rounded,
                        color: AppColors.amber,
                        metrics: [
                          _MetricInfo('System Version', 'v2.4.1'),
                          _MetricInfo('Environment', 'Production'),
                          _MetricInfo('Active Modules', '12 / 15'),
                        ],
                      ),
                      _buildDetailContainer(
                        title: 'Auth Queue',
                        icon: Icons.fact_check_rounded,
                        color: AppColors.red,
                        metrics: [
                          _MetricInfo('Pending Auth', '3 Requests'),
                          _MetricInfo('High Priority', '1 Request'),
                          _MetricInfo('Next Action', 'GL Review'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDetailContainer({
    required String title,
    required IconData icon,
    required Color color,
    required List<_MetricInfo> metrics,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: bodyStyle(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: metrics
                    .map(
                      (m) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            m.label,
                            style:
                                bodyStyle(size: 12.5, color: AppColors.ink3),
                          ),
                          Text(
                            m.value,
                            style: bodyStyle(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: AppColors.ink),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _MetricInfo {
  final String label;
  final String value;
  _MetricInfo(this.label, this.value);
}