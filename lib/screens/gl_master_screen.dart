import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../services/org_api_service.dart';
import '../utils/responsive.dart';

class GLMasterScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const GLMasterScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<GLMasterScreen> createState() => _GLMasterScreenState();
}

class _GLMasterScreenState extends State<GLMasterScreen> {
  String _searchQuery = '';
  bool _showForm = false;
  String? _selectedCategoryName; // Display name shown in dropdown
  int? _selectedCategoryCd; // Actual glCatCd sent to API
  String? _selectedStatus; // 'Active' / 'Inactive'
  bool _isViewOnly = false;
  bool _isEditing = false; // true = Edit mode, false = Create mode
  Map<String, dynamic> _editingRecord = {}; // original record for audit field preservation
  int _currentPage = 1;
  static const int _pageSize = 10;
  // When backend returns the full list despite page/size, cache it here so
  // subsequent page navigation can be served from the cache without extra requests.
  List<Map<String, dynamic>>? _backendFullGlMasters;

  // ── Loading / Error ──────────────────────────────────────────────────
  bool _loadingList = false;
  bool _loadingCategories = false;
  bool _saving = false;
  String? _listError;

  // ── Data ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _categoryList = []; // [{glCatCd, glCatName, ...}]
  int _totalItems = 0;

  // ── Controllers & Focus ──────────────────────────────────────────────
  final _orgCodeController = TextEditingController();

  // ── Org-code searchable dropdown ───────────────────────────────────────────
  final _orgSearchCtrl = TextEditingController(); // search text inside overlay
  final _orgLayerLink = LayerLink();
  OverlayEntry? _orgOverlay;
  List<Map<String, dynamic>> _orgList = [];
  bool _orgLoading = false;
  int? _selectedOrgCode;
  final _glNumberController = TextEditingController();
  final _glNameController = TextEditingController();

  final _orgFocus = FocusNode();
  final _glNumberFocus = FocusNode();
  final _glNameFocus = FocusNode();
  final _categoryFocus = FocusNode();
  final _statusFocus = FocusNode();

  // ── Validation errors ────────────────────────────────────────────────
  String? _orgError;
  String? _glNumberError;
  String? _glNameError;
  String? _categoryError;
  String? _statusError;

