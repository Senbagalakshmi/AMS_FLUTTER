import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

      // ── Helper: truncate string to max DB column length ──────────────────
      String trunc(String? v, int max) =>
          (v ?? '').length > max ? (v ?? '').substring(0, max) : (v ?? '');

      // Build a clean payload — only DB columns, values truncated to column size.
      // Sizes inferred from working payload & error (country VARCHAR(2) confirmed).
      final cleanPayload = {
        'orgCode': _formData['orgCode'], // BIGINT
        'brnCd': _formData['brnCd'], // BIGINT
        'brnName': trunc(_formData['brnName']?.toString(), 100),
        'openDate': trunc(_formData['openDate']?.toString(), 10), // yyyy-MM-dd
        'address': trunc(_formData['address']?.toString(), 200),
        'country':
            trunc(_formData['country']?.toString(), 2), // ISO2 VARCHAR(2)
        'divisionName': trunc(_formData['divisionName']?.toString(), 50),
        'pincode': trunc(_formData['pincode']?.toString(), 10),
        'addrline1': trunc(_formData['addrline1']?.toString(), 100),
        'addrline2': trunc(_formData['addrline2']?.toString(), 100),
        'addrline3': trunc(_formData['addrline3']?.toString(), 100),
        'addrline4': trunc(_formData['addrline4']?.toString(), 100),
        'addrline5': trunc(_formData['addrline5']?.toString(), 100),
        'telephone': trunc(_formData['telephone']?.toString(), 20),
        'email': trunc(_formData['email']?.toString(), 100),
        'status': _formData['status'], // INT
        'eUser': trunc(_formData['eUser']?.toString(), 5), // e.g. "ADMIN"
        'eDate': trunc(_formData['eDate']?.toString(), 10), // yyyy-MM-dd
        'headBrn': _formData['headBrn'], // BIGINT
      };

      final success = _isEditMode
          ? await branchApiService.updateBranch(cleanPayload)
          : await branchApiService.createBranch(cleanPayload);

      if (success) {
        final savedRecord = {
          'brnCd': _formData['brnCd'],
          'branchcd': _formData['brnCd'],
          'brnName': _formData['brnName'],
          'branchname': _formData['brnName'], // UI display only
          'brnname': _formData['brnName'], // UI display only
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
    final name =
        b['branchname'] ?? b['brnName'] ?? b['BRNNAME'] ?? 'this branch';
    final cd = int.tryParse(
            (b['branchcd'] ?? b['brnCd'] ?? b['BRNCD'] ?? '0').toString()) ??
        0;

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
      final orgCode = b['orgCode'] ?? b['orgcode'] ?? 50;
      final success = await branchApiService.deleteBranch(
          orgCode is int ? orgCode : 50, cd);
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

// ═══════════════════════════════════════════════════════════════════════════════
// BranchScreenFields
// ═══════════════════════════════════════════════════════════════════════════════

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
  // ── Text Controllers ────────────────────────────────────────────────────────
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

  // ── Overlay search controllers ──────────────────────────────────────────────
  final _countrySearchCtrl = TextEditingController();
  final _stateSearchCtrl = TextEditingController();
  final _districtSearchCtrl = TextEditingController();

  // ── LayerLinks for overlay positioning ─────────────────────────────────────
  final _countryLayerLink = LayerLink();
  final _stateLayerLink = LayerLink();
  final _districtLayerLink = LayerLink();

  // ── Overlay entries ─────────────────────────────────────────────────────────
  OverlayEntry? _countryOverlay;
  OverlayEntry? _stateOverlay;
  OverlayEntry? _districtOverlay;

  // ── API-driven dropdown data ────────────────────────────────────────────────
  List<String> _countries = [];
  List<String> _states = [];
  List<String> _districts = [];
  // country display name → ISO2 code  e.g. "India" → "IN"
  final Map<String, String> _countryIsoMap = {};
  bool _countriesLoading = false;
  bool _statesLoading = false;
  bool _districtsLoading = false;
  bool _pincodeLoading = false;
  String? _selectedCountryName;
  String? _selectedCountryIso; // 2-char code sent to DB (VARCHAR(2))
  String? _selectedStateName;
  String? _selectedStateAbbr; // e.g. "TN" for "Tamil Nadu"

  final Map<String, String?> _errors = {};

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadCountries();
    _populateFields();
  }

  @override
  void didUpdateWidget(covariant BranchScreenFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _populateFields();
    }
  }

  @override
  void dispose() {
    _removeAllOverlays();
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
    _countrySearchCtrl.dispose();
    _stateSearchCtrl.dispose();
    _districtSearchCtrl.dispose();
    super.dispose();
  }

  // ── Overlay helpers ─────────────────────────────────────────────────────────
  void _removeAllOverlays() {
    _countryOverlay?.remove();
    _countryOverlay = null;
    _stateOverlay?.remove();
    _stateOverlay = null;
    _districtOverlay?.remove();
    _districtOverlay = null;
  }

  OverlayEntry _buildDropdownOverlay({
    required LayerLink link,
    required List<String> items,
    required bool isLoading,
    required TextEditingController searchCtrl,
    required void Function(String) onSelect,
    required VoidCallback onClose,
  }) {
    return OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onClose,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: link,
                showWhenUnlinked: false,
                offset: const Offset(0, 50),
                child: GestureDetector(
                  onTap: () {}, // prevent tap-through to background dismiss
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(10),
                    shadowColor: Colors.black26,
                    child: StatefulBuilder(
                      builder: (ctx2, setInner) {
                        final query = searchCtrl.text.toLowerCase();
                        final filtered = items
                            .where((i) => i.toLowerCase().contains(query))
                            .toList();

                        return Container(
                          width: 300,
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Search bar inside dropdown
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: TextField(
                                  controller: searchCtrl,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    hintStyle: TextStyle(
                                        color: AppColors.ink4, fontSize: 13),
                                    prefixIcon: const Icon(Icons.search,
                                        size: 18, color: AppColors.ink3),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.tBlue, width: 1.5),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.bg,
                                  ),
                                  onChanged: (_) => setInner(() {}),
                                ),
                              ),
                              const Divider(height: 1, color: AppColors.border),
                              // List
                              Flexible(
                                child: isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.tBlue),
                                              SizedBox(height: 10),
                                              Text('Loading...',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: AppColors.ink3)),
                                            ],
                                          ),
                                        ),
                                      )
                                    : filtered.isEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Text(
                                              'No results found',
                                              style: bodyStyle(
                                                  color: AppColors.ink4),
                                            ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: filtered.length,
                                            itemBuilder: (_, idx) => InkWell(
                                              onTap: () {
                                                onSelect(filtered[idx]);
                                                searchCtrl.clear();
                                                onClose();
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 11),
                                                decoration: BoxDecoration(
                                                  border: idx <
                                                          filtered.length - 1
                                                      ? const Border(
                                                          bottom: BorderSide(
                                                              color: AppColors
                                                                  .border,
                                                              width: 0.5))
                                                      : null,
                                                ),
                                                child: Text(filtered[idx],
                                                    style: bodyStyle(size: 13)),
                                              ),
                                            ),
                                          ),
                              ),
                            ],
                          ),
                        );
                      },
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

  // ── Open Country Dropdown ───────────────────────────────────────────────────
  Future<void> _openCountryDropdown() async {
    if (widget.isViewMode) return;
    _removeAllOverlays();
    if (_countries.isEmpty) await _loadCountries();

    _countryOverlay = _buildDropdownOverlay(
      link: _countryLayerLink,
      items: _countries,
      isLoading: _countriesLoading,
      searchCtrl: _countrySearchCtrl,
      onSelect: (selected) {
        final iso = _countryIsoMap[selected] ??
            selected
                .substring(0, selected.length >= 2 ? 2 : selected.length)
                .toUpperCase();
        setState(() {
          _selectedCountryName = selected;
          _selectedCountryIso = iso;
          _brnCountryCtrl.text = selected; // show full name in UI
          // Reset dependent fields
          _selectedStateName = null;
          _brnStateCtrl.clear();
          _brnDistrictCtrl.clear();
          _brnPinCtrl.clear();
          _states = [];
          _districts = [];
        });
        widget.onChanged('country', iso); // send ISO2 to DB (VARCHAR 2)
        _loadStates(selected);
      },
      onClose: () {
        _countryOverlay?.remove();
        _countryOverlay = null;
      },
    );
    Overlay.of(context).insert(_countryOverlay!);
  }

  // ── Open State Dropdown ─────────────────────────────────────────────────────
  Future<void> _openStateDropdown() async {
    if (widget.isViewMode) return;
    if (_selectedCountryName == null || _selectedCountryName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Country first')),
      );
      return;
    }
    _removeAllOverlays();
    if (_states.isEmpty) await _loadStates(_selectedCountryName!);

    _stateOverlay = _buildDropdownOverlay(
      link: _stateLayerLink,
      items: _states,
      isLoading: _statesLoading,
      searchCtrl: _stateSearchCtrl,
      onSelect: (selected) {
        // Build abbreviation: first letter of each word, max 5 chars
        // e.g. "Tamil Nadu" → "TN", "Andhra Pradesh" → "AP"
        final abbr = selected
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase())
            .join();
        setState(() {
          _selectedStateName = selected;
          _selectedStateAbbr = abbr;
          _brnStateCtrl.text = selected;
          // Reset dependent fields
          _brnDistrictCtrl.clear();
          _brnPinCtrl.clear();
          _districts = [];
        });
        // divisionName not finalized until district is picked
        widget.onChanged('divisionName', abbr);
        _loadDistricts(_selectedCountryName!, selected);
      },
      onClose: () {
        _stateOverlay?.remove();
        _stateOverlay = null;
      },
    );
    Overlay.of(context).insert(_stateOverlay!);
  }

  // ── Open District Dropdown ──────────────────────────────────────────────────
  Future<void> _openDistrictDropdown() async {
    if (widget.isViewMode) return;
    if (_selectedStateName == null || _selectedStateName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a State first')),
      );
      return;
    }
    _removeAllOverlays();
    if (_districts.isEmpty) {
      await _loadDistricts(_selectedCountryName!, _selectedStateName!);
    }

    _districtOverlay = _buildDropdownOverlay(
      link: _districtLayerLink,
      items: _districts,
      isLoading: _districtsLoading,
      searchCtrl: _districtSearchCtrl,
      onSelect: (selected) {
        setState(() {
          _brnDistrictCtrl.text = selected;
          _brnPinCtrl.clear(); // clear while fetching
        });
        // Format: "TN, Madurai"  (state abbr + district name)
        final divVal = _selectedStateAbbr != null
            ? '$_selectedStateAbbr, $selected'
            : selected;
        widget.onChanged('divisionName', divVal);
        // Auto-populate pincode
        _loadPincode(selected);
      },
      onClose: () {
        _districtOverlay?.remove();
        _districtOverlay = null;
      },
    );
    Overlay.of(context).insert(_districtOverlay!);
  }

  // ── API: Countries ──────────────────────────────────────────────────────────
  Future<void> _loadCountries() async {
    if (_countriesLoading || _countries.isNotEmpty) return;
    setState(() => _countriesLoading = true);
    try {
      final res = await http
          .get(Uri.parse('https://countriesnow.space/api/v0.1/countries'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded['data'] ?? [];
        final names = data.map<String>((e) => e['country'] as String).toList()
          ..sort();
        // Build name→ISO2 map for DB payload
        final isoMap = <String, String>{};
        for (final entry in data) {
          final name = entry['country'] as String? ?? '';
          final iso = entry['iso2'] as String? ?? '';
          if (name.isNotEmpty && iso.isNotEmpty)
            isoMap[name] = iso.toUpperCase();
        }
        if (mounted)
          setState(() {
            _countries = names;
            _countryIsoMap.addAll(isoMap);
          });
      }
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _countriesLoading = false);
    }
  }

  // ── API: States ─────────────────────────────────────────────────────────────
  Future<void> _loadStates(String countryName) async {
    setState(() {
      _statesLoading = true;
      _states = [];
      _districts = [];
    });
    try {
      final res = await http
          .post(
            Uri.parse('https://countriesnow.space/api/v0.1/countries/states'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'country': countryName}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List stateList = decoded['data']?['states'] ?? [];
        final names = stateList.map<String>((s) => s['name'] as String).toList()
          ..sort();
        if (mounted) setState(() => _states = names);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _statesLoading = false);
    }
  }

  // ── API: Districts / Cities ─────────────────────────────────────────────────
  Future<void> _loadDistricts(String countryName, String stateName) async {
    setState(() {
      _districtsLoading = true;
      _districts = [];
    });
    try {
      final res = await http
          .post(
            Uri.parse(
                'https://countriesnow.space/api/v0.1/countries/state/cities'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'country': countryName, 'state': stateName}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List cities = decoded['data'] ?? [];
        final names = cities.cast<String>()..sort();
        if (mounted) setState(() => _districts = names);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _districtsLoading = false);
    }
  }

  // ── API: Pincode auto-populate ──────────────────────────────────────────────
  // Uses postalpincode.in for India; falls back gracefully for other countries.
  Future<void> _loadPincode(String cityName) async {
    if (!mounted) return;
    setState(() => _pincodeLoading = true);
    try {
      final res = await http
          .get(
            Uri.parse(
                'https://api.postalpincode.in/postoffice/${Uri.encodeComponent(cityName)}'),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List;
          if (postOffices.isNotEmpty) {
            final pincode = postOffices[0]['Pincode']?.toString() ?? '';
            if (pincode.isNotEmpty && mounted) {
              setState(() => _brnPinCtrl.text = pincode);
              widget.onChanged('pincode', pincode);
            }
          }
        }
      }
    } catch (_) {
      // Pincode lookup not available for this country – user enters manually
    } finally {
      if (mounted) setState(() => _pincodeLoading = false);
    }
  }

  // ── Populate / Clear ────────────────────────────────────────────────────────
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

    final countryVal = (data['country'] ?? data['COUNTRY'] ?? '').toString();
    _brnCountryCtrl.text = countryVal;
    _selectedCountryName = countryVal.isNotEmpty ? countryVal : null;
    _selectedCountryIso = countryVal.isNotEmpty ? countryVal : null;

    // ── FIX: Read state & district from divisionName ──────────────────────
    // divisionName is saved as "TN, Madurai" (stateAbbr, district)
    // or just "TN" if only state was selected.
    final divVal = (data['divisionName'] ??
            data['divisionname'] ??
            data['DIVISIONNAME'] ??
            '')
        .toString()
        .trim();

    if (divVal.contains(',')) {
      final commaIdx = divVal.indexOf(',');
      final stateAbbr = divVal.substring(0, commaIdx).trim();
      final districtName = divVal.substring(commaIdx + 1).trim();
      _brnStateCtrl.text = stateAbbr;
      _selectedStateName = stateAbbr;
      _selectedStateAbbr = stateAbbr;
      _brnDistrictCtrl.text = districtName;
    } else if (divVal.isNotEmpty) {
      // Only state abbr stored — no district chosen
      _brnStateCtrl.text = divVal;
      _selectedStateName = divVal;
      _selectedStateAbbr = divVal;
      _brnDistrictCtrl.clear();
    } else {
      _brnStateCtrl.clear();
      _brnDistrictCtrl.clear();
      _selectedStateName = null;
      _selectedStateAbbr = null;
    }
    // ── END FIX ───────────────────────────────────────────────────────────

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
    _selectedCountryName = null;
    _selectedCountryIso = null;
    _selectedStateName = null;
    _selectedStateAbbr = null;
    _states = [];
    _districts = [];
    _errors.clear();
    if (mounted) setState(() {});
  }

  int? getBranchCode() => int.tryParse(_brnCdCtrl.text);

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

  // ── Build ───────────────────────────────────────────────────────────────────
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
          // ── Basic Info Section ──────────────────────────────────────────────
          AmsFormGrid(
            children: [
              AmsField(
                label: 'Organisation Code',
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
                          v.trim().isEmpty ? 'Organisation Code required' : null;
                    });
                    widget.onChanged('orgCode', int.tryParse(v) ?? 50);
                  },
                ),
              ),
              AmsField(
                label: 'Branch Code',
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
                label: 'Branch name',
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
                  },
                ),
              ),
              AmsField(
                label: 'Open date',
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
                label: 'Status',
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

          // ── Address & Contact Section ───────────────────────────────────────
          AmsFormGrid(
            children: [
              AmsField(
                label: 'Address',
                labelAbove: true,
                tooltip: 'Full address block.',
                child: AmsTextInput(
                  controller: _brnAddressCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Enter Address',
                  onChanged: (v) => widget.onChanged('address', v),
                ),
              ),

              // ── COUNTRY (overlay dropdown) ────────────────────────────────
              AmsField(
                label: 'Country',
                labelAbove: true,
                tooltip: 'Select country.',
                child: CompositedTransformTarget(
                  link: _countryLayerLink,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openCountryDropdown,
                    child: AbsorbPointer(
                      child: AmsTextInput(
                        controller: _brnCountryCtrl,
                        readOnly: true,
                        placeholder: _countriesLoading
                            ? 'Loading countries...'
                            : 'Select Country',
                        icon: _countriesLoading
                            ? Icons.hourglass_empty_rounded
                            : Icons.public_rounded,
                      ),
                    ),
                  ),
                ),
              ),

              // ── STATE (overlay dropdown – depends on Country) ─────────────
              AmsField(
                label: 'State code',
                labelAbove: true,
                tooltip: 'Select state.',
                child: CompositedTransformTarget(
                  link: _stateLayerLink,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openStateDropdown,
                    child: AbsorbPointer(
                      child: AmsTextInput(
                        controller: _brnStateCtrl,
                        readOnly: true,
                        placeholder: _statesLoading
                            ? 'Loading states...'
                            : 'Select State',
                        icon: _statesLoading
                            ? Icons.hourglass_empty_rounded
                            : Icons.map_rounded,
                      ),
                    ),
                  ),
                ),
              ),

              // ── DISTRICT (overlay dropdown – depends on State) ────────────
              AmsField(
                label: 'Distric code',
                labelAbove: true,
                tooltip: 'Select district.',
                child: CompositedTransformTarget(
                  link: _districtLayerLink,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openDistrictDropdown,
                    child: AbsorbPointer(
                      child: AmsTextInput(
                        controller: _brnDistrictCtrl,
                        readOnly: true,
                        placeholder: _districtsLoading
                            ? 'Loading districts...'
                            : 'Select District',
                        icon: _districtsLoading
                            ? Icons.hourglass_empty_rounded
                            : Icons.location_city_rounded,
                      ),
                    ),
                  ),
                ),
              ),

              // ── PINCODE (auto-populated + manual) ────────────────────────
              AmsField(
                label: 'Pincode',
                labelAbove: true,
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    AmsTextInput(
                      controller: _brnPinCtrl,
                      readOnly: widget.isViewMode,
                      placeholder: _pincodeLoading
                          ? 'Fetching pincode...'
                          : 'Enter Pincode',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) => widget.onChanged('pincode', v),
                    ),
                    if (_pincodeLoading)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.tBlue),
                        ),
                      ),
                  ],
                ),
              ),

              AmsField(
                label: 'Address line',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnAddr1Ctrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Address Line 1',
                  onChanged: (v) => widget.onChanged('addrline1', v),
                ),
              ),
              AmsField(
                label: 'Address line 2',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnAddr2Ctrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Address Line 2',
                  onChanged: (v) => widget.onChanged('addrline2', v),
                ),
              ),
              AmsField(
                label: 'Address line 3',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnAddr3Ctrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Address Line 3',
                  onChanged: (v) => widget.onChanged('addrline3', v),
                ),
              ),
              AmsField(
                label: 'Address line 4',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnAddr4Ctrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Address Line 4',
                  onChanged: (v) => widget.onChanged('addrline4', v),
                ),
              ),
              AmsField(
                label: 'Address line 5',
                labelAbove: true,
                child: AmsTextInput(
                  controller: _brnAddr5Ctrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Address Line 5',
                  onChanged: (v) => widget.onChanged('addrline5', v),
                ),
              ),
              AmsField(
                label: 'Telephone',
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
                label: 'Email',
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
