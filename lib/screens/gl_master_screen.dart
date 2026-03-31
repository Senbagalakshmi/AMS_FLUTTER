import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';

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
  int _currentPage = 1;
  static const int _pageSize = 10;

  // ── Loading / Error ──────────────────────────────────────────────────
  bool _loadingList = false;
  bool _loadingCategories = false;
  bool _saving = false;
  String? _listError;

  // ── Data ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _categoryList = []; // [{glCatCd, glCatName, ...}]

  // ── Controllers & Focus ──────────────────────────────────────────────
  final _orgCodeController = TextEditingController();
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
    _loadCategories();
    _loadGlMasters();
  }

  @override
  void dispose() {
    _orgCodeController.dispose();
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

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final data = await apiService.getAllGlCategories();
    setState(() {
      _loadingCategories = false;
      _categoryList = data ?? [];
    });
  }

  Future<void> _loadGlMasters() async {
    setState(() {
      _loadingList = true;
      _listError = null;
    });
    final data = await apiService.getAllGlMasters();
    setState(() {
      _loadingList = false;
      if (data != null) {
        _accounts = data;
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

    final payload = {
      'orgCode': int.tryParse(_orgCodeController.text.trim()) ?? 0,
      'glNo': int.tryParse(_glNumberController.text.trim()) ?? 0,
      'glName': _glNameController.text.trim(),
      'glCatCd': _selectedCategoryCd ?? 0,
      'status': _selectedStatus == 'Active' ? 1 : 0,
      'eUser': widget.userName ?? '',
      // 'eDate': null,
      // 'aUser': null,
      // 'aDate': null,
      // 'cUser': null,
      // 'cDate': null,
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
      await _loadGlMasters(); // Refresh list
    } else {
      _showSnack(
        _isEditing
            ? 'Failed to update GL Master'
            : 'Failed to create GL Master',
        isError: true,
      );
    }
  }

  Future<void> _deleteGlMaster(Map<String, dynamic> c) async {
    final glNo = c['glNo'] is int
        ? c['glNo'] as int
        : int.tryParse(c['glNo'].toString()) ?? 0;
    final success = await apiService.deleteGlMaster(glNo);

    if (!mounted) return;

    if (success) {
      _showSnack('${c['glName']} deleted successfully', isError: false);
      await _loadGlMasters();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: bodyStyle(color: Colors.white, weight: FontWeight.w600)),
        backgroundColor: isError ? AppColors.red : AppColors.ink2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
        _orgError = value.trim().isEmpty ? 'Org Code is required' : null;
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
        _orgError = 'Org Code is required';
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
    });
  }

  void _editAccount(Map<String, dynamic> c) {
    final catCd = c['glCatCd'];
    final catName = _catName(catCd);
    setState(() {
      _showForm = true;
      _isViewOnly = false;
      _isEditing = true;
      _orgCodeController.text = c['orgCode']?.toString() ?? '';
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

  void _viewAccount(Map<String, dynamic> c) {
    final catCd = c['glCatCd'];
    final catName = _catName(catCd);
    setState(() {
      _showForm = true;
      _isViewOnly = true;
      _isEditing = false;
      _orgCodeController.text = c['orgCode']?.toString() ?? '';
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
            title: 'GL Master Account (GL102)',
            subtitle: '',
            badges: [],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(label: 'GL Module', onTap: widget.onBackToModule),
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
            child: Row(
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
            ),
          ),
          Expanded(child: _buildTable()),
          _buildPaginationFooter(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Table
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTable() {
    if (_loadingList) {
      return const Center(child: CircularProgressIndicator());
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
              onPressed: _loadGlMasters,
            ),
          ],
        ),
      );
    }

    final filtered = _accounts.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c['glName'].toString().toLowerCase().contains(q) ||
          c['glNo'].toString().toLowerCase().contains(q);
    }).toList();

    final startIndex = (_currentPage - 1) * _pageSize;
    final paginated = filtered.skip(startIndex).take(_pageSize).toList();

    if (paginated.isEmpty && filtered.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setState(() => _currentPage = 1));
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
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, idx) {
        final c = paginated[idx];
        final catName = _catName(c['glCatCd']);
        final statusLbl = _statusLabel(c['status']);
        final isActive = statusLbl == 'Active';

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
                        : (_isEditing ? 'Edit GL Account' : 'Create GL Account'),
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
            label: 'Org Code',
            required: true,
            labelAbove: true,
            tooltip: 'Organization Code',
            child: AmsTextInput(
              controller: _orgCodeController,
              focusNode: _orgFocus,
              errorText: _orgError,
              isValid: _orgCodeController.text.trim().isNotEmpty &&
                  _orgError == null,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (v) =>
                  _validateField(v, 'org', _glNumberFocus),
              placeholder: 'e.g. 1',
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
              onFieldSubmitted: (v) =>
                  _validateField(v, 'number', _glNameFocus),
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
              onFieldSubmitted: (v) =>
                  _validateField(v, 'name', _categoryFocus),
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
                    isValid: _selectedCategoryName != null &&
                        _categoryError == null,
                    onChanged: (val) {
                      final match = _categoryList.firstWhere(
                        (c) => c['glCatName']?.toString() == val,
                        orElse: () => {},
                      );
                      setState(() {
                        _selectedCategoryName = val;
                        _selectedCategoryCd = match['glCatCd'] is int
                            ? match['glCatCd'] as int
                            : int.tryParse(
                                match['glCatCd']?.toString() ?? '');
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
    final filteredCount = _accounts.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c['glName'].toString().toLowerCase().contains(q) ||
          c['glNo'].toString().toLowerCase().contains(q);
    }).length;

    if (filteredCount == 0) return const SizedBox(height: 16);

    final totalPages = (filteredCount / _pageSize).ceil();
    final start = ((_currentPage - 1) * _pageSize) + 1;
    final end = (start + _pageSize - 1).clamp(0, filteredCount);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing $start–$end of $filteredCount',
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
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              ...List.generate(totalPages, (index) {
                final pageNum = index + 1;
                final isCurr = pageNum == _currentPage;
                return GestureDetector(
                  onTap: () => setState(() => _currentPage = pageNum),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurr ? AppColors.tBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('$pageNum',
                        style: bodyStyle(
                            size: 13,
                            color: isCurr ? Colors.white : AppColors.ink3,
                            weight:
                                isCurr ? FontWeight.w700 : FontWeight.w500)),
                  ),
                );
              }),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded,
                    size: 20,
                    color: _currentPage < totalPages
                        ? AppColors.ink3
                        : AppColors.border),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
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
