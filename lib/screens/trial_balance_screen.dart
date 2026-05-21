import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/report_api_service.dart';
import '../utils/responsive.dart';
import '../theme.dart';

class TrialBalanceScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const TrialBalanceScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  final ReportApiService _apiService = ReportApiService();

  bool _loading = true;

  late DateTime _startDate;
  late DateTime _endDate;

  List<Map<String, dynamic>> _reportData = [];

  double _totalDebit = 0.0;
  double _totalCredit = 0.0;

  @override
  void initState() {
    super.initState();

    _endDate = DateTime.now();
    _startDate = DateTime(_endDate.year, _endDate.month, 1);

    _loadData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    setState(() => _loading = true);

    final toDateStr = DateFormat('yyyy-MM-dd').format(_endDate);

    final data = await _apiService.getFinancialReport(
      reportType: "TB",
      date: toDateStr,
    );

    if (!mounted) return;

    setState(() {
      _reportData = data ?? [];
      _calculateTotals();
      _loading = false;
    });
  }

  // ================= CALCULATE TOTALS =================
  void _calculateTotals() {
    double dr = 0;
    double cr = 0;

    for (var acc in _reportData) {
      dr += (acc['debit'] ?? 0).toDouble();
      cr += (acc['credit'] ?? 0).toDouble();
    }

    _totalDebit = dr;
    _totalCredit = cr;
  }

  // ================= FORMAT AMOUNT =================
  String _formatAmount(double amount) {
    if (amount == 0) return '-';

    return NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  // ================= GET ACCOUNT NAME =================
  String _getAccountName(Map<String, dynamic> acc) {
    if (acc['account_name'] != null) {
      return acc['account_name'].toString();
    }

    if (acc['glname'] != null) {
      return acc['glname'].toString();
    }

    return '-';
  }

  // ================= DATE PICKER =================
  Future<void> _pickDateRange() async {
    await showDialog(
      context: context,
      builder: (context) {
        DateTime localStart = _startDate;
        DateTime localEnd = _endDate;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text("Select Financial Date Range"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Start Date"),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(localStart)),
                    trailing: const Icon(Icons.calendar_month, color: Color(0xFF1967D2)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDate: localStart,
                      );
                      if (picked != null) {
                        setStateDialog(() => localStart = picked);
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("End Date"),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(localEnd)),
                    trailing: const Icon(Icons.calendar_month, color: Color(0xFF1967D2)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDate: localEnd,
                      );
                      if (picked != null) {
                        setStateDialog(() => localEnd = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _startDate = localStart;
                      _endDate = localEnd;
                    });
                    _loadData();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1967D2)),
                  child: const Text("Apply Range", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= EXPORT PDF =================
  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    final unicodeFont = await PdfGoogleFonts.robotoMedium();

    final pw.TextStyle baseStyle = pw.TextStyle(
      font: unicodeFont,
      fontSize: 11,
    );

    final pw.TextStyle boldStyle = pw.TextStyle(
      font: unicodeFont,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );

    final String rangeStr =
        "${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "TRIAL BALANCE REPORT",
                  style: boldStyle.copyWith(fontSize: 22),
                ),
                pw.Text(
                  rangeStr,
                  style: baseStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text("ACCOUNT NAME", style: boldStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text("ACCOUNT TYPE", style: boldStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text("DEBIT", textAlign: pw.TextAlign.right, style: boldStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text("CREDIT", textAlign: pw.TextAlign.right, style: boldStyle),
                  ),
                ],
              ),
              ..._reportData.map(
                (row) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(_getAccountName(row), style: baseStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(row['account_type']?.toString() ?? '-', style: baseStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _formatAmount((row['debit'] ?? 0).toDouble()),
                        textAlign: pw.TextAlign.right,
                        style: baseStyle,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _formatAmount((row['credit'] ?? 0).toDouble()),
                        textAlign: pw.TextAlign.right,
                        style: baseStyle,
                      ),
                    ),
                  ],
                ),
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue50,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text("TOTAL", style: boldStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text("", style: boldStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_formatAmount(_totalDebit), textAlign: pw.TextAlign.right, style: boldStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_formatAmount(_totalCredit), textAlign: pw.TextAlign.right, style: boldStyle),
                  ),
                ],
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
        ..setAttribute("download", "Trial_Balance_${DateFormat('yyyyMMdd').format(_endDate)}.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: "Trial_Balance_Report.pdf");
    }
  }

  // ================= EXPORT EXCEL =================
  Future<void> _exportExcel() async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Trial Balance'];

    sheet.appendRow([
      ex.TextCellValue("ACCOUNT"),
      ex.TextCellValue("TYPE"),
      ex.TextCellValue("DEBIT"),
      ex.TextCellValue("CREDIT"),
    ]);

    for (var row in _reportData) {
      sheet.appendRow([
        ex.TextCellValue(_getAccountName(row)),
        ex.TextCellValue(row['account_type']?.toString() ?? '-'),
        ex.DoubleCellValue((row['debit'] ?? 0).toDouble()),
        ex.DoubleCellValue((row['credit'] ?? 0).toDouble()),
      ]);
    }

    sheet.appendRow([
      ex.TextCellValue("TOTAL"),
      ex.TextCellValue(""),
      ex.DoubleCellValue(_totalDebit),
      ex.DoubleCellValue(_totalCredit),
    ]);

    final bytes = excel.save();

    if (bytes != null && kIsWeb) {
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "trial_balance.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  // ================= EXPORT MENU =================
  Widget _buildExportMenu({bool isMobile = false}) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'pdf') await _exportPdf();
        if (value == 'excel') await _exportExcel();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'pdf', child: Text("Export PDF")),
        PopupMenuItem(value: 'excel', child: Text("Export Excel")),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 18,
          vertical: isMobile ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1967D2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, color: Colors.white, size: isMobile ? 18 : 20),
            const SizedBox(width: 8),
            Text("Export", style: TextStyle(color: Colors.white, fontSize: isMobile ? 13 : 14)),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final rangeStr =
        "${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}";

    // Standard widths shared between Header, Body, and Footer grid structures
    final Map<int, TableColumnWidth> tableColumnWidths = {
      0: const FlexColumnWidth(3),
      1: const FlexColumnWidth(2),
      2: const FlexColumnWidth(1.5),
      3: const FlexColumnWidth(1.5),
    };

    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // HEADER BAR
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: isMobile ? 12 : 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: widget.onBackToModule,
                            icon: const Icon(Icons.arrow_back),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Trial Balance",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDateRange,
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                rangeStr,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildExportMenu(isMobile: true),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBackToModule,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Trial Balance",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(rangeStr),
                      ),
                      const SizedBox(width: 10),
                      _buildExportMenu(isMobile: false),
                    ],
                  ),
          ),

          // FINANCIAL TABLE MAIN CONTAINER
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1100),
                margin: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: isMobile ? 12 : 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          // FIXED GRID HEADER
                          Container(
                            color: const Color(0xFFF4F7FB),
                            child: Table(
                              columnWidths: tableColumnWidths,
                              children: [
                                TableRow(
                                  children: [
                                    _buildHeaderCell(context, "ACCOUNT"),
                                    _buildHeaderCell(context, "TYPE"),
                                    _buildHeaderCell(context, "DEBIT", alignRight: true),
                                    _buildHeaderCell(context, "CREDIT", alignRight: true),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // SCROLLABLE GRID BODY
                          Expanded(
                            child: SingleChildScrollView(
                              child: Table(
                                columnWidths: tableColumnWidths,
                                border: const TableBorder(
                                  horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                                ),
                                children: _reportData.map((acc) {
                                  return TableRow(
                                    children: [
                                      _buildBodyCell(context, _getAccountName(acc)),
                                      _buildBodyCell(context, acc['account_type']?.toString() ?? '-'),
                                      _buildBodyCell(context, _formatAmount((acc['debit'] ?? 0).toDouble()), alignRight: true),
                                      _buildBodyCell(context, _formatAmount((acc['credit'] ?? 0).toDouble()), alignRight: true),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                          // FIXED GRID TOTAL FOOTER
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: AppColors.border)),
                              color: Color(0xFFF0F7FF),
                            ),
                            child: Table(
                              columnWidths: tableColumnWidths,
                              children: [
                                TableRow(
                                  children: [
                                    _buildFooterCell(context, "TOTAL"),
                                    _buildFooterCell(context, ""),
                                    _buildFooterCell(context, _formatAmount(_totalDebit), alignRight: true),
                                    _buildFooterCell(context, _formatAmount(_totalCredit), alignRight: true),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CELL BUILDERS =================
  Widget _buildHeaderCell(BuildContext context, String text, {bool alignRight = false}) {
    final isMobile = Responsive.isMobile(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 10 : 16,
        horizontal: isMobile ? 6 : 24,
      ),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: isMobile ? 10 : 13,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildBodyCell(BuildContext context, String text, {bool alignRight = false}) {
    final isMobile = Responsive.isMobile(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 10 : 16,
        horizontal: isMobile ? 6 : 24,
      ),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: isMobile ? 10 : 14,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildFooterCell(BuildContext context, String text, {bool alignRight = false}) {
    final isMobile = Responsive.isMobile(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 20,
        horizontal: isMobile ? 6 : 24,
      ),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 10 : 14,
          color: const Color(0xFF1E3A8A),
        ),
      ),
    );
  }
}