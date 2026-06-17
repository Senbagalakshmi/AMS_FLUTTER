import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as ex;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;
import '../services/report_api_service.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../utils/responsive.dart';
import 'import_company_screen.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final VoidCallback onImport;
  final String? userName;

  const ChartOfAccountsScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    required this.onImport,
    required this.userName,
  });

  @override
  _ChartOfAccountsScreenState createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportApiService _apiService = ReportApiService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allAccounts = [];

  String _searchQuery = "";
  String _selectedCurrencyFilter = "All";
  String _selectedBalanceFilter = "All";

  final List<String> _tabs = [
    'All Accounts',
    'Asset',
    'Liability',
    'Equity',
    'Income',
    'Expense'
  ];

  TextStyle bodyStyle(
      {double size = 14,
      FontWeight weight = FontWeight.w500,
      Color color = Colors.black,
      double? height}) {
    return TextStyle(
        fontSize: size, fontWeight: weight, color: color, height: height);
  }

  TextStyle monoStyle(
      {double size = 11,
      FontWeight weight = FontWeight.w700,
      Color color = Colors.grey,
      double? letterSpacing}) {
    return TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFamily: 'monospace',
        letterSpacing: letterSpacing);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getChartOfAccounts();
    if (mounted) {
      setState(() {
        _allAccounts = data ?? [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredAccounts {
    final selectedTab = _tabs[_tabController.index];
    List<Map<String, dynamic>> list = _allAccounts;

    // 1. Tab filter (Asset, Liability, etc.)
    if (selectedTab != 'All Accounts') {
      list = list.where((acc) {
        final type = acc['accountType']?.toString().toLowerCase() ?? '';
        return type.contains(selectedTab.toLowerCase());
      }).toList();
    }

    // 2. Search query filter (matches name, number, or type)
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((acc) {
        final name = acc['accountName']?.toString().toLowerCase() ?? '';
        final number = acc['accountNumber']?.toString().toLowerCase() ?? '';
        final type = acc['accountType']?.toString().toLowerCase() ?? '';
        return name.contains(query) ||
            number.contains(query) ||
            type.contains(query);
      }).toList();
    }

    // 3. Currency filter
    if (_selectedCurrencyFilter != "All") {
      list = list.where((acc) {
        final curr = acc['currency']?.toString() ?? 'INR';
        return curr.toLowerCase() == _selectedCurrencyFilter.toLowerCase();
      }).toList();
    }

    // 5. Balance filter
    if (_selectedBalanceFilter != "All") {
      list = list.where((acc) {
        final balance = (acc['balance'] as num?)?.toDouble() ?? 0.0;
        if (_selectedBalanceFilter == "Non-Zero") {
          return balance != 0.0;
        } else if (_selectedBalanceFilter == "Positive") {
          return balance > 0.0;
        } else if (_selectedBalanceFilter == "Negative") {
          return balance < 0.0;
        }
        return true;
      }).toList();
    }

    return list;
  }

  Map<String, dynamic> _getAccountTypeTheme(String accountType) {
    final type = accountType.toLowerCase();
    if (type.contains('asset')) {
      return {
        'bg': AppColors.tBlueLt,
        'border': const Color(0xFFC5CAE9),
        'text': AppColors.tBlue,
        'icon': Icons.account_balance_wallet_rounded,
      };
    } else if (type.contains('liability')) {
      return {
        'bg': AppColors.amberLt,
        'border': const Color(0xFFFDE68A),
        'text': AppColors.amber,
        'icon': Icons.credit_card_rounded,
      };
    } else if (type.contains('equity')) {
      return {
        'bg': AppColors.purpleLt,
        'border': const Color(0xFFE9D5FF),
        'text': AppColors.purple,
        'icon': Icons.pie_chart_outline_rounded,
      };
    } else if (type.contains('income') || type.contains('revenue')) {
      return {
        'bg': AppColors.greenLt,
        'border': const Color(0xFFBBF7D0),
        'text': AppColors.green,
        'icon': Icons.trending_up_rounded,
      };
    } else if (type.contains('expense')) {
      return {
        'bg': AppColors.redLt,
        'border': const Color(0xFFFECDD3),
        'text': AppColors.red,
        'icon': Icons.trending_down_rounded,
      };
    } else {
      return {
        'bg': AppColors.grayLt,
        'border': AppColors.border,
        'text': AppColors.ink2,
        'icon': Icons.account_balance_rounded,
      };
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
    final unicodeFont = await PdfGoogleFonts.robotoMedium();
    final pw.TextStyle baseStyle =
        pw.TextStyle(font: unicodeFont, fontSize: 11);
    final pw.TextStyle boldStyle =
        baseStyle.copyWith(fontWeight: pw.FontWeight.bold);

    final tableHeaders = [
      'Account / Parent Account',
      'Account Number',
      'Account Type',
      'Balance'
    ];
    final tableRows = _filteredAccounts.map((acc) {
      final balance = (acc['balance'] as num?)?.toDouble() ?? 0.0;
      final currency = acc['currency']?.toString() ?? 'INR';
      return [
        acc['accountName']?.toString() ?? '',
        acc['accountNumber']?.toString() ?? '—',
        acc['accountType']?.toString() ?? '',
        '${NumberFormat.currency(symbol: 'Rs.', decimalDigits: 2, customPattern: '\u00A4#,##0.00').format(balance.abs())} $currency',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Chart of Accounts',
                  style: boldStyle.copyWith(fontSize: 18)),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Exported list of chart of accounts records.',
                style: baseStyle),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: tableHeaders,
              data: tableRows,
              headerStyle: boldStyle,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: baseStyle,
              cellPadding:
                  const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
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
        ..setAttribute('download', 'Chart_of_Accounts.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    }

    await Printing.sharePdf(bytes: bytes, filename: 'Chart_of_Accounts.pdf');
  }

  Future<void> _exportExcel() async {
    final workbook = ex.Excel.createExcel();
    final sheet = workbook['Chart of Accounts'];

    sheet.appendRow([
      ex.TextCellValue('Account / Parent Account'),
      ex.TextCellValue('Account Number'),
      ex.TextCellValue('Account Type'),
      ex.TextCellValue('Balance'),
    ]);

    for (final acc in _filteredAccounts) {
      final balance = (acc['balance'] as num?)?.toDouble() ?? 0.0;
      final currency = acc['currency']?.toString() ?? 'INR';
      sheet.appendRow([
        ex.TextCellValue(acc['accountName']?.toString() ?? ''),
        ex.TextCellValue(acc['accountNumber']?.toString() ?? ''),
        ex.TextCellValue(acc['accountType']?.toString() ?? ''),
        ex.TextCellValue(
            '${NumberFormat.currency(symbol: 'Rs.', decimalDigits: 2, customPattern: '\u00A4#,##0.00').format(balance.abs())} $currency'),
      ]);
    }

    final bytes = workbook.save();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate Excel file.')),
      );
      return;
    }

    if (kIsWeb) {
      final blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'Chart_of_Accounts.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Excel export is currently supported only on web.')),
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
                offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: const Icon(Icons.more_vert, color: AppColors.tBlue, size: 22),
      ),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'sort') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sort by feature coming soon')),
          );
        } else if (value == 'import') {
          _handleImport();
        } else if (value == 'export_excel') {
          _handleExport('Excel');
        } else if (value == 'export_pdf') {
          _handleExport('PDF');
        }
      },
      itemBuilder: (BuildContext context) => [
        // PopupMenuItem<String>(
        //   value: 'sort',
        //   child: Row(
        //     children: const [
        //       Icon(Icons.sort, size: 18, color: AppColors.tBlue),
        //       SizedBox(width: 12),
        //       Expanded(child: Text('Sort by')),
        //       Icon(Icons.arrow_right, size: 20, color: Colors.grey),
        //     ],
        //   ),
        // ),
        // const PopupMenuDivider(height: 6),
        PopupMenuItem<String>(
          value: 'import',
          child: Row(
            children: const [
              Icon(Icons.download_rounded, size: 18, color: AppColors.tBlue),
              SizedBox(width: 12),
              Text('Import Chart of Accounts'),
            ],
          ),
        ),
        const PopupMenuDivider(height: 6),
        const PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'Export',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        PopupMenuItem<String>(
          value: 'export_excel',
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Row(
              children: const [
                Icon(Icons.table_chart, size: 18, color: AppColors.tBlue),
                SizedBox(width: 12),
                Expanded(child: Text('Export Chart of Accounts as Excel')),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'export_pdf',
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Row(
              children: const [
                Icon(Icons.picture_as_pdf, size: 18, color: AppColors.tBlue),
                SizedBox(width: 12),
                Expanded(child: Text('Export Chart of Accounts as PDF')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filter Accounts",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B1628)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close,
                              size: 20, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      "Currency",
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCurrencyFilter,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      items: ["All", "INR", "USD", "EUR"]
                          .map((curr) =>
                              DropdownMenuItem(value: curr, child: Text(curr)))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          _selectedCurrencyFilter = val ?? "All";
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Balance Status",
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedBalanceFilter,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      items: ["All", "Non-Zero", "Positive", "Negative"]
                          .map((bal) =>
                              DropdownMenuItem(value: bal, child: Text(bal)))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          _selectedBalanceFilter = val ?? "All";
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCurrencyFilter = "All";
                                _selectedBalanceFilter = "All";
                              });
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: const Text("Reset All",
                                style: TextStyle(color: Color(0xFF475569))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Trigger main screen update
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text("Apply"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6), // tBlueLt style
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC5CAE9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tBlue)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            child: const Icon(Icons.cancel, size: 14, color: AppColors.tBlue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.list_alt_rounded,
                size: 28, color: AppColors.tBlue),
            title: 'Chart of Accounts',
            subtitle:
                'View your organized listing of all accounts in the general ledger.',
            badges: const [],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            onBack: widget.onBackToModule,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(
                  label: 'Transactions', onTap: widget.onBackToModule),
              HeaderBreadcrumb(label: 'Reports'),
              HeaderBreadcrumb(label: 'Chart of Accounts'),
            ],
            actions: [
              _buildImportExportMenu(),
            ],
          ),

          // Tabs Section
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.tBlue,
                unselectedLabelColor: const Color(0xFF64748B),
                indicator: BoxDecoration(
                  color: AppColors.tBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30),
                ),
                splashBorderRadius: BorderRadius.circular(30),
                labelStyle: bodyStyle(size: 14, weight: FontWeight.w700),
                unselectedLabelStyle:
                    bodyStyle(size: 14, weight: FontWeight.w600),
                tabs: _tabs
                    .map((t) => Tab(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18.0),
                            child: Text(t),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          // Data Table Container
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    margin: EdgeInsets.all(isMobile ? 12 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dynamic Title & Filter Button + Search
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      _tabs[_tabController.index].toUpperCase(),
                                      style: bodyStyle(
                                        size: 15,
                                        weight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 38,
                                            child: TextField(
                                              onChanged: (val) {
                                                setState(() {
                                                  _searchQuery = val;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText: "Search...",
                                                hintStyle: const TextStyle(
                                                    color: Color(0xFF94A3B8), fontSize: 13),
                                                prefixIcon: const Icon(Icons.search_rounded,
                                                    color: Color(0xFF64748B), size: 16),
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 10),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(
                                                      color: Color(0xFFCBD5E1)),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(
                                                      color: Color(0xFFE2E8F0)),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(
                                                      color: AppColors.tBlue),
                                                ),
                                              ),
                                              style: const TextStyle(fontSize: 13.5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        AmsButton(
                                          label: 'Filters',
                                          icon: Icons.filter_list_rounded,
                                          variant: AmsButtonVariant.outline,
                                          onPressed: _showFiltersDialog,
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Text(
                                      _tabs[_tabController.index].toUpperCase(),
                                      style: bodyStyle(
                                        size: 15,
                                        weight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Clean Search Input Field
                                    SizedBox(
                                      width: 240,
                                      height: 38,
                                      child: TextField(
                                        onChanged: (val) {
                                          setState(() {
                                            _searchQuery = val;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: "Search name or number...",
                                          hintStyle: const TextStyle(
                                              color: Color(0xFF94A3B8), fontSize: 13),
                                          prefixIcon: const Icon(Icons.search_rounded,
                                              color: Color(0xFF64748B), size: 16),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFCBD5E1)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: AppColors.tBlue),
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 13.5),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Filters Button
                                    AmsButton(
                                      label: 'Filters',
                                      icon: Icons.filter_list_rounded,
                                      variant: AmsButtonVariant.outline,
                                      onPressed: _showFiltersDialog,
                                    ),
                                  ],
                                ),
                        ),

                        // Active Filters Row
                        if (_selectedCurrencyFilter != "All" ||
                            _selectedBalanceFilter != "All" ||
                            _searchQuery.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              border: Border(
                                  bottom: BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  "Active Filters: ",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  _buildFilterChip("Search: '$_searchQuery'",
                                      () {
                                    setState(() {
                                      _searchQuery = "";
                                    });
                                  }),
                                if (_selectedCurrencyFilter != "All")
                                  _buildFilterChip(
                                      "Currency: $_selectedCurrencyFilter", () {
                                    setState(() {
                                      _selectedCurrencyFilter = "All";
                                    });
                                  }),
                                if (_selectedBalanceFilter != "All")
                                  _buildFilterChip(
                                      "Balance: $_selectedBalanceFilter", () {
                                    setState(() {
                                      _selectedBalanceFilter = "All";
                                    });
                                  }),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = "";
                                      _selectedCurrencyFilter = "All";
                                      _selectedBalanceFilter = "All";
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    "Clear All",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC9253A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Table Column Headers
                        if (!isMobile)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14.0, horizontal: 24),
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Color(0xFFE2E8F0))),
                              color: Color(0xFFF8FAFC),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 4,
                                    child: _buildColHeader(
                                        'ACCOUNT / PARENT ACCOUNT')),
                                Expanded(
                                    flex: 2,
                                    child: _buildColHeader('ACCOUNT NUMBER')),
                                Expanded(
                                    flex: 3,
                                    child: _buildColHeader(
                                        'ACCOUNT TYPE / SUB TYPE')),
                                Expanded(
                                    flex: 2,
                                    child: _buildColHeader('BALANCE',
                                        alignRight: true)),
                              ],
                            ),
                          ),

                        // Data Content List
                        Expanded(
                          child: _filteredAccounts.isEmpty
                              ? Center(
                                  child: Text(
                                    'No accounts found in this category.',
                                    style: bodyStyle(
                                        color: Colors.grey[500]!, size: 14),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: _filteredAccounts.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                          height: 1, color: Color(0xFFF1F5F9)),
                                  itemBuilder: (context, index) {
                                    return _buildAccountRow(
                                        _filteredAccounts[index]);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildColHeader(String title, {bool alignRight = false}) {
    return Text(
      title,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: monoStyle(
        size: 11,
        weight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAccountRow(Map<String, dynamic> acc) {
    final isMobile = Responsive.isMobile(context);
    final formatCurrency = NumberFormat.currency(
        symbol: 'Rs.', decimalDigits: 2, customPattern: '\u00A4#,##0.00');
    final balance = (acc['balance'] as num?)?.toDouble() ?? 0.0;
    final currency = acc['currency'] ?? 'INR';
    final isNegative = balance < 0;

    final String typeStr = acc['accountType']?.toString() ?? '';
    final theme = _getAccountTypeTheme(typeStr);

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme['bg'] as Color,
                          border: Border.all(
                              color: theme['border'] as Color, width: 1.0),
                        ),
                        child: Center(
                          child: Icon(
                            theme['icon'] as IconData,
                            size: 14,
                            color: theme['text'] as Color,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          acc['accountName']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle(
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${formatCurrency.format(balance.abs())} $currency',
                  style: bodyStyle(
                    size: 14.5,
                    weight: FontWeight.w700,
                    color: isNegative ? AppColors.red : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    acc['accountNumber']?.toString() ?? '—',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Text(
                  acc['accountType']?.toString() ?? '',
                  style: bodyStyle(
                    size: 12,
                    weight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Column 1: Account Name
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme['bg'] as Color,
                      border: Border.all(
                          color: theme['border'] as Color, width: 1.0),
                    ),
                    child: Center(
                      child: Icon(
                        theme['icon'] as IconData,
                        size: 16,
                        color: theme['text'] as Color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      acc['accountName']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle(
                        size: 14.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Column 2: Account Number
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    acc['accountNumber']?.toString() ?? '—',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),

            // Column 3: Account Type
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    acc['accountType']?.toString() ?? '',
                    style: bodyStyle(
                      size: 14,
                      weight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Standard Account',
                    style: bodyStyle(
                      size: 12,
                      weight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Column 4: Balance
            Expanded(
              flex: 2,
              child: Text(
                '${formatCurrency.format(balance.abs())} $currency',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle(
                  size: 14.5,
                  weight: FontWeight.w700,
                  color: isNegative ? AppColors.red : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
