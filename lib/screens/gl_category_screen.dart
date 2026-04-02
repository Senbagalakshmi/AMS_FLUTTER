import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';

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
  int _currentPage = 1;
  static const int _pageSize = 10;

  // API state
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _loadError;

  final _orgCodeController = TextEditingController();
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
  int? _lastModifiedId; // 🔥 Track recently saved/updated for top positioning

  @override
  void initState() {
    super.initState();
    _orgCodeController.addListener(_onFormChange);
    _catCodeController.addListener(_onFormChange);
    _catNameController.addListener(_onFormChange);
    _loadCategories();
  }

  // ─── API CALLS ────────────────────────────────────────────────────────────

  Future<void> _loadCategories({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final result =
        await apiService.getAllGlCategories(page: page - 1, size: _pageSize);

    setState(() {
      _isLoading = false;
      if (result != null) {
        _categories = result.items;
        // 🔥 SORT BY glCatCd DESCENDING (LATEST ON TOP)
        _categories.sort((a, b) {
          final idA = int.tryParse(_getCode(a)) ?? 0;
          final idB = int.tryParse(_getCode(b)) ?? 0;
          
          // 🔥 Move the most recently saved/updated record to the very top
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

    final data = {
      'orgCode': _orgCodeController.text.trim(), // Send as String
      'glCatCd': int.tryParse(_catCodeController.text.trim()) ?? 0,
      'glCatName': _catNameController.text.trim(),
      'glCatType': _selectedCategoryType,
      if (_subTypeController.text.trim().isNotEmpty)
        'glCatSubType': _subTypeController.text.trim(),
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
      });
      await _loadCategories(); // Refresh list
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

    if (glCatCd == null) {
      _showSnackbar('Cannot delete: invalid category code.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final success = await apiService.deleteGlCategory(glCatCd);

    setState(() => _isLoading = false);

    if (success) {
      _showSnackbar('${c['glCatName'] ?? c['name']} deleted successfully',
          isError: false);
      await _loadCategories(); // Refresh list from API
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
        _orgError = value.trim().isEmpty ? 'Org Code is required' : null;
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
        _orgError = 'Org Code is required';
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

  void _clearFields() {
    _orgCodeController.clear();
    _catCodeController.clear();
    _catNameController.clear();
    _subTypeController.clear();
    setState(() {
      _selectedCategoryType = null;
      _isViewOnly = false;
      _isEditMode = false;
      _editingGlCatCd = null;
      _orgError = null;
      _catCodeError = null;
      _catNameError = null;
      _catTypeError = null;
    });
  }

  // ─── FIELD MAPPING HELPERS ────────────────────────────────────────────────
  // API may return different key names — handle both gracefully

  String _getField(Map<String, dynamic> c, List<String> keys,
      {String fallback = ''}) {
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
            child: Row(
              children: [
                Expanded(
                  child: AmsTextInput(
                    icon: Icons.search_rounded,
                    placeholder: 'Search categories...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 16),

                /// Refresh
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

                /// Add Button
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
          ),
          Expanded(child: _buildTable()),
          _buildPaginationFooter(),
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
              label: 'Org Code',
              required: true,
              labelAbove: true,
              tooltip: 'Unique organization code identifying this entry',
              child: AmsTextInput(
                controller: _orgCodeController,
                focusNode: _orgFocus,
                errorText: _orgError,
                isValid: _orgCodeController.text.trim().isNotEmpty &&
                    _orgError == null,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (v) =>
                    _validateField(v, 'org', _catCodeFocus),
                placeholder: 'e.g. 1',
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
                  'Expense'
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

  Widget _buildTable() {
    // Show error state
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.red),
            const SizedBox(height: 16),
            Text(_loadError!,
                style: bodyStyle(
                    size: 14, color: AppColors.red, weight: FontWeight.w600)),
            const SizedBox(height: 16),
            AmsButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              variant: AmsButtonVariant.outline,
              onPressed: _loadCategories,
            ),
          ],
        ),
      );
    }

    // Show loading skeleton
    if (_isLoading && _categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: AmsTableSkeleton(rows: 10),
      );
    }

    final filtered = _categories.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return _getName(c).toLowerCase().contains(q) ||
          _getCode(c).toLowerCase().contains(q);
    }).toList();

    final startIndex = (_currentPage - 1) * _pageSize;
    final paginated = filtered.skip(startIndex).take(_pageSize).toList();

    if (paginated.isEmpty && filtered.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentPage = 1);
      });
    }

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
      itemCount: paginated.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final c = paginated[idx];
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

  // ─── PAGINATION FOOTER ────────────────────────────────────────────────────

  Widget _buildPaginationFooter() {
    final start = ((_currentPage - 1) * _pageSize) + 1;
    final end = (start + _categories.length - 1);

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
                    color:
                        _currentPage > 1 ? AppColors.ink3 : AppColors.border),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _loadCategories(page: _currentPage);
                      }
                    : null,
              ),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded,
                    size: 20,
                    color: _categories.length == _pageSize
                        ? AppColors.ink3
                        : AppColors.border),
                onPressed: _categories.length == _pageSize
                    ? () {
                        setState(() => _currentPage++);
                        _loadCategories(page: _currentPage);
                      }
                    : null,
              ),
            ],
          ),
        ],
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
      _orgCodeController.text = _getOrg(c);
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

  void _viewCategory(Map<String, dynamic> c) {
    final type = _getType(c);
    setState(() {
      _showForm = true;
      _isViewOnly = true;
      _viewStatus = _getStatus(c);
      _orgCodeController.text = _getOrg(c);
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
          label: 'Org Code',
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
