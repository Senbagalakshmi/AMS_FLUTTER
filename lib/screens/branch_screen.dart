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
  final _brnStateCtrl = TextEditingController();
  final _brnDistrictCtrl = TextEditingController();

  static const Map<String, Map<String, String>> _countryInfo = {
    'India': {'flag': '🇮🇳', 'code': '+91'},
    'USA': {'flag': '🇺🇸', 'code': '+1'},
    'UK': {'flag': '🇬🇧', 'code': '+44'},
    'Singapore': {'flag': '🇸🇬', 'code': '+65'},
    'Germany': {'flag': '🇩🇪', 'code': '+49'},
    'Japan': {'flag': '🇯🇵', 'code': '+81'},
    'Canada': {'flag': '🇨🇦', 'code': '+1'},
    'Australia': {'flag': '🇦🇺', 'code': '+61'},
  };

  final Map<String, List<String>> _stateDistricts = {
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Trichy'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik'],
    'Kerala': ['Kochi', 'Thiruvananthapuram', 'Kozhikode'],
    'New York': ['Manhattan', 'Brooklyn', 'Queens'],
  };

  final Map<String, String> _pincodeMap = {
    'Chennai': '600001',
    'Coimbatore': '641001',
    'Madurai': '625001',
    'Salem': '636001',
    'Trichy': '620001',
    'Bangalore': '560001',
    'Mysore': '570001',
    'Hubli': '580001',
    'Mangalore': '575001',
    'Mumbai': '400001',
    'Pune': '411001',
    'Nagpur': '440001',
    'Nashik': '422001',
    'Kochi': '682001',
    'Thiruvananthapuram': '695001',
    'Kozhikode': '673001',
    'Manhattan': '10001',
    'Brooklyn': '11201',
    'Queens': '11101',
  };

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
    _brnStateCtrl.text = (data['statecode'] ?? data['STATECODE'] ?? '').toString();
    _brnDistrictCtrl.text = (data['districtcode'] ?? data['DISTRICTCODE'] ?? '').toString();
    
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
    _brnStateCtrl.clear();
    _brnDistrictCtrl.clear();
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
    _brnStateCtrl.dispose();
    _brnDistrictCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectCountry() async {
    if (widget.isViewMode) return;
    final countries = _countryInfo.keys.toList();
    final s = await showDialog<String>(
        context: context,
        builder: (ctx) =>
            _SearchPicker(title: 'Select Country', items: countries));
    if (s != null) {
      setState(() {
        final info = _countryInfo[s]!;
        _brnCountryCtrl.text = "${info['flag']} $s";
        _brnTelCtrl.text = "${info['flag']} ${info['code']} ";
        _brnStateCtrl.clear();
        _brnDistrictCtrl.clear();
        _brnPinCtrl.clear();
      });
      widget.onChanged('country', s);
      widget.onChanged('telephone', _brnTelCtrl.text);
    }
  }

  Future<void> _selectState() async {
    if (widget.isViewMode) return;
    final s = await showDialog<String>(
        context: context,
        builder: (ctx) => _SearchPicker(
            title: 'Select State', items: _stateDistricts.keys.toList()));
    if (s != null) {
      setState(() {
        _brnStateCtrl.text = s;
        _brnDistrictCtrl.clear();
        _brnPinCtrl.clear();
      });
      widget.onChanged('statecode', s);
    }
  }

  Future<void> _selectDistrict() async {
    if (widget.isViewMode) return;
    if (_brnStateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a State first')),
      );
      return;
    }
    final s = await showDialog<String>(
        context: context,
        builder: (ctx) => _SearchPicker(
            title: 'Select District',
            items: _stateDistricts[_brnStateCtrl.text] ?? []));
    if (s != null) {
      setState(() {
        _brnDistrictCtrl.text = s;
        _brnPinCtrl.text = _pincodeMap[s] ?? '';
      });
      widget.onChanged('districtcode', s);
      widget.onChanged('pincode', _brnPinCtrl.text);
    }
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
                tooltip: 'Select country.',
                child: AmsTextInput(
                  controller: _brnCountryCtrl,
                  readOnly: true,
                  placeholder: 'Select Country',
                  icon: Icons.public_rounded,
                  onTap: _selectCountry,
                ),
              ),
              AmsField(
                label: 'STATE CODE',
                labelAbove: true,
                tooltip: 'Select state.',
                child: AmsTextInput(
                  controller: _brnStateCtrl,
                  readOnly: true,
                  placeholder: 'Select State',
                  icon: Icons.map_rounded,
                  onTap: _selectState,
                ),
              ),
              AmsField(
                label: 'DISTRICT CODE',
                labelAbove: true,
                tooltip: 'Select district.',
                child: AmsTextInput(
                  controller: _brnDistrictCtrl,
                  readOnly: true,
                  placeholder: 'Select District',
                  icon: Icons.location_city_rounded,
                  onTap: _selectDistrict,
                ),
              ),
             
              AmsField(
                label: 'PINCODE',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnPinCtrl,
                  readOnly: true,
                  placeholder: 'Auto-populated',
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

class _SearchPicker extends StatefulWidget {
  final String title;
  final List<String> items;
  const _SearchPicker({required this.title, required this.items});
  @override
  State<_SearchPicker> createState() => _SearchPickerState();
}

class _SearchPickerState extends State<_SearchPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((i) => i.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return AlertDialog(
      title: Text(widget.title, style: bodyStyle(weight: FontWeight.bold)),
      content: SizedBox(
          width: 400,
          height: 500,
          child: Column(children: [
            AmsTextInput(
                placeholder: 'Search...',
                icon: Icons.search,
                borderColor: AppColors.tBlue,
                onChanged: (v) => setState(() => _query = v)),
            const SizedBox(height: 16),
            Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('No results',
                            style: bodyStyle(color: AppColors.ink4)))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) => ListTile(
                            title: Text(filtered[idx], style: bodyStyle()),
                            onTap: () =>
                                Navigator.pop(context, filtered[idx])))),
          ])),
      actions: [
        AmsButton(
            label: 'Close',
            variant: AmsButtonVariant.ghost,
            onPressed: () => Navigator.pop(context))
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
