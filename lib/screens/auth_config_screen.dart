import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../utils/responsive.dart';

class AuthConfigScreen extends StatefulWidget {
  final Map<String, Auth101Config> configs;
  final void Function(String id, Auth101Config newCfg) onUpdate;
  final VoidCallback onBack;
  final String? userName;

  const AuthConfigScreen({
    super.key,
    required this.configs,
    required this.onUpdate,
    required this.onBack,
    this.userName,
  });

  @override
  State<AuthConfigScreen> createState() => _AuthConfigScreenState();
}

class _AuthConfigScreenState extends State<AuthConfigScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filteredIds = widget.configs.keys
        .where((id) =>
            id.toLowerCase().contains(_filter.toLowerCase()) ||
            widget.configs[id]!.name.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(Responsive.isMobile(context) ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(builder: (context, constraints) {
                    final isMobile = Responsive.isMobile(context);
                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Program Configurations',
                              style: bodyStyle(size: 20, weight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('AUTH101 — Authorization rules',
                              style: monoStyle(color: AppColors.ink3, size: 12)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: AmsTextInput(
                              placeholder: 'Search...',
                              icon: Icons.search,
                              onChanged: (v) => setState(() => _filter = v),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Program Configurations',
                                  style: bodyStyle(size: 24, weight: FontWeight.w800)),
                              Text('Table: AUTH101 — Capture authorization rules and procedures',
                                  style: monoStyle(color: AppColors.ink3, size: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 300,
                          child: AmsTextInput(
                            placeholder: 'Search by ID or Name...',
                            onChanged: (v) => setState(() => _filter = v),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _ConfigTable(
                          ids: filteredIds,
                          configs: widget.configs,
                          onUpdate: widget.onUpdate,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AmsSubmitBar(
            borderColor: AppColors.border,
            actions: [
              AmsButton(
                label: 'Back to Selection',
                variant: AmsButtonVariant.outline,
                onPressed: widget.onBack,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfigTable extends StatelessWidget {
  final List<String> ids;
  final Map<String, Auth101Config> configs;
  final void Function(String id, Auth101Config newCfg) onUpdate;

  const _ConfigTable({
    required this.ids,
    required this.configs,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      if (ids.isEmpty) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No program configs found.'),
        ));
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ids.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final id = ids[idx];
          final cfg = configs[id]!;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(id, style: monoStyle(weight: FontWeight.bold, color: cfg.isTran ? AppColors.tBlue : AppColors.nTeal, size: 14)),
                          const SizedBox(height: 4),
                          Text(cfg.name, style: bodyStyle(weight: FontWeight.bold, size: 14)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_suggest_outlined, color: AppColors.tBlue),
                      tooltip: 'Advanced Procedures',
                      onPressed: () => _showAdvancedDialog(context, id, cfg),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AmsBadge(
                      label: cfg.isTran ? 'TRANSACTION' : 'NON-TRAN',
                      color: cfg.isTran ? AppColors.tBlue : AppColors.nTeal,
                      background: cfg.isTran ? AppColors.tBlueLt : AppColors.nTealLt,
                      fontSize: 10,
                    ),
                    Text("Levels: ${cfg.levels}", style: bodyStyle(size: 13, weight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Approval Required', style: bodyStyle(size: 13, color: AppColors.ink2)),
                    ),
                    Switch(
                      value: cfg.approvalReq,
                      activeThumbColor: AppColors.green,
                      onChanged: (v) {
                        onUpdate(id, cfg.copyWith(approvalReq: v));
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.bg),
          horizontalMargin: 24,
          columnSpacing: 24,
          columns: [
            DataColumn(label: Text('PROGRAM ID', style: monoStyle(weight: FontWeight.w700, size: 11))),
            DataColumn(label: Text('NAME', style: monoStyle(weight: FontWeight.w700, size: 11))),
            DataColumn(label: Text('TYPE', style: monoStyle(weight: FontWeight.w700, size: 11))),
            DataColumn(label: Text('AUTH REQ', style: monoStyle(weight: FontWeight.w700, size: 11))),
            DataColumn(label: Text('LEVELS', style: monoStyle(weight: FontWeight.w700, size: 11))),
            DataColumn(label: Text('ACTIONS', style: monoStyle(weight: FontWeight.w700, size: 11))),
          ],
          rows: ids.map((id) {
            final cfg = configs[id]!;
            return DataRow(cells: [
              DataCell(Text(id, style: monoStyle(weight: FontWeight.w600, color: cfg.isTran ? AppColors.tBlue : AppColors.nTeal))),
              DataCell(Text(cfg.name, style: bodyStyle(size: 13, weight: FontWeight.w600))),
              DataCell(AmsBadge(
                label: cfg.isTran ? 'TRANSACTION' : 'NON-TRAN',
                color: cfg.isTran ? AppColors.tBlue : AppColors.nTeal,
                background: cfg.isTran ? AppColors.tBlueLt : AppColors.nTealLt,
                fontSize: 9,
              )),
              DataCell(
                Switch(
                  value: cfg.approvalReq,
                  activeThumbColor: AppColors.green,
                  onChanged: (v) {
                    onUpdate(id, cfg.copyWith(approvalReq: v));
                  },
                ),
              ),
              DataCell(Text(cfg.levels.toString(), style: bodyStyle())),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.settings_suggest_outlined, color: AppColors.ink2),
                  tooltip: 'Advanced Procedures',
                  onPressed: () => _showAdvancedDialog(context, id, cfg),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _showAdvancedDialog(BuildContext context, String id, Auth101Config cfg) {
    showDialog(
      context: context,
      builder: (ctx) => _AdvancedConfigDialog(
        id: id,
        cfg: cfg,
        onSave: (newCfg) => onUpdate(id, newCfg),
      ),
    );
  }
}

class _AdvancedConfigDialog extends StatefulWidget {
  final String id;
  final Auth101Config cfg;
  final void Function(Auth101Config) onSave;

  const _AdvancedConfigDialog({
    required this.id,
    required this.cfg,
    required this.onSave,
  });

  @override
  State<_AdvancedConfigDialog> createState() => _AdvancedConfigDialogState();
}

class _AdvancedConfigDialogState extends State<_AdvancedConfigDialog> {
  late bool _preReq;
  late String? _preMethod;
  late String? _preName;
  late bool _postReq;
  late String? _postMethod;
  late String? _postName;

  @override
  void initState() {
    super.initState();
    _preReq = widget.cfg.preApproveProc;
    _preMethod = widget.cfg.preExecMethod ?? '1';
    _preName = widget.cfg.preProcessName;
    _postReq = widget.cfg.postApproveProc;
    _postMethod = widget.cfg.postExecMethod ?? '1';
    _postName = widget.cfg.postProcessName;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Advanced Config: ${widget.id}', style: bodyStyle(size: 18, weight: FontWeight.w800)),
          Text('Configure Pre/Post Authorization Procedures', style: bodyStyle(size: 12, color: AppColors.ink3)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _buildSection(
              'Pre-Authorization Procedure',
              _preReq,
              (v) => setState(() => _preReq = v),
              _preMethod,
              (v) => setState(() => _preMethod = v),
              _preName,
              (v) => _preName = v,
            ),
            const Divider(height: 40),
            _buildSection(
              'Post-Authorization Procedure',
              _postReq,
              (v) => setState(() => _postReq = v),
              _postMethod,
              (v) => setState(() => _postMethod = v),
              _postName,
              (v) => _postName = v,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tBlue),
          onPressed: () {
            widget.onSave(Auth101Config(
              id: widget.cfg.id,
              name: widget.cfg.name,
              approvalReq: widget.cfg.approvalReq,
              isTran: widget.cfg.isTran,
              levels: widget.cfg.levels,
              preApproveProc: _preReq,
              preExecMethod: _preMethod,
              preProcessName: _preName,
              postApproveProc: _postReq,
              postExecMethod: _postMethod,
              postProcessName: _postName,
            ));
            Navigator.pop(context);
          },
          child: const Text('Apply Changes', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildSection(String title, bool active, Function(bool) onToggle, String? methodId, Function(String?) onMethod, String? name, Function(String) onNameChange) {
    final methodLabels = {
      '1': 'SQL Object (PROC)',
      '2': 'API Call',
      '3': 'Java Method',
    };
    final items = methodLabels.values.toList();
    final currentLabel = methodLabels[methodId] ?? items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: bodyStyle(weight: FontWeight.w700))),
            Switch(value: active, onChanged: onToggle),
          ],
        ),
        if (active) ...[
          const SizedBox(height: 12),
          Text('Execution Method', style: monoStyle(size: 10, color: AppColors.ink3)),
          const SizedBox(height: 4),
          AmsDropdown(
            initialValue: currentLabel,
            items: items,
            onChanged: (v) {
              final newId = methodLabels.entries.firstWhere((e) => e.value == v).key;
              onMethod(newId);
            },
          ),
          const SizedBox(height: 12),
          AmsTextInput(
            placeholder: 'Process Name (e.g. SP_VALIDATE_LOAN)',
            initialValue: name,
            onChanged: onNameChange,
          ),
        ] else
          Text('No automated procedure configured.', style: bodyStyle(size: 12, color: AppColors.ink3).copyWith(fontStyle: FontStyle.italic)),
      ],
    );
  }
}

// Add copyWith to Auth101Config in models.dart if needed, but here I'm using constructor direct
extension Auth101Extension on Auth101Config {
  Auth101Config copyWith({
    bool? approvalReq,
  }) {
    return Auth101Config(
      id: id,
      name: name,
      approvalReq: approvalReq ?? this.approvalReq,
      isTran: isTran,
      levels: levels,
      preApproveProc: preApproveProc,
      preExecMethod: preExecMethod,
      preProcessName: preProcessName,
      postApproveProc: postApproveProc,
      postExecMethod: postExecMethod,
      postProcessName: postProcessName,
    );
  }
}
