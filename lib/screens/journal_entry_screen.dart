import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/gl_api_service.dart';
import '../services/org_api_service.dart';
import '../services/branch_api_service.dart';
import '../services/journal_api_service.dart';

class JournalEntryScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const JournalEntryScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _dateController = TextEditingController(text: _formatDate(DateTime.now()));
  final _journalNoController = TextEditingController(text: 'Auto Generated');
  final _orgCodeController = TextEditingController(text: '50');
  final _branchCodeController = TextEditingController(text: '1001');
  final _descriptionController = TextEditingController();
  final _currencyController = TextEditingController(text: 'INR - Indian Rupee');
  final _referenceController = TextEditingController();

  final List<JournalRow> _rows = [
    JournalRow(),
  ];

  final GLApiService _glApiService = GLApiService();
  final OrgApiService _orgApiService = OrgApiService();
  final BranchApiService _branchApiService = BranchApiService();
  final JournalApiService _journalApiService = JournalApiService();

  List<Map<String, dynamic>> _accounts = [];
  List<String> _accountOptions = [];
  bool _isLoadingAccounts = true;

  List<Map<String, dynamic>> _orgList = [];
  bool _isLoadingOrgs = false;
  int? _selectedOrgCode = 50;
  final _orgSearchCtrl = TextEditingController();

  List<Map<String, dynamic>> _branchList = [];
  bool _isLoadingBranches = false;
  int? _selectedBranchCode = 1001;

  List<Map<String, dynamic>> get _filteredBranches {
    if (_selectedOrgCode == null) return _branchList;
    return _branchList.where((b) {
      final bOrg = (b['orgCode'] ?? b['orgcode'] ?? b['ORGCODE'] ?? b['org_code'] ?? '').toString().trim();
      final selOrg = _selectedOrgCode?.toString().trim() ?? '';
      return bOrg == selOrg && bOrg.isNotEmpty;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _fetchOrgs();
    _fetchBranches();
  }

  Future<void> _fetchOrgs() async {
    setState(() => _isLoadingOrgs = true);
    try {
      final res = await _orgApiService.getAllOrganisations(size: 200);
      if (res != null && mounted) {
        setState(() {
          _orgList = res.items;
          _isLoadingOrgs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOrgs = false);
    }
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final res = await _branchApiService.getBranches(size: 1000);
      if (res != null && mounted) {
        setState(() {
          _branchList = res.items;
          _isLoadingBranches = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  Future<void> _fetchAccounts() async {
    try {
      final list = await _glApiService.getGlList();
      if (mounted) {
        setState(() {
          _accounts = list ?? [];
          _accountOptions = _accounts
              .where((e) => e['glNo'] != null)
              .map((e) => "${e['glNo']} - ${e['glName'] ?? ''}")
              .toList();
          _isLoadingAccounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
          _accountOptions = [];
        });
      }
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.tBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = _formatDate(picked);
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _journalNoController.dispose();
    _orgCodeController.dispose();
    _branchCodeController.dispose();
    _orgSearchCtrl.dispose();
    _descriptionController.dispose();
    _currencyController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(JournalRow());
    });
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() {
        _rows.removeAt(index);
      });
    }
  }

  double get _totalDebit => _rows.fold(0, (sum, row) => sum + row.debit);
  double get _totalCredit => _rows.fold(0, (sum, row) => sum + row.credit);

  Future<void> _submitJournal() async {
    // Basic Validation
    if (_orgCodeController.text.isEmpty || _branchCodeController.text.isEmpty) {
      showAmsSnack(context, 'Please select Organization and Branch', type: 'e');
      return;
    }

    if (_rows.isEmpty || _rows.any((r) => r.accountNo.isEmpty)) {
      showAmsSnack(context, 'Please add account numbers for all rows', type: 'e');
      return;
    }

    if (_totalDebit != _totalCredit) {
      showAmsSnack(context, 'Total Debit must equal Total Credit', type: 'e');
      return;
    }

    if (_totalDebit <= 0) {
      showAmsSnack(context, 'Journal amount must be greater than zero', type: 'e');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final header = {
        'orgcode': int.tryParse(_orgCodeController.text),
        'brncd': int.tryParse(_branchCodeController.text),
        'trandate': DateFormat('dd/MM/yyyy').parse(_dateController.text).toIso8601String(),
        'tranid': 0, // Backend will generate
        'narr': _descriptionController.text,
        'basecurr': _currencyController.text.split(' - ').first,
        'transtatus': 'P',
      };

      final details = _rows.map((r) => {
        'acnum': int.tryParse(r.accountNo.replaceAll(RegExp(r'[^0-9]'), '')),
        'trandbamt': r.debit,
        'trancramt': r.credit,
        'extrefno': _referenceController.text,
      }).toList();

      final payload = {
        'header': header,
        'details': details,
      };

      final success = await _journalApiService.saveJournal(payload);
      
      if (mounted) {
        Navigator.pop(context); // Remove loading
        if (success) {
          showAmsSnack(context, 'Journal Saved Successfully', type: 's');
          widget.onBack(); // Go back to list
        } else {
          showAmsSnack(context, 'Failed to save Journal', type: 'e');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading
        showAmsSnack(context, 'Error: $e', type: 'e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.description_rounded, size: 28, color: AppColors.tBlue),
            title: 'Journals',
            subtitle: 'Create and manage ledger journal entries',
            badges: const [],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            onBack: widget.onBackToModule,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(label: 'GL Module', onTap: widget.onBackToModule),
              HeaderBreadcrumb(label: 'Journals'),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Screen Title Bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A69BD), // Replicating the blue from image
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Text(
                        'New Journal Entry',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Org and Branch Code
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AmsField(
                                  label: 'Organization Code',
                                  tooltip: 'Select your organization',
                                  child: _isLoadingOrgs
                                      ? const LinearProgressIndicator()
                                      : AmsSearchableDropdown(
                                          items: _orgList.map((o) {
                                            final code = (o['orgcode'] ?? o['orgCode'] ?? '').toString();
                                            final name = (o['name'] ?? '').toString();
                                            return name.isNotEmpty ? '$code – $name' : code;
                                          }).toList(),
                                          placeholder: 'Select Organization',
                                          initialValue: () {
                                            if (_selectedOrgCode == null) return null;
                                            final match = _orgList.firstWhere(
                                              (o) => (o['orgcode'] ?? o['orgCode'] ?? '').toString() == _selectedOrgCode.toString(),
                                              orElse: () => {},
                                            );
                                            if (match.isEmpty) return _selectedOrgCode.toString();
                                            final code = _selectedOrgCode.toString();
                                            final name = (match['name'] ?? '').toString();
                                            return name.isNotEmpty ? '$code – $name' : code;
                                          }(),
                                          onChanged: (v) {
                                            if (v == null) return;
                                            final codeStr = v.contains(' – ') ? v.split(' – ').first : v;
                                            setState(() {
                                              _selectedOrgCode = int.tryParse(codeStr);
                                              _orgCodeController.text = codeStr;
                                              // Reset branch when org changes
                                              _selectedBranchCode = null;
                                              _branchCodeController.text = '';
                                            });
                                          },
                                        ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: AmsField(
                                  label: 'Branch Code',
                                  tooltip: 'Select your branch',
                                  child: _isLoadingBranches
                                      ? const LinearProgressIndicator()
                                      : AmsDropdown(
                                          key: ValueKey('branch_dropdown_$_selectedOrgCode'),
                                          items: _filteredBranches.map((b) {
                                            final code = (b['brnCd'] ?? b['brncd'] ?? b['branchCd'] ?? b['branchcd'] ?? b['BRNCD'] ?? b['BRANCHCD'] ?? '').toString();
                                            final name = (b['brnName'] ?? b['brnname'] ?? b['branchName'] ?? b['branchname'] ?? b['BRNNAME'] ?? b['BRANCHNAME'] ?? '').toString();
                                            return name.isNotEmpty ? '$code – $name' : code;
                                          }).toList(),
                                          placeholder: 'Select Branch',
                                          initialValue: () {
                                            if (_selectedBranchCode == null) return null;
                                            final match = _filteredBranches.firstWhere(
                                              (b) => (b['brnCd'] ?? b['brncd'] ?? b['branchCd'] ?? b['branchcd'] ?? b['BRNCD'] ?? b['BRANCHCD'] ?? '').toString() == _selectedBranchCode.toString(),
                                              orElse: () => {},
                                            );
                                            if (match.isEmpty) return null;
                                            final code = _selectedBranchCode.toString();
                                            final name = (match['brnName'] ?? match['brnname'] ?? match['branchName'] ?? match['branchname'] ?? match['BRNNAME'] ?? match['BRANCHNAME'] ?? '').toString();
                                            return name.isNotEmpty ? '$code – $name' : code;
                                          }(),
                                          onChanged: (v) {
                                            if (v == null) return;
                                            final codeStr = v.contains(' – ') ? v.split(' – ').first : v;
                                            setState(() {
                                              _selectedBranchCode = int.tryParse(codeStr);
                                              _branchCodeController.text = codeStr;
                                            });
                                          },
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Header Fields
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AmsField(
                                  label: 'Date',
                                  tooltip: 'Transaction posting date',
                                  child: GestureDetector(
                                    onTap: _selectDate,
                                    child: AbsorbPointer(
                                      child: AmsTextInput(
                                        controller: _dateController,
                                        readOnly: true,
                                        icon: Icons.calendar_today_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: AmsField(
                                  label: 'Journal No',
                                  tooltip: 'System generated unique journal number',
                                  child: AmsTextInput(
                                    controller: _journalNoController,
                                    readOnly: true,
                                    placeholder: 'Auto Generated',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AmsField(
                            label: 'Journal Description',
                            tooltip: 'Narrative describing the purpose of this entry',
                            child: AmsTextInput(
                              controller: _descriptionController,
                              maxLines: 2,
                              placeholder: 'Enter journal description...',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AmsField(
                                  label: 'Currency',
                                  tooltip: 'Default currency of the organization',
                                  child: AmsTextInput(
                                    controller: _currencyController,
                                    placeholder: 'Load default currency of the organization',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: AmsField(
                                  label: 'Reference No (Optional)',
                                  tooltip: 'External reference or document number',
                                  child: AmsTextInput(
                                    controller: _referenceController,
                                    placeholder: 'Enter reference number',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Table Header
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B5998), // Slightly darker blue
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: const Row(
                              children: [
                                Expanded(flex: 2, child: Text('Account No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                SizedBox(width: 24), // Added space
                                Expanded(flex: 1, child: Text('Debit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text('Credit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                Expanded(flex: 4, child: Text('Remarks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                SizedBox(width: 40), // Space for action button
                              ],
                            ),
                          ),

                          // Table Rows
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _rows.length,
                            itemBuilder: (context, index) {
                              return _buildRow(index);
                            },
                          ),

                          const SizedBox(height: 20),

                          // Add Row Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: _addRow,
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B5998),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Totals (Optional but helpful)
                          Divider(color: AppColors.border),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Total Debit: ', style: bodyStyle(weight: FontWeight.w600)),
                              Text(_totalDebit.toStringAsFixed(2), style: bodyStyle(color: AppColors.green, weight: FontWeight.w700)),
                              const SizedBox(width: 40),
                              Text('Total Credit: ', style: bodyStyle(weight: FontWeight.w600)),
                              Text(_totalCredit.toStringAsFixed(2), style: bodyStyle(color: AppColors.red, weight: FontWeight.w700)),
                              const SizedBox(width: 40),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // Bottom Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AmsButton(
                                label: 'Save',
                                variant: AmsButtonVariant.primary,
                                backgroundColor: const Color(0xFF27AE60), // Green from image
                                onPressed: _submitJournal,
                              ),
                              const SizedBox(width: 16),
                              AmsButton(
                                label: 'Cancel',
                                variant: AmsButtonVariant.outline,
                                onPressed: widget.onBackToModule,
                              ),
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

  Widget _buildRow(int index) {
    final row = _rows[index];
    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _isLoadingAccounts
                ? const SizedBox(
                    height: 38,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : AmsSearchableDropdown(
                    items: _accountOptions,
                    placeholder: 'Auto help',
                    initialValue: row.accountNo.isNotEmpty ? _accountOptions.firstWhere((e) => e.startsWith(row.accountNo), orElse: () => '') : null,
                    onChanged: (v) {
                      if (v != null && v.contains(' - ')) {
                        row.accountNo = v.split(' - ').first;
                      } else {
                        row.accountNo = v ?? '';
                      }
                    },
                  ),
          ),
          const SizedBox(width: 24), // Added space
          Expanded(
            flex: 1,
            child: TextField(
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              style: bodyStyle(size: 14),
              onChanged: (v) {
                setState(() {
                  row.debit = double.tryParse(v) ?? 0.0;
                });
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: TextField(
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              style: bodyStyle(size: 14),
              onChanged: (v) {
                setState(() {
                  row.credit = double.tryParse(v) ?? 0.0;
                });
              },
            ),
          ),
          Expanded(
            flex: 4,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Remarks',
                border: InputBorder.none,
                isDense: true,
              ),
              style: bodyStyle(size: 14),
              onChanged: (v) => row.remarks = v,
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.red, size: 20),
              onPressed: () => _removeRow(index),
            ),
          ),
        ],
      ),
    );
  }
}

class JournalRow {
  String accountNo;
  double debit;
  double credit;
  String remarks;

  JournalRow({
    this.accountNo = '',
    this.debit = 0.0,
    this.credit = 0.0,
    this.remarks = '',
  });
}
