import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart'; // ← உங்கள் existing api_service import

// ═══════════════════════════════════════════════════════════════════════════════
// UserAccessScreen  (Table: PRODUsers001 / USER004)
// Fields: orgCode, userCode, productCode, accessCode
// ═══════════════════════════════════════════════════════════════════════════════

class UserAccessScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const UserAccessScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<UserAccessScreen> createState() => _UserAccessScreenState();
}

class _UserAccessScreenState extends State<UserAccessScreen> {
  bool _showForm = false;
  bool _isViewOnly = false;
  bool _isEditMode = false;
  Map<String, dynamic>? _selectedRecord;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSaving = false;
  final Map<String, dynamic> _formData = {};
  final GlobalKey<UserAccessFieldsState> _fieldsKey =
      GlobalKey<UserAccessFieldsState>();

  // ── Sample / stub data (replace with your real API service) ─────────────────
  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _records = [
          {
            'orgCode': 50,
            'userCode': 'USR001',
            'productCode': 'PROD001',
            'accessCode': 'ACC001',
            'status': 1,
          },
          {
            'orgCode': 50,
            'userCode': 'USR002',
            'productCode': 'PROD002',
            'accessCode': 'ACC002',
            'status': 0,
          },
        ];
        _isLoading = false;
      });
    }
  }

  Future<bool> _apiCreate(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  Future<bool> _apiUpdate(Map<String, dynamic> payload) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  Future<bool> _apiDelete(String userCode, String productCode) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // ── Mode helpers ─────────────────────────────────────────────────────────────
  void _enterViewMode(Map<String, dynamic> record, {bool viewOnly = true}) {
    setState(() {
      _selectedRecord = record;
      _formData.clear();
      _formData['orgCode'] = record['orgCode'] ?? 50;
      _formData['userCode'] = record['userCode'] ?? '';
      _formData['productCode'] = record['productCode'] ?? '';
      _formData['accessCode'] = record['accessCode'] ?? '';
      _formData['status'] = record['status'] ?? 1;
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
      _formData['userCode'] = '';
      _formData['productCode'] = '';
      _formData['accessCode'] = '';
      _formData['status'] = 1;
      _showForm = true;
      _isViewOnly = false;
      _isEditMode = false;
    });
  }

  // ── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (_fieldsKey.currentState?.validate() == false) return;

    setState(() => _isSaving = true);
    try {
      String trunc(String? v, int max) =>
          (v ?? '').length > max ? (v ?? '').substring(0, max) : (v ?? '');

      final payload = {
        'orgCode': _formData['orgCode'],
        'userCode': trunc(_formData['userCode']?.toString(), 20),
        'productCode': trunc(_formData['productCode']?.toString(), 20),
        'accessCode': trunc(_formData['accessCode']?.toString(), 50),
        'status': _formData['status'],
        'eUser': widget.userName ?? 'ADMIN',
        'eDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };

      final success =
          _isEditMode ? await _apiUpdate(payload) : await _apiCreate(payload);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'User Access ${_isEditMode ? 'updated' : 'created'} successfully'),
          ),
        );
        await _loadRecords();
        if (mounted) setState(() => _showForm = false);
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────
  void _confirmDelete(Map<String, dynamic> r) async {
    final userCode = r['userCode']?.toString() ?? '';
    final productCode = r['productCode']?.toString() ?? '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Access Mapping',
            style: bodyStyle(weight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete mapping for user "$userCode"?'),
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
      final success = await _apiDelete(userCode, productCode);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mapping deleted successfully')),
        );
        _loadRecords();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete operation failed.')),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
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

  // ── Identity Header ──────────────────────────────────────────────────────────
  Widget _buildIdentityHeader() {
    return AmsIdentityHeader(
      icon: const Icon(Icons.assignment_ind_rounded,
          size: 28, color: AppColors.tBlue),
      title: 'User Access Mapping',
      subtitle: '',
      badges: [],
      accentColor: AppColors.tBlue,
      accentLt: AppColors.tBlueLt,
      accentMd: AppColors.tBlueMd,
      breadcrumbs: [
        HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
        HeaderBreadcrumb(label: 'Masters', onTap: widget.onBackToModule),
        HeaderBreadcrumb(label: 'User Access Mapping'),
      ],
      onBack: _showForm
          ? () => setState(() => _showForm = false)
          : widget.onBackToModule,
    );
  }

  // ── List View ────────────────────────────────────────────────────────────────
  Widget _buildFullListView() {
    final filtered = _records.where((r) {
      final q = _searchQuery.toLowerCase();
      return (r['userCode'] ?? '').toString().toLowerCase().contains(q) ||
          (r['productCode'] ?? '').toString().toLowerCase().contains(q) ||
          (r['accessCode'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: AmsTextInput(
                    icon: Icons.search_rounded,
                    placeholder: 'Search by User / Product / Access Code...',
                    borderColor: AppColors.tBlue,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadRecords,
                ),
                const SizedBox(width: 16),
                AmsButton(
                  label: '+ Add New',
                  variant: AmsButtonVariant.primary,
                  onPressed: _createNew,
                ),
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
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_ind_outlined,
                size: 48, color: AppColors.ink4),
            const SizedBox(height: 12),
            Text('No access mappings found',
                style: bodyStyle(color: AppColors.ink3, size: 15)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final r = items[idx];
        final userCode = r['userCode']?.toString() ?? '—';
        final productCode = r['productCode']?.toString() ?? '—';
        final accessCode = r['accessCode']?.toString() ?? '—';
        final status = r['status']?.toString();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.tBlueLt,
                child: Text(
                  userCode.isNotEmpty ? userCode[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: AppColors.tBlue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('User: ',
                            style: bodyStyle(
                                color: AppColors.ink3,
                                size: 12,
                                weight: FontWeight.w500)),
                        Text(userCode,
                            style: bodyStyle(weight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _infoChip(
                            Icons.inventory_2_outlined, 'Product', productCode),
                        const SizedBox(width: 16),
                        _infoChip(Icons.vpn_key_outlined, 'Access', accessCode),
                      ],
                    ),
                  ],
                ),
              ),
              AmsBadge(
                label: (status == '0') ? 'Disabled' : 'Enabled',
                color: (status == '0') ? AppColors.red : AppColors.green,
                background:
                    (status == '0') ? AppColors.redLt : AppColors.greenLt,
              ),
              const SizedBox(width: 24),
              Row(children: [
                _actionIcon(
                  icon: Icons.visibility_outlined,
                  color: AppColors.green,
                  bg: Colors.white,
                  onTap: () => _enterViewMode(r),
                ),
                const SizedBox(width: 8),
                _actionIcon(
                  icon: Icons.edit_outlined,
                  color: AppColors.tBlue,
                  bg: Colors.white,
                  onTap: () => _enterViewMode(r, viewOnly: false),
                ),
                const SizedBox(width: 8),
                _actionIcon(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.red,
                  bg: AppColors.redLt,
                  onTap: () => _confirmDelete(r),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.ink3),
        const SizedBox(width: 4),
        Text('$label: ', style: bodyStyle(size: 11, color: AppColors.ink3)),
        Text(value, style: bodyStyle(size: 12, weight: FontWeight.w600)),
      ],
    );
  }

  // ── Entry / Form View ────────────────────────────────────────────────────────
  Widget _buildEntryView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.sidebar,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(children: [
              Icon(
                _isViewOnly ? Icons.visibility : Icons.add_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                _isViewOnly
                    ? 'Access Mapping Details'
                    : (_isEditMode
                        ? 'Edit Access Mapping'
                        : 'Create Access Mapping'),
                style: bodyStyle(color: Colors.white, weight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded,
                    color: Colors.white),
                onPressed: () => setState(() => _showForm = false),
              ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: UserAccessFields(
                key: _fieldsKey,
                isViewMode: _isViewOnly,
                initialData: _selectedRecord,
                onChanged: (k, v) => _formData[k] = v,
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
    return AmsSubmitBar(
      borderColor: AppColors.border,
      actions: [
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
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required Color bg,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildPaginationFooter(int total) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing 1–$total of $total',
              style: bodyStyle(size: 13, color: AppColors.ink3)),
          Row(children: [
            IconButton(
                icon: const Icon(Icons.chevron_left_rounded), onPressed: null),
            IconButton(
                icon: const Icon(Icons.chevron_right_rounded), onPressed: null),
          ]),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UserAccessFields  — the form body widget
// ═══════════════════════════════════════════════════════════════════════════════

class UserAccessFields extends StatefulWidget {
  final bool isViewMode;
  final Map<String, dynamic>? initialData;
  final void Function(String, dynamic) onChanged;
  final BuildContext parentContext;

  const UserAccessFields({
    super.key,
    required this.isViewMode,
    this.initialData,
    required this.onChanged,
    required this.parentContext,
  });

  @override
  State<UserAccessFields> createState() => UserAccessFieldsState();
}

class UserAccessFieldsState extends State<UserAccessFields> {
  // ── Controllers ──────────────────────────────────────────────────────────────
  final _orgCodeCtrl = TextEditingController(text: '50');

  int _status = 1;
  final Map<String, String?> _errors = {};

  // ── Dropdown state ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _userList = [];
  List<Map<String, dynamic>> _accessList = [];
  bool _loadingDropdowns = true;

  // ── Selected raw values (stored for payload) ─────────────────────────────────
  String? _selectedUserCode; // e.g. "USR001"
  String? _selectedAccessCode; // e.g. "ACC001"

  // ── Dropdown display values ──────────────────────────────────────────────────
  String? _selectedUserDisplay; // e.g. "USR001 - John Doe"
  String? _selectedAccessDisplay; // e.g. "ACC001 - Admin Access"

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  @override
  void didUpdateWidget(covariant UserAccessFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _applyInitialData();
    }
  }

  @override
  void dispose() {
    _orgCodeCtrl.dispose();
    super.dispose();
  }

  // ── Fetch dropdown data from API ─────────────────────────────────────────────
  Future<void> _fetchDropdownData() async {
    setState(() => _loadingDropdowns = true);
    try {
      // ── Users: apiService.getUsers() → usersCd, fName, lName ────────────────
      final usersResult = await apiService.getUsers(size: 200);
      // ── Access/Roles: apiService.getRoles() → accessCd, accessName ──────────
      final rolesResult = await apiService.getRoles(size: 200);

      if (mounted) {
        setState(() {
          _userList = usersResult?.items ?? [];
          _accessList = rolesResult?.items ?? [];
          _loadingDropdowns = false;
        });
        // Now apply initial data (needs lists to resolve display labels)
        _applyInitialData();
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDropdowns = false);
    }
  }

  // ── Populate fields from initialData ─────────────────────────────────────────
  void _applyInitialData() {
    final d = widget.initialData;
    if (d == null || d.isEmpty) {
      clear();
      return;
    }

    _orgCodeCtrl.text = (d['orgCode'] ?? d['orgcode'] ?? 50).toString();
    _status = int.tryParse((d['status'] ?? 1).toString()) ?? 1;

    // ── Resolve User Code display label ──────────────────────────────────────
    final rawUserCode = (d['userCode'] ?? d['usercode'] ?? '').toString();
    _selectedUserCode = rawUserCode.isNotEmpty ? rawUserCode : null;
    _selectedUserDisplay = _resolveUserDisplay(rawUserCode);

    // ── Resolve Access Code display label ────────────────────────────────────
    final rawAccessCode = (d['accessCode'] ?? d['accesscode'] ?? '').toString();
    _selectedAccessCode = rawAccessCode.isNotEmpty ? rawAccessCode : null;
    _selectedAccessDisplay = _resolveAccessDisplay(rawAccessCode);

    _errors.clear();
    if (mounted) setState(() {});
  }

  /// Returns "USR001 - John Doe" given "USR001"
  String? _resolveUserDisplay(String? code) {
    if (code == null || code.isEmpty) return null;
    final match = _userList.firstWhere(
      (u) =>
          (u['usersCd'] ?? u['userScd'] ?? u['USERSCD'] ?? '').toString() ==
          code,
      orElse: () => {},
    );
    if (match.isEmpty) return null;
    final cd = match['usersCd'] ?? match['userScd'] ?? match['USERSCD'] ?? '';
    final fn = match['fName'] ?? match['fname'] ?? match['FNAME'] ?? '';
    final ln = match['lName'] ?? match['lname'] ?? match['LNAME'] ?? '';
    final fullName = '$fn $ln'.trim();
    return '$cd${fullName.isNotEmpty ? ' - $fullName' : ''}';
  }

  /// Returns "ACC001 - Admin Access" given "ACC001"
  String? _resolveAccessDisplay(String? code) {
    if (code == null || code.isEmpty) return null;
    final match = _accessList.firstWhere(
      (a) =>
          (a['accessCd'] ?? a['accesscd'] ?? a['roleCd'] ?? a['rolecd'] ?? '')
              .toString() ==
          code,
      orElse: () => {},
    );
    if (match.isEmpty) return null;
    final cd = match['accessCd'] ??
        match['accesscd'] ??
        match['roleCd'] ??
        match['rolecd'] ??
        '';
    final name = match['access_name'] ??
        match['accessname'] ??
        match['roleName'] ??
        match['rolename'] ??
        '';
    return '$cd${name.toString().isNotEmpty ? ' - $name' : ''}';
  }

  // ── Build user dropdown items ─────────────────────────────────────────────
  List<String> get _userDropdownItems {
    return _userList
        .map((u) {
          final cd = u['usersCd'] ?? u['userScd'] ?? u['USERSCD'] ?? '';
          final fn = u['fName'] ?? u['fname'] ?? u['FNAME'] ?? '';
          final ln = u['lName'] ?? u['lname'] ?? u['LNAME'] ?? '';
          final fullName = '$fn $ln'.trim();
          return '$cd${fullName.isNotEmpty ? ' - $fullName' : ''}';
        })
        .toSet()
        .toList()
      ..sort();
  }

  // ── Build access dropdown items ───────────────────────────────────────────
  List<String> get _accessDropdownItems {
    return _accessList
        .map((a) {
          final cd = a['accessCd'] ??
              a['accesscd'] ??
              a['roleCd'] ??
              a['rolecd'] ??
              '';
          final name = a['access_name'] ??
              a['accessname'] ??
              a['roleName'] ??
              a['rolename'] ??
              '';
          return '$cd${name.toString().isNotEmpty ? ' - $name' : ''}';
        })
        .toSet()
        .toList()
      ..sort();
  }

  // ── Clear ────────────────────────────────────────────────────────────────────
  void clear() {
    _orgCodeCtrl.text = '50';
    _selectedUserCode = null;
    _selectedUserDisplay = null;
    _selectedAccessCode = null;
    _selectedAccessDisplay = null;
    _status = 1;
    _errors.clear();
    if (mounted) setState(() {});
  }

  // ── Validate ─────────────────────────────────────────────────────────────────
  bool validate() {
    bool ok = true;
    setState(() {
      if (_orgCodeCtrl.text.trim().isEmpty) {
        _errors['orgCode'] = 'Organisation Code is required';
        ok = false;
      } else {
        _errors['orgCode'] = null;
      }

      if (_selectedUserCode == null || _selectedUserCode!.isEmpty) {
        _errors['userCode'] = 'User Code is required';
        ok = false;
      } else {
        _errors['userCode'] = null;
      }

      if (_selectedAccessCode == null || _selectedAccessCode!.isEmpty) {
        _errors['accessCode'] = 'Access Code is required';
        ok = false;
      } else {
        _errors['accessCode'] = null;
      }
    });
    return ok;
  }

  // ── Build ────────────────────────────────────────────────────────────────────
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
          // ── Section: Identification ──────────────────────────────────────────
          sectionTitle('Identification', color: AppColors.tBlue),
          const SizedBox(height: 16),

          AmsFormGrid(
            children: [
              // Organisation Code
              AmsField(
                label: 'Organisation Code',
                required: true,
                labelAbove: true,
                tooltip: 'Numeric organisation code (e.g. 50).',
                child: AmsTextInput(
                  controller: _orgCodeCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. 50',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  errorText: _errors['orgCode'],
                  isValid: _errors['orgCode'] == null &&
                      _orgCodeCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['orgCode'] = v.trim().isEmpty
                          ? 'Organisation Code is required'
                          : null;
                    });
                    widget.onChanged('orgCode', int.tryParse(v) ?? 50);
                  },
                ),
              ),

              // ─── User Code — DROPDOWN ───────────────────────────────────────
              AmsField(
                label: 'User Code',
                required: true,
                labelAbove: true,
                tooltip: 'Select the user (UserCD - First Last).',
                child: _loadingDropdowns
                    ? const LinearProgressIndicator()
                    : widget.isViewMode
                        // View mode: show plain text
                        ? AmsTextInput(
                            initialValue:
                                _selectedUserDisplay ?? _selectedUserCode ?? '',
                            readOnly: true,
                          )
                        // Edit / Create mode: show dropdown
                        : AmsDropdown(
                            initialValue: _selectedUserDisplay,
                            placeholder: 'Select User',
                            items: _userDropdownItems,
                            errorText: _errors['userCode'],
                            isValid: _errors['userCode'] == null &&
                                _selectedUserCode != null,
                            onChanged: (v) {
                              // Extract raw code before " - "
                              final code = v?.split(' - ').first.trim() ?? '';
                              setState(() {
                                _selectedUserDisplay = v;
                                _selectedUserCode =
                                    code.isNotEmpty ? code : null;
                                _errors['userCode'] = code.isEmpty
                                    ? 'User Code is required'
                                    : null;
                              });
                              widget.onChanged('userCode', code);
                            },
                          ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Section: Product & Access ────────────────────────────────────────
          sectionTitle('Product & Access', color: AppColors.tBlue),
          const SizedBox(height: 16),

          AmsFormGrid(
            children: [
              // Product Code  (plain text — no dropdown needed per requirement)
              AmsField(
                label: 'Product Code',
                required: true,
                labelAbove: true,
                tooltip: 'Product code this user is mapped to (e.g. PROD001).',
                child: AmsTextInput(
                  initialValue:
                      widget.initialData?['productCode']?.toString() ??
                          widget.initialData?['productcode']?.toString() ??
                          '',
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. PROD001',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['productCode'],
                  isValid: _errors['productCode'] == null,
                  onChanged: (v) {
                    setState(() {
                      _errors['productCode'] =
                          v.trim().isEmpty ? 'Product Code is required' : null;
                    });
                    widget.onChanged('productCode', v.trim());
                  },
                ),
              ),

              // ─── Access Code — DROPDOWN ──────────────────────────────────────
              AmsField(
                label: 'Access Code',
                required: true,
                labelAbove: true,
                tooltip: 'Select the access/role (AccessCD - Name).',
                child: _loadingDropdowns
                    ? const LinearProgressIndicator()
                    : widget.isViewMode
                        // View mode: plain text
                        ? AmsTextInput(
                            initialValue: _selectedAccessDisplay ??
                                _selectedAccessCode ??
                                '',
                            readOnly: true,
                          )
                        // Edit / Create mode: dropdown
                        : AmsDropdown(
                            initialValue: _selectedAccessDisplay,
                            placeholder: 'Select Access',
                            items: _accessDropdownItems,
                            errorText: _errors['accessCode'],
                            isValid: _errors['accessCode'] == null &&
                                _selectedAccessCode != null,
                            onChanged: (v) {
                              final code = v?.split(' - ').first.trim() ?? '';
                              setState(() {
                                _selectedAccessDisplay = v;
                                _selectedAccessCode =
                                    code.isNotEmpty ? code : null;
                                _errors['accessCode'] = code.isEmpty
                                    ? 'Access Code is required'
                                    : null;
                              });
                              widget.onChanged('accessCode', code);
                            },
                          ),
              ),

              // Status
              AmsField(
                label: 'Status',
                required: true,
                labelAbove: true,
                tooltip: 'Enable or disable this access mapping.',
                child: widget.isViewMode
                    ? AmsTextInput(
                        initialValue:
                            _status == 1 ? '1 - Enable' : '0 - Disable',
                        readOnly: true,
                      )
                    : AmsDropdown(
                        initialValue:
                            _status == 1 ? '1 - Enable' : '0 - Disable',
                        items: const ['1 - Enable', '0 - Disable'],
                        onChanged: (v) {
                          final s = v?.startsWith('1') == true ? 1 : 0;
                          setState(() => _status = s);
                          widget.onChanged('status', s);
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
