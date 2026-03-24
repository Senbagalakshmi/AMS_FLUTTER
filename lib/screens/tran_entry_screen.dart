import 'package:flutter/material.dart';
import '../theme.dart';
import '../data.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class TransactionEntryScreen extends StatefulWidget {
  final Map<String, Auth101Config> authConfigs;
  final List<String> tranPrograms;
  final void Function(
      String prog, Auth101Config cfg, String authsl, String amount) onSubmit;
  final VoidCallback onBack;
  final String? initialProg;
  final String? userName;

  const TransactionEntryScreen({
    super.key,
    required this.authConfigs,
    required this.tranPrograms,
    required this.onSubmit,
    required this.onBack,
    this.initialProg,
    this.userName,
  });

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  String? _selProg;
  final _cifidCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  _AmtBarState? _amtBar;

  @override
  void initState() {
    super.initState();
    _selProg = widget.initialProg;
  }

  @override
  void didUpdateWidget(TransactionEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialProg != widget.initialProg) {
      setState(() {
        _selProg = widget.initialProg;
        _cifidCtrl.clear();
        _amtCtrl.clear();
        _amtBar = null;
      });
    }
  }

  Auth101Config? get _cfg =>
      _selProg != null ? widget.authConfigs[_selProg] : null;

  void _onAmountChanged(String val) {
    if (val.isEmpty || _selProg == null) {
      setState(() => _amtBar = null);
      return;
    }
    final limits = auth103[_selProg];
    if (limits == null) {
      setState(() => _amtBar = null);
      return;
    }
    final amt = double.tryParse(val) ?? 0;
    final match = limits.where((l) => amt >= l.from && amt <= l.to).firstOrNull;
    setState(() {
      if (match != null) {
        _amtBar = _AmtBarState(
          ok: true,
          msg:
              '✅ Within AUTH103 limit ₹${match.from.toInt().toString()} – ₹${match.to.toInt().toString()} · Approver: ${match.approver} (${match.role})',
        );
      } else {
        _amtBar = _AmtBarState(
          ok: false,
          msg:
              '⚠ Amount ₹$val is outside configured AUTH103 limits for $_selProg',
        );
      }
    });
  }

  void _doSubmit() {
    if (_selProg == null) {
      showAmsToast(context, '⚠', 'Please select a program first.', type: 'w');
      return;
    }
    if (_cifidCtrl.text.isEmpty) {
      showAmsToast(context, '⚠', 'Customer ID (CIFID) is required.', type: 'w');
      return;
    }
    if (_amtCtrl.text.isEmpty) {
      showAmsToast(context, '⚠', 'Transaction Amount is required.', type: 'w');
      return;
    }
    final authsl =
        '2026-${(100 + (DateTime.now().millisecondsSinceEpoch % 900)).toString().padLeft(4, '0')}';
    widget.onSubmit(_selProg!, _cfg!, authsl, _amtCtrl.text);
  }

  @override
  void dispose() {
    _cifidCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AmsIdentityHeader(
                    icon: const Icon(Icons.account_balance_wallet_rounded,
                        color: AppColors.tBlue, size: 24),
                    title: _cfg != null
                        ? '${_cfg!.name} Entry'
                        : 'Transaction Entry',
                    subtitle:
                        'Transaction Program — Amount field is active, AUTH103 limits apply.',
                    badges: [
                      const AmsBadge(label: 'ISTRANPGM = 1'),
                      const AmsBadge(
                          label: 'APPROVALREQ = 1',
                          color: AppColors.amber,
                          background: AppColors.amberLt),
                      if (_cfg != null)
                        AmsBadge(label: '${_cfg!.levels}-Level Auth'),
                    ],
                    accentColor: AppColors.tBlue,
                    accentLt: AppColors.tBlueLt,
                    accentMd: AppColors.tBlueMd,
                    onBack: widget.onBack,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.border, width: 1)),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      indicatorColor: AppColors.tBlue,
                      indicatorWeight: 3,
                      labelColor: AppColors.tBlue,
                      unselectedLabelColor: AppColors.ink2,
                      labelStyle:
                          bodyStyle(size: 13, weight: FontWeight.w700),
                      unselectedLabelStyle:
                          bodyStyle(size: 13, weight: FontWeight.w600),
                      tabs: const [
                        Tab(text: '1 · BASIC INFO'),
                        Tab(text: '2 · TRANSACTION DETAILS'),
                        Tab(text: '3 · SYSTEM & REMARKS'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // TAB 1: BASIC INFO
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AmsCard(
                              headLeft: Row(
                                children: [
                                  const Icon(Icons.payments_rounded,
                                      size: 20, color: AppColors.tBlue),
                                  const SizedBox(width: 8),
                                  sectionTitle('SELECT TRANSACTION PROGRAM',
                                      color: AppColors.tBlue),
                                ],
                              ),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: widget.tranPrograms.map((pid) {
                                  final cfg = widget.authConfigs[pid]!;
                                  final sel = _selProg == pid;
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _selProg = pid;
                                      _amtCtrl.clear();
                                      _amtBar = null;
                                    }),
                                    child: Container(
                                      width: 180,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? AppColors.tBlueLt
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: sel
                                                ? AppColors.tBlue
                                                : AppColors.border,
                                            width: 1.5),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(pid,
                                              style: monoStyle(
                                                  size: 11,
                                                  weight: FontWeight.w700,
                                                  color: sel
                                                      ? AppColors.tBlue
                                                      : AppColors.ink)),
                                          const SizedBox(height: 3),
                                          Text(cfg.name,
                                              style: bodyStyle(
                                                  size: 11,
                                                  color: AppColors.ink2)),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AmsField(
                                    label: 'Org Code',
                                    pill: AmsPill.auto(),
                                    tooltip:
                                        'The organization where this transaction originated.',
                                    child: const AmsTextInput(
                                        initialValue:
                                            'ORG001 — Head Office',
                                        readOnly: true),
                                  ),
                                  AmsField(
                                    label: 'Program ID',
                                    pill: AmsPill.locked(),
                                    tooltip:
                                        'The specific transaction program code (e.g., LOAN-DIS).',
                                    child: AmsTextInput(
                                        initialValue: _selProg != null
                                            ? '$_selProg — ${_cfg!.name}'
                                            : '',
                                        readOnly: true,
                                        placeholder:
                                            'Select program above'),
                                  ),
                                  AmsField(
                                    label: 'Effective Date',
                                    required: true,
                                    tooltip:
                                        'The date on which the transaction becomes effective.',
                                    child:
                                        AmsTextInput(initialValue: today),
                                  ),
                                  AmsField(
                                    label: 'Customer ID (CIFID)',
                                    required: true,
                                    tooltip:
                                        'Unique identifier for the customer (CIFID).',
                                    child: AmsTextInput(
                                        controller: _cifidCtrl,
                                        placeholder: 'e.g. CIF-88234'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                  ),

                  // TAB 2: TRANSACTION DETAILS
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount Section
                        Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AmsField(
                                    label: 'Transaction Amount (₹)',
                                    required: true,
                                    tooltip:
                                        'Total amount for this transaction in INR.',
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AmsTextInput(
                                            controller: _amtCtrl,
                                            placeholder: '0.00',
                                            keyboardType:
                                                TextInputType.number,
                                            borderColor: AppColors.tBlue,
                                            onChanged: _onAmountChanged),
                                        if (_amtBar != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _amtBar!.ok
                                                  ? AppColors.greenLt
                                                  : AppColors.redLt,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(_amtBar!.msg,
                                                style: monoStyle(
                                                    size: 11,
                                                    color: _amtBar!.ok
                                                        ? AppColors.green
                                                        : AppColors.red)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  AmsField(
                                    label: 'Currency',
                                    tooltip:
                                        'Currency in which the transaction is processed.',
                                    child: AmsDropdown(items: const [
                                      'INR — Indian Rupee',
                                      'USD — US Dollar',
                                      'EUR — Euro'
                                    ]),
                                  ),
                                  AmsField(
                                    label: 'Transaction Date',
                                    required: true,
                                    tooltip:
                                        'The specific date on which the transaction occurs.',
                                    child: AmsTextInput(initialValue: today),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (_selProg != null) ...[
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: _DynamicTranFields(prog: _selProg!),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: _BeneFields(prog: _selProg!),
                              ),
                            ] else
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Text(
                                      'Select a program on Tab 1 to see details.',
                                      style: bodyStyle(color: AppColors.ink3)),
                                ),
                              ),
                          ],
                        ),
                  ),

                  // TAB 3: REMARKS & SYSTEM
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AmsField(
                                    label: 'Display Remarks',
                                    hint: 'Publicly visible to authorizer',
                                    child: const AmsTextInput(
                                      placeholder: 'Internal notes...',
                                      keyboardType: TextInputType.multiline,
                                    ),
                                  ),
                                  AmsField(
                                    label: 'Extraordinary Remarks',
                                    hintColor: AppColors.amber,
                                    hint:
                                        'Displayed with high-visibility amber highlight',
                                    child: const AmsTextInput(
                                      placeholder: 'Exceptions, risks, etc.',
                                      keyboardType: TextInputType.multiline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AmsField(
                                      label: 'Entry User',
                                      pill: AmsPill.auto(),
                                      child: AmsTextInput(
                                          initialValue:
                                              '${widget.userName ?? 'Arjun Mehta'} (EMP00123)',
                                          readOnly: true)),
                                  AmsField(
                                      label: 'Entry Date',
                                      pill: AmsPill.auto(),
                                      child: AmsTextInput(
                                          initialValue: today,
                                          readOnly: true)),
                                  AmsField(
                                      label: 'Primary Key',
                                      pill: AmsPill.auto(),
                                      child: AmsTextInput(
                                          initialValue: _selProg != null
                                              ? '${tranProgPkPrefix[_selProg] ?? 'XX'}-2026-####'
                                              : '',
                                          readOnly: true)),
                                ],
                              ),
                            ),
                          ],
                        ),
                  ),
                ],
              ),
            ),

            // Submit bar
            AmsSubmitBar(
              borderColor: AppColors.tBlueMd,
              actions: [
                AmsButton(
                    label: 'Clear',
                    variant: AmsButtonVariant.ghost,
                    onPressed: () {
                      _cifidCtrl.clear();
                      _amtCtrl.clear();
                      setState(() => _amtBar = null);
                    }),
                AmsButton(
                    label: 'Save Draft',
                    variant: AmsButtonVariant.outline,
                    onPressed: () {}),
                AmsButton(
                    label: (_cfg != null && !_cfg!.approvalReq)
                        ? 'Save'
                        : 'Submit for Authorization',
                    large: true,
                    onPressed: _doSubmit),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _AmtBarState {
  final bool ok;
  final String msg;
  _AmtBarState({required this.ok, required this.msg});
}

class _DynamicTranFields extends StatelessWidget {
  final String prog;
  const _DynamicTranFields({required this.prog});

  @override
  Widget build(BuildContext context) {
    switch (prog) {
      case 'LOAN-DIS':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const AmsAuthField(
              label: 'Loan Account No.',
              value: '',
              isEditable: true,
              placeholder: 'e.g. LN-2026-00123'),
          AmsField(
            label: 'Loan Type',
            required: true,
            child: AmsDropdown(items: const [
              'Term Loan',
              'Working Capital Loan',
              'Overdraft',
              'Vehicle Loan',
              'Home Loan'
            ]),
          ),
          const AmsAuthField(
              label: 'Sanction Letter Ref.',
              value: '',
              isEditable: true,
              placeholder: 'e.g. SL-2026-00456'),
          AmsField(
            label: 'Disbursement Mode',
            required: true,
            child: AmsDropdown(items: const ['NEFT', 'RTGS', 'Cheque', 'Cash']),
          ),
          AmsField(
            label: 'Loan Purpose',
            required: true,
            child: AmsDropdown(items: const [
              'Business Expansion',
              'Working Capital',
              'Property Purchase',
              'Machinery / Equipment',
              'Personal'
            ]),
          ),
          const AmsAuthField(
            label: 'Repayment Start Date',
            value: '',
            isEditable: true,
            placeholder: 'YYYY-MM-DD',
          ),
        ]);
      case 'NEFT-TXN':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const AmsAuthField(
              label: 'Debit Account No.',
              value: '',
              isEditable: true,
              placeholder: "Customer's debit account"),
          AmsField(
            label: 'Transfer Mode',
            required: true,
            child: AmsDropdown(items: const ['NEFT', 'RTGS', 'IMPS']),
          ),
          const AmsAuthField(
              label: 'Transfer Narration',
              value: '',
              isEditable: true,
              placeholder: 'Purpose of transfer'),
          const AmsAuthField(
            label: 'Value Date',
            value: '',
            isEditable: true,
            placeholder: 'YYYY-MM-DD',
          ),
          const AmsAuthField(
              label: 'UTR Reference',
              value: 'System generated',
              isEditable: false),
        ]);
      case 'FD-OPEN':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const AmsAuthField(
              label: 'Source Account No.',
              value: '',
              isEditable: true,
              placeholder: 'Debit from this account'),
          AmsField(
            label: 'FD Tenure',
            required: true,
            child: AmsDropdown(items: const [
              '6 Months',
              '1 Year',
              '2 Years',
              '3 Years',
              '5 Years'
            ]),
          ),
          AmsField(
            label: 'Interest Payout Frequency',
            child: AmsDropdown(items: const [
              'On Maturity',
              'Monthly',
              'Quarterly',
              'Half-Yearly'
            ]),
          ),
          AmsField(
            label: 'Auto-Renewal',
            child: AmsDropdown(
                items: const ['Yes — Auto Renew', 'No — Pay on Maturity']),
          ),
        ]);
      case 'RD-OPEN':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const AmsAuthField(
              label: 'Source Account No.',
              value: '',
              isEditable: true,
              placeholder: 'Monthly debit account'),
          AmsField(
            label: 'RD Tenure',
            required: true,
            child: AmsDropdown(items: const [
              '12 Months',
              '24 Months',
              '36 Months',
              '60 Months'
            ]),
          ),
          AmsField(
            label: 'Installment Date',
            required: true,
            child: AmsDropdown(items: const [
              '1st of Month',
              '5th of Month',
              '10th of Month',
              '15th of Month',
              'Last Day of Month'
            ]),
          ),
          const AmsAuthField(
              label: 'Interest Rate',
              value: '6.50% p.a.',
              isEditable: false),
        ]);
      default:
        return const SizedBox();
    }
  }
}

