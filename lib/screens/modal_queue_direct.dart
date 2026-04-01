import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// DECISION MODAL
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class DecisionModal extends StatelessWidget {
  final String prog;
  final Auth101Config cfg;
  final String authsl;
  final VoidCallback onQueue;
  final VoidCallback onDirect;
  final VoidCallback onClose;

  const DecisionModal({
    super.key,
    required this.prog,
    required this.cfg,
    required this.authsl,
    required this.onQueue,
    required this.onDirect,
    required this.onClose,
  });


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: const Color(0x99050C19),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent close on modal tap
            child: Container(
              width: 480,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x2E000000),
                      blurRadius: 40,
                      offset: Offset(0, 12))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: cfg.approvalReq
                                ? AppColors.tBlueLt
                                : AppColors.greenLt,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(cfg.approvalReq ? 'ðŸ“¥' : 'ðŸ’¾',
                                style: const TextStyle(fontSize: 30)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          cfg.approvalReq
                              ? 'PROCEED TO AUTHORIZATION'
                              : 'PROCEED TO DIRECT SAVE',
                          style: bodyStyle(size: 18, weight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cfg.approvalReq
                              ? 'This program ($prog) requires ${cfg.levels}-level approval.'
                              : 'This program ($prog) does not require authorization.',
                          style: bodyStyle(size: 13, color: AppColors.ink2),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: cfg.approvalReq
                        ? _RouteOption(
                            color: AppColors.tBlue,
                            bg: AppColors.tBlueLt,
                            title: 'ðŸ“¥ ADD TO QUEUE',
                            desc:
                                'AUTHSL: $authsl Â· Waiting for ${cfg.levels}-level approval. Once approved, the transaction will be processed.',
                            onTap: onQueue,
                          )
                        : _RouteOption(
                            color: AppColors.green,
                            bg: AppColors.greenLt,
                            title: 'ðŸ’¾ SAVE DIRECTLY',
                            desc:
                                'Entry will be saved immediately to the target table. No additional authorization required.',
                            onTap: onDirect,
                          ),
                  ),
                  // Footer - Logic Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      border: Border(top: BorderSide(color: AppColors.border)),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AMS LOGIC: $prog',
                            style: monoStyle(
                                size: 10,
                                weight: FontWeight.w700,
                                color: AppColors.ink3)),
                        const SizedBox(height: 12),
                        _InfoRow(
                            icon: Icons.check_circle_outline_rounded,
                            text: 'APPROVALREQ = ${cfg.approvalReq ? 1 : 0}'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            icon: Icons.layers_outlined,
                            text: 'AUTH001/002 records managed by system'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            icon: Icons.api_rounded,
                            text: 'Target Table: ${cfg.isTran ? 'TRAN' : 'NON-TRAN'} Engine'),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AmsButton(
                              label: 'Cancel',
                              variant: AmsButtonVariant.ghost,
                              small: true,
                              onPressed: onClose),
                        ),
                      ],
                    ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.ink3),
        const SizedBox(width: 10),
        Text(text, style: bodyStyle(size: 13, color: AppColors.ink2)),
      ],
    );
  }
}

