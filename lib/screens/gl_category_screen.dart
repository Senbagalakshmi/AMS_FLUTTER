import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../services/org_api_service.dart';
import '../utils/responsive.dart';

class GLCategoryScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const GLCategoryScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<GLCategoryScreen> createState() => _GLCategoryScreenState();
}

class _GLCategoryScreenState extends State<GLCategoryScreen> {
  String _searchQuery = '';
  bool _showForm = false;
  String? _selectedCategoryType;
  bool _isViewOnly = false;
  static const int _pageSize = 10;

  // API state
  List<Map<String, dynamic>> _allCategories = [];
  bool _isLoading = false;
  String? _loadError;
  
  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) return _allCategories;
    final q = _searchQuery.toLowerCase();
    return _allCategories.where((c) {
      if (c == null) return false;
      final name = _getName(c).toLowerCase();
      final code = _getCode(c).toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  final _orgCodeController = TextEditingController();

  // ── Org-code searchable dropdown ───────────────────────────────────────────
  final _orgSearchCtrl = TextEditingController(); // search text inside overlay
  final _orgLayerLink = LayerLink();
  OverlayEntry? _orgOverlay;
  List<Map<String, dynamic>> _orgList = [];
  bool _orgLoading = false;
  int? _selectedOrgCode;
  final _catCodeController = TextEditingController();
  final _catNameController = TextEditingController();
  final _subTypeController = TextEditingController();

  final _orgFocus = FocusNode();
  final _catCodeFocus = FocusNode();
  final _catNameFocus = FocusNode();
  final _catTypeFocus = FocusNode();
  final _subTypeFocus = FocusNode();

  String? _orgError;
  String? _catCodeError;
  String? _catNameError;
  String? _catTypeError;
  String? _viewStatus;

  // Track if we're in edit mode and which record
  bool _isEditMode = false;
  int? _editingGlCatCd;
  Map<String, dynamic> _editingRecord = {}; // original record — used for audit field preservation
  int? _lastModifiedId; // 🔥 Track recently saved/updated for top positioning

  @override
  void initState() {
    super.initState();
    _orgCodeController.addListener(_onFormChange);
    _catCodeController.addListener(_onFormChange);
    _catNameController.addListener(_onFormChange);
    _loadOrganisations();
    _loadCategories();
  }

  // ─── API CALLS ────────────────────────────────────────────────────────────

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final result =
        await apiService.getAllGlCategories(page: 0, size: 1000);

    setState(() {
      _isLoading = false;
      if (result != null) {
        _allCategories = result.items;
        // 🔥 SORT BY glCatCd DESCENDING (LATEST ON TOP)
        _allCategories.sort((a, b) {
          final idA = int.tryParse(_getCode(a)) ?? 0;
          final idB = int.tryParse(_getCode(b)) ?? 0;
          if (_lastModifiedId != null) {
            if (idA == _lastModifiedId) return -1;
            if (idB == _lastModifiedId) return 1;
          }
          return idB.compareTo(idA);
        });
      } else {
        _loadError = 'Failed to load categories. Please try again.';
      }
    });
  }

  Future<void> _saveCategory() async {
    if (!_isFormValid) {
      _validateAll();
      return;
    }

    setState(() => _isLoading = true);

    // ── Compute audit fields ─────────────────────────────────────────────
    String nowIso =
        "${DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(DateTime.now().toUtc())}+00:00";
    String cleanUser = (widget.userName ?? 'admin');
    if (cleanUser.contains('@')) cleanUser = cleanUser.split('@').first;

    final orig = _editingRecord;

    // creator — preserved on edit, set on create
    String cUserVal = _isEditMode
        ? (orig['cUser'] ?? orig['cuser'] ?? cleanUser).toString()
        : cleanUser;
    String cDateVal = _isEditMode
        ? (orig['cDate'] ?? orig['cdate'] ?? nowIso).toString()
        : nowIso;

    // last editor — always current user/time
    String eUserVal = cleanUser;
    String eDateVal = nowIso;

    // approver — preserve existing DB value on edit; default to eUser on create
    String aUserVal = _isEditMode
        ? (orig['aUser'] ?? orig['auser'] ?? eUserVal).toString()
        : eUserVal;
    String aDateVal = _isEditMode
        ? (orig['aDate'] ?? orig['adate'] ?? eDateVal).toString()
        : eDateVal;
    // ────────────────────────────────────────────────────────────────────

    final data = {
      'orgCode': (_selectedOrgCode ?? int.tryParse(_orgCodeController.text.split(' – ')[0]) ?? 0).toString(),
      'glCatCd': int.tryParse(_catCodeController.text.trim()) ?? 0,
      'glCatName': _catNameController.text.trim(),
      'glCatType': _selectedCategoryType,
      if (_subTypeController.text.trim().isNotEmpty)
        'glCatSubType': _subTypeController.text.trim(),

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

    // ✅ Edit mode → PUT (updateGlCategory), Create mode → POST (createGlCategory)
    final success = _isEditMode
        ? await apiService.updateGlCategory(_editingGlCatCd!, data)
        : await apiService.createGlCategory(data);

    setState(() => _isLoading = false);

    if (success) {
      _lastModifiedId = int.tryParse(_catCodeController.text.trim()) ?? 0;
      _showSnackbar(
        _isEditMode
            ? '${_catNameController.text} updated successfully'
            : '${_catNameController.text} created successfully',
        isError: false,
      );
      _clearFields();
      setState(() {
        _showForm = false;
        _isEditMode = false;
        _editingGlCatCd = null;
        _editingRecord = {};
      });
      // Invalidate cached full-list responses so we fetch fresh data next.
      await _loadCategories();
    } else {
      _showSnackbar('Failed to save category. Please try again.',
          isError: true);
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> c) async {
    // glCatCd is the primary key used for delete
    final glCatCd = c['glCatCd'] is int
        ? c['glCatCd'] as int
        : int.tryParse(c['glCatCd']?.toString() ?? '');

    final orgCodeRaw = c['orgCode'] ?? c['orgcode'] ?? c['org_code'];
    final orgCode = orgCodeRaw is int ? orgCodeRaw : int.tryParse(orgCodeRaw?.toString() ?? '');

    if (glCatCd == null || orgCode == null) {
      _showSnackbar('Cannot delete: invalid category or organisation code.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final success = await apiService.deleteGlCategory(orgCode, glCatCd);

    setState(() => _isLoading = false);

    if (success) {
      _showSnackbar('${c['glCatName'] ?? c['name']} deleted successfully',
          isError: false);
      await _loadCategories(); // Refresh
    } else {
      _showSnackbar('Failed to delete category. Please try again.',
          isError: true);
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    showAmsSnack(context, message, type: isError ? 'e' : 's');
  }

  void _onFormChange() {
    setState(() {
      if (_orgCodeController.text.trim().isNotEmpty) _orgError = null;
      if (_catCodeController.text.trim().isNotEmpty) _catCodeError = null;
      if (_catNameController.text.trim().isNotEmpty) _catNameError = null;
      if (_selectedCategoryType != null) _catTypeError = null;
    });
  }

  void _validateField(String value, String fieldName, FocusNode? nextFocus) {
    setState(() {
      if (fieldName == 'org') {
        _orgError = value.trim().isEmpty ? 'Organisation Code is required' : null;
      } else if (fieldName == 'code') {
        _catCodeError =
            value.trim().isEmpty ? 'Category Code is required' : null;
      } else if (fieldName == 'name') {
        _catNameError =
            value.trim().isEmpty ? 'Category Name is required' : null;
      } else if (fieldName == 'type') {
        _catTypeError =
            _selectedCategoryType == null ? 'Category Type is required' : null;
      }
    });
    if (value.trim().isNotEmpty && nextFocus != null) {
      nextFocus.requestFocus();
    }
  }

  bool get _isFormValid {
    return _orgCodeController.text.trim().isNotEmpty &&
        _catCodeController.text.trim().isNotEmpty &&
        _catNameController.text.trim().isNotEmpty &&
        _selectedCategoryType != null;
  }

  void _validateAll() {
    setState(() {
      if (_orgCodeController.text.trim().isEmpty) {
        _orgError = 'Organisation Code is required';
      }
      if (_catCodeController.text.trim().isEmpty) {
        _catCodeError = 'Category Code is required';
      }
      if (_catNameController.text.trim().isEmpty) {
        _catNameError = 'Category Name is required';
      }
      if (_selectedCategoryType == null) {
        _catTypeError = 'Category Type is required';
      }
    });
  }

  @override
  void dispose() {
    _orgCodeController.dispose();
    _orgSearchCtrl.dispose();
    _orgOverlay?.remove();
    _catCodeController.dispose();
    _catNameController.dispose();
    _subTypeController.dispose();
    _orgFocus.dispose();
    _catCodeFocus.dispose();
    _catNameFocus.dispose();
    _catTypeFocus.dispose();
    _subTypeFocus.dispose();
    super.dispose();
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

  void _clearFields() {
    _subTypeController.clear();
    setState(() {
      _selectedCategoryType = null;
      _isViewOnly = false;
      _isEditMode = false;
      _editingGlCatCd = null;
      _orgError = null;
      _selectedOrgCode = null;
      _orgCodeController.clear();
      _catCodeError = null;
      _catNameError = null;
      _catTypeError = null;
    });
  }

  // ─── FIELD MAPPING HELPERS ────────────────────────────────────────────────
  // API may return different key names — handle both gracefully

  String _getField(Map<String, dynamic>? c, List<String> keys,
      {String fallback = ''}) {
    if (c == null) return fallback;
    for (final k in keys) {
      if (c.containsKey(k) && c[k] != null) return c[k].toString();
    }
    return fallback;
  }

  String _getName(Map<String, dynamic> c) =>
      _getField(c, ['glCatName', 'name', 'gl_cat_name']);
  String _getCode(Map<String, dynamic> c) =>
      _getField(c, ['glCatCd', 'code', 'glCatCode', 'gl_cat_cd']);
  String _getType(Map<String, dynamic> c) =>
      _getField(c, ['glCatType', 'type', 'gl_cat_type']);
  String _getOrg(Map<String, dynamic> c) =>
      _getField(c, ['orgCode', 'org', 'org_code'], fallback: 'ORG01');
  String _getSubType(Map<String, dynamic> c) => _getField(c, [
        'glCatSubType',
        'glSubType',
        'subType',
        'gl_sub_type',
        'gl_cat_sub_type'
      ]);
  String _getStatus(Map<String, dynamic> c) =>
      _getField(c, ['status', 'gl_status'], fallback: 'Active');

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.category_rounded,
                size: 28, color: AppColors.tBlue),
            title: 'GL Category',
            subtitle: '',
            badges: [],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(
                  label: 'GL Module', onTap: widget.onBackToModule),
              HeaderBreadcrumb(label: 'GL Category'),
            ],
            onBack: widget.onBackToModule,
          ),

          /// 🔥 FULL WIDTH SWITCH (NO ROW)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _showForm
                  ? _buildFullFormView() // 👉 FORM FULL WIDTH
                  : _buildFullListView(), // 👉 LIST FULL WIDTH
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullListView() {
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
                      placeholder: 'Search categories...',
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.tBlue,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          onPressed: _isLoading ? null : _loadCategories,
                        ),
                        const Spacer(),
                        AmsButton(
                          label: '+ Add New',
                          variant: AmsButtonVariant.primary,
                          onPressed: () {
                            setState(() {
                              _showForm = true;
                              _isViewOnly = false;
                              _isEditMode = false;
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
                      placeholder: 'Search categories...',
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.tBlue,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    onPressed: _isLoading ? null : _loadCategories,
                  ),
                  const SizedBox(width: 8),
                  AmsButton(
                    label: '+ Add New',
                    variant: AmsButtonVariant.primary,
                    onPressed: () {
                      setState(() {
                        _showForm = true;
                        _isViewOnly = false;
                        _isEditMode = false;
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
              items: _filteredCategories,
              itemsPerPage: _pageSize,
              forceShowFooter: true,
              builder: (context, paginatedItems) => _buildTable(paginatedItems),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullFormView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.sidebar,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isViewOnly
                      ? 'View GL Category'
                      : (_isEditMode
                          ? 'Edit GL Category'
                          : 'Create GL Category'),
                  style: bodyStyle(
                    size: 14,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),

                /// 🔥 ACCORDION SYMBOL (COLLAPSE FORM)
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up_rounded,
                      color: Colors.white),
                  onPressed: () {
                    _clearFields();
                    setState(() => _showForm = false);
                  },
                )
              ],
            ),
          ),

          /// BODY
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
                if (_isLoading)
                  const SizedBox(
                    width: 80,
                    height: 36,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.tBlue),
                      ),
                    ),
                  )
                else ...[
                  AmsButton(
                    label: _isEditMode ? 'Update' : 'Save',
                    variant: AmsButtonVariant.primary,
                    backgroundColor: AppColors.sidebar,
                    onPressed: _saveCategory,
                  ),
                  AmsButton(
                    label: 'Clear',
                    icon: Icons.clear_all_rounded,
                    variant: AmsButtonVariant.outline,
                    onPressed: _isLoading ? null : _clearFields,
                  ),
                  AmsButton(
                    label: 'Cancel',
                    icon: Icons.close_rounded,
                    variant: AmsButtonVariant.danger,
                    onPressed: _isLoading
                        ? null
                        : () {
                            _clearFields();
                            setState(() => _showForm = false);
                          },
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // ─── VIEW UI ──────────────────────────────────────────────────────────────

  Widget _buildViewUI() {
    final firstLetter = _catNameController.text.isNotEmpty
        ? _catNameController.text.substring(0, 1).toUpperCase()
        : 'C';

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
                      _catNameController.text.isEmpty
                          ? 'Unnamed Category'
                          : _catNameController.text,
                      style: bodyStyle(size: 18, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildStatusChip(_viewStatus ?? 'Active'),
                        const SizedBox(width: 10),
                        if (_selectedCategoryType != null)
                          AmsBadge(
                            label: _selectedCategoryType!,
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
        Text('Category Details',
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
                  'Rec Code', _catCodeController.text, Icons.tag_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard('Classification', _selectedCategoryType ?? '—',
            Icons.category_rounded),
        const SizedBox(height: 16),
        _buildInfoCard(
            'Sub-Classification',
            _subTypeController.text.isEmpty
                ? 'Not Provided'
                : _subTypeController.text,
            Icons.account_tree_outlined),
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
          Text(status,
              style: bodyStyle(
                  size: 11,
                  weight: FontWeight.w700,
                  color: isActive ? AppColors.green : AppColors.red)),
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

  Widget _buildFormUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmsFormGrid(
          children: [
            AmsField(
              label: 'Organisation Code',
              required: true,
              labelAbove: true,
              tooltip: 'Unique organization code identifying this entry',
              child: CompositedTransformTarget(
                link: _orgLayerLink,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isViewOnly || _isEditMode ? null : _openOrgDropdown,
                  child: AbsorbPointer(
                    child: AmsTextInput(
                      placeholder:
                          _orgLoading ? "Loading…" : "Select Organisation",
                      controller: _orgCodeController,
                      readOnly: true,
                      icon:
                          _orgLoading ? Icons.hourglass_empty : Icons.business,
                      errorText: _orgError,
                    ),
                  ),
                ),
              ),
            ),
            AmsField(
              label: 'Category Code',
              required: true,
              labelAbove: true,
              tooltip: 'Unique code for this GL Category',
              child: AmsTextInput(
                controller: _catCodeController,
                focusNode: _catCodeFocus,
                readOnly: _isEditMode,
                errorText: _catCodeError,
                isValid: _catCodeController.text.trim().isNotEmpty &&
                    _catCodeError == null,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (v) =>
                    _validateField(v, 'code', _catNameFocus),
                placeholder: 'e.g. 1001',
                keyboardType: TextInputType.number,
              ),
            ),
            AmsField(
              label: 'Category Name',
              required: true,
              labelAbove: true,
              tooltip: 'Provide a descriptive name for this Category',
              child: AmsTextInput(
                controller: _catNameController,
                focusNode: _catNameFocus,
                errorText: _catNameError,
                isValid: _catNameController.text.trim().isNotEmpty &&
                    _catNameError == null,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (v) =>
                    _validateField(v, 'name', _catTypeFocus),
                placeholder: 'Enter name...',
              ),
            ),
            AmsField(
              label: 'Category Type',
              required: true,
              labelAbove: true,
              tooltip: 'Select the classification of this Category Element',
              child: AmsDropdown(
                focusNode: _catTypeFocus,
                placeholder: 'Select type',
                initialValue: _selectedCategoryType,
                errorText: _catTypeError,
                isValid: _selectedCategoryType != null && _catTypeError == null,
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryType = val;
                    _catTypeError = null;
                  });
                  _subTypeFocus.requestFocus();
                },
                items: const [
                  'Asset',
                  'Liability',
                  'Capital',
                  'Income',
                  'Expense',
                  'Equity'
                ],
              ),
            ),
            AmsField(
              label: 'Sub Type',
              required: false,
              labelAbove: true,
              tooltip:
                  'Optional sub-classification type for granular filtering',
              child: AmsTextInput(
                controller: _subTypeController,
                focusNode: _subTypeFocus,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (v) => _saveCategory(),
                placeholder: 'Optional sub-type',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('* Required fields',
            style: bodyStyle(
                    size: 11, color: AppColors.ink3, weight: FontWeight.w500)
                .copyWith(fontStyle: FontStyle.italic)),
      ],
    );
  }

  // ─── TABLE ────────────────────────────────────────────────────────────────

  Widget _buildTable(List<Map<String, dynamic>> items) {
    if (_isLoading && _allCategories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: AmsTableSkeleton(rows: 8),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.red),
            const SizedBox(height: 12),
            Text(_loadError!, style: bodyStyle(size: 14, color: AppColors.red)),
            const SizedBox(height: 16),
            AmsButton(
              label: 'Retry',
              variant: AmsButtonVariant.outline,
              onPressed: () => _loadCategories(),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
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
            Text('No categories found',
                style: bodyStyle(
                    size: 14, color: AppColors.ink3, weight: FontWeight.w600)),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final c = items[idx] ?? <String, dynamic>{};
        final isMobile = Responsive.isMobile(context);
        final type = _getType(c);
        final name = _getName(c);
        final code = _getCode(c);
        final status = _getStatus(c);

        Color typeBg = AppColors.bg;
        Color typeFg = AppColors.ink2;
        if (type == 'Asset') {
          typeBg = AppColors.tBlueLt.withValues(alpha: 0.5);
          typeFg = AppColors.tBlue;
        } else if (type == 'Liability') {
          typeBg = const Color(0xFFF3E8FF);
          typeFg = const Color(0xFF7E22CE);
        } else if (type == 'Capital') {
          typeBg = AppColors.nTealLt.withValues(alpha: 0.5);
          typeFg = AppColors.nTeal;
        } else if (type == 'Income') {
          typeBg = AppColors.greenLt;
          typeFg = AppColors.green;
        } else if (type == 'Expense') {
          typeBg = AppColors.amberLt.withValues(alpha: 0.5);
          typeFg = AppColors.amber;
        }

        final isActive = status == 'Active';

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
                    offset: const Offset(0, 2))
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
                          color: AppColors.tBlueLt, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
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
                          Text(name,
                              style: bodyStyle(size: 14, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: typeBg, borderRadius: BorderRadius.circular(4)),
                            child: Text(type,
                                style: bodyStyle(
                                    size: 10, color: typeFg, weight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    AmsBadge(label: code),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(status,
                        style: bodyStyle(
                            size: 12,
                            color: isActive ? AppColors.green : AppColors.red,
                            weight: FontWeight.w600)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionIcon(
                          icon: Icons.history_rounded,
                          color: AppColors.ink3,
                          bg: Colors.white,
                          onTap: () => showAuditLogPopup(context, c),
                        ),
                        const SizedBox(width: 8),
                        _actionIcon(
                          icon: Icons.visibility_outlined,
                          color: AppColors.green,
                          bg: Colors.white,
                          onTap: () => _viewCategory(c),
                        ),
                        const SizedBox(width: 8),
                        _actionIcon(
                          icon: Icons.edit_outlined,
                          color: AppColors.tBlue,
                          bg: Colors.white,
                          onTap: () => _editCategory(c),
                        ),
                        const SizedBox(width: 8),
                        _actionIcon(
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.red,
                          bg: AppColors.redLt,
                          borderColor: AppColors.red.withValues(alpha: 0.2),
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
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: AppColors.tBlueLt, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                    style: bodyStyle(
                        size: 16,
                        color: AppColors.tBlue,
                        weight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: bodyStyle(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Type: ',
                            style: bodyStyle(size: 12, color: AppColors.ink3)),
                        Text(type,
                            style: bodyStyle(
                                size: 12,
                                color: typeFg,
                                weight: FontWeight.w600)),
                        Text('   |   Status: ',
                            style: bodyStyle(size: 12, color: AppColors.ink3)),
                        Text(status,
                            style: bodyStyle(
                                size: 12,
                                color:
                                    isActive ? AppColors.green : AppColors.red,
                                weight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              AmsBadge(label: code),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: typeBg, borderRadius: BorderRadius.circular(4)),
                child: Text(type,
                    style: bodyStyle(
                        size: 11, color: typeFg, weight: FontWeight.w600)),
              ),
              const SizedBox(width: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionIcon(
                    icon: Icons.history_rounded,
                    color: AppColors.ink3,
                    bg: Colors.white,
                    onTap: () => showAuditLogPopup(context, c),
                  ),
                  const SizedBox(width: 8),
                  _actionIcon(
                    icon: Icons.visibility_outlined,
                    color: AppColors.green,
                    bg: Colors.white,
                    onTap: () => _viewCategory(c),
                  ),
                  const SizedBox(width: 8),
                  _actionIcon(
                    icon: Icons.edit_outlined,
                    color: AppColors.tBlue,
                    bg: Colors.white,
                    onTap: () => _editCategory(c),
                  ),
                  const SizedBox(width: 8),
                  _actionIcon(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.red,
                    bg: AppColors.redLt,
                    borderColor: AppColors.red.withValues(alpha: 0.2),
                    onTap: () => _confirmDelete(c),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required Color bg,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: borderColor ?? AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }


  // ─── ROW ACTIONS ──────────────────────────────────────────────────────────

  void _editCategory(Map<String, dynamic> c) {
    final type = _getType(c);
    setState(() {
      _showForm = true;
      _isViewOnly = false;
      _isEditMode = true;
      _editingGlCatCd = c['glCatCd'] is int
          ? c['glCatCd'] as int
          : int.tryParse(c['glCatCd']?.toString() ?? '');
      _refreshOrgDisplay(_getOrg(c));
      _catCodeController.text = _getCode(c);
      _catNameController.text = _getName(c);
      _subTypeController.text = _getSubType(c);
      _selectedCategoryType =
          ['Asset', 'Liability', 'Capital', 'Income', 'Expense'].contains(type)
              ? type
              : null;
      _orgError = null;
      _catCodeError = null;
      _catNameError = null;
      _catTypeError = null;
      _editingRecord = Map<String, dynamic>.from(c); // store original for audit field preservation
    });
  }

  void _viewCategory(Map<String, dynamic> c) {
    final type = _getType(c);
    setState(() {
      _showForm = true;
      _isViewOnly = true;
      _viewStatus = _getStatus(c);
      _refreshOrgDisplay(_getOrg(c));
      _catCodeController.text = _getCode(c);
      _catNameController.text = _getName(c);
      _subTypeController.text = _getSubType(c);
      _selectedCategoryType =
          ['Asset', 'Liability', 'Capital', 'Income', 'Expense'].contains(type)
              ? type
              : null;
      _orgError = null;
      _catCodeError = null;
      _catNameError = null;
      _catTypeError = null;
    });
  }

  void _confirmDelete(Map<String, dynamic> c) {
    final name = _getName(c);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Category',
            style: bodyStyle(size: 16, weight: FontWeight.w700)),
        content: Text('Are you sure you want to delete $name?',
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
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteCategory(c); // ← Real API delete
            },
          ),
        ],
      ),
    );
  }
}

// ─── GLCategoryFields Widget ──────────────────────────────────────────────────
class GLCategoryFields extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool isViewMode;
  final void Function(String key, dynamic val) onChanged;

  const GLCategoryFields({
    super.key,
    this.initialData,
    this.isViewMode = false,
    required this.onChanged,
  });

  @override
  State<GLCategoryFields> createState() => _GLCategoryFieldsState();
}

class _GLCategoryFieldsState extends State<GLCategoryFields> {
  final _orgCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _subTypeCtrl = TextEditingController();
  String? _catType;
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.initialData == null) return;
    final d = widget.initialData!.map((k, v) => MapEntry(k.toLowerCase(), v));

    _orgCtrl.text = d['orgcode']?.toString() ?? d['org']?.toString() ?? '50';
    _codeCtrl.text = d['glcatcd']?.toString() ?? d['code']?.toString() ?? '';
    _nameCtrl.text = d['glcatname']?.toString() ?? d['name']?.toString() ?? '';
    _subTypeCtrl.text = d['glcatsubtype']?.toString() ?? d['subtype']?.toString() ?? '';
    _catType = d['glcattype']?.toString() ?? d['type']?.toString();
  }

  @override
  void dispose() {
    _orgCtrl.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _subTypeCtrl.dispose();
    super.dispose();
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
            placeholder: 'e.g. 50',
            onChanged: (v) => widget.onChanged('orgCode', v),
          ),
        ),
        AmsField(
          label: 'Category Code',
          required: true,
          labelAbove: true,
          child: AmsTextInput(
            controller: _codeCtrl,
            readOnly: widget.isViewMode,
            placeholder: 'e.g. 1001',
            keyboardType: TextInputType.number,
            errorText: _errors['glCatCd'],
            onChanged: (v) {
              setState(() => _errors['glCatCd'] =
                  v.trim().isEmpty ? 'Category Code required' : null);
              widget.onChanged('glCatCd', int.tryParse(v) ?? 0);
            },
          ),
        ),
        AmsField(
          label: 'Category Name',
          required: true,
          labelAbove: true,
          child: AmsTextInput(
            controller: _nameCtrl,
            readOnly: widget.isViewMode,
            placeholder: 'Enter name...',
            errorText: _errors['glCatName'],
            onChanged: (v) {
              setState(() => _errors['glCatName'] =
                  v.trim().isEmpty ? 'Category Name required' : null);
              widget.onChanged('glCatName', v);
            },
          ),
        ),
        AmsField(
          label: 'Category Type',
          required: true,
          labelAbove: true,
          child: AmsDropdown(
            initialValue: _catType,
            items: const ['Asset', 'Liability', 'Capital', 'Income', 'Expense'],
            errorText: _errors['glCatType'],
            onChanged: (v) {
              setState(() {
                _catType = v;
                _errors['glCatType'] = v == null ? 'Category Type required' : null;
              });
              widget.onChanged('glCatType', v);
            },
          ),
        ),
        AmsField(
          label: 'Sub Type',
          labelAbove: true,
          child: AmsTextInput(
            controller: _subTypeCtrl,
            readOnly: widget.isViewMode,
            placeholder: 'Optional sub-type',
            onChanged: (v) => widget.onChanged('glCatSubType', v),
          ),
        ),
      ],
    );
  }

  Widget _buildViewUI() {
    final firstLetter = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text.substring(0, 1).toUpperCase()
        : 'C';

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
                      _nameCtrl.text.isEmpty
                          ? 'Unnamed Category'
                          : _nameCtrl.text,
                      style: bodyStyle(size: 18, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (_catType != null)
                          AmsBadge(
                            label: _catType!,
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
        Text('Category Details',
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
                  'Record Code', _codeCtrl.text, Icons.tag_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard('Classification', _catType ?? '—',
            Icons.category_rounded),
        const SizedBox(height: 16),
        _buildInfoCard(
            'Sub-Classification',
            _subTypeCtrl.text.isEmpty
                ? 'Not Provided'
                : _subTypeCtrl.text,
            Icons.account_tree_outlined),
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
              Expanded(
                child: Text(
                  label,
                  style: bodyStyle(
                    size: 11,
                    color: AppColors.ink3,
                    weight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: bodyStyle(
              size: 14,
              color: AppColors.ink,
              weight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
