import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import '../utils/responsive.dart';
import 'nontran_entry_screen.dart';
import 'gl_category_screen.dart';
import 'gl_master_screen.dart';
import 'gl_segments_screen.dart';
import 'gl_attribute_screen.dart';
import 'organisation_screen.dart';
import 'program_master_screen.dart';

class NonTranAuthScreen extends StatefulWidget {
  final List<AuthRecord> authQueue;
  final int? totalRecords;
  final bool isLoading;
  final Future<void> Function(AuthRecord record, bool isApprove) onProcess;
  final Future<void> Function(AuthRecord record, String remarks) onCorrection;
  final Future<void> Function(AuthRecord record)? onLock;
  final VoidCallback onBack;
  final String? userName;
  final Future<void> Function()? onRefresh;
  final Map<String, Auth101Config> authConfigs;

  const NonTranAuthScreen({
    super.key,
    required this.authQueue,
    this.totalRecords,
    this.isLoading = false,
    required this.onProcess,
    required this.onCorrection,
    required this.onBack,
    this.onLock,
    this.userName,
    this.onRefresh,
    required this.authConfigs,
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
  void didUpdateWidget(NonTranAuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Initial selection if none exists
    if (_selectedRecord == null &&
        widget.authQueue.isNotEmpty &&
        !widget.isLoading) {
      setState(() {
        _selectedRecord = widget.authQueue.first;
      });
    }

    // Sync selected record with the new queue if it's been refreshed
    if (_selectedRecord != null) {
      try {
        final updated = widget.authQueue.firstWhere(
          (r) => r.authSl == _selectedRecord!.authSl,
          orElse: () => _selectedRecord!,
        );
        if (updated != _selectedRecord) {
          setState(() => _selectedRecord = updated);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildQueueScreen();
  }

  Widget _buildQueueScreen() {
    final isMobile = Responsive.isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Authorization',
                              style: bodyStyle(
                                  size: 22,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.onRefresh != null)
                                  IconButton(
                                    icon: const Icon(Icons.refresh_rounded, color: AppColors.tBlue, size: 20),
                                    onPressed: widget.onRefresh!,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                if (widget.onRefresh != null) const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.tBlue, size: 18),
                                  onPressed: widget.onBack,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select a record from the queue to review and authorize.',
                          style: bodyStyle(size: 13, color: AppColors.ink3),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
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
                                style: bodyStyle(size: 13, color: AppColors.ink3),
                              ),
                            ],
                          ),
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
                  if (widget.isLoading)
                    const AmsTableSkeleton(rows: 8, shrinkWrap: true)
                  else
                    _AuthQueueTable(
                      queue: widget.authQueue,
                      totalRecords: widget.totalRecords,
                      selectedRecord: _selectedRecord,
                      onSelect: (r) {
                        setState(() => _selectedRecord = r);
                        if (widget.onLock != null) {
                          widget.onLock!(r);
                        }
                      },
                      onView: (r) {
                        setState(() {
                          _selectedRecord = r;
                        });
                        _showDetailPopup(r);
                      },
                    ),

                  if (_selectedRecord != null && !widget.isLoading) ...[
                    const SizedBox(height: 28),
                    _AuthDetailPanel(
                      record: _selectedRecord!,
                      remarksCtrl: _remarksCtrl,
                      authConfigs: widget.authConfigs,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Submit Bar ───────────────────────────────────────────────
          _buildActionFooter(),
        ],
      ),
    );
  }

  Widget _buildActionFooter() {
    return AmsSubmitBar(
      borderColor: AppColors.tBlue,
      actions: [
        AmsButton(
          label: 'Approve',
          variant: AmsButtonVariant.primary,
          icon: Icons.arrow_forward_rounded,
          onPressed: () async {
            if (_selectedRecord == null) return;
            await widget.onProcess(_selectedRecord!, true);
            if (widget.onRefresh != null) {
              await widget.onRefresh!();
            }
            if (mounted) {
              showAmsSnack(context, 'Record Approved', type: 's');
              _remarksCtrl.clear();
              setState(() {
                if (widget.authQueue.isEmpty) _selectedRecord = null;
              });
            }
          },
        ),
        const SizedBox(width: 8),
        AmsButton(
          label: 'Reject',
          variant: AmsButtonVariant.outline,
          onPressed: () async {
            if (_selectedRecord == null) return;

            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: Text('Confirm Rejection',
                    style: bodyStyle(weight: FontWeight.w700)),
                content: Text('Are you sure you want to reject this record?',
                    style: bodyStyle()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child:
                        Text('Cancel', style: bodyStyle(color: AppColors.ink3)),
                  ),
                  AmsButton(
                    label: 'Yes, Reject',
                    variant: AmsButtonVariant.danger,
                    small: true,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await widget.onProcess(_selectedRecord!, false);
              if (widget.onRefresh != null) {
                await widget.onRefresh!();
              }
              if (mounted) {
                showAmsSnack(context, 'Record Rejected', type: 'e');
                _remarksCtrl.clear();
                setState(() {
                });
              }
            }
          },
        ),
        const SizedBox(width: 8),
        AmsButton(
          label: 'Correction',
          variant: AmsButtonVariant.outline,
          icon: Icons.edit_note_rounded,
          onPressed: () async {
            if (_selectedRecord == null) return;

            final remarksController = TextEditingController();
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: Text('Request Correction',
                    style: bodyStyle(weight: FontWeight.w700)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Please provide details for the correction:',
                        style: bodyStyle()),
                    const SizedBox(height: 16),
                    AmsTextInput(
                      controller: remarksController,
                      placeholder: 'Correction details...',
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child:
                        Text('Cancel', style: bodyStyle(color: AppColors.ink3)),
                  ),
                  AmsButton(
                    label: 'Send Correction',
                    variant: AmsButtonVariant.teal,
                    small: true,
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            );

            if (confirmed == true && remarksController.text.isNotEmpty) {
              await widget.onCorrection(
                  _selectedRecord!, remarksController.text);
              if (widget.onRefresh != null) {
                await widget.onRefresh!();
              }
              if (mounted) {
                setState(() {
                  if (widget.authQueue.isEmpty) _selectedRecord = null;
                });
              }
            } else if (confirmed == true && remarksController.text.isEmpty) {
              if (mounted) {
                showAmsSnack(
                    context, 'Remarks are mandatory for correction',
                    type: 'w');
              }
            }
          },
        ),
      ],
    );
  }

  void _showDetailPopup(AuthRecord record) {
    showDialog(
      context: context,
      builder: (context) {
        final isMobile = Responsive.isMobile(context);
        return Dialog(
          insetPadding: EdgeInsets.all(isMobile ? 12 : 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: isMobile ? double.infinity : 900,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.tBlue,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Authorize - ${record.authSl} | ${record.programId} Review',
                          style: bodyStyle(color: Colors.white, weight: FontWeight.w700, size: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (record.programId == 'GL-JRN') ...[
                            JournalDetailsView(
                              header: record.dataBlocks
                                  .firstWhere((b) => b.tableName == 'TRAN001',
                                      orElse: () => record.dataBlocks.first)
                                  .data,
                              details: record.dataBlocks
                                  .where((b) => b.tableName == 'TRAN002')
                                  .map((b) => b.data)
                                  .toList(),
                            ),
                          ] else
                            ...record.dataBlocks.map((block) {
                              if (record.programId == 'GL-CAT') {
                                return GLCategoryFields(
                                  initialData: block.data,
                                  isViewMode: true,
                                  onChanged: (k, v) {},
                                );
                              } else if (record.programId == 'GL-MST' || record.programId == 'GL-MAT') {
                                return GLMasterFields(
                                  initialData: block.data,
                                  isViewMode: true,
                                  onChanged: (k, v) {},
                                  categoryList: const [],
                                );
                              } else if (record.programId == 'ORG-CRT') {
                                return OrganisationFields(
                                  isViewMode: true,
                                  initialData: block.data,
                                  onChanged: (k, v) {},
                                );
                              } else if (record.programId == 'GL-SEG') {
                                return GLSegmentFields(
                                  initialData: block.data,
                                  isViewMode: true,
                                  onChanged: (k, v) {},
                                );
                              } else if (record.programId == 'GL-ATT' || record.programId == 'GL-ATR' || record.programId == 'GL-ATTR') {
                                return GLAttributeFields(
                                  initialData: block.data,
                                  isViewMode: true,
                                  onChanged: (k, v) {},
                                );
                              } else if (record.programId == 'PRM_CRT' || record.programId == 'PROG-CRT') {
                                return ProgramMasterFields(
                                  isViewMode: true,
                                  initialData: block.data,
                                  onChanged: (k, v) {},
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DynamicNTFields(
                                    prog: record.programId,
                                    onChanged: (k, v) {},
                                    initialData: block.data,
                                    isViewMode: true,
                                  ),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Auth Queue Table ──────────────────────────────────────────────────────────

class _AuthQueueTable extends StatelessWidget {
  final List<AuthRecord> queue;
  final int? totalRecords;
  final AuthRecord? selectedRecord;
  final void Function(AuthRecord) onSelect;
  final void Function(AuthRecord) onView;

  const _AuthQueueTable({
    required this.queue,
    this.totalRecords,
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
                  size: 14, weight: FontWeight.w600, color: AppColors.tBlue)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.tBlue.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${queue.length} records',
                style: monoStyle(
                    size: 11, color: AppColors.tBlue, weight: FontWeight.w600)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AmsPaginatedView<AuthRecord>(
          items: queue,
          totalRecords: totalRecords,
          shrinkWrap: true,
          builder: (ctx, currentItems) {
            final isMobile = Responsive.isMobile(ctx);

            if (isMobile) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentItems.length,
                itemBuilder: (context, idx) {
                  final record = currentItems[idx];
                  final isSelected = selectedRecord?.authSl == record.authSl;

                  return InkWell(
                    onTap: () => onSelect(record),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.tBlue.withValues(alpha: 0.04) : Colors.white,
                        border: Border.all(
                          color: isSelected ? AppColors.tBlue : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.tBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  record.programId,
                                  style: monoStyle(
                                    size: 12,
                                    weight: FontWeight.w800,
                                    color: AppColors.tBlue,
                                  ),
                                ),
                              ),
                              _ViewButton(onTap: () => onView(record)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            record.displayRemarks,
                            style: bodyStyle(
                              size: 14,
                              weight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ENTERED BY',
                                      style: bodyStyle(size: 9, color: AppColors.ink3, weight: FontWeight.w700, letterSpacing: 0.5)),
                                  const SizedBox(height: 3),
                                  Text(record.eUser, style: bodyStyle(size: 12, color: AppColors.ink2, weight: FontWeight.w600)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('ENTERED ON',
                                      style: bodyStyle(size: 9, color: AppColors.ink3, weight: FontWeight.w700, letterSpacing: 0.5)),
                                  const SizedBox(height: 3),
                                  Text(record.eDate, style: monoStyle(size: 11, color: AppColors.ink2, weight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return Table(
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
                      : (idx % 2 == 0 ? const Color(0xFFF8FAFB) : Colors.white);
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
                              color:
                                  isSelected ? AppColors.tBlue : AppColors.ink3,
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
                          style: bodyStyle(size: 13, color: AppColors.tBlue)
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
            );
          },
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
        style:
            bodyStyle(size: 12, weight: FontWeight.w700, color: Colors.white),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hover ? AppColors.tBlue : AppColors.tBlue.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.tBlue.withAlpha(50), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_outlined,
                  size: 13, color: _hover ? Colors.white : AppColors.tBlue),
              const SizedBox(width: 4),
              Text('View',
                  style: bodyStyle(
                      size: 12,
                      weight: FontWeight.w700,
                      color: _hover ? Colors.white : AppColors.tBlue)),
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
  final bool readOnly;
  final Map<String, Auth101Config> authConfigs;

  const _AuthDetailPanel({
    required this.record,
    required this.remarksCtrl,
    this.readOnly = false,
    required this.authConfigs,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: Auth Levels ──
        if (isMobile)
          _buildLevelsCard()
        else
          Expanded(child: _buildLevelsCard()),
        
        SizedBox(
          width: isMobile ? 0 : 20,
          height: isMobile ? 20 : 0,
        ),
        
        // ── Right: Exception & Correction info ──
        if (isMobile)
          _buildInfoCard()
        else
          Expanded(child: _buildInfoCard()),
      ],
    );
  }

  Widget _buildLevelsCard() {
    return AmsCard(
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
          if ((authConfigs[record.programId]?.levels ?? 1) >= 1 ||
              (authConfigs[record.programId]?.levels ?? 0) == 0) ...[
            _levelRow(
                '1st Level', record.flUser ?? '', record.flDate ?? ''),
            const SizedBox(height: 12),
          ],
          if ((authConfigs[record.programId]?.levels ?? 0) >= 2) ...[
            _levelRow(
                '2nd Level', record.slUser ?? '', record.slDate ?? ''),
            const SizedBox(height: 12),
          ],
          if ((authConfigs[record.programId]?.levels ?? 0) >= 3) ...[
            _levelRow(
                '3rd Level', record.tlUser ?? '', record.tlDate ?? ''),
            const SizedBox(height: 12),
          ],
          _levelRow('Risk Auth', record.rUser ?? '', record.rDate ?? ''),
          const SizedBox(height: 16),
          AmsField(
            label: 'Approver Remarks',
            labelAbove: true,
            child: AmsTextInput(
              controller: remarksCtrl,
              readOnly: readOnly,
              placeholder: 'Enter your remarks...',
              keyboardType: TextInputType.multiline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return AmsCard(
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
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .expand((c) => [c, const SizedBox(height: 12)])
            .toList()
          ..removeLast(),
      );
    }

    return Row(
      children: children
          .expand((c) => [Expanded(child: c), const SizedBox(width: 12)])
          .toList()
        ..removeLast(),
    );
  }
}
