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
  String? _selectedProg;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawPrograms = [...widget.tranPrograms, ...widget.nonTranPrograms];
    const title = 'Select a Program';
    const headerIcon = Icon(Icons.dashboard_customize_rounded, color: AppColors.tBlue, size: 28);

    final programs = rawPrograms.where((pid) {
      final cfg = widget.authConfigs[pid];
      if (cfg == null) return false;
      final q = _searchQuery.toLowerCase();
      return pid.toLowerCase().contains(q) ||
          cfg.name.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: Column(
        children: [

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 80),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          headerIcon,
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: bodyStyle(
                                      size: 20, weight: FontWeight.w800)),
                              Text(
                                  'Select a specific program to proceed to the entry form.',
                                  style: bodyStyle(
                                      size: 13, color: AppColors.ink2)),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 300,
                                child: AmsTextInput(
                                  controller: _searchController,
                                  placeholder: 'Search Program Name or ID...',
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.redLt,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                                        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                        title: Text('Confirm Logout', style: bodyStyle(size: 20, weight: FontWeight.w700)),
                                        content: SizedBox(
                                          width: 400,
                                          child: Text('Are you sure you want to logout off your account?', style: bodyStyle(size: 16)),
                                        ),
                                        actions: [
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            ),
                                            onPressed: () => Navigator.of(ctx).pop(),
                                            child: Text('Cancel', style: bodyStyle(size: 15, weight: FontWeight.w600, color: AppColors.ink3)),
                                          ),
                                          const SizedBox(width: 8),
                                          AmsButton(
                                            label: 'Yes, Logout',
                                            large: true,
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                              widget.onBack();
                                            },
                                          ),
                                        ],
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.logout),
                                  color: AppColors.red,
                                  tooltip: 'Logout',
                                  iconSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Grid of programs
                      if (programs.isEmpty)
                        const SizedBox.shrink()
                      else
                        AmsPaginatedView<String>(
                          items: programs,
                          itemsPerPage: 9,
                          shrinkWrap: true,
                          builder: (ctx, currentItems) => LayoutBuilder(builder: (ctx, constraints) {
                            final crossAxisCount = constraints.maxWidth > 800
                                ? 3
                                : (constraints.maxWidth > 500 ? 2 : 1);

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 110,
                              ),
                              itemCount: currentItems.length,
                              itemBuilder: (ctx, idx) {
                                final pid = currentItems[idx];
                              final cfg = widget.authConfigs[pid]!;
                              final isSel = _selectedProg == pid;
                              final isTLocal = widget.tranPrograms.contains(pid);
                              final itemAccent = isTLocal ? AppColors.tBlue : AppColors.nTeal;
                              final itemAccentLt = isTLocal ? AppColors.tBlueLt : AppColors.nTealLt;

                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedProg = pid),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSel ? itemAccentLt : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSel ? itemAccent : AppColors.border,
                                        width: isSel ? 2 : 1.5,
                                      ),
                                      boxShadow: isSel
                                          ? [
                                              BoxShadow(
                                                color: itemAccent.withValues(alpha: 0.1),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(pid,
                                                style: monoStyle(
                                                    size: 12,
                                                    weight: FontWeight.w700,
                                                    color: itemAccent)),
                                            if (isSel)
                                              Icon(Icons.check_circle,
                                                  color: itemAccent, size: 18),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(cfg.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: bodyStyle(
                                                size: 14,
                                                weight: FontWeight.w600,
                                                color: AppColors.ink)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                        ),

                      const SizedBox(height: 32),
                      if (programs.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AmsButton(
                              label: 'Proceed →',
                              large: true,
                              variant: _selectedProg != null && widget.tranPrograms.contains(_selectedProg)
                                  ? AmsButtonVariant.primary
                                  : AmsButtonVariant.teal,
                              onPressed: _selectedProg != null
                                  ? () => widget.onSelect(_selectedProg!)
                                  : null,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