class _RouteOption extends StatefulWidget {
  final Color color;
  final Color bg;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _RouteOption({
    required this.color,
    required this.bg,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  State<_RouteOption> createState() => _RouteOptionState();
}

class _RouteOptionState extends State<_RouteOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: widget.color, width: 2),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                        color: widget.color.withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          transform: _hovered
              ? (Matrix4.translationValues(0.0, -2.0, 0.0))
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: bodyStyle(
                      size: 12,
                      weight: FontWeight.w800,
                      color: widget.color)),
              const SizedBox(height: 4),
              Text(widget.desc,
                  style: bodyStyle(size: 11, color: AppColors.ink2)),
            ],
          ),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SCREEN 4 â€” PENDING QUEUE
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class QueueScreen extends StatefulWidget {
  final List<QueueEntry> queue;
  final QueueEntry? lastSubmitted;
  final VoidCallback onNewEntry;
  final String subType;
  final String? userName;

  const QueueScreen({
    super.key,
    required this.queue,
    this.lastSubmitted,
    required this.onNewEntry,
    this.subType = 'Submitted',
    this.userName,
  });

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  String _filter = '';

  List<QueueEntry> get _filtered {
    if (_filter.isEmpty) return widget.queue;
    final fl = _filter.toLowerCase();
    return widget.queue
        .where((r) =>
            r.authsl.toLowerCase().contains(fl) ||
            r.prog.toLowerCase().contains(fl) ||
            r.user.toLowerCase().contains(fl))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final l1Count = widget.queue.where((r) => r.level == 'L1').length;

    return Scaffold(
      body: Column(
        children: [
          AmsTopBar(currentStep: 5, userName: widget.userName),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 60),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Confirm banner
                      if (widget.lastSubmitted != null)
                        _ConfirmBanner(
                          entry: widget.lastSubmitted!,
                          onNewEntry: widget.onNewEntry,
                        ),
                      const SizedBox(height: 4),
                      // Stats
                      _StatsGrid(l1Count: l1Count),
                      const SizedBox(height: 4),
                      // Filters
                      AmsCard(
                        headLeft: sectionTitle('ðŸ” FILTERS'),
                        headRight: AmsButton(
                            label: 'Clear',
                            variant: AmsButtonVariant.ghost,
                            small: true,
                            onPressed: () =>
                                setState(() => _filter = '')),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: 300,
                              child: AmsField(
                                label: 'Search AUTHSL / User / Program',
                                child: AmsTextInput(
                                  placeholder: 'Type to filter...',
                                  onChanged: (v) =>
                                      setState(() => _filter = v),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: AmsField(
                                  label: 'Program Type',
                                  child: AmsDropdown(items: const [
                                    'All Types',
                                    'ðŸ’° Transaction',
                                    'ðŸ“„ Non-Transaction'
                                  ])),
                            ),
                            SizedBox(
                              width: 140,
                              child: AmsField(
                                  label: 'Auth Level',
                                  child: AmsDropdown(items: const [
                                    'All Levels',
                                    'L1',
                                    'L2',
                                    'L3'
                                  ])),
                            ),
                            SizedBox(
                              width: 140,
                              child: AmsField(
                                  label: 'Status',
                                  child: AmsDropdown(items: const [
                                    'All Status',
                                    'Pending',
                                    'Approved'
                                  ])),
                            ),
                          ],
                        ),
                      ),

                      // Table
                      AmsCard(
                        headLeft:
                            sectionTitle('â³ PENDING AUTHORIZATIONS'),
                        headRight: Row(
                          children: [
                            Text('${rows.length} records',
                                style: monoStyle(
                                    size: 11, color: AppColors.ink3)),
                            const SizedBox(width: 8),
                            AmsButton(
                                label: 'Export CSV',
                                variant: AmsButtonVariant.outline,
                                small: true,
                                onPressed: () {}),
                          ],
                        ),
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            AmsPaginatedView<QueueEntry>(
                              items: rows,
                              shrinkWrap: true,
                              builder: (ctx, currentItems) => SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      AppColors.cardHead),
                                  headingTextStyle: monoStyle(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: AppColors.ink3),
                                  dataTextStyle: bodyStyle(
                                      size: 12, color: AppColors.ink2),
                                  columnSpacing: 20,
                                  horizontalMargin: 16,
                                  dividerThickness: 1,
                                  columns: const [
                                    DataColumn(label: Text('AUTH REF â†•')),
                                    DataColumn(label: Text('PROG TYPE')),
                                    DataColumn(label: Text('PROGRAM')),
                                    DataColumn(label: Text('ENTRY USER')),
                                    DataColumn(label: Text('DATE â†•')),
                                    DataColumn(label: Text('AMOUNT â†•')),
                                    DataColumn(label: Text('STATUS')),
                                    DataColumn(label: Text('LEVEL')),
                                    DataColumn(label: Text('FLAGS')),
                                    DataColumn(label: Text('ACTION')),
                                  ],
                                  rows: currentItems.map((r) {
                                  final isT = r.type == 'T';
                                  return DataRow(
                                    color: r.isNew
                                        ? WidgetStateProperty.all(
                                            const Color(0xFFEFF6FF))
                                        : null,
                                    cells: [
                                      // AUTH REF
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 3,
                                            height: 32,
                                            color: isT
                                                ? AppColors.tBlue
                                                : AppColors.nTeal,
                                            margin: const EdgeInsets.only(
                                                right: 8),
                                          ),
                                          Text(r.authsl,
                                              style: monoStyle(
                                                  size: 12,
                                                  weight: FontWeight.w700,
                                                  color: AppColors.tBlue)),
                                          if (r.isNew) ...[
                                            const SizedBox(width: 6),
                                            const AmsBadge(
                                                label: 'NEW',
                                                fontSize: 9),
                                          ],
                                        ],
                                      )),
                                      // PROG TYPE
                                      DataCell(AmsBadge(
                                        label: isT
                                            ? 'ðŸ’° Txn'
                                            : 'ðŸ“„ Non-Txn',
                                        color: isT
                                            ? AppColors.tBlue
                                            : AppColors.nTeal,
                                        background: isT
                                            ? AppColors.tBlueLt
                                            : AppColors.nTealLt,
                                      )),
                                      // PROGRAM
                                      DataCell(Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(r.prog,
                                              style: bodyStyle(
                                                  size: 12,
                                                  weight: FontWeight.w700,
                                                  color: AppColors.ink)),
                                          Text(r.name,
                                              style: monoStyle(
                                                  size: 10,
                                                  color: AppColors.ink3)),
                                        ],
                                      )),
                                      DataCell(Text(r.user)),
                                      DataCell(Text(r.date,
                                          style: monoStyle(
                                              size: 11,
                                              color: AppColors.ink3))),
                                      DataCell(Text(r.amount,
                                          style: bodyStyle(
                                              size: 12,
                                              weight: FontWeight.w700,
                                              color: AppColors.ink))),
                                      // STATUS
                                      DataCell(AmsBadge(
                                        label: 'â— Pending',
                                        color: const Color(0xFF78350F),
                                        background: AppColors.amberLt,
                                      )),
                                      // LEVEL
                                      DataCell(AmsBadge(
                                        label: r.level,
                                        color: r.level == 'L1'
                                            ? const Color(0xFF1E3A8A)
                                            : r.level == 'L2'
                                                ? const Color(0xFF4C1D95)
                                                : const Color(0xFF7C2D12),
                                        background: r.level == 'L1'
                                            ? AppColors.tBlueLt
                                            : r.level == 'L2'
                                                ? AppColors.purpleLt
                                                : const Color(0xFFFFEDD5),
                                      )),
                                      // FLAGS
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (r.risk)
                                            const AmsBadge(
                                                label: 'âš  Risk',
                                                color: AppColors.red,
                                                background: AppColors.redLt),
                                          if (r.locked)
                                            const AmsBadge(
                                                label: 'ðŸ”’ Locked',
                                                color: AppColors.ink3,
                                                background: AppColors.grayLt),
                                          if (!r.risk && !r.locked)
                                            Text('â€”',
                                                style: monoStyle(
                                                    size: 11,
                                                    color: AppColors.ink3)),
                                        ],
                                      )),
                                      // ACTION
                                      DataCell(AmsButton(
                                        label: r.locked
                                            ? 'ðŸ”’ Locked'
                                            : 'Review â†’',
                                        small: true,
                                        variant: r.locked
                                            ? AmsButtonVariant.ghost
                                            : (isT
                                                ? AmsButtonVariant.primary
                                                : AmsButtonVariant.teal),
                                        onPressed: r.locked
                                            ? null
                                            : () => showAmsSnack(
                                                context,
                                                'Opening ${r.authsl} — AUTHLOCK=1 set.',
                                                type: 'i'),
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            ),
                          ],
                        ),
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

