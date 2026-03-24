import 'package:flutter/material.dart';
import '../theme.dart';
import '../data.dart';
import '../widgets/widgets.dart';

class SelectTypeScreen extends StatefulWidget {
  final void Function(String type) onProceed;
  final String? userName;
  const SelectTypeScreen({super.key, required this.onProceed, this.userName});

  @override
  State<SelectTypeScreen> createState() => _SelectTypeScreenState();
}

class _SelectTypeScreenState extends State<SelectTypeScreen> {
  String? _chosen; // 'T' or 'N'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AmsTopBar(currentStep: 2, userName: widget.userName),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 80),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page header
                      Text('Select Program Type',
                          style: bodyStyle(
                              size: 20, weight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                          'Choose what kind of entry you want to create. '
                          'The entry form, fields, and workflow differ significantly '
                          'between Transaction Programs and Non-Transaction Programs.',
                          style: bodyStyle(
                              size: 13, color: AppColors.ink2)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tBlueLt,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.tBlueMd, width: 1.5),
                        ),
                        child: Text(
                            'STEP 2 OF 5 · PROGRAM TYPE SELECTION · AUTH101 LOOKUP',
                            style: monoStyle(
                                size: 10,
                                weight: FontWeight.w600,
                                color: AppColors.tBlue)),
                      ),
                      const SizedBox(height: 24),
                      // Cards grid
                      LayoutBuilder(builder: (ctx, constraints) {
                        final useRow = constraints.maxWidth > 600;
                        return useRow
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: _TypeCard(
                                          type: 'T',
                                          chosen: _chosen == 'T',
                                          onTap: () => setState(
                                              () => _chosen =
                                                  _chosen == 'T' ? null : 'T'))),
                                  const SizedBox(width: 20),
                                  Expanded(
                                      child: _TypeCard(
                                          type: 'N',
                                          chosen: _chosen == 'N',
                                          onTap: () => setState(
                                              () => _chosen =
                                                  _chosen == 'N' ? null : 'N'))),
                                ],
                              )
                            : Column(children: [
                                _TypeCard(
                                    type: 'T',
                                    chosen: _chosen == 'T',
                                    onTap: () => setState(() => _chosen =
                                        _chosen == 'T' ? null : 'T')),
                                const SizedBox(height: 16),
                                _TypeCard(
                                    type: 'N',
                                    chosen: _chosen == 'N',
                                    onTap: () => setState(() => _chosen =
                                        _chosen == 'N' ? null : 'N')),
                              ]);
                      }),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AmsButton(
                            label: 'Queue',
                            variant: AmsButtonVariant.outline,
                            icon: Icons.checklist_rtl_rounded,
                            onPressed: () => widget.onProceed('AUTH'),
                          ),
                          const SizedBox(width: 8),
                          AmsButton(
                            label: 'Controller',
                            variant: AmsButtonVariant.outline,
                            icon: Icons.settings_applications_rounded,
                            onPressed: () => widget.onProceed('AUTH_CONFIG'),
                          ),
                          const SizedBox(width: 12),
                          AmsButton(
                            label: 'Proceed →',
                            large: true,
                            variant: _chosen == 'N'
                                ? AmsButtonVariant.teal
                                : AmsButtonVariant.primary,
                            onPressed: _chosen != null
                                ? () => widget.onProceed(_chosen!)
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

class _TypeCard extends StatelessWidget {
  final String type;
  final bool chosen;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.chosen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isT = type == 'T';
    final accent = isT ? AppColors.tBlue : AppColors.nTeal;
    final accentLt = isT ? AppColors.tBlueLt : AppColors.nTealLt;
    final accentMd = isT ? AppColors.tBlueMd : AppColors.nTealMd;
    final flag = isT ? 'ISTRANPGM = 1' : 'ISTRANPGM = 0';
    final title = isT ? 'Transaction Program' : 'Non-Transaction Program';
    final icon = isT ? '💰' : '📄';
    final desc = isT
        ? 'Involves monetary transactions. The entry form includes an Amount field validated against AUTH103 limits. Multi-level authorization routes through L1 → L2 → L3 before final posting.'
        : 'Operational or administrative updates with no monetary amount. AUTH103 limit checks do not apply. Some programs may bypass authorization entirely (APPROVALREQ = 0).';
    final programs = isT ? tranPrograms : nonTranPrograms;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: chosen ? accent : AppColors.border,
              width: chosen ? 2 : 1.5),
          boxShadow: chosen
              ? [
                  BoxShadow(
                      color: accentLt,
                      spreadRadius: 4,
                      blurRadius: 0),
                  const BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 14,
                      offset: Offset(0, 4)),
                ]
              : const [
                  BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top stripe indicator
            if (chosen)
              Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [accent, accentMd]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // Checkmark
            if (chosen)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                      color: accent, shape: BoxShape.circle),
                  child: const Center(
                    child: Text('✓',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            Text(icon,
                style: const TextStyle(fontSize: 34)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: accentLt, borderRadius: BorderRadius.circular(6)),
              child: Text(flag,
                  style: monoStyle(
                      size: 10, weight: FontWeight.w700, color: accent)),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: bodyStyle(
                    size: 17, weight: FontWeight.w800, color: accent)),
            const SizedBox(height: 8),
            Text(desc,
                style:
                    bodyStyle(size: 12, color: AppColors.ink2)),
            const SizedBox(height: 14),
            // Program rows
            ...programs.map((pid) {
              final cfg = auth101[pid]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: accentLt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(pid,
                        style: monoStyle(
                            size: 11,
                            weight: FontWeight.w700,
                            color: accent)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(cfg.name,
                          style: bodyStyle(
                              size: 11, color: AppColors.ink2)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cfg.approvalReq
                            ? AppColors.amberLt
                            : AppColors.greenLt,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                          cfg.approvalReq
                              ? 'APPROVALREQ=1'
                              : 'APPROVALREQ=0',
                          style: monoStyle(
                              size: 8,
                              weight: FontWeight.w700,
                              color: cfg.approvalReq
                                  ? AppColors.amber
                                  : AppColors.green)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
