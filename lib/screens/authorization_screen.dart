import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class AuthorizationScreen extends StatefulWidget {
  final List<AuthRecord> authQueue;
  final void Function(AuthRecord, bool isApprove) onProcess;
  final VoidCallback onBack;
  final String? userName;

  const AuthorizationScreen({
    super.key,
    required this.authQueue,
    required this.onProcess,
    required this.onBack,
    this.userName,
  });

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  AuthRecord? _selectedRecord;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [

          Expanded(
            child: Row(
              children: [
                // Left Panel: Queue List
                Container(
                  width: 450,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Pending Requests',
                                style: bodyStyle(
                                    size: 18, weight: FontWeight.w800)),
                            AmsBadge(
                                label: '${widget.authQueue.length} PENDING',
                                color: AppColors.amber,
                                background: AppColors.amberLt),
                          ],
                        ),
                      ),
                      Expanded(
                        child: widget.authQueue.isEmpty
                            ? _buildEmptyState()
                            : AmsPaginatedView<AuthRecord>(
                                items: widget.authQueue,
                                builder: (ctx, currentItems) => ListView.builder(
                                  itemCount: currentItems.length,
                                  itemBuilder: (ctx, i) {
                                    final rec = currentItems[i];
                                  final isSel = _selectedRecord == rec;
                                  return _AuthQueueItem(
                                    record: rec,
                                    isSelected: isSel,
                                    onTap: () =>
                                        setState(() => _selectedRecord = rec),
                                  );
                                },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                // Right Panel: Details
                Expanded(
                  child: _selectedRecord == null
                      ? _buildNoSelection()
                      : _AuthDetailView(
                          record: _selectedRecord!,
                          onApprove: () =>
                              widget.onProcess(_selectedRecord!, true),
                          onReject: () =>
                              widget.onProcess(_selectedRecord!, false),
                        ),
                ),
              ],
            ),
          ),
          AmsSubmitBar(
            borderColor: AppColors.tBlue,
            actions: [
              AmsButton(
                label: 'Close Queue',
                variant: AmsButtonVariant.outline,
                onPressed: widget.onBack,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('All caught up!', style: bodyStyle(weight: FontWeight.w700)),
          Text('No pending authorizations found.',
              style: monoStyle(color: AppColors.ink3)),
        ],
      ),
    );
  }

  Widget _buildNoSelection() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_outlined,
              size: 48, color: AppColors.border2),
          const SizedBox(height: 16),
          Text('Select a request to review',
              style: bodyStyle(size: 15, weight: FontWeight.w700)),
          Text('Choose an entry from the left panel to see its details',
              style: bodyStyle(color: AppColors.ink3)),
        ],
      ),
    );
  }
}

class _AuthQueueItem extends StatelessWidget {
  final AuthRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuthQueueItem({
    required this.record,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.tBlue : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppColors.tBlue.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AmsBadge(
                    label: record.programId,
                    color: AppColors.nTeal,
                    background: AppColors.nTealLt,
                    fontSize: 9),
                const Spacer(),
                Text(record.authSl,
                    style: monoStyle(size: 10, color: AppColors.ink3)),
              ],
            ),
            const SizedBox(height: 10),
            Text(record.displayRemarks,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle(weight: FontWeight.w700, size: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppColors.ink3),
                const SizedBox(width: 4),
                Text(record.eUser, style: monoStyle(size: 10)),
                const Spacer(),
                const Icon(Icons.access_time, size: 14, color: AppColors.ink3),
                const SizedBox(width: 4),
                Text(record.eDate.split(' ')[0], style: monoStyle(size: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthDetailView extends StatelessWidget {
  final AuthRecord record;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AuthDetailView({
    required this.record,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REQUEST DETAILS',
                        style: monoStyle(
                            weight: FontWeight.w800, color: AppColors.ink3)),
                    const SizedBox(height: 8),
                    Text(record.displayRemarks,
                        style: bodyStyle(size: 20, weight: FontWeight.w800)),
                  ],
                ),
              ),
              Row(
                children: [
                  AmsButton(
                    label: 'Reject',
                    variant: AmsButtonVariant.outline,
                    icon: Icons.close,
                    onPressed: onReject,
                  ),
                  const SizedBox(width: 12),
                  AmsButton(
                    label: 'Authorize',
                    variant: AmsButtonVariant.teal,
                    icon: Icons.check,
                    onPressed: onApprove,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          AmsCard(
            headLeft: Text('Technical Metadata',
                style: bodyStyle(weight: FontWeight.w700)),
            child: AmsAuthTable(
              headers: const ['Field', 'Value'],
              rows: [
                TableRow(children: [
                  _tableCell('Daily Auth SL'),
                  _tableCell(record.authSl, isValue: true),
                ]),
                TableRow(children: [
                  _tableCell('Program ID'),
                  _tableCell(record.programId, isValue: true),
                ]),
                TableRow(children: [
                  _tableCell('Primary Key'),
                  _tableCell(record.primaryKey, isValue: true),
                ]),
                TableRow(children: [
                  _tableCell('Entered By'),
                  _tableCell(record.eUser, isValue: true),
                ]),
                TableRow(children: [
                  _tableCell('Entry Date/Time'),
                  _tableCell(record.eDate, isValue: true),
                ]),
                TableRow(children: [
                  _tableCell('Organisation Code'),
                  _tableCell(record.orgCode, isValue: true),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          sectionTitle('DATA CHANGES'),
          const SizedBox(height: 12),
          ...record.dataBlocks.map((block) => _AuthDataCard(block: block)),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool isValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: isValue
            ? bodyStyle(weight: FontWeight.w600)
            : monoStyle(size: 10, color: AppColors.ink3),
      ),
    );
  }
}

class _AuthDataCard extends StatelessWidget {
  final AuthDataBlock block;
  const _AuthDataCard({required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined,
                    size: 16, color: AppColors.ink2),
                const SizedBox(width: 8),
                Text('TABLE: ${block.tableName}',
                    style: monoStyle(weight: FontWeight.w700, size: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: block.data.entries.map((e) {
                return AmsAuthField(
                  label: e.key,
                  value: e.value.toString(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
