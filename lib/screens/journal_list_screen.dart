import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/journal_api_service.dart';

class JournalListScreen extends StatefulWidget {
  final VoidCallback onNew;
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const JournalListScreen({
    super.key,
    required this.onNew,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final JournalApiService _apiService = JournalApiService();
  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJournals();
  }

  Future<void> _fetchJournals() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getJournals();
      if (mounted) {
        setState(() {
          _journals = data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header section
          _buildHeader(),
          
          // Filters & Stats bar (Optional, but adds premium feel)
          _buildStatsBar(),

          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _journals.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: widget.onBackToModule,
          ),
          const SizedBox(width: 8),
          const Text(
            'Manual Journals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: widget.onNew,
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('New Journal', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _buildStatItem('All Journals', _journals.length.toString(), true),
          _buildStatDivider(),
          _buildStatItem('Draft', '0', false),
          _buildStatDivider(),
          _buildStatItem('Published', _journals.length.toString(), false),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool active) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: active ? AppColors.tBlue : AppColors.ink4, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.tBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_outlined, size: 64, color: AppColors.tBlue),
          ),
          const SizedBox(height: 24),
          const Text('No journals found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('Create your first manual journal entry to see it here.', style: bodyStyle(color: AppColors.ink4)),
          const SizedBox(height: 32),
          AmsButton(
            label: 'New Journal',
            onPressed: widget.onNew,
            variant: AmsButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            horizontalMargin: 24,
            columnSpacing: 24,
            headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink4, letterSpacing: 0.5),
            dataTextStyle: const TextStyle(fontSize: 13, color: AppColors.ink),
            columns: const [
              DataColumn(label: Text('DATE')),
              DataColumn(label: Text('JOURNAL#')),
              DataColumn(label: Text('NOTES')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('AMOUNT')),
              DataColumn(label: Text('CREATED BY')),
            ],
            rows: _journals.map((j) {
              final dateStr = j['trandate']?.toString() ?? '';
              final date = dateStr.isNotEmpty ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr)) : '-';
              final amount = j['totaldebit'] ?? 0.0;
              
              return DataRow(
                onSelectChanged: (_) => _showJournalDetails(j),
                cells: [
                  DataCell(Text(date)),
                  DataCell(Text(j['tranid']?.toString() ?? '-', style: const TextStyle(color: AppColors.tBlue, fontWeight: FontWeight.bold))),
                  DataCell(SizedBox(width: 200, child: Text(j['narr'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis))),
                  DataCell(_buildStatusChip(j['transtatus'] ?? 'P')),
                  DataCell(Text('INR ${NumberFormat('#,##,##0.00').format(amount)}')),
                  DataCell(Text(j['euser'] ?? '-')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showJournalDetails(Map<String, dynamic> header) async {
    final orgCode = header['orgcode'] ?? header['ORGCODE'] ?? 50;
    final dateStr = (header['trandate'] ?? header['TRANDATE']).toString().split('T').first;
    final tranId = header['tranid'] ?? header['TRANID'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<Map<String, dynamic>>?>(
        future: _apiService.getJournalDetails(orgCode, dateStr, tranId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final details = snapshot.data ?? [];
          return Dialog(
            insetPadding: const EdgeInsets.all(40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: 800,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Journal Details: ${header['tranid']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildHeaderInfo(header),
                  const SizedBox(height: 24),
                  const Text('Transaction Details (TRAN002)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink4)),
                  const SizedBox(height: 12),
                  _buildDetailsTable(details),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfo(Map<String, dynamic> h) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _infoItem('Date', DateFormat('dd/MM/yyyy').format(DateTime.parse(h['trandate']))),
        _infoItem('Description', h['narr'] ?? '-'),
        _infoItem('Total Amount', 'INR ${NumberFormat('#,##,##0.00').format(h['totaldebit'])}'),
      ],
    );
  }

  Widget _infoItem(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.ink4)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailsTable(List<Map<String, dynamic>> details) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DataTable(
        headingRowHeight: 40,
        dataRowHeight: 40,
        headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
        columns: const [
          DataColumn(label: Text('Line#')),
          DataColumn(label: Text('Account')),
          DataColumn(label: Text('Account Name')),
          DataColumn(label: Text('Debit')),
          DataColumn(label: Text('Credit')),
        ],
        rows: details.map((d) {
          final legid = d['legid'] ?? d['LEGID'] ?? '-';
          final acnum = d['acnum'] ?? d['ACNUM'] ?? '-';
          final accname = d['accname'] ?? d['ACCNAME'] ?? '-';
          final debit = d['trandbamt'] ?? d['TRANDBAMT'] ?? 0;
          final credit = d['trancramt'] ?? d['TRANCRAMT'] ?? 0;
          
          return DataRow(cells: [
            DataCell(Text(legid.toString())),
            DataCell(Text(acnum.toString())),
            DataCell(Text(accname.toString())),
            DataCell(Text(NumberFormat('#,##,##0.00').format(debit))),
            DataCell(Text(NumberFormat('#,##,##0.00').format(credit))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.green;
    String label = 'PUBLISHED';
    
    if (status == 'R') {
      color = Colors.red;
      label = 'REVERSED';
    } else if (status == 'C') {
      color = Colors.orange;
      label = 'CANCELLED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
