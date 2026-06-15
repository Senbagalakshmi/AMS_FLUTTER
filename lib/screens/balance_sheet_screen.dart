import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/report_api_service.dart';
import 'account_transactions_screen.dart';

class BalanceSheetScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const BalanceSheetScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  final ReportApiService _api = ReportApiService();

  bool _loading = false;

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  List<Map<String, dynamic>> assetItems = [];
  List<Map<String, dynamic>> liabilityItems = [];
  List<Map<String, dynamic>> equityItems = [];

  double totalAssets = 0;
  double totalLiabilities = 0;
  double totalEquity = 0;

  final currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  // ================= THEME DESIGN COLORS =================
  static const bg = Color(0xFFF5F9FF);
  static const primaryBlue = Color(0xFF1976D2);
  static const lightBlue = Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    setState(() => _loading = true);

    final data = await _api.getFinancialReport(
      reportType: "BS",
      date: DateFormat('yyyy-MM-dd').format(_endDate),
    );

    if (data == null) {
      setState(() => _loading = false);
      return;
    }

    List<Map<String, dynamic>> a = [];
    List<Map<String, dynamic>> l = [];
    List<Map<String, dynamic>> e = [];

    double ta = 0, tl = 0, te = 0;

    for (var item in data) {
      final amount = (item['amount'] ?? 0) is num
          ? (item['amount'] ?? 0).toDouble()
          : double.tryParse(item['amount'].toString()) ?? 0;

      final type = (item['gltype'] ?? '').toString().toUpperCase();

      if (type == 'ASSET') {
        a.add(item);
        ta += amount;
      } else if (type == 'LIABILITY') {
        l.add(item);
        tl += amount;
      } else if (type == 'EQUITY') {
        e.add(item);
        te += amount;
      }
    }

    setState(() {
      assetItems = a;
      liabilityItems = l;
      equityItems = e;

      totalAssets = ta;
      totalLiabilities = tl;
      totalEquity = te;

      _loading = false;
    });
  }

  // ================= CUSTOM DIALOG DATE RANGE PICKER =================
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

  // ================= EXPORT BEAUTIFIED UNICODE PDF =================
  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    // Fetch Roboto font from printing framework to enable proper "₹" Unicode symbol support
    final unicodeFont = await PdfGoogleFonts.robotoMedium();
    final pw.TextStyle baseStyle = pw.TextStyle(font: unicodeFont, fontSize: 11);
    final pw.TextStyle boldStyle = baseStyle.copyWith(fontWeight: pw.FontWeight.bold);

    final String rangeStr = "${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("BALANCE SHEET STATEMENT", style: boldStyle.copyWith(fontSize: 20)),
                  pw.Text(rangeStr, style: baseStyle.copyWith(fontSize: 11, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ASSETS BLOCK
            pw.Text("ASSETS", style: boldStyle.copyWith(fontSize: 14, color: PdfColors.blue800)),
            pw.Divider(color: PdfColors.blue200, thickness: 1),
            pw.SizedBox(height: 5),
            ...assetItems.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(item['glname'] ?? '', style: baseStyle),
                  pw.Text(currency.format((item['amount'] ?? 0).toDouble()), style: baseStyle),
                ],
              ),
            )),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("TOTAL ASSETS", style: boldStyle),
                pw.Text(currency.format(totalAssets), style: boldStyle.copyWith(color: PdfColors.blue800)),
              ],
            ),
            pw.SizedBox(height: 24),

            // LIABILITIES BLOCK
            pw.Text("LIABILITIES", style: boldStyle.copyWith(fontSize: 14, color: PdfColors.amber900)),
            pw.Divider(color: PdfColors.amber200, thickness: 1),
            pw.SizedBox(height: 5),
            ...liabilityItems.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(item['glname'] ?? '', style: baseStyle),
                  pw.Text(currency.format((item['amount'] ?? 0).toDouble()), style: baseStyle),
                ],
              ),
            )),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("TOTAL LIABILITIES", style: boldStyle),
                pw.Text(currency.format(totalLiabilities), style: boldStyle.copyWith(color: PdfColors.amber900)),
              ],
            ),
            pw.SizedBox(height: 24),

            // EQUITY BLOCK
            pw.Text("EQUITY", style: boldStyle.copyWith(fontSize: 14, color: PdfColors.green800)),
            pw.Divider(color: PdfColors.green200, thickness: 1),
            pw.SizedBox(height: 5),
            ...equityItems.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(item['glname'] ?? '', style: baseStyle),
                  pw.Text(currency.format((item['amount'] ?? 0).toDouble()), style: baseStyle),
                ],
              ),
            )),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("TOTAL EQUITY", style: boldStyle),
                pw.Text(currency.format(totalEquity), style: boldStyle.copyWith(color: PdfColors.green800)),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey400, thickness: 1.5),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.grey100,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL LIABILITIES & EQUITY", style: boldStyle.copyWith(fontSize: 13)),
                  pw.Text(currency.format(totalLiabilities + totalEquity), style: boldStyle.copyWith(fontSize: 13, color: PdfColors.blueGrey900)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "Balance_Sheet_Report.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: "BalanceSheet.pdf");
    }
  }

  // ================= EXCEL EXPORT ENGINE =================
  Future<void> _exportExcel() async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['Balance Sheet'];
    final rangeStr = "${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}";

    sheet.appendRow([ex.TextCellValue("BALANCE SHEET REPORT")]);
    sheet.appendRow([ex.TextCellValue("Date Range: $rangeStr")]);
    sheet.appendRow([]);

    sheet.appendRow([ex.TextCellValue("ASSETS Particulars"), ex.TextCellValue("Amount")]);
    for (var i in assetItems) {
      sheet.appendRow([ex.TextCellValue(i['glname'] ?? ''), ex.DoubleCellValue((i['amount'] ?? 0).toDouble())]);
    }
    sheet.appendRow([ex.TextCellValue("TOTAL ASSETS"), ex.DoubleCellValue(totalAssets)]);
    sheet.appendRow([]);

    sheet.appendRow([ex.TextCellValue("LIABILITIES Particulars"), ex.TextCellValue("Amount")]);
    for (var i in liabilityItems) {
      sheet.appendRow([ex.TextCellValue(i['glname'] ?? ''), ex.DoubleCellValue((i['amount'] ?? 0).toDouble())]);
    }
    sheet.appendRow([ex.TextCellValue("TOTAL LIABILITIES"), ex.DoubleCellValue(totalLiabilities)]);
    sheet.appendRow([]);

    sheet.appendRow([ex.TextCellValue("EQUITY Particulars"), ex.TextCellValue("Amount")]);
    for (var i in equityItems) {
      sheet.appendRow([ex.TextCellValue(i['glname'] ?? ''), ex.DoubleCellValue((i['amount'] ?? 0).toDouble())]);
    }
    sheet.appendRow([ex.TextCellValue("TOTAL EQUITY"), ex.DoubleCellValue(totalEquity)]);

    final bytes = excel.save();

    if (bytes != null && kIsWeb) {
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "BalanceSheet.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  // ================= RENDERING APP WINDOW CANVAS =================
  @override
  Widget build(BuildContext context) {
    final range = "${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}";

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // APP BAR WITH BACK ARROW ACTION
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBackToModule,
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Balance Sheet",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),

                // UNIFIED DROPDOWN EXPORT BUTTON
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'pdf') await _exportPdf();
                    if (value == 'excel') await _exportExcel();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text("Export as PDF"),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'excel',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text("Export as Excel"),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1967D2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.file_download_outlined, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text("Export", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // DATE SELECTION BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, size: 18, color: primaryBlue),
                        const SizedBox(width: 8),
                        Text(range),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BODY BODY CONTENT
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          children: [
                            // 3 CONTAINER SUB-HEADER METRIC CARDS
                            _buildTopSummaryCards(),
                            const SizedBox(height: 24),

                            // DYNAMIC TABLES
                            _buildTable("ASSETS", assetItems, totalAssets, Colors.blue, "ASSET"),
                            const SizedBox(height: 16),
                            _buildTable("LIABILITIES", liabilityItems, totalLiabilities, Colors.orange, "LIABILITY"),
                            const SizedBox(height: 16),
                            _buildTable("EQUITY", equityItems, totalEquity, Colors.green, "EQUITY"),
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

  // ================= METHOD FOR SUMMARY METRIC CARDS =================
  Widget _buildTopSummaryCards() {
    return Row(
      children: [
        Expanded(child: _metricCard("Total Assets", totalAssets, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _metricCard("Total Liabilities", totalLiabilities, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _metricCard("Total Equity", totalEquity, Colors.green)),
      ],
    );
  }

  Widget _metricCard(String label, double val, Color col) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            currency.format(val),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: col),
          ),
        ],
      ),
    );
  }

  // ================= INDIVIDUAL DATA GRID TABLE BUILDER =================
  // Navigate to account transaction drill-down
  void _openAccountTransactions(Map<String, dynamic> item, String gltype) {
    final glno = (item['glno'] ?? item['accountNumber'] ?? '').toString();
    final glname = (item['glname'] ?? item['accountName'] ?? '').toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountTransactionsScreen(
          glno: glno,
          glname: glname,
          gltype: gltype,
          fromDate: _startDate,
          toDate: _endDate,
        ),
      ),
    );
  }

  Widget _buildTable(String title, List<Map<String, dynamic>> items, double total, Color color, String gltype) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Column(
        children: [
          // MAIN CONTAINER HEADER SECTION BAR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),

          // SUB FIELD COLUMN LABELS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade50,
            child: const Row(
              children: [
                Expanded(child: Text("Particulars", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
                Text("Amount", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              ],
            ),
          ),

          // LIST ITEMS
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("- No Records Found -", style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            ...items.map((e) {
              final amt = (e['amount'] ?? 0).toDouble();
              return InkWell(
                onTap: () => _openAccountTransactions(e, gltype),
                hoverColor: color.withOpacity(0.04),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      // Clickable GL name — underlined to hint interactivity
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                e['glname'] ?? '',
                                style: TextStyle(
                                  color: color.withOpacity(0.85),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: color.withOpacity(0.4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.open_in_new, size: 13, color: color.withOpacity(0.5)),
                          ],
                        ),
                      ),
                      // Clickable amount
                      Text(
                        currency.format(amt),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color.withOpacity(0.9),
                          decoration: TextDecoration.underline,
                          decorationColor: color.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          // ACCUMULATIVE TOTAL BOTTOM BAR
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "TOTAL $title",
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                Text(
                  currency.format(total),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}