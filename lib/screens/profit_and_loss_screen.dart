import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/report_api_service.dart';

class ProfitAndLossScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const ProfitAndLossScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<ProfitAndLossScreen> createState() => _ProfitAndLossScreenState();
}

class _ProfitAndLossScreenState extends State<ProfitAndLossScreen> {
  final ReportApiService _api = ReportApiService();

  bool _loading = false;

  DateTimeRange? selectedRange;

  String selectedDate =
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  List<Map<String, dynamic>> incomeItems = [];
  List<Map<String, dynamic>> expenseItems = [];

  double totalIncome = 0;
  double totalExpense = 0;
  double netProfit = 0;

  final currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= LOAD API =================
  Future<void> _loadData() async {
    setState(() => _loading = true);

    final data = await _api.getFinancialReport(
      reportType: "PL",
      date: selectedDate,
    );

    if (data == null) {
      setState(() => _loading = false);
      return;
    }

    List<Map<String, dynamic>> income = [];
    List<Map<String, dynamic>> expense = [];

    double incomeTotal = 0;
    double expenseTotal = 0;

    for (var item in data) {
      final rawAmount = item['amount'] ?? 0;
      final amount = (rawAmount is num)
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount.toString()) ?? 0.0;

      final type = (item['gltype'] ?? '').toString().toUpperCase();

      if (type == 'INCOME') {
        income.add(item);
        incomeTotal += amount;
      } else if (type == 'EXPENSE') {
        expense.add(item);
        expenseTotal += amount;
      }
    }