class _ConfirmBanner extends StatelessWidget {
  final QueueEntry entry;
  final VoidCallback onNewEntry;

  const _ConfirmBanner({required this.entry, required this.onNewEntry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: const BorderSide(color: AppColors.tBlue, width: 4),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: AppColors.tBlueLt,
                borderRadius: BorderRadius.circular(11)),
            child: const Center(
                child: Text('ðŸ“¥', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SUBMITTED SUCCESSFULLY Â· AUTH001 + AUTH002 CREATED',
                    style: monoStyle(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.tBlue)),
                const SizedBox(height: 4),
                Text(entry.authsl,
                    style: monoStyle(
                        size: 20,
                        weight: FontWeight.w800,
                        color: AppColors.tBlue)),
                Text(
                    '${entry.prog} Â· ${entry.name}${entry.amount != 'â€”' ? ' Â· ${entry.amount}' : ''}',
                    style: bodyStyle(size: 12, color: AppColors.ink2)),
                RichText(
                  text: TextSpan(
                    style: bodyStyle(size: 12, color: AppColors.ink2),
                    children: [
                      const TextSpan(text: 'Routed to '),
                      TextSpan(
                          text: 'L1 Authorization Queue',
                          style: bodyStyle(
                              size: 12,
                              weight: FontWeight.w700,
                              color: AppColors.tBlue)),
                      const TextSpan(
                          text: ' Â· Awaiting Branch Manager approval'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AmsButton(
              label: '+ New Entry',
              variant: AmsButtonVariant.outline,
              small: true,
              onPressed: onNewEntry),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int l1Count;
  const _StatsGrid({required this.l1Count});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 700 ? 4 : 2;
      final stats = [
        (l1Count.toString(), 'Pending L1', 'â†‘ 1 just added',
            AppColors.amber),
        ('3', 'Pending L2', 'Unchanged', AppColors.purple),
        ('2', 'Risk Flagged', 'Needs attention', AppColors.red),
        ('18', 'Approved Today', 'â†‘ 3 vs yesterday', AppColors.green),
      ];
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: stats.map((s) {
          final w =
              (constraints.maxWidth - (cols - 1) * 14) / cols;
          return SizedBox(
            width: w,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 3,
                      offset: Offset(0, 1))
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  border:
                      Border(top: BorderSide(color: s.$4, width: 3)),
                ),
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.$1,
                        style: bodyStyle(
                            size: 28,
                            weight: FontWeight.w800,
                            color: s.$4)),
                    Text(s.$2,
                        style: bodyStyle(
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppColors.ink2)),
                    const SizedBox(height: 5),
                    Text(s.$3,
                        style: monoStyle(
                            size: 10,
                            weight: FontWeight.w600,
                            color: s.$4)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SCREEN 5 â€” DIRECT SAVE SUCCESS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class DirectSaveScreen extends StatefulWidget {
  final String prog;
  final VoidCallback onNewEntry;
  final String? userName;

  const DirectSaveScreen({
    super.key,
    required this.prog,
    required this.onNewEntry,
    this.userName,
  });

  @override
  State<DirectSaveScreen> createState() => _DirectSaveScreenState();
}

class _DirectSaveScreenState extends State<DirectSaveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scale = CurvedAnimation(
        parent: _ctrl, curve: const Cubic(.34, 1.56, .64, 1));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref =
        'DIR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final today = DateTime.now().toString().split(' ')[0];

    return Scaffold(
      body: Column(
        children: [
          AmsTopBar(
              currentStep: 5,
              brandSub: 'APPROVALREQ = 0',
              brandColor: AppColors.green,
              userName: widget.userName),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: FadeTransition(
                  opacity: _fade,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x21000000),
                              blurRadius: 40,
                              offset: Offset(0, 12))
                        ],
                      ),
                      child: Column(
                        children: [
                          // Icon
                          ScaleTransition(
                            scale: _scale,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x401976D2),
                                      blurRadius: 28,
                                      offset: Offset(0, 8))
                                ],
                              ),
                              child: const Center(
                                  child: Text('âœ…',
                                      style: TextStyle(fontSize: 28))),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text('Saved Successfully!',
                              style: bodyStyle(
                                  size: 22,
                                  weight: FontWeight.w800,
                                  color: AppColors.green)),
                          const SizedBox(height: 10),
                          Text(
                              'APPROVALREQ = 0 is configured for ${widget.prog}.\n'
                              'No authorization workflow was triggered â€” the entry was saved directly to the target database table.',
                              style: bodyStyle(
                                  size: 13, color: AppColors.ink2),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          // Chips
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _Chip('PROGRAM', widget.prog),
                              _Chip('TYPE', 'NON-TXN'),
                              _Chip('REF NO.', ref),
                              _Chip('SAVED AT', today),
                              _Chip('APPROVALREQ', '0 (Bypass)'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Timeline
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.bg,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'WHY WAS NO AUTHORIZATION TRIGGERED?',
                                    style: monoStyle(
                                        size: 9,
                                        weight: FontWeight.w700,
                                        color: AppColors.ink3)),
                                const SizedBox(height: 14),
                                ...[
                                  ('ðŸ“‹', 'AUTH101 Checked for Program',
                                      'APPROVALREQ flag queried for ${widget.prog}'),
                                  ('ðŸ”„', 'APPROVALREQ = 0 â€” Authorization Bypass',
                                      'Program configured to skip authorization workflow'),
                                  ('ðŸ’¾', 'Direct Insert to Target Table',
                                      'No AUTH001/AUTH002 records created Â· Data written immediately'),
                                ].asMap().entries.map((e) {
                                  final i = e.key;
                                  final row = e.value;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 14),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                  color: AppColors.greenLt,
                                                  shape: BoxShape.circle),
                                              child: Center(
                                                  child: Text(row.$1,
                                                      style: const TextStyle(
                                                          fontSize: 13))),
                                            ),
                                            if (i < 2)
                                              Container(
                                                  width: 2,
                                                  height: 20,
                                                  color: AppColors.border),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(row.$2,
                                                    style: bodyStyle(
                                                        size: 12,
                                                        weight:
                                                            FontWeight.w700)),
                                                Text(row.$3,
                                                    style: monoStyle(
                                                        size: 10,
                                                        color:
                                                            AppColors.ink3)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              AmsButton(
                                  label: 'â† Back to Dashboard',
                                  variant: AmsButtonVariant.outline,
                                  onPressed: widget.onNewEntry),
                              AmsButton(
                                  label: '+ New Entry',
                                  variant: AmsButtonVariant.green,
                                  onPressed: widget.onNewEntry),
                            ],
                          ),
                        ],
                      ),
                    ),
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

class _Chip extends StatelessWidget {
  final String key_;
  final String val;
  const _Chip(this.key_, this.val);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      constraints: const BoxConstraints(minWidth: 100),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(key_,
              style: monoStyle(size: 9, color: AppColors.ink3)),
          const SizedBox(height: 3),
          Text(val,
              style: bodyStyle(size: 13, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

