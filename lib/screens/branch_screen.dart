import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/branch_api_service.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class BranchScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const BranchScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  bool _showForm = false;
  bool _isViewOnly = false;
  bool _isEditMode = false;
  Map<String, dynamic>? _selectedRecord;
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = true;
  int _totalItems = 0;
  String _searchQuery = '';
  int _pgmStatus = 1;
  bool _isSaving = false;
  final Map<String, dynamic> _formData = {};
  final GlobalKey<BranchScreenFieldsState> _fieldsKey =
      GlobalKey<BranchScreenFieldsState>();

  @override
  void initState() {
    super.initState();
    _loadBranches(1);
  }

  Future<void> _loadBranches(int page) async {
    setState(() => _isLoading = true);
    final result = await branchApiService.getBranches(page: page - 1, size: 10);
    if (mounted) {
      setState(() {
        _branches = result?.items ?? [];
        _totalItems = result?.totalElements ?? 0;
        _isLoading = false;
      });
    }
  }

  void _enterViewMode(Map<String, dynamic> record, {bool viewOnly = true}) {
    setState(() {
      _selectedRecord = record;
      _formData.clear();
      _formData['orgCode'] = record['orgCode'] ?? record['orgcode'] ?? 50;
      _formData['brnCd'] = record['brnCd'] ?? record['brncd'] ?? 0;
      _formData['brnName'] = record['brnName'] ?? record['brnname'] ?? '';
      _formData['openDate'] = record['openDate'] ?? record['opendate'] ?? '';
      _formData['status'] = record['status'] ?? 1;
      _formData['address'] = record['address'] ?? '';
      _formData['country'] = record['country'] ?? '';
      _formData['divisionName'] =
          record['divisionName'] ?? record['divisionname'] ?? '';
      _formData['pincode'] = record['pincode'] ?? '';
      _formData['addrline1'] = record['addrline1'] ?? '';
      _formData['addrline2'] = record['addrline2'] ?? '';
      _formData['addrline3'] = record['addrline3'] ?? '';
      _formData['addrline4'] = record['addrline4'] ?? '';
      _formData['addrline5'] = record['addrline5'] ?? '';
      _formData['telephone'] = record['telephone'] ?? '';
      _formData['email'] = record['email'] ?? '';
      _formData['eUser'] = record['eUser'] ?? record['euser'] ?? 'ADMIN';
      _formData['eDate'] = record['eDate'] ??
          record['edate'] ??
          DateFormat('yyyy-MM-dd').format(DateTime.now());
      _formData['headBrn'] = record['headBrn'] ?? record['headbrn'] ?? 1;
      _formData['telephone'] = record['telephone'] ?? record['TELEPHONE'] ?? '';
      _formData['email'] = record['email'] ?? record['EMAIL'] ?? '';

      _pgmStatus = int.tryParse(_formData['status'].toString()) ?? 1;
      _showForm = true;
      _isViewOnly = viewOnly;
      _isEditMode = !viewOnly;
    });
  }

  void _createNew() {
    setState(() {
      _selectedRecord = null;
      _formData.clear();
      _formData['orgCode'] = 50;
      _formData['brnCd'] = 0;
      _formData['brnName'] = '';
      _formData['openDate'] = '';
      _formData['address'] = '';
      _formData['country'] = '';
      _formData['divisionName'] = '';
      _formData['pincode'] = '';
      _formData['addrline1'] = '';
      _formData['addrline2'] = '';
      _formData['addrline3'] = '';
      _formData['addrline4'] = '';
      _formData['addrline5'] = '';
      _formData['telephone'] = '';
      _formData['email'] = '';
      _formData['status'] = 1;
      _formData['eUser'] = widget.userName ?? 'ADMIN';
      _formData['eDate'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _formData['headBrn'] = 1;

      _pgmStatus = 1;
      _showForm = true;
      _isViewOnly = false;
      _isEditMode = false;
    });
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (_fieldsKey.currentState?.validate() == false) return;

    setState(() => _isSaving = true);
    try {
      if (_formData['brnCd'] == null || _formData['brnCd'] == 0) {
        final val = _fieldsKey.currentState?.getBranchCode();
        if (val != null) {
          _formData['brnCd'] = val;
        }
      }

      _formData['eUser'] = widget.userName ?? 'ADMIN';
      _formData['eDate'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _formData['headBrn'] = 1;
      _formData['orgCode'] = 50;

      final success = _isEditMode
          ? await branchApiService.updateBranch(_formData)
          : await branchApiService.createBranch(_formData);

      if (success) {
        final savedRecord = {
          'brnCd': _formData['brnCd'],
          'branchcd': _formData['brnCd'],
          'brnName': _formData['brnName'],
          'branchname': _formData['brnName'],
          'brnname': _formData['brnName'],
          'status': _formData['status'],
          'orgCode': _formData['orgCode'],
          'orgcode': _formData['orgCode'],
          'openDate': _formData['openDate'],
          'opendate': _formData['openDate'],
          'address': _formData['address'],
          'country': _formData['country'],
          'divisionName': _formData['divisionName'],
          'divisionname': _formData['divisionName'],
          'pincode': _formData['pincode'],
          'addrline1': _formData['addrline1'],
          'addrline2': _formData['addrline2'],
          'addrline3': _formData['addrline3'],
          'addrline4': _formData['addrline4'],
          'addrline5': _formData['addrline5'],
          'telephone': _formData['telephone'],
          'TELEPHONE': _formData['telephone'],
          'email': _formData['email'],
          'EMAIL': _formData['email'],
          'eUser': _formData['eUser'],
          'euser': _formData['eUser'],
          'eDate': _formData['eDate'],
          'edate': _formData['eDate'],
          'headBrn': _formData['headBrn'],
          'headbrn': _formData['headBrn'],
        };

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Branch ${_isEditMode ? 'updated' : 'created'} successfully')),
        );

        await _loadBranches(1);

        if (mounted) {
          setState(() {
            final exists = _branches.any((b) =>
                (b['brnCd'] ?? b['brncd'] ?? b['branchcd'])?.toString() ==
                savedRecord['brnCd']?.toString());
            if (!exists) _branches.insert(0, savedRecord);
            _showForm = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Operation failed. Please check field values.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _confirmDelete(Map<String, dynamic> b) async {
    final name = b['branchname'] ?? b['brnName'] ?? b['BRNNAME'] ?? 'this branch';
    final cd = int.tryParse((b['branchcd'] ?? b['brnCd'] ?? b['BRNCD'] ?? '0').toString()) ?? 0;
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Branch', style: bodyStyle(weight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          AmsButton(
            label: 'Cancel',
            variant: AmsButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AmsButton(
            label: 'Delete',
            variant: AmsButtonVariant.danger,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (ok == true) {
      final success = await branchApiService.deleteBranch(cd);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch deleted successfully')),
        );
        _loadBranches(1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete operation failed.')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildIdentityHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _showForm ? _buildEntryView() : _buildFullListView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityHeader() {
    return AmsIdentityHeader(
      icon: const Icon(Icons.store_rounded, size: 28, color: AppColors.tBlue),
      title: 'Branch Management',
      subtitle: '',
      badges: [],
      accentColor: AppColors.tBlue,
      accentLt: AppColors.tBlueLt,
      accentMd: AppColors.tBlueMd,
      breadcrumbs: [
        HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
        HeaderBreadcrumb(label: 'Masters', onTap: widget.onBackToModule),
        HeaderBreadcrumb(label: 'Branch'),
      ],
      onBack: _showForm
          ? () => setState(() => _showForm = false)
          : widget.onBackToModule,
    );
  }

  Widget _buildFullListView() {
    final filtered = _branches.where((b) {
      final q = _searchQuery.toLowerCase();
      return (b['branchname'] ?? b['brnName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(q) ||
          (b['branchcd'] ?? b['brnCd'] ?? '').toString().contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                    child: AmsTextInput(
                        icon: Icons.search_rounded,
                        placeholder: 'Search Branch...',
                        borderColor: AppColors.tBlue,
                        onChanged: (v) => setState(() => _searchQuery = v))),
                const SizedBox(width: 16),
                IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => _loadBranches(1)),
                const SizedBox(width: 16),
                AmsButton(
                    label: '+ Add New',
                    variant: AmsButtonVariant.primary,
                    onPressed: _createNew),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const AmsListSkeleton()
                : _buildListTable(filtered),
          ),
          _buildPaginationFooter(filtered.length),
        ],
      ),
    );
  }

  Widget _buildListTable(List<Map<String, dynamic>> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final b = items[idx];
        final bName =
            b['branchname'] ?? b['brnName'] ?? b['BRNNAME'] ?? 'Unknown';
        final bCd = b['branchcd'] ?? b['brnCd'] ?? b['BRNCD'] ?? '—';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              CircleAvatar(
                  backgroundColor: AppColors.nTealLt,
                  child: Text(bName.isNotEmpty ? bName[0] : 'B',
                      style: const TextStyle(
                          color: AppColors.nTeal,
                          fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(bName, style: bodyStyle(weight: FontWeight.bold)),
                    Text('Code: $bCd',
                        style: bodyStyle(color: AppColors.ink3, size: 12)),
                  ])),
              AmsBadge(
                label:
                    (b['status']?.toString() == '0') ? 'Disabled' : 'Enabled',
                color: (b['status']?.toString() == '0')
                    ? AppColors.red
                    : AppColors.green,
                background: (b['status']?.toString() == '0')
                    ? AppColors.redLt
                    : AppColors.greenLt,
              ),
              const SizedBox(width: 24),
              Row(children: [
                _actionIcon(
                    icon: Icons.visibility_outlined,
                    color: AppColors.green,
                    bg: Colors.white,
                    onTap: () => _enterViewMode(b)),
                const SizedBox(width: 8),
                _actionIcon(
                    icon: Icons.edit_outlined,
                    color: AppColors.tBlue,
                    bg: Colors.white,
                    onTap: () => _enterViewMode(b, viewOnly: false)),
                const SizedBox(width: 8),
                _actionIcon(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.red,
                    bg: AppColors.redLt,
                    onTap: () => _confirmDelete(b)),
              ]),

            ],
          ),
        );
      },
    );
  }

  Widget _buildEntryView() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
                color: AppColors.sidebar,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
            child: Row(children: [
              Icon(_isViewOnly ? Icons.visibility : Icons.add_circle,
                  color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                  _isViewOnly
                      ? 'Branch Details'
                      : (_isEditMode ? 'Edit Branch' : 'Create Branch'),
                  style:
                      bodyStyle(color: Colors.white, weight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up_rounded,
                      color: Colors.white),
                  onPressed: () => setState(() => _showForm = false)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(0),
              child: BranchScreenFields(
                key: _fieldsKey,
                isViewMode: _isViewOnly,
                initialData: _selectedRecord,
                pgmStatus: _pgmStatus,
                onChanged: (k, v) => _formData[k] = v,
                onStatusChanged: (s) => setState(() => _pgmStatus = s),
                parentContext: context,
              ),
            ),
          ),
          _buildEntryFooter(),
        ],
      ),
    );
  }

  Widget _buildEntryFooter() {
    return AmsSubmitBar(borderColor: AppColors.border, actions: [
      if (!_isViewOnly) ...[
        AmsButton(
          label: _isEditMode ? 'Update' : 'Submit',
          variant: AmsButtonVariant.primary,
          backgroundColor: _isSaving ? Colors.grey : AppColors.sidebar,
          onPressed: _isSaving ? null : _handleSave,
        ),
        const SizedBox(width: 12),
        AmsButton(
          label: 'Clear',
          variant: AmsButtonVariant.outline,
          icon: Icons.clear_all_rounded,
          onPressed: () => _fieldsKey.currentState?.clear(),
        ),
        const SizedBox(width: 12),
        AmsButton(
          label: 'Cancel',
          variant: AmsButtonVariant.danger,
          icon: Icons.close_rounded,
          onPressed: () => setState(() => _showForm = false),
        ),
      ] else ...[
        AmsButton(
          label: 'Back to List',
          variant: AmsButtonVariant.outline,
          icon: Icons.arrow_back_rounded,
          onPressed: () => setState(() => _showForm = false),
        ),
      ]
    ]);
  }

  Widget _actionIcon(
      {required IconData icon,
      required Color color,
      required Color bg,
      VoidCallback? onTap}) {
    return InkWell(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border)),
            child: Icon(icon, size: 16, color: color)));
  }

  Widget _buildPaginationFooter(int total) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Showing 1–$total of $total',
              style: bodyStyle(size: 13, color: AppColors.ink3)),
          Row(children: [
            IconButton(
                icon: const Icon(Icons.chevron_left_rounded), onPressed: null),
            IconButton(
                icon: const Icon(Icons.chevron_right_rounded), onPressed: null)
          ]),
        ]));
  }
}

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
    'India': {'flag': '🇮🇳', 'code': '+91', 'iso': 'IN'},
    'USA': {'flag': '🇺🇸', 'code': '+1', 'iso': 'US'},
    'UK': {'flag': '🇬🇧', 'code': '+44', 'iso': 'UK'},
    'Singapore': {'flag': '🇸🇬', 'code': '+65', 'iso': 'SG'},
    'Germany': {'flag': '🇩🇪', 'code': '+49', 'iso': 'DE'},
    'Japan': {'flag': '🇯🇵', 'code': '+81', 'iso': 'JP'},
    'Canada': {'flag': '🇨🇦', 'code': '+1', 'iso': 'CA'},
    'Australia': {'flag': '🇦🇺', 'code': '+61', 'iso': 'AU'},
  };

  static const Map<String, String> _stateCodes = {
    'Tamil Nadu': 'TN',
    'Karnataka': 'KA',
    'Maharashtra': 'MH',
    'Kerala': 'KL',
    'New York': 'NY',
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

    _brnOrgCtrl.text =
        (data['orgcode'] ?? data['ORGCODE'] ?? data['orgCode'] ?? '1')
            .toString();
    _brnCdCtrl.text = (data['branchcd'] ??
            data['brncd'] ??
            data['BRNCD'] ??
            data['brnCd'] ??
            '')
        .toString();
    _brnNameCtrl.text = (data['branchname'] ??
            data['brnname'] ??
            data['BRNNAME'] ??
            data['brnName'] ??
            '')
        .toString();
    _brnOpenDateCtrl.text =
        (data['opendate'] ?? data['OPENDATE'] ?? data['openDate'] ?? '')
            .toString();
    _brnAddressCtrl.text =
        (data['address'] ?? data['ADDRESS'] ?? '').toString();

    String countryVal = (data['country'] ?? data['COUNTRY'] ?? '').toString();
    if (_countryInfo.values.any((e) => e['iso'] == countryVal)) {
      final entry =
          _countryInfo.entries.firstWhere((e) => e.value['iso'] == countryVal);
      _brnCountryCtrl.text = "${entry.value['flag']} ${entry.key}";
    } else {
      _brnCountryCtrl.text = countryVal;
    }

    _brnDivCtrl.text = (data['divisionname'] ??
            data['DIVISIONNAME'] ??
            data['divisionName'] ??
            '')
        .toString();
    _brnPinCtrl.text = (data['pincode'] ?? data['PINCODE'] ?? '').toString();
    _brnAddr1Ctrl.text =
        (data['addrline1'] ?? data['ADDRLINE1'] ?? '').toString();
    _brnAddr2Ctrl.text =
        (data['addrline2'] ?? data['ADDRLINE2'] ?? '').toString();
    _brnAddr3Ctrl.text =
        (data['addrline3'] ?? data['ADDRLINE3'] ?? '').toString();
    _brnAddr4Ctrl.text =
        (data['addrline4'] ?? data['ADDRLINE4'] ?? '').toString();
    _brnAddr5Ctrl.text =
        (data['addrline5'] ?? data['ADDRLINE5'] ?? '').toString();
    _brnTelCtrl.text =
        (data['telephone'] ?? data['TELEPHONE'] ?? '').toString();
    _brnEmailCtrl.text = (data['email'] ?? data['EMAIL'] ?? '').toString();

    String stateVal = (data['statecode'] ?? data['STATECODE'] ?? '').toString();
    if (_stateCodes.values.contains(stateVal)) {
      _brnStateCtrl.text =
          _stateCodes.entries.firstWhere((e) => e.value == stateVal).key;
    } else {
      _brnStateCtrl.text = stateVal;
    }
    _brnDistrictCtrl.text =
        (data['districtcode'] ?? data['DISTRICTCODE'] ?? '').toString();

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

  int? getBranchCode() {
    return int.tryParse(_brnCdCtrl.text);
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

      if (_brnOpenDateCtrl.text.trim().isEmpty) {
        _errors['openDate'] = 'Open Date required';
        isValid = false;
      } else {
        _errors['openDate'] = null;
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
      widget.onChanged('country', _countryInfo[s]!['iso']);
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
      final stateISO = _stateCodes[s] ?? s;
      widget.onChanged('divisionName', stateISO);
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
      final stateISO = _stateCodes[_brnStateCtrl.text] ?? _brnStateCtrl.text;
      widget.onChanged('divisionName', "$stateISO, $s");
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
                  isValid:
                      _errors['orgCode'] == null && _brnOrgCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['orgCode'] =
                          v.trim().isEmpty ? 'Org Code required' : null;
                    });
                    widget.onChanged('orgCode', int.tryParse(v) ?? 50);
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
                  isValid:
                      _errors['brnCd'] == null && _brnCdCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['brnCd'] =
                          v.trim().isEmpty ? 'Branch Code required' : null;
                    });
                    widget.onChanged('brnCd', int.tryParse(v) ?? 0);
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
                  isValid: _errors['brnName'] == null &&
                      _brnNameCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['brnName'] =
                          v.trim().isEmpty ? 'Branch Name required' : null;
                    });
                    widget.onChanged('brnName', v);
                    widget.onChanged('brnname', v);
                    widget.onChanged('branchname', v);
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
                  isValid: _errors['openDate'] == null &&
                      _brnOpenDateCtrl.text.isNotEmpty,
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
                      final formattedDataDate =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      const monthNames = [
                        "Jan",
                        "Feb",
                        "Mar",
                        "Apr",
                        "May",
                        "Jun",
                        "Jul",
                        "Aug",
                        "Sep",
                        "Oct",
                        "Nov",
                        "Dec"
                      ];
                      final displayDate =
                          '${picked.day.toString().padLeft(2, '0')}-${monthNames[picked.month - 1]}-${picked.year}';
                      setState(() {
                        _brnOpenDateCtrl.text = displayDate;
                        _errors['openDate'] = null;
                      });
                      widget.onChanged('openDate', formattedDataDate);
                    }
                  },
                  onChanged: (v) {
                    setState(() {
                      _errors['openDate'] =
                          v.trim().isEmpty ? 'Open Date required' : null;
                    });
                    widget.onChanged('openDate', v);
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
                        initialValue: widget.pgmStatus == 1
                            ? '1 - Enable'
                            : '0 - Disable',
                        readOnly: true,
                      )
                    : AmsDropdown(
                        initialValue: widget.pgmStatus == 1
                            ? '1 - Enable'
                            : '0 - Disable',
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
