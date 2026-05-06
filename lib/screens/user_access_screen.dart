import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../services/user_mapping_service.dart';
import '../services/org_api_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// UserAccessScreen  (Table: USER004)
// Fields: orgCode, userScd, prodCode, accessCd, status
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
  int _currentPage = 1;
  int _totalItems = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _records = [];
  String _searchQuery = '';
  final _fieldsKey = GlobalKey<UserAccessFieldsState>();
  Map<String, dynamic>? _selectedRecord;
  final Map<String, dynamic> _formData = {};
  bool _isSaving = false;

  Future<void> _loadRecords({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _currentPage = page;
    });
    try {
      final res = await userMappingService.getAll(page: page - 1, size: 10);
      if (mounted) {
        setState(() {
          _records = res?.items.map((m) => m.toScreenMap()).toList() ?? [];
          _totalItems = res?.totalElements ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnack('Failed to load records: $e', isError: true);
    }
  }

  Future<bool> _apiCreate(Map<String, dynamic> payload) async {
    final model = _payloadToModel(payload);
    return userMappingService.create(model, currentUser: widget.userName);
  }

  Future<bool> _apiUpdate(Map<String, dynamic> payload) async {
    final model = _payloadToModel(payload);
    return userMappingService.update(model, currentUser: widget.userName);
  }

  Future<bool> _apiDelete(String userScd) async {
    return userMappingService.delete(userScd);
  }

  UserMappingModel _payloadToModel(Map<String, dynamic> p) {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return UserMappingModel(
      orgCode: int.tryParse(p['orgCode']?.toString() ?? '') ?? 50,
      userScd: p['userCode']?.toString() ?? '',
      prodCode: int.tryParse(p['productCode']?.toString() ?? '') ?? 0,
      accessCd: int.tryParse(p['accessCode']?.toString() ?? '') ?? 0,
      status: (p['status'] ?? 1).toString(),
      eUser: widget.userName ?? 'ADMIN',
      eDate: now,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRecords(page: 1);
  }

  void _enterViewMode(Map<String, dynamic> record, {bool viewOnly = true}) {
    setState(() {
      _selectedRecord = record;
      _formData
        ..clear()
        ..['orgCode'] = record['orgCode'] ?? 50
        ..['userCode'] = record['userCode'] ?? ''
        ..['productCode'] = record['productCode'] ?? ''
        ..['accessCode'] = record['accessCode'] ?? ''
        ..['status'] = record['status'] ?? 1;
      _showForm = true;
      _isViewOnly = viewOnly;
      _isEditMode = !viewOnly;
    });
  }

  void _createNew() {
    setState(() {
      _selectedRecord = null;
      _formData
        ..clear()
        ..['orgCode'] = 50
        ..['userCode'] = ''
        ..['productCode'] = ''
        ..['accessCode'] = ''
        ..['status'] = 1;
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
      String trunc(String? v, int max) =>
          (v ?? '').length > max ? (v ?? '').substring(0, max) : (v ?? '');

      final payload = {
        'orgCode': _formData['orgCode'],
        'userCode': trunc(_formData['userCode']?.toString(), 20),
        'productCode': trunc(_formData['productCode']?.toString(), 20),
        'accessCode': trunc(_formData['accessCode']?.toString(), 50),
        'status': _formData['status'],
      };

      final success =
          _isEditMode ? await _apiUpdate(payload) : await _apiCreate(payload);

      if (success) {
        _showSnack(
            'User Access ${_isEditMode ? 'updated' : 'created'} successfully');
        await _loadRecords();
        if (mounted) setState(() => _showForm = false);
      } else {
        _showSnack('Operation failed. Please check field values.',
            isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDelete(Map<String, dynamic> r) async {
    final userCode = r['userCode']?.toString() ?? '';

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
      final success = await _apiDelete(userCode);
      if (success) {
        _showSnack('Mapping deleted successfully');
        _loadRecords();
      } else {
        _showSnack('Delete operation failed.', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.red : null,
      ),
    );
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
                  onPressed: () => _loadRecords(page: 1),
                  tooltip: 'Refresh',
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
            child: AmsPaginatedView<Map<String, dynamic>>(
              items: filtered,
              totalRecords: _totalItems,
              currentPage: _currentPage,
              onPageChanged: (page) => _loadRecords(page: page),
              builder: (ctx, items) => _buildListTable(items),
            ),
          ),
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
                    Row(children: [
                      Text('User: ',
                          style: bodyStyle(
                              color: AppColors.ink3,
                              size: 12,
                              weight: FontWeight.w500)),
                      Text(userCode, style: bodyStyle(weight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      _infoChip(
                          Icons.inventory_2_outlined, 'Product', productCode),
                      const SizedBox(width: 16),
                      _infoChip(Icons.vpn_key_outlined, 'Access', accessCode),
                    ]),
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
        ],
      ],
    );
  }

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
}

// ═══════════════════════════════════════════════════════════════════════════════
// UserAccessFields
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
  // ── Org-code searchable overlay ──────────────────────────────────────────
  final _orgCodeCtrl = TextEditingController();
  final _orgSearchCtrl = TextEditingController();
  final _orgLayerLink = LayerLink();
  OverlayEntry? _orgOverlay;
  List<Map<String, dynamic>> _orgList = [];
  bool _orgLoading = false;
  int? _selectedOrgCode;

  // ── Other field state ────────────────────────────────────────────────────
  int _status = 1;
  final Map<String, String?> _errors = {};

  // ── ALL users + roles fetched once (unfiltered master lists) ─────────────
  List<Map<String, dynamic>> _allUserList = [];
  List<Map<String, dynamic>> _allAccessList = [];

  // ── Filtered by selected org (what dropdowns actually show) ──────────────
  List<Map<String, dynamic>> _userList = [];
  List<Map<String, dynamic>> _accessList = [];

  bool _loadingDropdowns = true;

  String? _selectedUserCode;
  String? _selectedAccessCode;
  String? _selectedUserDisplay;
  String? _selectedAccessDisplay;

  final _productCodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrganisations();
    _fetchDropdownData(); // fetch all users + roles once
  }

  @override
  void didUpdateWidget(covariant UserAccessFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) _applyInitialData();
  }

  @override
  void dispose() {
    _removeOrgOverlay();
    _orgCodeCtrl.dispose();
    _orgSearchCtrl.dispose();
    _productCodeCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ORG CODE – fetch + searchable overlay
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadOrganisations() async {
    if (_orgLoading || _orgList.isNotEmpty) return;
    setState(() => _orgLoading = true);
    try {
      final res = await orgApiService.getAllOrganisations(page: 0, size: 200);
      if (res != null && mounted) {
        setState(() => _orgList = res.items);
        _applyInitialData();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _orgLoading = false);
    }
  }

  void _removeOrgOverlay() {
    _orgOverlay?.remove();
    _orgOverlay = null;
  }

  void _openOrgDropdown() {
    if (widget.isViewMode) return;
    _removeOrgOverlay();
    _orgSearchCtrl.text = '';

    _orgOverlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOrgOverlay,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _orgLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 52),
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(10),
                  shadowColor: Colors.black26,
                  child: StatefulBuilder(
                    builder: (ctx2, setInner) {
                      final query = _orgSearchCtrl.text.toLowerCase();
                      final filtered = _orgList.where((o) {
                        final code =
                            (o['orgcode'] ?? o['orgCode'] ?? '').toString();
                        final name = (o['name'] ?? '').toString().toLowerCase();
                        return code.contains(query) || name.contains(query);
                      }).toList();

                      return Container(
                        width: 360,
                        constraints: const BoxConstraints(maxHeight: 340),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: TextField(
                                controller: _orgSearchCtrl,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Search by code or name…',
                                  hintStyle: const TextStyle(
                                      color: AppColors.ink4, fontSize: 13),
                                  prefixIcon: const Icon(Icons.search,
                                      size: 18, color: AppColors.ink3),
                                  suffixIcon: _orgSearchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear,
                                              size: 16, color: AppColors.ink3),
                                          onPressed: () {
                                            _orgSearchCtrl.clear();
                                            setInner(() {});
                                          },
                                        )
                                      : null,
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
                            Flexible(
                              child: _orgLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.tBlue),
                                            SizedBox(height: 8),
                                            Text('Loading organisations…',
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
                                            'No organisations found',
                                            style: bodyStyle(
                                                color: AppColors.ink4),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: filtered.length,
                                          itemBuilder: (_, idx) {
                                            final org = filtered[idx];
                                            final code = (org['orgcode'] ??
                                                    org['orgCode'] ??
                                                    '')
                                                .toString();
                                            final name =
                                                (org['name'] ?? '').toString();
                                            final isSelected =
                                                _selectedOrgCode?.toString() ==
                                                    code;

                                            return InkWell(
                                              onTap: () {
                                                _selectOrg(org);
                                                _orgSearchCtrl.clear();
                                                _removeOrgOverlay();
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 11),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppColors.tBlueLt
                                                          .withValues(
                                                              alpha: 0.15)
                                                      : Colors.transparent,
                                                  border: idx <
                                                          filtered.length - 1
                                                      ? const Border(
                                                          bottom: BorderSide(
                                                              color: AppColors
                                                                  .border,
                                                              width: 0.5))
                                                      : null,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? AppColors.tBlue
                                                            : AppColors.tBlueLt,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Text(
                                                        code,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isSelected
                                                              ? Colors.white
                                                              : AppColors.tBlue,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        style:
                                                            bodyStyle(size: 13),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      const Icon(
                                                          Icons.check_rounded,
                                                          size: 16,
                                                          color:
                                                              AppColors.tBlue),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                            ),
                            if (!_orgLoading && _orgList.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: AppColors.bg,
                                  border: Border(
                                      top: BorderSide(
                                          color: AppColors.border, width: 0.5)),
                                  borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(10)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded,
                                        size: 13, color: AppColors.ink3),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${filtered.length} of ${_orgList.length} organisations',
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.ink3),
                                    ),
                                  ],
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
      ),
    );

    Overlay.of(context).insert(_orgOverlay!);
  }

  // ── CHANGED: org select → client-side filter dependent dropdowns ──────────
  void _selectOrg(Map<String, dynamic> org) {
    final code = (org['orgcode'] ?? org['orgCode'] ?? '').toString();
    final name = (org['name'] ?? '').toString();
    final newOrgCode = int.tryParse(code);

    setState(() {
      _selectedOrgCode = newOrgCode;
      _orgCodeCtrl.text = name.isNotEmpty ? '$code – $name' : code;
      _errors['orgCode'] = null;

      // Reset dependent selections when org changes
      _selectedUserCode = null;
      _selectedUserDisplay = null;
      _selectedAccessCode = null;
      _selectedAccessDisplay = null;

      // Client-side filter: show only records whose orgcode matches
      _applyOrgFilter(newOrgCode);
    });

    widget.onChanged('orgCode', newOrgCode ?? 50);
  }

  // ── NEW: filter _allUserList and _allAccessList by orgCode ────────────────
  void _applyOrgFilter(int? orgCode) {
    if (orgCode == null) {
      // No org selected → show nothing (or all, your choice)
      _userList = [];
      _accessList = [];
      return;
    }
    final orgStr = orgCode.toString();
    _userList = _allUserList.where((u) {
      final uOrg = (u['orgcode'] ?? u['orgCode'] ?? '').toString();
      return uOrg == orgStr;
    }).toList();
    _accessList = _allAccessList.where((a) {
      final aOrg = (a['orgcode'] ?? a['orgCode'] ?? '').toString();
      return aOrg == orgStr;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dropdowns: fetch ALL users + roles once, filter client-side by org
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _fetchDropdownData() async {
    setState(() => _loadingDropdowns = true);
    try {
      final usersResult = await apiService.getUsers(size: 200);
      final rolesResult = await apiService.getRoles(size: 200);
      if (mounted) {
        setState(() {
          // Store full master lists
          _allUserList = usersResult?.items ?? [];
          _allAccessList = rolesResult?.items ?? [];
          _loadingDropdowns = false;

          // Apply filter if an org is already selected (edit/view mode)
          _applyOrgFilter(_selectedOrgCode);
        });
        _applyInitialData();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDropdowns = false);
    }
  }

  void _applyInitialData() {
    final d = widget.initialData;
    if (d == null || d.isEmpty) {
      clear();
      return;
    }

    // Org code
    final rawOrg = (d['orgCode'] ?? d['orgcode'] ?? 50).toString();
    _selectedOrgCode = int.tryParse(rawOrg);
    if (_orgList.isNotEmpty && _selectedOrgCode != null) {
      final match = _orgList.firstWhere(
          (o) => (o['orgcode'] ?? o['orgCode'] ?? '').toString() == rawOrg,
          orElse: () => {});
      final orgName = (match['name'] ?? '').toString();
      _orgCodeCtrl.text = orgName.isNotEmpty ? '$rawOrg – $orgName' : rawOrg;
    } else {
      _orgCodeCtrl.text = rawOrg;
    }

    // Apply org filter so dropdowns show correct items for this org
    _applyOrgFilter(_selectedOrgCode);

    _status = int.tryParse((d['status'] ?? 1).toString()) ?? 1;

    final rawProd =
        (d['productCode'] ?? d['prodCode'] ?? d['prodcode'] ?? '').toString();
    _productCodeCtrl.text = rawProd;

    final rawUserCode = (d['userCode'] ?? d['usercode'] ?? '').toString();
    _selectedUserCode = rawUserCode.isNotEmpty ? rawUserCode : null;
    _selectedUserDisplay = _resolveUserDisplay(rawUserCode);

    final rawAccessCode = (d['accessCode'] ?? d['accesscode'] ?? '').toString();
    _selectedAccessCode = rawAccessCode.isNotEmpty ? rawAccessCode : null;
    _selectedAccessDisplay = _resolveAccessDisplay(rawAccessCode);

    _errors.clear();
    if (mounted) setState(() {});
  }

  String? _resolveUserDisplay(String? code) {
    if (code == null || code.isEmpty) return null;
    // Search in filtered list first, fallback to full list
    final list = _userList.isNotEmpty ? _userList : _allUserList;
    final match = list.firstWhere(
      (u) => (u['usersCd'] ?? u['userScd'] ?? '').toString() == code,
      orElse: () => {},
    );
    if (match.isEmpty) return null;
    final cd = match['usersCd'] ?? match['userScd'] ?? '';
    final fn = (match['fName'] ?? match['fname'] ?? '').toString();
    final ln = (match['lName'] ?? match['lname'] ?? '').toString();
    final fullName = '$fn $ln'.trim();
    return '$cd${fullName.isNotEmpty ? ' - $fullName' : ''}';
  }

  String? _resolveAccessDisplay(String? code) {
    if (code == null || code.isEmpty) return null;
    // Search in filtered list first, fallback to full list
    final list = _accessList.isNotEmpty ? _accessList : _allAccessList;
    final match = list.firstWhere(
      (a) =>
          (a['accessCd'] ?? a['accesscd'] ?? a['roleCd'] ?? '').toString() ==
          code,
      orElse: () => {},
    );
    if (match.isEmpty) return null;
    final cd = (match['accessCd'] ?? match['roleCd'] ?? '').toString();
    final name = (match['access_name'] ?? match['roleName'] ?? '').toString();
    return '$cd${name.isNotEmpty ? ' - $name' : ''}';
  }

  // Dropdown items come from org-filtered list
  List<String> get _userDropdownItems => _userList
      .map((u) {
        final cd = (u['usersCd'] ?? u['userScd'] ?? '').toString();
        final fn = (u['fName'] ?? u['fname'] ?? '').toString();
        final ln = (u['lName'] ?? u['lname'] ?? '').toString();
        final fullName = '$fn $ln'.trim();
        return '$cd${fullName.isNotEmpty ? ' - $fullName' : ''}';
      })
      .toSet()
      .toList()
    ..sort();

  List<String> get _accessDropdownItems => _accessList
      .map((a) {
        final cd = (a['accessCd'] ?? a['roleCd'] ?? '').toString();
        final name = (a['access_name'] ?? a['roleName'] ?? '').toString();
        return '$cd${name.isNotEmpty ? ' - $name' : ''}';
      })
      .toSet()
      .toList()
    ..sort();

  void clear() {
    _orgCodeCtrl.text = '';
    _selectedOrgCode = null;
    _productCodeCtrl.text = '';
    _selectedUserCode = null;
    _selectedUserDisplay = null;
    _selectedAccessCode = null;
    _selectedAccessDisplay = null;
    _userList = [];
    _accessList = [];
    _status = 1;
    _errors.clear();
    if (mounted) setState(() {});
  }

  bool validate() {
    bool ok = true;
    setState(() {
      _errors['orgCode'] =
          (_selectedOrgCode == null && _orgCodeCtrl.text.trim().isEmpty)
              ? 'Organisation Code is required'
              : null;
      if (_errors['orgCode'] != null) ok = false;

      _errors['userCode'] =
          (_selectedUserCode ?? '').isEmpty ? 'User Code is required' : null;
      if (_errors['userCode'] != null) ok = false;

      _errors['productCode'] = _productCodeCtrl.text.trim().isEmpty
          ? 'Product Code is required'
          : null;
      if (_errors['productCode'] != null) ok = false;

      _errors['accessCode'] = (_selectedAccessCode ?? '').isEmpty
          ? 'Access Code is required'
          : null;
      if (_errors['accessCode'] != null) ok = false;
    });
    return ok;
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
          sectionTitle('Identification', color: AppColors.tBlue),
          const SizedBox(height: 16),
          AmsFormGrid(
            children: [
              // ── ORGANISATION CODE ─────────────────────────────────────────
              AmsField(
                label: 'Organisation Code',
                required: true,
                labelAbove: true,
                tooltip: 'Select the parent organisation.',
                child: CompositedTransformTarget(
                  link: _orgLayerLink,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.isViewMode ? null : _openOrgDropdown,
                    child: AbsorbPointer(
                      child: AmsTextInput(
                        controller: _orgCodeCtrl,
                        readOnly: true,
                        placeholder: _orgLoading
                            ? 'Loading organisations…'
                            : 'Select Organisation',
                        icon: _orgLoading
                            ? Icons.hourglass_empty_rounded
                            : Icons.business_rounded,
                        errorText: _errors['orgCode'],
                        isValid: _errors['orgCode'] == null &&
                            _orgCodeCtrl.text.isNotEmpty,
                      ),
                    ),
                  ),
                ),
              ),

              // ── USER CODE – filtered by selected org ──────────────────────
              AmsField(
                label: 'User Code',
                required: true,
                labelAbove: true,
                tooltip: 'Select the user.',
                child: _loadingDropdowns
                    ? const LinearProgressIndicator()
                    : widget.isViewMode
                        ? AmsTextInput(
                            initialValue:
                                _selectedUserDisplay ?? _selectedUserCode ?? '',
                            readOnly: true,
                          )
                        : AmsDropdown(
                            initialValue: _selectedUserDisplay,
                            placeholder: _selectedOrgCode == null
                                ? 'Select Organisation first'
                                : _userList.isEmpty
                                    ? 'No users for this org'
                                    : 'Select User',
                            items: _userDropdownItems,
                            errorText: _errors['userCode'],
                            isValid: _errors['userCode'] == null &&
                                _selectedUserCode != null,
                            onChanged: (v) {
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
          sectionTitle('Product & Access', color: AppColors.tBlue),
          const SizedBox(height: 16),
          AmsFormGrid(
            children: [
              // Product Code
              AmsField(
                label: 'Product Code',
                required: true,
                labelAbove: true,
                tooltip: 'Numeric product code (e.g. 1001).',
                child: AmsTextInput(
                  controller: _productCodeCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. 1001',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  errorText: _errors['productCode'],
                  isValid: _errors['productCode'] == null &&
                      _productCodeCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['productCode'] =
                          v.trim().isEmpty ? 'Product Code is required' : null;
                    });
                    widget.onChanged('productCode', v.trim());
                  },
                ),
              ),

              // ── ACCESS CODE – filtered by selected org ────────────────────
              AmsField(
                label: 'Access Code',
                required: true,
                labelAbove: true,
                tooltip: 'Select the access/role.',
                child: _loadingDropdowns
                    ? const LinearProgressIndicator()
                    : widget.isViewMode
                        ? AmsTextInput(
                            initialValue: _selectedAccessDisplay ??
                                _selectedAccessCode ??
                                '',
                            readOnly: true,
                          )
                        : AmsDropdown(
                            initialValue: _selectedAccessDisplay,
                            placeholder: _selectedOrgCode == null
                                ? 'Select Organisation first'
                                : _accessList.isEmpty
                                    ? 'No roles for this org'
                                    : 'Select Access',
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