    setState(() {
      incomeItems = income;
      expenseItems = expense;

      totalIncome = incomeTotal;
      totalExpense = expenseTotal;
      netProfit = incomeTotal - expenseTotal;

      _loading = false;
    });
  }

  // ================= DATE RANGE PICKER =================
  Future<void> _pickDateRange() async {
    DateTime startDate = selectedRange?.start ?? DateTime.now();
    DateTime endDate = selectedRange?.end ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text("Select Date Range"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ================= START DATE =================
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Start Date"),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy').format(startDate),
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDate: startDate,
                      );

                      if (picked != null) {
                        setStateDialog(() {
                          startDate = picked;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  // ================= END DATE =================
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("End Date"),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy').format(endDate),
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDate: endDate,
                      );

                      if (picked != null) {
                        setStateDialog(() {
                          endDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedRange = DateTimeRange(
                        start: startDate,
                        end: endDate,
                      );

                      selectedDate =
                          DateFormat('yyyy-MM-dd').format(endDate);
                    });

                    _loadData();
                    Navigator.pop(context);
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // ================= PDF EXPORT =================
  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Profit & Loss",
                  style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 10),
              pw.Text("Income: $totalIncome"),
              pw.Text("Expense: $totalExpense"),
              pw.Text("Net Profit: $netProfit"),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "PL_Report.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: "PL_Report.pdf");
    }
  }

  // ================= EXCEL EXPORT =================
  Future<void> _exportExcel() async {
    final excel = ex.Excel.createExcel();
    final sheet = excel['PL'];

    sheet.appendRow([ex.TextCellValue("Profit & Loss")]);
    sheet.appendRow([ex.TextCellValue("Income")]);

    for (var i in incomeItems) {
      sheet.appendRow([
        ex.TextCellValue(i['glname'] ?? ''),
        ex.DoubleCellValue((i['amount'] ?? 0).toDouble()),
      ]);
    }

    sheet.appendRow([
      ex.TextCellValue("Total Income"),
      ex.DoubleCellValue(totalIncome),
    ]);

    sheet.appendRow([ex.TextCellValue("Expense")]);

    for (var i in expenseItems) {
      sheet.appendRow([
        ex.TextCellValue(i['glname'] ?? ''),
        ex.DoubleCellValue((i['amount'] ?? 0).toDouble()),
      ]);
    }

    sheet.appendRow([
      ex.TextCellValue("Total Expense"),
      ex.DoubleCellValue(totalExpense),
    ]);

    sheet.appendRow([
      ex.TextCellValue("Net Profit"),
      ex.DoubleCellValue(netProfit),
    ]);

    final bytes = excel.save();

    if (bytes != null && kIsWeb) {
      final blob = html.Blob(
        [bytes],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "PL_Report.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Scaffold(
          backgroundColor: const Color(0xffF5F7FB),
          body: Column(
            children: [
              // ================= HEADER =================
              _buildHeader(isMobile),

              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // ================= TOOLBAR =================
              _buildToolbar(isMobile),

              // ================= BODY =================
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isMobile ? 12 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ================= SUMMARY CARDS =================
                                _buildSummaryCards(isMobile),

                                const SizedBox(height: 24),

                                _buildTableSection(
                                  "INCOME",
                                  incomeItems,
                                  Colors.green,
                                  Icons.trending_up,
                                  totalIncome,
                                ),

                                const SizedBox(height: 24),

                                _buildTableSection(
                                  "EXPENSES",
                                  expenseItems,
                                  Colors.red,
                                  Icons.trending_down,
                                  totalExpense,
                                ),

                                const SizedBox(height: 24),

                                // ================= NET PROFIT FOOTER =================
                                _buildNetProfitFooter(isMobile),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= HEADER WIDGET =================
  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Profit & Loss",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Financial Performance Report",
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined, size: 16),
                    label: const Text("Customize Report",
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.black, size: 20),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Profit & Loss",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Financial Performance Report",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text("Customize Report"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ],
            ),
    );
  }

  // ================= TOOLBAR WIDGET =================
  Widget _buildToolbar(bool isMobile) {
    final dateWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: _pickDateRange,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                selectedRange == null
                    ? "01 Apr 2025 - 30 Apr 2025"
                    : "${DateFormat('dd MMM yyyy').format(selectedRange!.start)} - "
                        "${DateFormat('dd MMM yyyy').format(selectedRange!.end)}",
                style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down,
                size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
    );

    final exportWidget = PopupMenuButton<String>(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1967D2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text("Export", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24, vertical: 10),
      color: Colors.white,
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dateWidget,
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: exportWidget,
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                dateWidget,
                exportWidget,
              ],
            ),
    );
  }

  // ================= SUMMARY CARDS =================
  Widget _buildSummaryCards(bool isMobile) {
    final cards = [
      _summaryCard(
        "Total Income",
        totalIncome,
        Colors.green,
        Icons.trending_up,
        100.0,
        isMobile,
      ),
      _summaryCard(
        "Total Expenses",
        totalExpense,
        Colors.red,
        Icons.trending_down,
        totalIncome > 0 ? (totalExpense / totalIncome * 100) : 0,
        isMobile,
      ),
      _summaryCard(
        "Net Profit",
        netProfit,
        Colors.blue,
        Icons.pie_chart_outline,
        totalIncome > 0 ? (netProfit / totalIncome * 100) : 0,
        isMobile,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 12),
          cards[1],
          const SizedBox(height: 12),
          cards[2],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
      ],
    );
  }

  // ================= NET PROFIT FOOTER =================
  Widget _buildNetProfitFooter(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "NET PROFIT",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            netProfit >= 0
                                ? "Your business is profitable. Keep up the good work!"
                                : "Your business is running at a loss.",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  currency.format(netProfit),
                  style: TextStyle(
                    color: netProfit >= 0 ? Colors.green : Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "NET PROFIT",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        netProfit >= 0
                            ? "Your business is profitable. Keep up the good work!"
                            : "Your business is running at a loss.",
                      ),
                    ],
                  ),
                ),
                Text(
                  currency.format(netProfit),
                  style: TextStyle(
                    color: netProfit >= 0 ? Colors.green : Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryCard(String title, double value, Color color, IconData icon,
      double percentage, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            currency.format(value),
            style: TextStyle(
                color: color,
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold),
          ),
          Text(
            "${percentage.toStringAsFixed(2)}% of Revenue",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection(String title, List<Map<String, dynamic>> items,
      Color color, IconData icon, double total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: color.withOpacity(0.05),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...items.map((e) => ListTile(
                title: Text(e['glname'] ?? '',
                    style: const TextStyle(fontSize: 14)),
                trailing: Text(
                  currency.format((e['amount'] ?? 0).toDouble()),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              )),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TOTAL $title",
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold)),
                Text(
                  currency.format(total),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}