  // ─────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _orgCodeController.addListener(_onFormChange);
    _glNumberController.addListener(_onFormChange);
    _glNameController.addListener(_onFormChange);
    _loadOrganisations();
    _loadCategories();
    _loadGlMasters();
  }

  @override
  void dispose() {
    _orgCodeController.dispose();
    _orgSearchCtrl.dispose();
    _orgOverlay?.remove();
    _glNumberController.dispose();
    _glNameController.dispose();
    _orgFocus.dispose();
    _glNumberFocus.dispose();
    _glNameFocus.dispose();
    _categoryFocus.dispose();
    _statusFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // API Calls
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _loadCategories({int page = 1}) async {
    setState(() => _loadingCategories = true);
    final result = await apiService.getAllGlCategories(page: page - 1, size: _pageSize);
    setState(() {
      _loadingCategories = false;
      _categoryList = result?.items ?? [];
    });
  }

  Future<void> _loadGlMasters({int page = 1}) async {
    setState(() {
      _loadingList = true;
      _listError = null;
      _currentPage = page;
    });
    // If we previously detected the backend returned a full list and cached it,
    // serve from cache instead of making another network request.
    if (_backendFullGlMasters != null) {
      final cache = _backendFullGlMasters!;
      _loadingList = false;
      _totalItems = cache.length;
      final startIndex = (page - 1) * _pageSize;
      final pageItems = cache.skip(startIndex).take(_pageSize).toList();
      setState(() {
        _accounts = pageItems;
        _loadingList = false;
      });
      return;
    }

    final result = await apiService.getAllGlMasters(page: page - 1, size: _pageSize);
    setState(() {
      _loadingList = false;
      if (result != null) {
        // Detect backend returning full list ignoring page/size.
        final bool backendReturnedFullList =
            result.items.length > _pageSize && result.totalElements == result.items.length;

        _totalItems = result.totalElements;

        if (backendReturnedFullList) {
          // Cache the full list so subsequent page clicks can be served from cache
          // without re-requesting the API which incorrectly returns all items.
          _backendFullGlMasters = result.items.reversed.toList();
          final startIndex = (page - 1) * _pageSize;
          _accounts = _backendFullGlMasters!.skip(startIndex).take(_pageSize).toList();
        } else {
          _accounts = result.items.reversed.toList();
        }
      } else {
        _listError = 'Failed to load GL Master records.';
      }
    });
  }

  Future<void> _saveGlMaster() async {
    if (!_isFormValid) {
      _validateAll();
      return;
    }

    setState(() => _saving = true);

    // ── Compute audit fields ─────────────────────────────────────────────
    String nowIso =
        "${DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(DateTime.now().toUtc())}+00:00";
    String cleanUser = (widget.userName ?? 'admin');
    if (cleanUser.contains('@')) cleanUser = cleanUser.split('@').first;

    final orig = _editingRecord;

    // creator — preserved on edit, set on create
    String cUserVal = _isEditing
        ? (orig['cUser'] ?? orig['cuser'] ?? cleanUser).toString()
        : cleanUser;
    String cDateVal = _isEditing
        ? (orig['cDate'] ?? orig['cdate'] ?? nowIso).toString()
        : nowIso;

    // last editor — always current user/time
    String eUserVal = cleanUser;
    String eDateVal = nowIso;

    // approver — preserve existing DB value on edit; default to eUser on create
    String aUserVal = _isEditing
        ? (orig['aUser'] ?? orig['auser'] ?? eUserVal).toString()
        : eUserVal;
    String aDateVal = _isEditing
        ? (orig['aDate'] ?? orig['adate'] ?? eDateVal).toString()
        : eDateVal;
    // ────────────────────────────────────────────────────────────────────

    final payload = {
      'orgCode': _selectedOrgCode ?? int.tryParse(_orgCodeController.text.split(' – ')[0]) ?? 0,
      'glNo': int.tryParse(_glNumberController.text.trim()) ?? 0,
      'glName': _glNameController.text.trim(),
      'glCatCd': _selectedCategoryCd ?? 0,
      'status': _selectedStatus == 'Active' ? 1 : 0,

      // ── Audit: creator ─────────────────────────────────────────────
      'cUser': cUserVal,  'cuser': cUserVal,
      'cDate': cDateVal,  'cdate': cDateVal,

      // ── Audit: last editor ────────────────────────────────────────
      'eUser': eUserVal,  'euser': eUserVal,
      'eDate': eDateVal,  'edate': eDateVal,

      // ── Audit: approver ───────────────────────────────────────────
      // Defaults to eUser so the table column is never null.
      'aUser': aUserVal,  'auser': aUserVal,
      'aDate': aDateVal,  'adate': aDateVal,
    };

    bool success;
    if (_isEditing) {
      success = await apiService.updateGlMaster(payload);
    } else {
      success = await apiService.createGlMaster(payload);
    }

    setState(() => _saving = false);

    if (!mounted) return;

    if (success) {
      _showSnack(
        _isEditing
            ? 'GL Master updated successfully'
            : 'GL Master created successfully',
        isError: false,
      );
      _clearFields();
      setState(() => _showForm = false);
        // Invalidate any cached full-list responses so the next load fetches fresh data.
        _backendFullGlMasters = null;
        await _loadGlMasters(page: 1); // Refresh to page 1 (first page only)
    } else {
      _showSnack(
        _isEditing
            ? 'Failed to update GL Master'
            : 'Failed to create GL Master',
        isError: true,
      );
    }
  }

  // ── Organisation logic ──────────────────────────────────────────────────────
  Future<void> _loadOrganisations() async {
    if (_orgLoading || _orgList.isNotEmpty) return;
    setState(() => _orgLoading = true);
    try {
      final res = await orgApiService.getAllOrganisations(page: 0, size: 200);
      if (res != null && mounted) {
        setState(() {
          _orgList = res.items;
          final cur = _orgCodeController.text.trim();
          if (cur.isNotEmpty) _refreshOrgDisplay(cur);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _orgLoading = false);
    }
  }

  void _refreshOrgDisplay(String orgCodeRaw) {
    if (orgCodeRaw.isEmpty) {
      _orgCodeController.clear();
      return;
    }
    if (_orgList.isNotEmpty) {
      try {
        final match = _orgList.firstWhere(
          (o) => (o['orgcode'] ?? o['orgCode'] ?? '').toString() == orgCodeRaw,
        );
        final name = (match['name'] ?? '').toString();
        _orgCodeController.text =
            name.isNotEmpty ? '$orgCodeRaw – $name' : orgCodeRaw;
        _selectedOrgCode = int.tryParse(orgCodeRaw);
        return;
      } catch (_) {}
    }
    _orgCodeController.text = orgCodeRaw;
    _selectedOrgCode = int.tryParse(orgCodeRaw);
  }

  void _openOrgDropdown() {
    _orgOverlay?.remove();
    _orgOverlay = null;
    _orgSearchCtrl.clear();

    _orgOverlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _orgOverlay?.remove();
          _orgOverlay = null;
        },
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
                                          child: Text('No organisations found',
                                              style: bodyStyle(
                                                  color: AppColors.ink4)),
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
                                                _orgOverlay?.remove();
                                                _orgOverlay = null;
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
                                                      child: Text(name,
                                                          style: bodyStyle(
                                                              size: 13),
                                                          overflow: TextOverflow
                                                              .ellipsis),
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

  void _selectOrg(Map<String, dynamic> org) {
    final code = (org['orgcode'] ?? org['orgCode'] ?? '').toString();
    final name = (org['name'] ?? '').toString();
    setState(() {
      _selectedOrgCode = int.tryParse(code);
      _orgCodeController.text = name.isNotEmpty ? '$code – $name' : code;
      _orgError = null;
    });
  }

  Future<void> _deleteGlMaster(Map<String, dynamic> c) async {
    final glNo = c['glNo'] is int
        ? c['glNo'] as int
        : int.tryParse(c['glNo'].toString()) ?? 0;
    final success = await apiService.deleteGlMaster(glNo);

    if (!mounted) return;

    if (success) {
      _showSnack('${c['glName']} deleted successfully', isError: false);
      await _loadGlMasters(page: 1);
    } else {
      _showSnack('Failed to delete ${c['glName']}', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────

  /// Convert glCatCd → display name
  String _catName(dynamic glCatCd) {
    if (_categoryList.isEmpty) return glCatCd?.toString() ?? '—';
    final match = _categoryList.firstWhere(
      (c) => c['glCatCd'].toString() == glCatCd.toString(),
      orElse: () => {},
    );
    return match['glCatName']?.toString() ?? glCatCd?.toString() ?? '—';
  }

  /// Status int → display string
  String _statusLabel(dynamic status) {
    if (status == 1 || status == true) return 'Active';
    return 'Inactive';
  }

  /// Category dropdown items (display names)
  List<String> get _categoryNames =>
      _categoryList.map((c) => c['glCatName']?.toString() ?? '').toList();

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    showAmsSnack(context, message, type: isError ? 'e' : 's');
  }

  void _onFormChange() {
    setState(() {
      if (_orgCodeController.text.trim().isNotEmpty) _orgError = null;
      if (_glNumberController.text.trim().isNotEmpty) _glNumberError = null;
      if (_glNameController.text.trim().isNotEmpty) _glNameError = null;
    });
  }

  void _validateField(String value, String fieldName, FocusNode? nextFocus) {
    setState(() {
      if (fieldName == 'org') {
        _orgError = value.trim().isEmpty ? 'Organisation Code is required' : null;
      }
      if (fieldName == 'number') {
        _glNumberError = value.trim().isEmpty ? 'GL Number is required' : null;
      }
      if (fieldName == 'name') {
        _glNameError = value.trim().isEmpty ? 'GL Name is required' : null;
      }
    });
    if (value.trim().isNotEmpty && nextFocus != null) nextFocus.requestFocus();
  }

  bool get _isFormValid =>
      _orgCodeController.text.trim().isNotEmpty &&
      _glNumberController.text.trim().isNotEmpty &&
      _glNameController.text.trim().isNotEmpty &&
      _selectedCategoryName != null &&
      _selectedStatus != null;

  void _validateAll() {
    setState(() {
      if (_orgCodeController.text.trim().isEmpty) {
        _orgError = 'Organisation Code is required';
      }
      if (_glNumberController.text.trim().isEmpty) {
        _glNumberError = 'GL Number is required';
      }
      if (_glNameController.text.trim().isEmpty) {
        _glNameError = 'GL Name is required';
      }
      if (_selectedCategoryName == null) {
        _categoryError = 'Category is required';
      }
      if (_selectedStatus == null) _statusError = 'Status is required';
    });
  }

  void _clearFields() {
    _orgCodeController.clear();
    _selectedOrgCode = null;
    _glNumberController.clear();
    _glNameController.clear();
    setState(() {
      _selectedCategoryName = null;
      _selectedCategoryCd = null;
      _selectedStatus = null;
      _isViewOnly = false;
      _isEditing = false;
      _orgError = null;
      _glNumberError = null;
      _glNameError = null;
      _categoryError = null;
      _statusError = null;
      _editingRecord = {};
    });
  }

  void _editAccount(Map<String, dynamic> c) {
    final catCd = c['glCatCd'];
    final catName = _catName(catCd);
    setState(() {
      _showForm = true;
      _isViewOnly = false;
      _isEditing = true;
      _refreshOrgDisplay(c['orgCode']?.toString() ?? '');
      _glNumberController.text = c['glNo']?.toString() ?? '';
      _glNameController.text = c['glName']?.toString() ?? '';
      _selectedCategoryName = catName;
      _selectedCategoryCd =
          catCd is int ? catCd : int.tryParse(catCd.toString());
      _selectedStatus = _statusLabel(c['status']);
      _orgError =
          _glNumberError = _glNameError = _categoryError = _statusError = null;
      _editingRecord = Map<String, dynamic>.from(c);
    });
  }

  void _viewAccount(Map<String, dynamic> c) {
    final catCd = c['glCatCd'];
    final catName = _catName(catCd);
    setState(() {
      _showForm = true;
      _isViewOnly = true;
      _isEditing = false;
      _refreshOrgDisplay(c['orgCode']?.toString() ?? '');
      _glNumberController.text = c['glNo']?.toString() ?? '';
      _glNameController.text = c['glName']?.toString() ?? '';
      _selectedCategoryName = catName;
      _selectedCategoryCd =
          catCd is int ? catCd : int.tryParse(catCd.toString());
      _selectedStatus = _statusLabel(c['status']);
      _orgError =
          _glNumberError = _glNameError = _categoryError = _statusError = null;
    });
  }

  void _confirmDelete(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Account',
            style: bodyStyle(size: 16, weight: FontWeight.w700)),
        content: Text('Are you sure you want to delete ${c['glName']}?',
            style: bodyStyle(size: 14)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          AmsButton(
            label: 'No',
            variant: AmsButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx),
          ),
          AmsButton(
            label: 'Yes, Delete',
            variant: AmsButtonVariant.primary,
            onPressed: () {
              Navigator.pop(ctx);
              _deleteGlMaster(c);
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.account_balance_wallet_rounded,
                size: 28, color: AppColors.tBlue),
            title: 'GL Master Account',
            subtitle: '',
            badges: [],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(
                  label: 'GL Module', onTap: widget.onBackToModule),
              HeaderBreadcrumb(label: 'GL Master'),
            ],
            onBack: widget.onBackToModule,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _showForm ? _buildFormScreen() : _buildListScreen(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // List Screen
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildListScreen() {
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
            child: LayoutBuilder(builder: (context, constraints) {
              final isMobile = Responsive.isMobile(context);
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AmsTextInput(
                      icon: Icons.search_rounded,
                      placeholder: 'Search GL accounts...',
                      onChanged: (v) => setState(() {
                        _searchQuery = v;
                        _currentPage = 1;
                      }),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: _loadGlMasters,
                          icon: _loadingList
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded,
                                  color: AppColors.ink3),
                        ),
                        const Spacer(),
                        AmsButton(
                          label: '+ New GL',
                          variant: AmsButtonVariant.primary,
                          onPressed: () {
                            setState(() {
                              _showForm = true;
                              _isViewOnly = false;
                              _isEditing = false;
                              _clearFields();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: AmsTextInput(
                      icon: Icons.search_rounded,
                      placeholder: 'Search GL accounts...',
                      onChanged: (v) => setState(() {
                        _searchQuery = v;
                        _currentPage = 1;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loadGlMasters,
                    icon: _loadingList
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded,
                            color: AppColors.ink3),
                  ),
                  const SizedBox(width: 8),
                  AmsButton(
                    label: '+ New GL',
                    variant: AmsButtonVariant.primary,
                    onPressed: () {
                      setState(() {
                        _showForm = true;
                        _isViewOnly = false;
                        _isEditing = false;
                        _clearFields();
                      });
                    },
                  ),
                ],
              );
            }),
          ),
          Expanded(
            child: AmsPaginatedView<Map<String, dynamic>>(
              items: _accounts,
              itemsPerPage: _pageSize,
              currentPage: _currentPage,
              totalRecords: _totalItems,
              onPageChanged: (page) => _loadGlMasters(page: page),
              builder: (context, paginatedItems) => _buildTable(paginatedItems),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Table
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTable(List<Map<String, dynamic>> items) {
    if (_loadingList && _accounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: AmsTableSkeleton(rows: 8),
      );
    }

    if (_listError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.red),
            const SizedBox(height: 12),
            Text(_listError!, style: bodyStyle(size: 14, color: AppColors.red)),
            const SizedBox(height: 16),
            AmsButton(
              label: 'Retry',
              variant: AmsButtonVariant.outline,
              onPressed: () => _loadGlMasters(page: _currentPage),
            ),
          ],
        ),
      );
    }

    final filtered = items.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c['glName'].toString().toLowerCase().contains(q) ||
          c['glNo'].toString().toLowerCase().contains(q);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.search_off_rounded,
                  size: 32, color: AppColors.ink4),
            ),
            const SizedBox(height: 16),
            Text('No data available',
                style: bodyStyle(
                    size: 14, color: AppColors.ink3, weight: FontWeight.w600)),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, idx) {
        final c = filtered[idx];
        final isMobile = Responsive.isMobile(context);
        final catName = _catName(c['glCatCd']);
        final statusLbl = _statusLabel(c['status']);
        final isActive = statusLbl == 'Active';

        if (isMobile) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.tBlueLt,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (c['glName']?.toString() ?? 'G')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: bodyStyle(
                              size: 14,
                              color: AppColors.tBlue,
                              weight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['glName']?.toString() ?? '—',
                              style: bodyStyle(size: 14, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Category: $catName',
                              style: bodyStyle(size: 11, color: AppColors.ink3)),
                        ],
                      ),
                    ),
                    AmsBadge(label: c['glNo']?.toString() ?? '—'),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(statusLbl,
                        style: bodyStyle(
                          size: 12,
                          color: isActive ? AppColors.green : AppColors.red,
                          weight: FontWeight.w600,
                        )),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionButton(
                          icon: Icons.visibility_outlined,
                          color: AppColors.green,
                          onTap: () => _viewAccount(c),
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          icon: Icons.edit_outlined,
                          color: AppColors.tBlue,
                          onTap: () => _editAccount(c),
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          icon: Icons.close_rounded,
                          color: AppColors.red,
                          isDanger: true,
                          onTap: () => _confirmDelete(c),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.tBlueLt,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (c['glName']?.toString() ?? 'G')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: bodyStyle(
                        size: 16,
                        color: AppColors.tBlue,
                        weight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['glName']?.toString() ?? '—',
                        style: bodyStyle(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Category: ',
                            style: bodyStyle(size: 12, color: AppColors.ink3)),
                        Text(catName,
                            style: bodyStyle(
                                size: 12,
                                color: AppColors.tBlue,
                                weight: FontWeight.w600)),
                        Text('   |   Status: ',
                            style: bodyStyle(size: 12, color: AppColors.ink3)),
                        Text(statusLbl,
                            style: bodyStyle(
                              size: 12,
                              color: isActive ? AppColors.green : AppColors.red,
                              weight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              // GL Number Badge
              SizedBox(
                width: 80,
                child: Center(
                    child: AmsBadge(label: c['glNo']?.toString() ?? '—')),
              ),
              const SizedBox(width: 20),
              // Category Pill
              SizedBox(
                width: 150,
                child: UnconstrainedBox(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tBlueLt.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      catName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle(
                          size: 11,
                          color: AppColors.tBlue,
                          weight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Actions
              SizedBox(
                width: 110,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionButton(
                      icon: Icons.visibility_outlined,
                      color: AppColors.green,
                      onTap: () => _viewAccount(c),
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.tBlue,
                      onTap: () => _editAccount(c),
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.close_rounded,
                      color: AppColors.red,
                      isDanger: true,
                      onTap: () => _confirmDelete(c),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Form Screen wrapper
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildFormScreen() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.f2) {
            FocusManager.instance.primaryFocus?.previousFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 FORM HEADER (DARK NAVY)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.sidebar,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isViewOnly
                        ? 'View GL Account'
                        : (_isEditing
                            ? 'Edit GL Account'
                            : 'Create GL Account'),
                    style: bodyStyle(
                        size: 14, color: Colors.white, weight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up_rounded,
                        color: Colors.white),
                    onPressed: () {
                      _clearFields();
                      setState(() => _showForm = false);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _isViewOnly ? _buildViewUI() : _buildFormUI(),
              ),
            ),

            /// FIXED FOOTER
            if (!_isViewOnly)
              AmsSubmitBar(
                borderColor: AppColors.border,
                actions: [
                  if (_saving)
                    const SizedBox(
                      width: 80,
                      height: 36,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    AmsButton(
                      label: _isEditing ? 'Update' : 'Save',
                      variant: AmsButtonVariant.primary,
                      backgroundColor: AppColors.sidebar,
                      onPressed: _saveGlMaster,
                    ),
                    AmsButton(
                      label: 'Clear',
                      icon: Icons.clear_all_rounded,
                      variant: AmsButtonVariant.outline,
                      onPressed: _clearFields,
                    ),
                    AmsButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      variant: AmsButtonVariant.danger,
                      onPressed: () {
                        _clearFields();
                        setState(() => _showForm = false);
                      },
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // View UI (read-only)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildViewUI() {
    final firstLetter = _glNameController.text.isNotEmpty
        ? _glNameController.text.substring(0, 1).toUpperCase()
        : 'G';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.tBlue,
                      AppColors.tBlue.withValues(alpha: 0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.tBlue.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Center(
                  child: Text(firstLetter,
                      style: bodyStyle(
                          size: 24,
                          color: Colors.white,
                          weight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _glNameController.text.isEmpty
                          ? 'Unnamed Account'
                          : _glNameController.text,
                      style: bodyStyle(size: 18, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStatusChip(_selectedStatus ?? 'Active'),
                        const SizedBox(width: 10),
                        if (_selectedCategoryName != null)
                          AmsBadge(
                            label: _selectedCategoryName!,
                            background: AppColors.tBlueLt,
                            color: AppColors.tBlue,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Account Details',
            style: bodyStyle(
                size: 14, weight: FontWeight.w700, color: AppColors.ink2)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard('Organization', _orgCodeController.text,
                  Icons.business_rounded),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                  'GL Number', _glNumberController.text, Icons.tag_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
            'Category', _selectedCategoryName ?? '—', Icons.category_rounded),
        const SizedBox(height: 40),
        AmsButton(
          label: 'Back to List',
          icon: Icons.arrow_back_rounded,
          variant: AmsButtonVariant.primary,
          backgroundColor: AppColors.red,
          small: true,
          onPressed: () {
            _clearFields();
            setState(() => _showForm = false);
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Create / Edit Form UI
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildFormUI() {
    return AmsFormGrid(
      children: [
        AmsField(
          label: 'Organisation Code',
          required: true,
          labelAbove: true,
          tooltip: 'Organization Code',
          child: CompositedTransformTarget(
            link: _orgLayerLink,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isViewOnly || _isEditing ? null : _openOrgDropdown,
              child: AbsorbPointer(
                child: AmsTextInput(
                  placeholder: _orgLoading ? "Loading…" : "Select Organisation",
                  controller: _orgCodeController,
                  readOnly: true,
                  icon: _orgLoading ? Icons.hourglass_empty : Icons.business,
                  errorText: _orgError,
                ),
              ),
            ),
          ),
        ),
        AmsField(
          label: 'GL Number',
          required: true,
          labelAbove: true,
          tooltip: 'Unique GL Number',
          child: AmsTextInput(
            controller: _glNumberController,
            focusNode: _glNumberFocus,
            errorText: _glNumberError,
            isValid: _glNumberController.text.trim().isNotEmpty &&
                _glNumberError == null,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (v) => _validateField(v, 'number', _glNameFocus),
            placeholder: 'e.g. 10010',
          ),
        ),
        AmsField(
          label: 'GL Name',
          required: true,
          labelAbove: true,
          tooltip: 'Descriptive name for this GL Account',
          child: AmsTextInput(
            controller: _glNameController,
            focusNode: _glNameFocus,
            errorText: _glNameError,
            isValid: _glNameController.text.trim().isNotEmpty &&
                _glNameError == null,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (v) => _validateField(v, 'name', _categoryFocus),
            placeholder: 'e.g. Cash In Hand',
          ),
        ),
        AmsField(
          label: 'GL Category',
          required: true,
          labelAbove: true,
          tooltip: 'Select the category for this GL Account',
          child: _loadingCategories
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : AmsDropdown(
                  focusNode: _categoryFocus,
                  placeholder: 'Select category',
                  initialValue: _selectedCategoryName,
                  errorText: _categoryError,
                  isValid:
                      _selectedCategoryName != null && _categoryError == null,
                  onChanged: (val) {
                    final match = _categoryList.firstWhere(
                      (c) => c['glCatName']?.toString() == val,
                      orElse: () => {},
                    );
                    setState(() {
                      _selectedCategoryName = val;
                      _selectedCategoryCd = match['glCatCd'] is int
                          ? match['glCatCd'] as int
                          : int.tryParse(match['glCatCd']?.toString() ?? '');
                      _categoryError = null;
                    });
                    _statusFocus.requestFocus();
                  },
                  items: _categoryNames,
                ),
        ),
        AmsField(
          label: 'Status',
          required: true,
          labelAbove: true,
          tooltip: 'Set the current status of the GL Account',
          child: AmsDropdown(
            focusNode: _statusFocus,
            placeholder: 'Active / Inactive',
            initialValue: _selectedStatus,
            errorText: _statusError,
            isValid: _selectedStatus != null && _statusError == null,
            onChanged: (val) {
              setState(() {
                _selectedStatus = val;
                _statusError = null;
              });
            },
            items: const ['Active', 'Inactive'],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Pagination Footer
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildPaginationFooter() {
    final start = ((_currentPage - 1) * _pageSize) + 1;
    final end = start + _accounts.length - 1;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing $start–$end',
              style: bodyStyle(size: 13, color: AppColors.ink3)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded,
                    size: 20,
                    color: _currentPage > 1 ? AppColors.ink3 : AppColors.border),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                        _loadGlMasters(page: _currentPage);
                      }
                    : null,
              ),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded,
                    size: 20,
                    color: _accounts.length == _pageSize
                        ? AppColors.ink3
                        : AppColors.border),
                onPressed: _accounts.length == _pageSize
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                        _loadGlMasters(page: _currentPage);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Small helpers
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStatusChip(String status) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.greenLt : AppColors.redLt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isActive ? AppColors.green : AppColors.red)
              .withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppColors.green : AppColors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: bodyStyle(
                size: 11,
                weight: FontWeight.w700,
                color: isActive ? AppColors.green : AppColors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.ink3),
              const SizedBox(width: 8),
              Text(label,
                  style: bodyStyle(
                      size: 11,
                      color: AppColors.ink3,
                      weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: bodyStyle(
                  size: 14, color: AppColors.ink, weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDanger ? AppColors.redLt : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDanger
                ? AppColors.red.withValues(alpha: 0.2)
                : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ─── GLMasterFields Widget ────────────────────────────────────────────────────
class GLMasterFields extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool isViewMode;
  final List<Map<String, dynamic>> categoryList;
  final void Function(String key, dynamic val) onChanged;

  const GLMasterFields({
    super.key,
    this.initialData,
    this.isViewMode = false,
    this.categoryList = const [],
    required this.onChanged,
  });

  @override
  State<GLMasterFields> createState() => _GLMasterFieldsState();
}

class _GLMasterFieldsState extends State<GLMasterFields> {
  final _orgCtrl = TextEditingController();
  final _glNoCtrl = TextEditingController();
  final _glNameCtrl = TextEditingController();
  int? _glCatCd;
  String? _status;
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.initialData == null) return;
    final d = widget.initialData!.map((k, v) => MapEntry(k.toLowerCase(), v));

    _orgCtrl.text = (d['orgcode'] ?? d['org_code'] ?? d['org'] ?? '50').toString();
    _glNoCtrl.text = (d['glno'] ?? d['gl_no'] ?? d['no'] ?? d['gl_number'] ?? '').toString();
    _glNameCtrl.text = (d['glname'] ?? d['gl_name'] ?? d['name'] ?? '').toString();
    _glCatCd = int.tryParse((d['glcatcd'] ?? d['gl_cat_cd'] ?? d['category_code'] ?? '').toString());
    
    final statusVal = d['status'];
    _status = (statusVal == 1 || statusVal == '1' || statusVal == true || statusVal == 'Active') 
        ? 'Active' : 'Inactive';
  }

  @override
  void dispose() {
    _orgCtrl.dispose();
    _glNoCtrl.dispose();
    _glNameCtrl.dispose();
    super.dispose();
  }

  String _catName(dynamic catCd) {
    if (widget.categoryList.isEmpty) return catCd?.toString() ?? '—';
    final match = widget.categoryList.firstWhere(
      (c) => c['glCatCd'].toString() == catCd.toString(),
      orElse: () => {},
    );
    return match['glCatName']?.toString() ?? catCd?.toString() ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isViewMode) return _buildViewUI();
    return _buildFormUI();
  }

  Widget _buildFormUI() {
    return AmsFormGrid(
      children: [
        AmsField(
          label: 'Organisation Code',
          required: true,
          labelAbove: true,
          child: AmsTextInput(
            controller: _orgCtrl,
            readOnly: widget.isViewMode,
            onChanged: (v) => widget.onChanged('orgCode', v),
          ),
        ),
        AmsField(
          label: 'GL Number',
          required: true,
          labelAbove: true,
          child: AmsTextInput(
            controller: _glNoCtrl,
            readOnly: widget.isViewMode,
            placeholder: 'e.g. 101001',
            keyboardType: TextInputType.number,
            errorText: _errors['glNo'],
            onChanged: (v) {
              setState(() => _errors['glNo'] =
                  v.trim().isEmpty ? 'GL Number required' : null);
              widget.onChanged('glNo', int.tryParse(v) ?? 0);
            },
          ),
        ),
        AmsField(
          label: 'GL Name',
          required: true,
          labelAbove: true,
          child: AmsTextInput(
            controller: _glNameCtrl,
            readOnly: widget.isViewMode,
            placeholder: 'Enter GL name...',
            errorText: _errors['glName'],
            onChanged: (v) {
              setState(() => _errors['glName'] =
                  v.trim().isEmpty ? 'GL Name required' : null);
              widget.onChanged('glName', v);
            },
          ),
        ),
        AmsField(
          label: 'Category',
          required: true,
          labelAbove: true,
          child: AmsDropdown(
            initialValue: widget.categoryList.isEmpty ? null : () {
              if (_glCatCd == null) return null;
              final match = widget.categoryList.firstWhere(
                (c) => c['glCatCd'].toString() == _glCatCd.toString(),
                orElse: () => {},
              );
              if (match.isEmpty) return null;
              return '${match['glCatCd']} - ${match['glCatName']}';
            }(),
            items: widget.categoryList
                .map((c) => '${c['glCatCd']} - ${c['glCatName']}')
                .toList(),
            errorText: _errors['glCatCd'],
            onChanged: (v) {
              final cd = int.tryParse(v?.split(' - ').first ?? '');
              setState(() {
                _glCatCd = cd;
                _errors['glCatCd'] = cd == null ? 'Category required' : null;
              });
              widget.onChanged('glCatCd', cd);
            },
          ),
        ),
        AmsField(
          label: 'Status',
          required: true,
          labelAbove: true,
          child: AmsDropdown(
            initialValue: _status,
            items: const ['Active', 'Inactive'],
            onChanged: (v) {
              setState(() => _status = v);
              widget.onChanged('status', v == 'Active' ? 1 : 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewUI() {
    final firstLetter = _glNameCtrl.text.isNotEmpty
        ? _glNameCtrl.text.substring(0, 1).toUpperCase()
        : 'G';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.tBlue, Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(firstLetter,
                      style: bodyStyle(
                          size: 24, color: Colors.white, weight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _glNameCtrl.text.isEmpty
                          ? 'Unnamed GL Account'
                          : _glNameCtrl.text,
                      style: bodyStyle(size: 18, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        AmsBadge(
                          label: _status ?? 'Active',
                          background: (_status == 'Active') ? AppColors.greenLt : AppColors.redLt,
                          color: (_status == 'Active') ? AppColors.green : AppColors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('GL Account Details',
            style: bodyStyle(
                size: 14, weight: FontWeight.w700, color: AppColors.ink2)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard('Organization', _orgCtrl.text,
                  Icons.business_rounded),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                  'GL Number', _glNoCtrl.text, Icons.tag_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard('Category', _catName(_glCatCd),
            Icons.category_rounded),
        const SizedBox(height: 16),
        _buildInfoCard('Account Status', _status ?? '—',
            Icons.info_outline_rounded),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.ink3),
              const SizedBox(width: 8),
              Text(label,
                  style: bodyStyle(
                      size: 11,
                      color: AppColors.ink3,
                      weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: bodyStyle(
                  size: 14, color: AppColors.ink, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
