import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import 'nontran_entry_screen.dart';

class NonTranAuthScreen extends StatefulWidget {
  final List<AuthRecord> authQueue;
  final Future<void> Function(AuthRecord record, bool isApprove) onProcess;
  final Future<void> Function(AuthRecord record)? onLock;
  final VoidCallback onBack;
  final String? userName;
  final Future<void> Function()? onRefresh;

  const NonTranAuthScreen({
    super.key,
    required this.authQueue,
    required this.onProcess,
    required this.onBack,
    this.onLock,
    this.userName,
    this.onRefresh,
  });

  @override
  State<NonTranAuthScreen> createState() => _NonTranAuthScreenState();
}

class _NonTranAuthScreenState extends State<NonTranAuthScreen> {
  AuthRecord? _selectedRecord;
  final _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.authQueue.isNotEmpty) {
      _selectedRecord = widget.authQueue.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                          'Authorization',
                            style: bodyStyle(
                                size: 22,
                                weight: FontWeight.w700,
                                color: AppColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a record from the queue to review and authorize.',
                            style:
                                bodyStyle(size: 13, color: AppColors.ink3),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (widget.onRefresh != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AmsButton(
                                label: 'Refresh',
                                variant: AmsButtonVariant.outline,
                                small: true,
                                icon: Icons.refresh_rounded,
                                onPressed: widget.onRefresh!,
                              ),
                            ),
                          AmsButton(
                            label: 'Back',
                            variant: AmsButtonVariant.outline,
                            small: true,
                            icon: Icons.arrow_back_ios_new_rounded,
                            onPressed: widget.onBack,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Queue Table ───────────────────────────────────────
                  _AuthQueueTable(
                    queue: widget.authQueue,
                    selectedRecord: _selectedRecord,
                    onSelect: (r) {
                      setState(() => _selectedRecord = r);
                      if (widget.onLock != null) {
                        widget.onLock!(r);
                      }
                    },
                    onView: _showDetailsDialog,
                  ),

                  if (_selectedRecord != null) ...[
                    const SizedBox(height: 28),
                    _AuthDetailPanel(record: _selectedRecord!,
                        remarksCtrl: _remarksCtrl),
                  ],
                ],
              ),
            ),
          ),

          // ── Submit Bar ───────────────────────────────────────────────
          AmsSubmitBar(
            borderColor: AppColors.tBlue,
            actions: [
              AmsButton(
                label: 'Approve',
                variant: AmsButtonVariant.primary,
                icon: Icons.check_circle_outline_rounded,
                onPressed: () async {
                  if (_selectedRecord == null) return;
                  await widget.onProcess(_selectedRecord!, true);
                  if (context.mounted) {
                    showAmsToast(context, '✅', 'Record Approved');
                  }
                },
              ),
              const SizedBox(width: 8),
              AmsButton(
                label: 'Reject',
                variant: AmsButtonVariant.outline,
                onPressed: () async {
                  if (_selectedRecord == null) return;
                  await widget.onProcess(_selectedRecord!, false);
                  if (context.mounted) {
                    showAmsToast(context, '❌', 'Record Rejected', type: 'e');
                  }
                },
              ),
              const SizedBox(width: 8),
              AmsButton(
                label: 'Request for Correction',
                variant: AmsButtonVariant.outline,
                icon: Icons.edit_note_rounded,
                onPressed: () {
                  showAmsToast(
                      context, '🔄', 'Sent for Correction',
                      type: 'w');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(AuthRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 600),
          child: Column(
            children: [
              // Dialog header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 18),
                decoration: const BoxDecoration(
                  color: AppColors.tBlue,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Record Details — ${record.authSl}',
                              style: bodyStyle(
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                          Text(
                              '${record.programId} · ${record.primaryKey}',
                              style: monoStyle(
                                  size: 11,
                                  color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Dialog body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...record.dataBlocks.map((block) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DynamicNTFields(
                              prog: record.programId,
                              onChanged: (k, v) {}, // Locked inside isViewMode
                              initialData: block.data,
                              isViewMode: true,
                            ),
                            const Divider(height: 28),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Dialog footer
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AmsButton(
                    label: 'Close',
                    variant: AmsButtonVariant.outline,
                    small: true,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(key,
                style: monoStyle(size: 11, color: AppColors.ink3)),
          ),
          Expanded(
            child: Text(value,
                style:
                    bodyStyle(size: 13, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Auth Queue Table ──────────────────────────────────────────────────────────

class _AuthQueueTable extends StatelessWidget {
  final List<AuthRecord> queue;
  final AuthRecord? selectedRecord;
  final void Function(AuthRecord) onSelect;
  final void Function(AuthRecord) onView;

  const _AuthQueueTable({
    required this.queue,
    required this.selectedRecord,
    required this.onSelect,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return AmsCard(
      headLeft: Row(
        children: [
          const Icon(Icons.playlist_add_check_circle_rounded,
              size: 18, color: AppColors.tBlue),
          const SizedBox(width: 8),
          Text('Authorization Queue',
              style: bodyStyle(
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppColors.tBlue)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.tBlue.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${queue.length} records',
                style: monoStyle(
                    size: 11,
                    color: AppColors.tBlue,
                    weight: FontWeight.w600)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AmsPaginatedView<AuthRecord>(
          items: queue,
          shrinkWrap: true,
          builder: (ctx, currentItems) => Table(
            columnWidths: const {
              0: FixedColumnWidth(52),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(2),
              5: FixedColumnWidth(100),
            },
            border: TableBorder.all(color: AppColors.border, width: 0.5),
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(color: AppColors.tBlue),
                children: [
                  _th(''),
                  _th('Program Name'),
                  _th('Entry Details'),
                  _th('Entered By'),
                  _th('Entered On'),
                  _th('Verify', center: true),
                ],
              ),
              // Data rows
              ...currentItems.asMap().entries.map((e) {
              final idx = e.key;
              final record = e.value;
              final isSelected = selectedRecord?.authSl == record.authSl;
              final rowBg = isSelected
                  ? AppColors.tBlueLt
                  : (idx % 2 == 0
                      ? const Color(0xFFF8FAFB)
                      : Colors.white);
              return TableRow(
                decoration: BoxDecoration(color: rowBg),
                children: [
                  // Select radio
                  _tdCenter(
                    InkWell(
                      onTap: () => onSelect(record),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.tBlue
                              : AppColors.ink3,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Program Name
                  _td(
                    Text(record.programId,
                        style: monoStyle(
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.ink)),
                    onTap: () => onSelect(record),
                  ),
                  // Entry Details
                  _td(
                    Text(
                      record.displayRemarks,
                      style: bodyStyle(
                              size: 13,
                              color: AppColors.tBlue)
                          .copyWith(
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.tBlue),
                    ),
                    onTap: () => onSelect(record),
                  ),
                  // Entered By
                  _td(
                    Text(record.eUser,
                        style: bodyStyle(size: 13, color: AppColors.ink2)),
                    onTap: () => onSelect(record),
                  ),
                  // Entered On
                  _td(
                    Text(record.eDate,
                        style: monoStyle(size: 11, color: AppColors.ink2)),
                    onTap: () => onSelect(record),
                  ),
                  // View button
                  _tdCenter(
                    _ViewButton(onTap: () => onView(record)),
                  ),
                ],
              );
              }),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _th(String text, {bool center = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: bodyStyle(size: 12, weight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  static Widget _td(Widget child, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: child,
      ),
    );
  }

  static Widget _tdCenter(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Center(child: child),
    );
  }
}


// ─── Hover View Button ────────────────────────────────────────────────────────

class _ViewButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ViewButton({required this.onTap});

  @override
  State<_ViewButton> createState() => _ViewButtonState();
}

class _ViewButtonState extends State<_ViewButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hover
                ? AppColors.tBlue
                : AppColors.tBlue.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: AppColors.tBlue.withAlpha(50),
                width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_outlined,
                  size: 13,
                  color: _hover ? Colors.white : AppColors.tBlue),
              const SizedBox(width: 4),
              Text('View',
                  style: bodyStyle(
                      size: 12,
                      weight: FontWeight.w700,
                      color: _hover
                          ? Colors.white
                          : AppColors.tBlue)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Auth Detail Panel ────────────────────────────────────────────────────────

class _AuthDetailPanel extends StatelessWidget {
  final AuthRecord record;
  final TextEditingController remarksCtrl;

  const _AuthDetailPanel(
      {required this.record, required this.remarksCtrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: Auth Levels ──
        Expanded(
          child: AmsCard(
            headLeft: Row(
              children: [
                const Icon(Icons.how_to_reg_rounded,
                    size: 18, color: AppColors.tBlue),
                const SizedBox(width: 8),
                Text('Authorization Levels',
                    style: bodyStyle(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.tBlue)),
              ],
            ),
            child: Column(
              children: [
                _levelRow('1st Level', record.flUser ?? '', record.flDate ?? ''),
                const SizedBox(height: 12),
                _levelRow('2nd Level', record.slUser ?? '', record.slDate ?? ''),
                const SizedBox(height: 12),
                _levelRow('3rd Level', record.tlUser ?? '', record.tlDate ?? ''),
                const SizedBox(height: 12),
                _levelRow('Risk Auth', record.rUser ?? '', record.rDate ?? ''),
                const SizedBox(height: 16),
                AmsField(
                  label: 'Approver Remarks',
                  labelAbove: true,
                  child: AmsTextInput(
                    controller: remarksCtrl,
                    placeholder: 'Enter your remarks...',
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        // ── Right: Exception & Correction info ──
        Expanded(
          child: AmsCard(
            headLeft: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.amber),
                const SizedBox(width: 8),
                Text('Exception & Correction Info',
                    style: bodyStyle(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.amber)),
              ],
            ),
            child: Column(
              children: [
                AmsField(
                  label: 'Exceptional Details',
                  labelAbove: true,
                  child: AmsTextInput(
                    initialValue: record.exceptionalRemarks,
                    readOnly: true,
                    keyboardType: TextInputType.multiline,
                    placeholder: '—',
                  ),
                ),
                const SizedBox(height: 12),
                AmsField(
                  label: 'Corrections Info',
                  labelAbove: true,
                  child: AmsTextInput(
                    initialValue: record.correctionDetails,
                    readOnly: true,
                    keyboardType: TextInputType.multiline,
                    placeholder: '—',
                  ),
                ),
                const SizedBox(height: 12),
                _FormGridSimple(
                  children: [
                    AmsField(
                      label: 'Corrected By',
                      labelAbove: true,
                      child: AmsTextInput(
                          initialValue: record.cUser,
                          readOnly: true,
                          placeholder: '—'),
                    ),
                    AmsField(
                      label: 'Corrected On',
                      labelAbove: true,
                      child: AmsTextInput(
                          initialValue: record.cDate,
                          readOnly: true,
                          placeholder: '—'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _levelRow(String label, String user, String date) {
    return _FormGridSimple(
      children: [
        AmsField(
          label: '$label — Authorised By',
          labelAbove: true,
          pill: user.isNotEmpty && user != '0' ? AmsPill.auto() : null,
          child: AmsTextInput(
              initialValue: user.isEmpty || user == '0' ? '—' : user,
              readOnly: true,
              placeholder: '—'),
        ),
        AmsField(
          label: '$label — Authorised On',
          labelAbove: true,
          child: AmsTextInput(
              initialValue: date.isEmpty ? '—' : date,
              readOnly: true,
              placeholder: '—'),
        ),
      ],
    );
  }
}

class _FormGridSimple extends StatelessWidget {
  final List<Widget> children;
  const _FormGridSimple({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .expand((c) => [Expanded(child: c), const SizedBox(width: 12)])
          .toList()
        ..removeLast(),
    );
  }
}
