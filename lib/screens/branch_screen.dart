import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class BranchScreenFields extends StatefulWidget {
  final bool isViewMode;
  final Map<String, dynamic>? initialData;
  final int pgmStatus;
  final void Function(String, dynamic) onChanged;
  final void Function(int) onStatusChanged;
  final BuildContext parentContext;

  const BranchScreenFields({
    super.key,
    required this.isViewMode,
    this.initialData,
    required this.pgmStatus,
    required this.onChanged,
    required this.onStatusChanged,
    required this.parentContext,
  });

  @override
  State<BranchScreenFields> createState() => BranchScreenFieldsState();
}

class BranchScreenFieldsState extends State<BranchScreenFields> {
  final _brnOrgCtrl = TextEditingController(text: '1');
  final _brnCdCtrl = TextEditingController();
  final _brnNameCtrl = TextEditingController();
  final _brnOpenDateCtrl = TextEditingController();
  final _brnAddressCtrl = TextEditingController();
  final _brnCountryCtrl = TextEditingController();
  final _brnDivCtrl = TextEditingController();
  final _brnPinCtrl = TextEditingController();
  final _brnAddr1Ctrl = TextEditingController();
  final _brnAddr2Ctrl = TextEditingController();
  final _brnAddr3Ctrl = TextEditingController();
  final _brnAddr4Ctrl = TextEditingController();
  final _brnAddr5Ctrl = TextEditingController();
  final _brnTelCtrl = TextEditingController();
  final _brnEmailCtrl = TextEditingController();

  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  @override
  void didUpdateWidget(covariant BranchScreenFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _populateFields();
    }
  }

  void _populateFields() {
    final data = widget.initialData;
    if (data == null || data.isEmpty) {
      clear();
      return;
    }
    
    _brnOrgCtrl.text = (data['orgcode'] ?? data['ORGCODE'] ?? '1').toString();
    _brnCdCtrl.text = (data['branchcd'] ?? data['brncd'] ?? data['BRNCD'] ?? '').toString();
    _brnNameCtrl.text = (data['branchname'] ?? data['brnname'] ?? data['BRNNAME'] ?? '').toString();
    _brnOpenDateCtrl.text = (data['opendate'] ?? data['OPENDATE'] ?? '').toString();
    _brnAddressCtrl.text = (data['address'] ?? data['ADDRESS'] ?? '').toString();
    _brnCountryCtrl.text = (data['country'] ?? data['COUNTRY'] ?? '').toString();
    _brnDivCtrl.text = (data['divisionname'] ?? data['DIVISIONNAME'] ?? '').toString();
    _brnPinCtrl.text = (data['pincode'] ?? data['PINCODE'] ?? '').toString();
    _brnAddr1Ctrl.text = (data['addrline1'] ?? data['ADDRLINE1'] ?? '').toString();
    _brnAddr2Ctrl.text = (data['addrline2'] ?? data['ADDRLINE2'] ?? '').toString();
    _brnAddr3Ctrl.text = (data['addrline3'] ?? data['ADDRLINE3'] ?? '').toString();
    _brnAddr4Ctrl.text = (data['addrline4'] ?? data['ADDRLINE4'] ?? '').toString();
    _brnAddr5Ctrl.text = (data['addrline5'] ?? data['ADDRLINE5'] ?? '').toString();
    _brnTelCtrl.text = (data['telephone'] ?? data['TELEPHONE'] ?? '').toString();
    _brnEmailCtrl.text = (data['email'] ?? data['EMAIL'] ?? '').toString();
    
    _errors.clear();
  }

  void clear() {
    _brnOrgCtrl.text = '1';
    _brnCdCtrl.clear();
    _brnNameCtrl.clear();
    _brnOpenDateCtrl.clear();
    _brnAddressCtrl.clear();
    _brnCountryCtrl.clear();
    _brnDivCtrl.clear();
    _brnPinCtrl.clear();
    _brnAddr1Ctrl.clear();
    _brnAddr2Ctrl.clear();
    _brnAddr3Ctrl.clear();
    _brnAddr4Ctrl.clear();
    _brnAddr5Ctrl.clear();
    _brnTelCtrl.clear();
    _brnEmailCtrl.clear();
    _errors.clear();
  }

  bool validate() {
    bool isValid = true;
    setState(() {
      if (_brnCdCtrl.text.trim().isEmpty) {
        _errors['brnCd'] = 'Branch Code required';
        isValid = false;
      } else {
        _errors['brnCd'] = null;
      }

      if (_brnNameCtrl.text.trim().isEmpty) {
        _errors['brnName'] = 'Branch Name required';
        isValid = false;
      } else {
        _errors['brnName'] = null;
      }
    });
    return isValid;
  }

  @override
  void dispose() {
    _brnOrgCtrl.dispose();
    _brnCdCtrl.dispose();
    _brnNameCtrl.dispose();
    _brnOpenDateCtrl.dispose();
    _brnAddressCtrl.dispose();
    _brnCountryCtrl.dispose();
    _brnDivCtrl.dispose();
    _brnPinCtrl.dispose();
    _brnAddr1Ctrl.dispose();
    _brnAddr2Ctrl.dispose();
    _brnAddr3Ctrl.dispose();
    _brnAddr4Ctrl.dispose();
    _brnAddr5Ctrl.dispose();
    _brnTelCtrl.dispose();
    _brnEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AmsFormGrid(
            children: [
               AmsField(
                label: 'ORG CODE',
                required: true,
                labelAbove: true,
                tooltip: 'Organization code.',
                child: AmsTextInput(
                  controller: _brnOrgCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. 1',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  errorText: _errors['orgCode'],
                  isValid: _errors['orgCode'] == null && _brnOrgCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['orgCode'] = v.trim().isEmpty ? 'Org Code required' : null;
                    });
                    widget.onChanged('orgcode', int.tryParse(v) ?? 1);
                  },
                ),
              ),
              AmsField(
                label: 'BRANCH CODE',
                required: true,
                labelAbove: true,
                tooltip: 'Unique branch identification code.',
                child: AmsTextInput(
                  controller: _brnCdCtrl,
                  readOnly: widget.isViewMode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  placeholder: 'e.g. 101',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['brnCd'],
                  isValid: _errors['brnCd'] == null && _brnCdCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['brnCd'] = v.trim().isEmpty ? 'Branch Code required' : null;
                    });
                    widget.onChanged('brncd', int.tryParse(v) ?? 0);
                    widget.onChanged('BRNCD', int.tryParse(v) ?? 0);
                  },
                ),
              ),
              AmsField(
                label: 'BRANCH NAME',
                required: true,
                labelAbove: true,
                tooltip: 'Full name of the branch.',
                child: AmsTextInput(
                  controller: _brnNameCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. Main Street Branch',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['brnName'],
                  isValid: _errors['brnName'] == null && _brnNameCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['brnName'] = v.trim().isEmpty ? 'Branch Name required' : null;
                    });
                    widget.onChanged('brnname', v);
                    widget.onChanged('BRNNAME', v);
                  },
                ),
              ),
              AmsField(
                label: 'OPEN_DATE',
                required: true,
                labelAbove: true,
                tooltip: 'Opening date of the branch.',
                child: AmsTextInput(
                  controller: _brnOpenDateCtrl,
                  readOnly: true,
                  icon: Icons.calendar_today_outlined,
                  placeholder: 'e.g. 01-Jan-2026',
                  errorText: _errors['openDate'],
                  isValid: _errors['openDate'] == null && _brnOpenDateCtrl.text.isNotEmpty,
                  onTap: () async {
                    if (widget.isViewMode) return;
                    final picked = await showDatePicker(
                      context: widget.parentContext,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      builder: (ctx, child) {
                        return Theme(
                          data: Theme.of(ctx).copyWith(
                            useMaterial3: false,
                            dialogBackgroundColor: Colors.white,
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
                      const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                      final formattedDate = '${picked.day.toString().padLeft(2, '0')}-${monthNames[picked.month - 1]}-${picked.year}';
                      setState(() {
                        _brnOpenDateCtrl.text = formattedDate;
                        _errors['openDate'] = null;
                      });
                      widget.onChanged('opendate', formattedDate);
                    }
                  },
                  onChanged: (v) {
                    setState(() {
                      _errors['openDate'] = v.trim().isEmpty ? 'Open Date required' : null;
                    });
                    widget.onChanged('opendate', v);
                  },
                ),
              ),
              AmsField(
                label: 'STATUS',
                required: true,
                labelAbove: true,
                tooltip: 'Enable or disable this branch.',
                child: widget.isViewMode
                    ? AmsTextInput(
                        initialValue: widget.pgmStatus == 1 ? '1 - Enable' : '0 - Disable',
                        readOnly: true,
                      )
                    : AmsDropdown(
                        initialValue: widget.pgmStatus == 1 ? '1 - Enable' : '0 - Disable',
                        items: const ['1 - Enable', '0 - Disable'],
                        onChanged: (v) {
                          final st = v?.startsWith('1') == true ? 1 : 0;
                          widget.onStatusChanged(st);
                          widget.onChanged('status', st);
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          sectionTitle('Address & Contact', color: AppColors.tBlue),
          const SizedBox(height: 16),
          AmsFormGrid(
            children: [
               AmsField(
                label: 'ADDRESS',
                labelAbove: true,
                tooltip: 'Full address block.',
                child: AmsTextInput(
                  controller: _brnAddressCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Enter Address',
                  onChanged: (v) => widget.onChanged('address', v),
                ),
              ),
              AmsField(
                label: 'COUNTRY',
                labelAbove: true,
                tooltip: 'Country code.',
                child: AmsTextInput(
                  controller: _brnCountryCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. IN',
                  inputFormatters: [LengthLimitingTextInputFormatter(2)],
                  onChanged: (v) => widget.onChanged('country', v),
                ),
              ),
              AmsField(
                label: 'DIVISION NAME',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnDivCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Division Name',
                  onChanged: (v) => widget.onChanged('divisionname', v),
                ),
              ),
              AmsField(
                label: 'PINCODE',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnPinCtrl,
                  readOnly: widget.isViewMode,
                  keyboardType: TextInputType.number,
                  placeholder: 'e.g. 600001',
                  onChanged: (v) => widget.onChanged('pincode', v),
                ),
              ),
              AmsField(
                label: 'ADDRESS LINE 1',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnAddr1Ctrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Address Line 1',
                  onChanged: (v) => widget.onChanged('addrline1', v),
                ),
              ),
              AmsField(
                label: 'ADDRESS LINE 2',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnAddr2Ctrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Address Line 2',
                  onChanged: (v) => widget.onChanged('addrline2', v),
                ),
              ),
              AmsField(
                label: 'ADDRESS LINE 3',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnAddr3Ctrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Address Line 3',
                  onChanged: (v) => widget.onChanged('addrline3', v),
                ),
              ),
              AmsField(
                label: 'ADDRESS LINE 4',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnAddr4Ctrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Address Line 4',
                  onChanged: (v) => widget.onChanged('addrline4', v),
                ),
              ),
              AmsField(
                label: 'ADDRESS LINE 5',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnAddr5Ctrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Address Line 5',
                  onChanged: (v) => widget.onChanged('addrline5', v),
                ),
              ),
              AmsField(
                label: 'TELEPHONE',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnTelCtrl,
                  readOnly: widget.isViewMode,
                  keyboardType: TextInputType.phone,
                  icon: Icons.phone_outlined,
                  placeholder: '+919876543210',
                  onChanged: (v) => widget.onChanged('telephone', v),
                ),
              ),
              AmsField(
                label: 'EMAIL',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnEmailCtrl,
                  readOnly: widget.isViewMode,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                  placeholder: 'contact@branch.com',
                  onChanged: (v) => widget.onChanged('email', v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