class _BeneFields extends StatelessWidget {
  final String prog;
  const _BeneFields({required this.prog});

  @override
  Widget build(BuildContext context) {
    switch (prog) {
      case 'LOAN-DIS':
      case 'NEFT-TXN':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const AmsAuthField(
              label: 'Beneficiary Name',
              value: '',
              isEditable: true,
              placeholder: 'Full legal name as per account'),
          const AmsAuthField(
              label: 'Beneficiary Account No.',
              value: '',
              isEditable: true,
              placeholder: 'Beneficiary bank account number'),
          const AmsAuthField(
              label: 'Beneficiary Bank',
              value: '',
              isEditable: true,
              placeholder: 'Bank name'),
          const AmsAuthField(
              label: 'IFSC Code',
              value: '',
              isEditable: true,
              placeholder: 'e.g. SBIN0001234'),
        ]);
      case 'FD-OPEN':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const AmsAuthField(
              label: 'Interest Rate (%)',
              value: '7.25%',
              isEditable: false),
          const AmsAuthField(
              label: 'Estimated Maturity Amount',
              value: 'Calculated on submit',
              isEditable: false),
        ]);
      case 'RD-OPEN':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const AmsAuthField(
              label: 'Estimated Maturity Amount',
              value: 'Calculated after submit',
              isEditable: false),
        ]);
      default:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No separate beneficiary section for this program.',
                style: bodyStyle(size: 12, color: AppColors.ink3)),
          ),
        );
    }
  }
}
