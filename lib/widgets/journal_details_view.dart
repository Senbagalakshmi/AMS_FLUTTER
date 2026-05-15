import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../utils/responsive.dart';
import '../services/gl_api_service.dart';
import 'widgets.dart';

class JournalDetailsView extends StatefulWidget {
  final Map<String, dynamic> header;
  final List<Map<String, dynamic>> details;
  final Map<String, String>? accountNames;
  final bool isModal;

  const JournalDetailsView({
    super.key,
    required this.header,
    required this.details,
    this.accountNames,
    this.isModal = false,
  });

  @override
  State<JournalDetailsView> createState() => _JournalDetailsViewState();
}

class _JournalDetailsViewState extends State<JournalDetailsView> {
  late Timer _timer;
  final Map<String, String> _localCache = {};
  bool _isFetchingMissing = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
    _triggerInitialSync();
  }

  void _triggerInitialSync() async {
    // Aggressively prime the cache if it's empty
    if (GLApiService.accountCache.isEmpty) {
      await GLApiService().getGlList();
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchMissingName(String code) async {
    if (_isFetchingMissing || code.isEmpty || code == '-') return;
    _isFetchingMissing = true;
    try {
      // Direct fetch from server for this specific missing name
      await GLApiService().getGlList();
    } finally {
      _isFetchingMissing = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  dynamic dVal(Map<String, dynamic> data, List<String> keys) {
    for (var k in keys) {
      if (data.containsKey(k)) return data[k];
      for (var entry in data.entries) {
        if (entry.key.toLowerCase() == k.toLowerCase()) return entry.value;
      }
    }
    for (var entry in data.entries) {
      if (entry.value is Map<String, dynamic>) {
        final res = dVal(entry.value as Map<String, dynamic>, keys);
        if (res != null) return res;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    List<Map<String, dynamic>> finalDetails = widget.details;
    if (finalDetails.isEmpty) {
      final possibleLines = dVal(widget.header, ['lines', 'details', 'transactions', 'tranlines', 'tran002', 'items']);
      if (possibleLines is List) {
        finalDetails = possibleLines.whereType<Map<String, dynamic>>().toList();
      }
    }

    double displayAmount = double.tryParse(dVal(widget.header, ['totaldebit', 'totalDebit', 'TOTALDEBIT', 'amount', 'total_debit'])?.toString() ?? '0') ?? 0.0;
    if (displayAmount == 0) {
      for (var d in finalDetails) {
        final val = double.tryParse(dVal(d, ['trandbamt', 'debit', 'amount'])?.toString() ?? '0') ?? 0.0;
        displayAmount += val;
      }
    }

    final tranId = dVal(widget.header, ['tranid', 'tranId', 'TRANID', 'authSl', 'primaryKey'])?.toString() ?? '0';
    final tranDate = dVal(widget.header, ['trandate', 'tranDate', 'TRANDATE', 'eDate'])?.toString() ?? '';
    String formattedDate = '-';
    try {
      if (tranDate.isNotEmpty) {
        final dt = DateTime.parse(tranDate.split(' ')[0]);
        formattedDate = DateFormat('dd MMM yyyy').format(dt);
      }
    } catch (_) {}

    final org = dVal(widget.header, ['orgcd', 'orgCode', 'ORGCD', 'organization', 'org'])?.toString() ?? '-';
    final branch = dVal(widget.header, ['brncd', 'branchCode', 'BRNCD', 'branch', 'branch_code'])?.toString() ?? '-';
    final desc = dVal(widget.header, ['narr', 'trandesc', 'description', 'TRANDESC', 'remarks'])?.toString() ?? '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(
            children: [
              Row(
                children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.tBlueLt, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.description_outlined, color: AppColors.tBlue)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Journal Entry #$tranId', style: bodyStyle(size: 18, weight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(formattedDate, style: monoStyle(size: 12, color: AppColors.ink3)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('TOTAL AMOUNT', style: monoStyle(size: 10, color: AppColors.ink4)),
                      const SizedBox(height: 4),
                      Text('INR ${NumberFormat('#,##,##0.00').format(displayAmount)}', style: bodyStyle(size: 20, weight: FontWeight.w900, color: AppColors.ink)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.border2),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _infoItem('ORGANIZATION', org)),
                  Expanded(child: _infoItem('BRANCH', branch)),
                  Expanded(child: _infoItem('DESCRIPTION', desc, flex: 2)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (isMobile)
          ...finalDetails.map((d) => _buildMobileCard(d))
        else
          _buildTable(finalDetails, displayAmount),
      ],
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> lines, double total) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.bg,
            child: Row(
              children: [
                _th('ACCOUNT', 120),
                Expanded(child: _th('ACCOUNT NAME', 0)),
                Expanded(child: _th('REMARKS', 0)),
                _th('DEBIT', 120, align: TextAlign.right),
                _th('CREDIT', 120, align: TextAlign.right),
              ],
            ),
          ),
          ...lines.map((d) {
            final acNumRaw = dVal(d, ['acnum', 'acNum', 'ACNUM', 'accountNo', 'glNo'])?.toString() ?? '-';
            final acNum = acNumRaw.split('.').first.trim();
            String accName = dVal(d, ['accname', 'accName', 'ACCNAME', 'accountName', 'glName', 'glname', 'name', 'account_name'])?.toString() ?? '';
            String remarks = dVal(d, ['tranrem', 'remarks', 'description', 'TRANREM'])?.toString() ?? '-';
            
            if (accName.isEmpty || accName == '-') {
              // 1. Try exact matches from prop and cache
              accName = widget.accountNames?[acNumRaw] ?? widget.accountNames?[acNum] ?? GLApiService.accountCache[acNumRaw] ?? GLApiService.accountCache[acNum] ?? '';
              
              // 2. Try Numeric/Fuzzy matching if still empty
              if (accName.isEmpty) {
                final acInt = int.tryParse(acNum);
                if (acInt != null) {
                  // Search cache for any key that matches this number
                  for (var entry in GLApiService.accountCache.entries) {
                    final cacheKeyInt = int.tryParse(entry.key.split('.').first.trim());
                    if (cacheKeyInt == acInt) {
                      accName = entry.value;
                      break;
                    }
                  }
                }
              }

              if (accName.isEmpty || accName == '...') {
                accName = '...';
                // Trigger background fetch if missing
                _fetchMissingName(acNum);
              }
            }

            final db = double.tryParse(dVal(d, ['trandbamt', 'debit'])?.toString() ?? '0') ?? 0.0;
            final cr = double.tryParse(dVal(d, ['trancramt', 'credit'])?.toString() ?? '0') ?? 0.0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border2))),
              child: Row(
                children: [
                  Container(width: 120, child: Text(acNumRaw, style: bodyStyle(size: 13, weight: FontWeight.w600, color: AppColors.tBlue))),
                  Expanded(child: Text(accName, style: bodyStyle(size: 13))),
                  Expanded(child: Text(remarks, style: bodyStyle(size: 13, color: AppColors.ink3))),
                  Container(width: 120, child: Text(db > 0 ? NumberFormat('#,##,##0.00').format(db) : '-', textAlign: TextAlign.right, style: bodyStyle(size: 13, weight: FontWeight.bold, color: AppColors.green))),
                  Container(width: 120, child: Text(cr > 0 ? NumberFormat('#,##,##0.00').format(cr) : '-', textAlign: TextAlign.right, style: bodyStyle(size: 13, weight: FontWeight.bold, color: AppColors.red))),
                ],
              ),
            );
          }).toList(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: AppColors.bg,
            child: Row(
              children: [
                const Spacer(),
                Text('TOTALS', style: monoStyle(weight: FontWeight.w800, size: 11)),
                const SizedBox(width: 40),
                Container(width: 120, child: Text(NumberFormat('#,##,##0.00').format(total), textAlign: TextAlign.right, style: bodyStyle(size: 14, weight: FontWeight.w800, color: AppColors.green))),
                Container(width: 120, child: Text(NumberFormat('#,##,##0.00').format(total), textAlign: TextAlign.right, style: bodyStyle(size: 14, weight: FontWeight.w800, color: AppColors.red))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> d) {
    final acNumRaw = dVal(d, ['acnum', 'acNum', 'ACNUM', 'accountNo', 'glNo'])?.toString() ?? '-';
    final acNum = acNumRaw.split('.').first.trim();
    String accName = dVal(d, ['accname', 'accName', 'ACCNAME', 'accountName', 'glName', 'glname', 'name', 'account_name'])?.toString() ?? '';
    if (accName.isEmpty || accName == '-') {
      accName = widget.accountNames?[acNum] ?? GLApiService.accountCache[acNum] ?? '...';
    }
    final remarks = dVal(d, ['tranrem', 'remarks', 'description', 'TRANREM'])?.toString() ?? '-';
    final db = double.tryParse(dVal(d, ['trandbamt', 'debit'])?.toString() ?? '0') ?? 0.0;
    final cr = double.tryParse(dVal(d, ['trancramt', 'credit'])?.toString() ?? '0') ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(acNumRaw, style: bodyStyle(size: 12, weight: FontWeight.bold, color: AppColors.tBlue)),
              if (remarks != '-') Text(remarks, style: bodyStyle(size: 11, color: AppColors.ink4)),
            ],
          ),
          const SizedBox(height: 4),
          Text(accName, style: bodyStyle(size: 14, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _mon('DEBIT', db, AppColors.green)),
              Expanded(child: _mon('CREDIT', cr, AppColors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, {int flex = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: monoStyle(size: 9, weight: FontWeight.w700, color: AppColors.ink4)),
        const SizedBox(height: 4),
        Text(value, style: bodyStyle(size: 14, weight: FontWeight.w700, color: AppColors.ink)),
      ],
    );
  }

  Widget _th(String label, double width, {TextAlign align = TextAlign.left}) => Container(
    width: width > 0 ? width : null,
    child: Text(label, textAlign: align, style: monoStyle(size: 10, weight: FontWeight.w700, color: AppColors.ink3)),
  );

  Widget _mon(String label, double val, Color color) => Column(
    crossAxisAlignment: label == 'DEBIT' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
    children: [
      Text(label, style: monoStyle(size: 9, color: AppColors.ink4)),
      Text(val > 0 ? NumberFormat('#,##,##0.00').format(val) : '-', style: bodyStyle(size: 14, weight: FontWeight.bold, color: val > 0 ? color : AppColors.ink4)),
    ],
  );
}
