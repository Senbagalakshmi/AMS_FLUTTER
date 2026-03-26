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
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 3 : 2),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.1,
                children: [
                  _DashboardTile(
                    label: 'User',
                    icon: Icons.person_add_rounded,
                    onTap: () => widget.onSelect('USR-CRT'),
                  ),
                  _DashboardTile(
                    label: 'Role Associate',
                    icon: Icons.assignment_ind_rounded,
                    onTap: () => widget.onSelect('USR-ROLE'),
                  ),
                  _DashboardTile(
                    label: 'Role',
                    icon: Icons.admin_panel_settings_rounded,
                    onTap: () => widget.onSelect('ROLE-CRT'),
                  ),
                  _DashboardTile(
                    label: 'Modules',
                    icon: Icons.view_module_rounded,
                    onTap: () => widget.onSelect('MOD-CRT'),
                  ),
                  _DashboardTile(
                    label: 'Menus',
                    icon: Icons.menu_open_rounded,
                    onTap: () => widget.onSelect('MENU-CRT'),
                  ),
                  _DashboardTile(
                    label: 'Program',
                    icon: Icons.app_settings_alt_rounded,
                    onTap: () => widget.onSelect('PGM-CRT'),
                  ),
                  // _DashboardTile(
                  //   label: 'Auth Controller',
                  //   icon: Icons.security_rounded,
                  //   onTap: () => widget.onSelect('AUTHCTL'),
                  // ),
                  _DashboardTile(
                    label: 'Authorization',
                    icon: Icons.verified_user_rounded,
                    onTap: () => widget.onProceed('AUTH'),
                  ),
                  _DashboardTile(
                    label: 'GL Category',
                    icon: Icons.category_rounded,
                    onTap: () => widget.onSelect('GL-CAT'),
                  ),
                  _DashboardTile(
                    label: 'GL Master',
                    icon: Icons.account_balance_rounded,
                    onTap: () => widget.onSelect('GL-MST'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _DashboardTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3E8B), // Dark Blue Icon Box
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                style: bodyStyle(
                  size: 14,
                  weight: FontWeight.w600,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
