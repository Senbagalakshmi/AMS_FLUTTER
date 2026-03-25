import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class GLMasterScreen extends StatefulWidget {
  final VoidCallback onBack;
  final String? userName;

  const GLMasterScreen({
    super.key,
    required this.onBack,
    this.userName,
  });

  @override
  State<GLMasterScreen> createState() => _GLMasterScreenState();
}

class _GLMasterScreenState extends State<GLMasterScreen> {
  String _searchQuery = '';
  bool _showForm = false;
  String? _selectedCategory;
  String? _selectedStatus;
  bool _isViewOnly = false;
  int _currentPage = 1;
  static const int _pageSize = 10;

  final _orgCodeController = TextEditingController();
  final _glNumberController = TextEditingController();
  final _glNameController = TextEditingController();

  final _orgFocus = FocusNode();
  final _glNumberFocus = FocusNode();
  final _glNameFocus = FocusNode();
  final _categoryFocus = FocusNode();
  final _statusFocus = FocusNode();

  String? _orgError;
  String? _glNumberError;
  String? _glNameError;
  String? _categoryError;
  String? _statusError;

  @override
  void initState() {
    super.initState();
    _orgCodeController.addListener(_onFormChange);
    _glNumberController.addListener(_onFormChange);
    _glNameController.addListener(_onFormChange);
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
      } else if (fieldName == 'number') {
        _glNumberError = value.trim().isEmpty ? 'GL Number is required' : null;
      } else if (fieldName == 'name') {
        _glNameError = value.trim().isEmpty ? 'GL Name is required' : null;
      }
    });
    if (value.trim().isNotEmpty && nextFocus != null) {
      nextFocus.requestFocus();
    }
  }

  bool get _isFormValid {
    return _orgCodeController.text.trim().isNotEmpty &&
           _glNumberController.text.trim().isNotEmpty &&
           _glNameController.text.trim().isNotEmpty &&
           _selectedCategory != null &&
           _selectedStatus != null;
  }

  void _validateAll() {
    setState(() {
      if (_orgCodeController.text.trim().isEmpty) _orgError = 'Org Code is required';
      if (_glNumberController.text.trim().isEmpty) _glNumberError = 'GL Number is required';
      if (_glNameController.text.trim().isEmpty) _glNameError = 'GL Name is required';
      if (_selectedCategory == null) _categoryError = 'Category is required';
      if (_selectedStatus == null) _statusError = 'Status is required';
    });
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

  void _clearFields() {
    _orgCodeController.clear();
    _glNumberController.clear();
    _glNameController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedStatus = null;
      _isViewOnly = false;
      _orgError = null;
      _glNumberError = null;
      _glNameError = null;
      _categoryError = null;
      _statusError = null;
    });
  }

  // Dummy data based on the screenshot
  final List<Map<String, dynamic>> _accounts = [
    {'glNo': '10010', 'glName': 'Cash In Hand', 'category': 'Current Assets', 'status': 'Active'},
    {'glNo': '10020', 'glName': 'Bank — Operating A/c', 'category': 'Current Assets', 'status': 'Active'},
    {'glNo': '20010', 'glName': 'Accounts Payable', 'category': 'Current Liabilities', 'status': 'Active'},
    {'glNo': '40010', 'glName': 'Product Sales', 'category': 'Sales Revenue', 'status': 'Active'},
    {'glNo': '50010', 'glName': 'Staff Salaries', 'category': 'Operating Expense', 'status': 'Active'},
    {'glNo': '50020', 'glName': 'Office Supplies', 'category': 'Operating Expense', 'status': 'Inactive'},
  ];

  final List<String> _categories = [
    'Current Assets',
    'Fixed Assets',
    'Current Liabilities',
    'Share Capital',
    'Sales Revenue',
    'Operating Expense'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 28, color: AppColors.tBlue),
            title: 'GL Master Account (GL102)',
            subtitle: 'List View + Create / Edit Form',
            badges: [],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            onBack: widget.onBack,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT PANEL: List View
                  Expanded(
                    flex: 6,
                    child: Container(
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
                                    onChanged: (v) => setState(() => _searchQuery = v),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                AmsButton(
                                  label: '+ New GL',
                                  variant: AmsButtonVariant.primary,
                                  onPressed: () {
                                    setState(() {
                                      _showForm = true;
                                      _isViewOnly = false;
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
                    ),
                  ),

                  if (_showForm) const SizedBox(width: 20),

                  // RIGHT PANEL: Form
                  if (_showForm)
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Focus(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f2) {
                              FocusManager.instance.primaryFocus?.previousFocus();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: const BoxDecoration(
                                  color: AppColors.tBlue, // Matching the GL Category header color
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                child: Text(
                                  _isViewOnly
                                      ? 'View GL Account'
                                      : (_glNumberController.text.isNotEmpty
                                          ? 'Edit GL Account'
                                          : 'Create GL Account'),
                                  style: bodyStyle(size: 14, color: Colors.white, weight: FontWeight.w700),
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: _isViewOnly ? _buildViewUI() : _buildFormUI(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewUI() {
    final firstLetter = _glNameController.text.isNotEmpty
        ? _glNameController.text.substring(0, 1).toUpperCase()
        : 'G';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile/Header Session
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
                    colors: [AppColors.tBlue, AppColors.tBlue.withValues(alpha: 0.8)],
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
                  child: Text(
                    firstLetter,
                    style: bodyStyle(
                        size: 24, color: Colors.white, weight: FontWeight.w800),
                  ),
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
                        if (_selectedCategory != null)
                          AmsBadge(
                            label: _selectedCategory!,
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
            style: bodyStyle(size: 14, weight: FontWeight.w700, color: AppColors.ink2)),
        const SizedBox(height: 16),

        // Info Cards Side-by-Side
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                  'Organization', _orgCodeController.text, Icons.business_rounded),
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
            'Category', _selectedCategory ?? '—', Icons.category_rounded),

        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: AmsButton(
            label: 'Back to List',
            icon: Icons.arrow_back_rounded,
            variant: AmsButtonVariant.outline,
            onPressed: () {
              _clearFields();
              setState(() => _showForm = false);
            },
          ),
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
          color: (isActive ? AppColors.green : AppColors.red).withValues(alpha: 0.1),
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
                      size: 11, color: AppColors.ink3, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: bodyStyle(size: 14, color: AppColors.ink, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildFormUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmsField(
          label: 'Org Code',
          required: true,
          labelAbove: true,
          tooltip: 'Organization Code (Auto-filled)',
          child: AmsTextInput(
            controller: _orgCodeController,
            focusNode: _orgFocus,
            errorText: _orgError,
            isValid: _orgCodeController.text.trim().isNotEmpty && _orgError == null,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (v) => _validateField(v, 'org', _glNumberFocus),
            placeholder: 'e.g. ORG01',
          ),
        ),
        AmsField(
          label: 'GL Number',
          required: true,
          labelAbove: true,
          tooltip: 'Enter the unique GL Number (e.g. 10010)',
          child: AmsTextInput(
            controller: _glNumberController,
            focusNode: _glNumberFocus,
            errorText: _glNumberError,
            isValid: _glNumberController.text.trim().isNotEmpty && _glNumberError == null,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (v) => _validateField(v, 'number', _glNameFocus),
            placeholder: 'e.g. 10010',
          ),
        ),
        AmsField(
          label: 'GL Name',
          required: true,
          labelAbove: true,
          tooltip: 'Provide a descriptive name for this GL Account',
          child: AmsTextInput(
            controller: _glNameController,
            focusNode: _glNameFocus,
            errorText: _glNameError,
            isValid: _glNameController.text.trim().isNotEmpty && _glNameError == null,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (v) => _validateField(v, 'name', _categoryFocus),
            placeholder: 'Descriptive account name',
          ),
        ),
        AmsField(
          label: 'GL Category',
          required: true,
          labelAbove: true,
          tooltip: 'Select the category for this GL Account',
          child: AmsDropdown(
            focusNode: _categoryFocus,
            placeholder: 'Select category',
            initialValue: _selectedCategory,
            errorText: _categoryError,
            isValid: _selectedCategory != null && _categoryError == null,
            onChanged: (val) {
              setState(() {
                _selectedCategory = val;
                _categoryError = null;
              });
              _statusFocus.requestFocus();
            },
            items: _categories,
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
        const SizedBox(height: 16),
        Text('* Required fields',
            style: bodyStyle(size: 11, color: AppColors.ink3, weight: FontWeight.w500).copyWith(fontStyle: FontStyle.italic)),
        const SizedBox(height: 24),
        Row(
          children: [
            AmsButton(
              label: 'Save',
              variant: AmsButtonVariant.primary,
              onPressed: _isFormValid
                  ? () {
                      if (_isFormValid) {
                        setState(() => _showForm = false);
                        _clearFields();
                      } else {
                        _validateAll();
                      }
                    }
                  : null,
            ),
            const SizedBox(width: 8),
            AmsButton(
              label: 'Clear',
              icon: Icons.clear_all_rounded,
              variant: AmsButtonVariant.outline,
              onPressed: _clearFields,
            ),
            const SizedBox(width: 8),
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
        ),
      ],
    );
  }

  Widget _buildPaginationFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(builder: (context) {
            final filteredCount = _accounts.where((c) {
              if (_searchQuery.isEmpty) return true;
              final q = _searchQuery.toLowerCase();
              return c['glName'].toString().toLowerCase().contains(q) || c['glNo'].toString().toLowerCase().contains(q);
            }).length;
            if (filteredCount == 0) return const SizedBox();
            final start = ((_currentPage - 1) * _pageSize) + 1;
            final end = (start + _pageSize - 1).clamp(0, filteredCount);
            return Text('Showing $start–$end', style: bodyStyle(size: 13, color: AppColors.ink3));
          }),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded, size: 20, color: _currentPage > 1 ? AppColors.ink3 : AppColors.border),
                onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
              ),
              ...List.generate(((_accounts.where((c) {
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                return c['glName'].toString().toLowerCase().contains(q) || c['glNo'].toString().toLowerCase().contains(q);
              }).length) / _pageSize).ceil(), (index) {
                final pageNum = index + 1;
                final isCurrent = pageNum == _currentPage;
                return GestureDetector(
                  onTap: () => setState(() => _currentPage = pageNum),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.tBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('$pageNum',
                        style: bodyStyle(size: 13, color: isCurrent ? Colors.white : AppColors.ink3, weight: isCurrent ? FontWeight.w700 : FontWeight.w500)),
                  ),
                );
              }),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded,
                    size: 20,
                    color: (_currentPage * _pageSize <
                            _accounts.where((c) {
                              if (_searchQuery.isEmpty) return true;
                              final q = _searchQuery.toLowerCase();
                              return c['glName'].toString().toLowerCase().contains(q) || c['glNo'].toString().toLowerCase().contains(q);
                            }).length)
                        ? AppColors.ink3
                        : AppColors.border),
                onPressed: (_currentPage * _pageSize <
                        _accounts.where((c) {
                          if (_searchQuery.isEmpty) return true;
                          final q = _searchQuery.toLowerCase();
                          return c['glName'].toString().toLowerCase().contains(q) || c['glNo'].toString().toLowerCase().contains(q);
                        }).length)
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editAccount(Map<String, dynamic> c) {
    setState(() {
      _showForm = true;
      _isViewOnly = false;
      _orgCodeController.text = 'ORG01';
      _glNumberController.text = c['glNo']?.toString() ?? '';
      _glNameController.text = c['glName']?.toString() ?? '';
      _selectedCategory = c['category']?.toString();
      _selectedStatus = c['status']?.toString();

      _orgError = null;
      _glNumberError = null;
      _glNameError = null;
      _categoryError = null;
      _statusError = null;
    });
  }

  void _viewAccount(Map<String, dynamic> c) {
    setState(() {
      _showForm = true;
      _isViewOnly = true;
      _orgCodeController.text = 'ORG01';
      _glNumberController.text = c['glNo']?.toString() ?? '';
      _glNameController.text = c['glName']?.toString() ?? '';
      _selectedCategory = c['category']?.toString();
      _selectedStatus = c['status']?.toString();

      _orgError = null;
      _glNumberError = null;
      _glNameError = null;
      _categoryError = null;
      _statusError = null;
    });
  }

  void _confirmDelete(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Account', style: bodyStyle(size: 16, weight: FontWeight.w700)),
        content: Text('Are you sure you want to delete ${c['glName']}?', style: bodyStyle(size: 14)),
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
              setState(() {
                _accounts.removeWhere((item) => item['glNo'] == c['glNo']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${c['glName']} deleted successfully', style: bodyStyle(color: Colors.white, weight: FontWeight.w600)),
                  backgroundColor: AppColors.ink2,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final filtered = _accounts.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c['glName'].toString().toLowerCase().contains(q) || c['glNo'].toString().toLowerCase().contains(q);
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
              decoration: BoxDecoration(color: AppColors.bg, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.search_off_rounded, size: 32, color: AppColors.ink4),
            ),
            const SizedBox(height: 16),
            Text('No data available', style: bodyStyle(size: 14, color: AppColors.ink3, weight: FontWeight.w600)),
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
        final isActive = c['status'] == 'Active';

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
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.tBlueLt,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    c['glName'].toString().substring(0, 1).toUpperCase(),
                    style: bodyStyle(
                      size: 16,
                      color: AppColors.tBlue,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['glName'],
                      style: bodyStyle(size: 14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Category: ',
                            style: bodyStyle(size: 12, color: AppColors.ink3)),
                        Text(
                          '${c['category']}',
                          style: bodyStyle(
                              size: 12,
                              color: AppColors.tBlue,
                              weight: FontWeight.w600),
                        ),
                        Text('   |   Status: ',
                            style: bodyStyle(size: 12, color: AppColors.ink3)),
                        Text(
                          '${c['status']}',
                          style: bodyStyle(
                            size: 12,
                            color: isActive ? AppColors.green : AppColors.red,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Column 2: GL Number Badge
              SizedBox(
                width: 80,
                child: Center(child: AmsBadge(label: c['glNo'])),
              ),
              const SizedBox(width: 20),
              // Column 3: Category Pill
              SizedBox(
                width: 150,
                child: UnconstrainedBox(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tBlueLt.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c['category'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle(
                        size: 11,
                        color: AppColors.tBlue,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Column 4: Actions Row
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
