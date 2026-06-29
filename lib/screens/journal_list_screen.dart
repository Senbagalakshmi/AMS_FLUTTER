import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/journal_api_service.dart';
import '../utils/responsive.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex;

class JournalListScreen extends StatefulWidget {
  final VoidCallback onNew;
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;
  final onImport;

  const JournalListScreen({
    super.key,
    required this.onNew,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
    required this.onImport,
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

  void _handleImport() {
  widget.onImport();
}

Future<void> _handleExport(String format) async {
  if (format == 'Excel') {
    await _exportExcel();
  } else if (format == 'PDF') {
    await _exportPdf();
  }
}

Future<void> _exportPdf() async {
  final pdf = pw.Document();

  final font = await PdfGoogleFonts.robotoMedium();

  final headers = [
    'Tran Date',
    'Journal No',
    'Narration',
    'Status',
    'Amount',
    'Created By',
    'Authorized By'
  ];

  final rows = _journals.map((j) {
    String date = '';

    try {
      if (j['trandate'] != null) {
        date = DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(j['trandate'].toString()));
      }
    } catch (_) {}

    return [
      date,
      j['tranid']?.toString() ?? '',
      j['narr']?.toString() ?? '',
      j['transtatus']?.toString() ?? '',
      NumberFormat('#,##,##0.00')
          .format(j['totaldebit'] ?? 0),
      j['euser']?.toString() ?? '',
      j['auser']?.toString() ?? '',
    ];
  }).toList();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) => [
        pw.Text(
          'Manual Journals',
          style: pw.TextStyle(
            font: font,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Table.fromTextArray(
          headers: headers,
          data: rows,
          headerStyle: pw.TextStyle(
            font: font,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: pw.TextStyle(font: font),
          border: pw.TableBorder.all(),
        ),
      ],
    ),
  );

  final bytes = await pdf.save();

  if (kIsWeb) {
    final blob = html.Blob([bytes], 'application/pdf');

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', 'Manual_Journals.pdf')
      ..click();

    html.Url.revokeObjectUrl(url);
    return;
  }

  await Printing.sharePdf(
    bytes: bytes,
    filename: 'Manual_Journals.pdf',
  );
}

Future<void> _exportExcel() async {
  final workbook = ex.Excel.createExcel();

  final sheet = workbook['Manual Journals'];

  sheet.appendRow([
    ex.TextCellValue('Tran Date'),
    ex.TextCellValue('Journal No'),
    ex.TextCellValue('Narration'),
    ex.TextCellValue('Status'),
    ex.TextCellValue('Amount'),
    ex.TextCellValue('Created By'),
    ex.TextCellValue('Authorized By'),
  ]);

  for (final j in _journals) {
    String date = '';

    try {
      if (j['trandate'] != null) {
        date = DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(j['trandate'].toString()));
      }
    } catch (_) {}

    sheet.appendRow([
      ex.TextCellValue(date),
      ex.TextCellValue(j['tranid']?.toString() ?? ''),
      ex.TextCellValue(j['narr']?.toString() ?? ''),
      ex.TextCellValue(j['transtatus']?.toString() ?? ''),
      ex.TextCellValue(
        NumberFormat('#,##,##0.00')
            .format(j['totaldebit'] ?? 0),
      ),
      ex.TextCellValue(j['euser']?.toString() ?? ''),
      ex.TextCellValue(j['auser']?.toString() ?? ''),
    ]);
  }

  final bytes = workbook.save();

  if (bytes == null) return;

  if (kIsWeb) {
    final blob = html.Blob(
      [bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', 'Manual_Journals.xlsx')
      ..click();

    html.Url.revokeObjectUrl(url);
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

  Widget _buildImportExportMenu() {
  return PopupMenuButton<String>(
    icon: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: const Icon(
        Icons.more_vert,
        color: AppColors.tBlue,
        size: 22,
      ),
    ),
    color: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    onSelected: (value) {
      if (value == 'import') {
        _handleImport();
      } else if (value == 'export_excel') {
        _handleExport('Excel');
      } else if (value == 'export_pdf') {
        _handleExport('PDF');
      }
    },
    itemBuilder: (context) => [
      PopupMenuItem<String>(
        value: 'import',
        child: Row(
          children: const [
            Icon(Icons.download_rounded,
                size: 18,
                color: AppColors.tBlue),
            SizedBox(width: 12),
            Text('Import Journal'),
          ],
        ),
      ),
      const PopupMenuDivider(),

      const PopupMenuItem(
        enabled: false,
        child: Text(
          'Export',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      PopupMenuItem<String>(
        value: 'export_excel',
        child: Row(
          children: const [
            Icon(Icons.table_chart,
                size: 18,
                color: AppColors.tBlue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Export Journal as Excel',
              ),
            ),
          ],
        ),
      ),

      PopupMenuItem<String>(
        value: 'export_pdf',
        child: Row(
          children: const [
            Icon(Icons.picture_as_pdf,
                size: 18,
                color: AppColors.tBlue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Export Journal as PDF',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildHeader() {
    final isMobile = Responsive.isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                    onPressed: widget.onBackToModule,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Manual Journals',
                      style: bodyStyle(size: 18, weight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AmsButton(
                      label: 'New Journal',
                      onPressed: widget.onNew,
                      icon: Icons.add,
                      variant: AmsButtonVariant.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildImportExportMenu(),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.ink),
              onPressed: widget.onBackToModule,
            ),
            const SizedBox(width: 8),
            Text(
              'Manual Journals',
              style: bodyStyle(size: 20, weight: FontWeight.w700, color: AppColors.ink),
            ),
            const Spacer(),

const SizedBox(width: 12),

AmsButton(
  label: 'New Journal',
  onPressed: widget.onNew,
  icon: Icons.add,
  variant: AmsButtonVariant.primary,
),
const SizedBox(width: 12),

_buildImportExportMenu(),
const SizedBox(width: 12),

          ],
        );
      }),
    );
  }

  Widget _buildList() {
    final isMobile = Responsive.isMobile(context);
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: isMobile ? null : BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header (Hidden on mobile)
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  _buildHeaderCell('TRAN DATE', 100),
                  _buildHeaderCell('JOURNAL#', 100),
                  Expanded(child: _buildHeaderCell('NOTES', 0)),
                  _buildHeaderCell('STATUS', 120),
                  _buildHeaderCell('AMOUNT', 120, textAlign: TextAlign.right),
                  _buildHeaderCell('CREATED BY', 120, textAlign: TextAlign.right),
                  _buildHeaderCell('AUTHORIZED BY', 120, textAlign: TextAlign.right),
                  _buildHeaderCell('', 60),
                ],
              ),
            ),
          // Table Body
          Expanded(
            child: ListView.separated(
              padding: isMobile ? const EdgeInsets.symmetric(vertical: 8) : EdgeInsets.zero,
              itemCount: _journals.length,
              separatorBuilder: (context, index) => isMobile ? const SizedBox(height: 12) : const Divider(height: 1, color: AppColors.border2),
              itemBuilder: (context, index) {
                final j = _journals[index];
                return _buildJournalRow(j);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width, {TextAlign textAlign = TextAlign.left}) {
    return Container(
      width: width > 0 ? width : null,
      child: Text(
        label,
        textAlign: textAlign,
        style: monoStyle(size: 11, weight: FontWeight.w700, color: AppColors.ink3, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildJournalRow(Map<String, dynamic> j) {
    final isMobile = Responsive.isMobile(context);
    final dateStr = j['trandate']?.toString() ?? '';
    final date = dateStr.isNotEmpty ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr)) : '-';
    final amount = j['totaldebit'] ?? 0.0;

    if (isMobile) {
      return InkWell(
        onTap: () => _showJournalDetails(j),
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                  Text(
                    "Journal# ${j['tranid']?.toString() ?? '-'}",
                    style: bodyStyle(size: 14, weight: FontWeight.bold, color: AppColors.tBlue),
                  ),
                  _buildStatusChip(j['transtatus'] ?? 'P'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                j['narr'] ?? '-',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle(size: 13, color: AppColors.ink),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Date: $date", style: bodyStyle(size: 12, color: AppColors.ink3)),
                      const SizedBox(height: 4),
                      Text("Created: ${j['euser'] ?? '-'}", style: bodyStyle(size: 11, color: AppColors.ink4)),
                    ],
                  ),
                  Text(
                    'INR ${NumberFormat('#,##,##0.00').format(amount)}',
                    style: bodyStyle(size: 14, weight: FontWeight.bold, color: AppColors.ink),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _showJournalDetails(j),
      hoverColor: AppColors.tBlueLt.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(width: 100, child: Text(date, style: bodyStyle(size: 13))),
            Container(
              width: 100,
              child: Text(
                j['tranid']?.toString() ?? '-',
                style: bodyStyle(size: 13, weight: FontWeight.w700, color: AppColors.tBlue),
              ),
            ),
            Expanded(
              child: Text(
                j['narr'] ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle(size: 13, color: AppColors.ink2),
              ),
            ),
            Container(width: 120, child: _buildStatusChip(j['transtatus'] ?? 'P')),
            Container(
              width: 120,
              child: Text(
                'INR ${NumberFormat('#,##,##0.00').format(amount)}',
                textAlign: TextAlign.right,
                style: bodyStyle(size: 13, weight: FontWeight.w600),
              ),
            ),
            Container(
              width: 120,
              child: Text(
                j['euser'] ?? '-',
                textAlign: TextAlign.right,
                style: bodyStyle(size: 13, color: AppColors.ink3),
              ),
            ),
            Container(
              width: 120,
              child: Text(
                j['auser'] ?? '-',
                textAlign: TextAlign.right,
                style: bodyStyle(size: 13, color: AppColors.ink3),
              ),
            ),
            Container(
              width: 60,
              alignment: Alignment.center,
              child: IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.tBlue),
                onPressed: () => _showJournalDetails(j),
                tooltip: 'View Details',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    if (status == 'R') {
      return const AmsBadge(label: 'REVERSED', color: AppColors.red, background: AppColors.redLt);
    } else if (status == 'C') {
      return const AmsBadge(label: 'CANCELLED', color: AppColors.amber, background: AppColors.amberLt);
    }
    return const AmsBadge(label: 'POSTED', color: AppColors.green, background: AppColors.greenLt);
  }

  void _showJournalDetails(Map<String, dynamic> header) async {
    final orgCode = header['orgcode'] ?? header['ORGCODE'] ?? 50;
    final dateStr = (header['trandate'] ?? header['TRANDATE']).toString().split('T').first;
    final tranId = header['tranid'] ?? header['TRANID'] ?? 0;
    final isMobile = Responsive.isMobile(context);

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
            insetPadding: EdgeInsets.all(isMobile ? 12 : 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: isMobile ? double.infinity : 900,
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Journal Details',
                          style: bodyStyle(size: 20, weight: FontWeight.w800),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close), 
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    JournalDetailsView(
                      header: header,
                      details: details,
                      isModal: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfo(Map<String, dynamic> h) {
    final isMobile = Responsive.isMobile(context);
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoItem('Date', DateFormat('dd/MM/yyyy').format(DateTime.parse(h['trandate']))),
          const SizedBox(height: 12),
          _infoItem('Description', h['narr'] ?? '-'),
          const SizedBox(height: 12),
          _infoItem('Total Amount', 'INR ${NumberFormat('#,##,##0.00').format(h['totaldebit'])}'),
        ],
      );
    }
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
    final isMobile = Responsive.isMobile(context);
    if (isMobile) {
      return Column(
        children: details.map((d) {
          final legid = d['legid'] ?? d['LEGID'] ?? '-';
          final acnum = d['acnum'] ?? d['ACNUM'] ?? '-';
          final accname = d['accname'] ?? d['ACCNAME'] ?? '-';
          final debit = d['trandbamt'] ?? d['TRANDBAMT'] ?? 0;
          final credit = d['trancramt'] ?? d['TRANCRAMT'] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.bg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Line #$legid", style: monoStyle(size: 11, weight: FontWeight.bold)),
                    Text(acnum.toString(), style: bodyStyle(size: 12, weight: FontWeight.bold, color: AppColors.tBlue)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(accname.toString(), style: bodyStyle(size: 13, color: AppColors.ink2)),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.border2),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Debit", style: bodyStyle(size: 11, color: AppColors.ink4)),
                        Text(NumberFormat('#,##,##0.00').format(debit), style: bodyStyle(size: 13, weight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Credit", style: bodyStyle(size: 11, color: AppColors.ink4)),
                        Text(NumberFormat('#,##,##0.00').format(credit), style: bodyStyle(size: 13, weight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                _buildDetailHeaderCell('Line#', 60),
                _buildDetailHeaderCell('Account', 100),
                Expanded(child: _buildDetailHeaderCell('Account Name', 0)),
                _buildDetailHeaderCell('Debit', 100, textAlign: TextAlign.right),
                _buildDetailHeaderCell('Credit', 100, textAlign: TextAlign.right),
              ],
            ),
          ),
          // Body
          ...details.map((d) {
            final legid = d['legid'] ?? d['LEGID'] ?? '-';
            final acnum = d['acnum'] ?? d['ACNUM'] ?? '-';
            final accname = d['accname'] ?? d['ACCNAME'] ?? '-';
            final debit = d['trandbamt'] ?? d['TRANDBAMT'] ?? 0;
            final credit = d['trancramt'] ?? d['TRANCRAMT'] ?? 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border2)),
              ),
              child: Row(
                children: [
                  Container(width: 60, child: Text(legid.toString(), style: monoStyle(size: 12))),
                  Container(width: 100, child: Text(acnum.toString(), style: bodyStyle(size: 13))),
                  Expanded(child: Text(accname.toString(), style: bodyStyle(size: 13))),
                  Container(
                    width: 100,
                    child: Text(
                      NumberFormat('#,##,##0.00').format(debit),
                      textAlign: TextAlign.right,
                      style: bodyStyle(size: 13, weight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    width: 100,
                    child: Text(
                      NumberFormat('#,##,##0.00').format(credit),
                      textAlign: TextAlign.right,
                      style: bodyStyle(size: 13, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailHeaderCell(String label, double width, {TextAlign textAlign = TextAlign.left}) {
    return Container(
      width: width > 0 ? width : null,
      child: Text(
        label.toUpperCase(),
        textAlign: textAlign,
        style: monoStyle(size: 10, weight: FontWeight.w700, color: AppColors.ink3),
      ),
    );
  }

  Widget _buildStatsBar() {
    final isMobile = Responsive.isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildStatItem('All Journals', _journals.length.toString(), true),
            _buildStatDivider(),
            _buildStatItem('Draft', '0', false),
            _buildStatDivider(),
            _buildStatItem('Posted', _journals.length.toString(), false),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool active) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: bodyStyle(size: 11, color: active ? AppColors.tBlue : AppColors.ink4, weight: active ? FontWeight.w700 : FontWeight.w400)),
        const SizedBox(height: 2),
        Text(value, style: bodyStyle(size: 16, weight: FontWeight.w700, color: AppColors.ink)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.tBlue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_outlined, size: 64, color: AppColors.tBlue),
          ),
          const SizedBox(height: 24),
          Text('No journals found', style: bodyStyle(size: 20, weight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('Create your first manual journal entry to see it here.', style: bodyStyle(color: AppColors.ink3)),
          const SizedBox(height: 32),
          AmsButton(
            label: 'New Journal',
            onPressed: widget.onNew,
            icon: Icons.add,
            variant: AmsButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}
