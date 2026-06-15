import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/report_api_service.dart';

class AccountTransactionsScreen extends StatefulWidget {
  final String glno;
  final String glname;
  final String gltype;
  final DateTime fromDate;
  final DateTime toDate;

  const AccountTransactionsScreen({
    super.key,
    required this.glno,
    required this.glname,
    required this.gltype,
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<AccountTransactionsScreen> createState() =>
      _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState
    extends State<AccountTransactionsScreen> {
  final ReportApiService _api = ReportApiService();

  bool _loading = false;
  List<Map<String, dynamic>> _transactions = [];

  late DateTime _fromDate;
  late DateTime _toDate;

  final currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  // ── Design tokens ────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF5F9FF);
  static const _primaryBlue = Color(0xFF1976D2);
  static const _surfaceColor = Colors.white;

  Color get _accentColor {
    final t = widget.gltype.toUpperCase();
    if (t == 'ASSET') return const Color(0xFF1976D2);
    if (t == 'LIABILITY') return const Color(0xFFE65100);
    if (t == 'EQUITY') return const Color(0xFF2E7D32);
    return _primaryBlue;
  }

  @override
  void initState() {
    super.initState();
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;
    _loadData();
  }

  // ── Data loading ─────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _loading = true);

    final data = await _api.getAccountTransactions(
      glno: widget.glno,
      fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
      toDate: DateFormat('yyyy-MM-dd').format(_toDate),
    );

    setState(() {
      _transactions = data ?? [];
      _loading = false;
    });
  }

  // ── Date range picker ─────────────────────────────────────────────────────
  Future<void> _pickDateRange() async {
    await showDialog(
      context: context,
      builder: (context) {
        DateTime localFrom = _fromDate;
        DateTime localTo = _toDate;
        return StatefulBuilder(
          builder: (ctx, setD) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: const Text('Select Date Range'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('From Date'),
                  subtitle:
                      Text(DateFormat('dd MMM yyyy').format(localFrom)),
                  trailing: const Icon(Icons.calendar_month,
                      color: Color(0xFF1967D2)),
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDate: localFrom,
                    );
                    if (p != null) setD(() => localFrom = p);
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('To Date'),
                  subtitle:
                      Text(DateFormat('dd MMM yyyy').format(localTo)),
                  trailing: const Icon(Icons.calendar_month,
                      color: Color(0xFF1967D2)),
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDate: localTo,
                    );
                    if (p != null) setD(() => localTo = p);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _fromDate = localFrom;
                    _toDate = localTo;
                  });
                  _loadData();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1967D2)),
                child: const Text('Apply',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Computed totals ───────────────────────────────────────────────────────
  double get _totalDebit => _transactions.fold(
      0,
      (s, e) =>
          s + ((e['debit'] ?? e['totaldebit'] ?? 0) as num).toDouble());

  double get _totalCredit => _transactions.fold(
      0,
      (s, e) =>
          s + ((e['credit'] ?? e['totalcredit'] ?? 0) as num).toDouble());

  double get _netBalance => _totalDebit - _totalCredit;

  // ── PDF export ────────────────────────────────────────────────────────────
  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoMedium();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final base = pw.TextStyle(font: font, fontSize: 10);
    final bold = pw.TextStyle(font: boldFont, fontSize: 10);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Account Transactions Report',
                    style: bold.copyWith(fontSize: 16)),
                pw.SizedBox(height: 4),
                pw.Text(
                    '${widget.glname} (GL: ${widget.glno}) | ${DateFormat('dd MMM yyyy').format(_fromDate)} – ${DateFormat('dd MMM yyyy').format(_toDate)}',
                    style: base.copyWith(color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.blue50),
                children: [
                  'Date',
                  'Tran ID',
                  'Narration',
                  'Debit (₹)',
                  'Credit (₹)',
                  'Balance (₹)',
                ]
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(h, style: bold),
                        ))
                    .toList(),
              ),
              ..._transactions.map((t) {
                final dr =
                    ((t['debit'] ?? t['totaldebit'] ?? 0) as num)
                        .toDouble();
                final cr =
                    ((t['credit'] ?? t['totalcredit'] ?? 0) as num)
                        .toDouble();
                return pw.TableRow(
                  children: [
                    t['trandate']?.toString() ?? '',
                    t['tranid']?.toString() ?? '',
                    t['narration']?.toString() ?? '',
                    dr > 0 ? NumberFormat('#,##0.00').format(dr) : '-',
                    cr > 0 ? NumberFormat('#,##0.00').format(cr) : '-',
                    NumberFormat('#,##0.00').format(dr - cr),
                  ]
                      .map((v) => pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(v, style: base),
                          ))
                      .toList(),
                );
              }),
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  'TOTAL',
                  '',
                  '',
                  NumberFormat('#,##0.00').format(_totalDebit),
                  NumberFormat('#,##0.00').format(_totalCredit),
                  NumberFormat('#,##0.00').format(_netBalance),
                ]
                    .map((v) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(v, style: bold),
                        ))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download',
            'Transactions_${widget.glno}_${DateFormat('yyyyMMdd').format(_fromDate)}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.sharePdf(
          bytes: bytes,
          filename:
              'Transactions_${widget.glno}.pdf');
    }
  }

  // ── Excel export ──────────────────────────────────────────────────────────
  Future<void> _exportExcel() async {
    final wb = ex.Excel.createExcel();
    final sheet = wb['Transactions'];

    sheet.appendRow([
      ex.TextCellValue('Account Transactions: ${widget.glname} (${widget.glno})')
    ]);
    sheet.appendRow([
      ex.TextCellValue(
          'Period: ${DateFormat('dd MMM yyyy').format(_fromDate)} – ${DateFormat('dd MMM yyyy').format(_toDate)}')
    ]);
    sheet.appendRow([]);

    sheet.appendRow([
      ex.TextCellValue('Date'),
      ex.TextCellValue('Tran ID'),
      ex.TextCellValue('Narration'),
      ex.TextCellValue('Debit'),
      ex.TextCellValue('Credit'),
      ex.TextCellValue('Balance'),
    ]);

    for (final t in _transactions) {
      final dr =
          ((t['debit'] ?? t['totaldebit'] ?? 0) as num).toDouble();
      final cr =
          ((t['credit'] ?? t['totalcredit'] ?? 0) as num).toDouble();
      sheet.appendRow([
        ex.TextCellValue(t['trandate']?.toString() ?? ''),
        ex.TextCellValue(t['tranid']?.toString() ?? ''),
        ex.TextCellValue(t['narration']?.toString() ?? ''),
        ex.DoubleCellValue(dr),
        ex.DoubleCellValue(cr),
        ex.DoubleCellValue(dr - cr),
      ]);
    }

    final bytes = wb.save();
    if (bytes != null && kIsWeb) {
      final blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download',
            'Transactions_${widget.glno}_${DateFormat('yyyyMMdd').format(_fromDate)}.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final rangeLabel =
        '${DateFormat('dd MMM yyyy').format(_fromDate)}  –  ${DateFormat('dd MMM yyyy').format(_toDate)}';

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Top app bar ───────────────────────────────────────────────
          _buildHeader(rangeLabel),

          // ── Summary metric cards ──────────────────────────────────────
          if (!_loading) _buildSummaryRow(),

          // ── Date picker bar ───────────────────────────────────────────
          _buildDateBar(rangeLabel),

          // ── Transaction table ─────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? _buildEmpty()
                    : _buildTable(),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(String rangeLabel) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Back arrow
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            tooltip: 'Back to Balance Sheet',
          ),
          const SizedBox(width: 8),

          // GL badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.glno,
              style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.glname,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.gltype,
                  style: TextStyle(
                      fontSize: 11,
                      color: _accentColor,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Export dropdown
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'pdf') await _exportPdf();
              if (v == 'excel') await _exportExcel();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'pdf',
                child: Row(children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Export as PDF'),
                ]),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(children: [
                  Icon(Icons.table_chart, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Text('Export as Excel'),
                ]),
              ),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(children: [
                Icon(Icons.file_download_outlined,
                    color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Export',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down,
                    color: Colors.white, size: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary cards ─────────────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          _summaryCard('Total Debit', _totalDebit, Colors.orange.shade700),
          const SizedBox(width: 10),
          _summaryCard('Total Credit', _totalCredit, Colors.green.shade700),
          const SizedBox(width: 10),
          _summaryCard('Net Balance', _netBalance.abs(),
              _netBalance >= 0 ? _primaryBlue : Colors.red.shade600,
              prefix: _netBalance < 0 ? '(CR) ' : '(DR) '),
          const SizedBox(width: 10),
          _infoCard('Transactions', _transactions.length.toString()),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double val, Color col,
      {String prefix = ''}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              '$prefix${currency.format(val)}',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: col),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ── Date filter bar ───────────────────────────────────────────────────────
  Widget _buildDateBar(String rangeLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 18, color: _primaryBlue),
                  const SizedBox(width: 8),
                  Text(rangeLabel,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Refresh button
          InkWell(
            onTap: _loadData,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.refresh,
                  size: 18, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ── Transaction data table ────────────────────────────────────────────────
  Widget _buildTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade50),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            // Column headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  _headerCell('Date', flex: 2),
                  _headerCell('Tran ID', flex: 1),
                  _headerCell('Narration', flex: 4),
                  _headerCell('Debit (₹)', flex: 2, align: TextAlign.right),
                  _headerCell('Credit (₹)', flex: 2, align: TextAlign.right),
                  _headerCell('Balance (₹)', flex: 2, align: TextAlign.right),
                ],
              ),
            ),

            // Rows
            ..._transactions.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              final dr = ((t['debit'] ?? t['totaldebit'] ?? 0) as num).toDouble();
              final cr = ((t['credit'] ?? t['totalcredit'] ?? 0) as num).toDouble();
              final net = dr - cr;
              final isEven = i % 2 == 0;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: isEven ? Colors.white : const Color(0xFFF9FBFF),
                  border: const Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    _dataCell(
                      t['trandate']?.toString() ?? '-',
                      flex: 2,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF1976D2)),
                    ),
                    _dataCell(
                      t['tranid']?.toString() ?? '-',
                      flex: 1,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    _dataCell(
                      t['narration']?.toString() ?? '-',
                      flex: 4,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                    _amountCell(dr, flex: 2, positiveColor: Colors.orange.shade700),
                    _amountCell(cr, flex: 2, positiveColor: Colors.green.shade700),
                    _amountCell(net, flex: 2,
                        positiveColor: _primaryBlue,
                        negativeColor: Colors.red.shade600,
                        bold: true),
                  ],
                ),
              );
            }),

            // Footer totals
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  _dataCell('TOTALS', flex: 7,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                  _totalCell(_totalDebit, flex: 2,
                      color: Colors.orange.shade700),
                  _totalCell(_totalCredit, flex: 2,
                      color: Colors.green.shade700),
                  _totalCell(_netBalance, flex: 2,
                      color: _netBalance >= 0 ? _primaryBlue : Colors.red.shade600),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label,
      {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey,
            fontSize: 12),
      ),
    );
  }

  Widget _dataCell(String text,
      {int flex = 1, TextStyle? style, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        overflow: TextOverflow.ellipsis,
        style: style ?? const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _amountCell(double val,
      {int flex = 1, Color? positiveColor, Color? negativeColor, bool bold = false}) {
    final isZero = val == 0;
    final color = isZero
        ? Colors.grey.shade400
        : (val < 0 ? (negativeColor ?? Colors.red) : (positiveColor ?? Colors.black87));
    return Expanded(
      flex: flex,
      child: Text(
        isZero ? '-' : currency.format(val.abs()),
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _totalCell(double val, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        currency.format(val.abs()),
        textAlign: TextAlign.right,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting the date range',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
