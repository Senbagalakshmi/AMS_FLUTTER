import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class GLCategoryScreen extends StatefulWidget {
  final VoidCallback onBack;
  final String? userName;

  const GLCategoryScreen({
    super.key,
    required this.onBack,
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

  @override
  void initState() {
    super.initState();
    _orgCodeController.addListener(_onFormChange);
    _catCodeController.addListener(_onFormChange);
    _catNameController.addListener(_onFormChange);
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
        _catCodeError = value.trim().isEmpty ? 'Category Code is required' : null;
      } else if (fieldName == 'name') {
        _catNameError = value.trim().isEmpty ? 'Category Name is required' : null;
      } else if (fieldName == 'type') {
        _catTypeError = _selectedCategoryType == null ? 'Category Type is required' : null;
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
      if (_orgCodeController.text.trim().isEmpty) _orgError = 'Org Code is required';
      if (_catCodeController.text.trim().isEmpty) _catCodeError = 'Category Code is required';
      if (_catNameController.text.trim().isEmpty) _catNameError = 'Category Name is required';
      if (_selectedCategoryType == null) _catTypeError = 'Category Type is required';
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
      _orgError = null;
      _catCodeError = null;
      _catNameError = null;
      _catTypeError = null;
    });
  }

  // Dummy data based on the screenshot
  final List<Map<String, dynamic>> _categories = [
    {'orgCode': 'ORG01', 'code': '1001', 'name': 'Current Assets', 'type': 'Asset', 'subType': 'Operating', 'status': 'Active'},
    {'orgCode': 'ORG01', 'code': '1002', 'name': 'Fixed Assets', 'type': 'Asset', 'subType': 'Non-Operating', 'status': 'Active'},
    {'orgCode': 'ORG01', 'code': '2001', 'name': 'Current Liabilities', 'type': 'Liability', 'subType': 'Short-term', 'status': 'Active'},
    {'orgCode': 'ORG01', 'code': '3001', 'name': 'Share Capital', 'type': 'Capital', 'subType': 'Equity', 'status': 'Active'},
    {'orgCode': 'ORG01', 'code': '4001', 'name': 'Sales Revenue', 'type': 'Income', 'subType': 'Operating', 'status': 'Active'},
    {'orgCode': 'ORG02', 'code': '5001', 'name': 'Operating Expense', 'type': 'Expense', 'subType': 'Indirect', 'status': 'Inactive'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.category_rounded, size: 28, color: AppColors.tBlue),
            title: 'GL Category',
            subtitle: 'List View • Create / Edit Form',
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
                                    placeholder: 'Search categories...',
                                    onChanged: (v) => setState(() => _searchQuery = v),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                AmsButton(
                                  label: '+ Add New',
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
                                  color: AppColors.tBlue,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                child: Text(
                                  _isViewOnly
                                      ? 'View GL Category'
                                      : (_catCodeController.text.isNotEmpty
                                          ? 'Edit GL Category'
                                          : 'Create GL Category'),
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
    final firstLetter = _catNameController.text.isNotEmpty
        ? _catNameController.text.substring(0, 1).toUpperCase()
        : 'C';

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
                  'Rec Code', _catCodeController.text, Icons.tag_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
            'Classification', _selectedCategoryType ?? '—', Icons.category_rounded),
        const SizedBox(height: 16),
        _buildInfoCard(
            'Sub-Classification',
            _subTypeController.text.isEmpty ? 'Not Provided' : _subTypeController.text,
            Icons.account_tree_outlined),

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
          tooltip: 'Enter the Organization Code identifying this record',
          child: AmsTextInput(
            controller: _orgCodeController,
            focusNode: _orgFocus,
            errorText: _orgError,
            isValid: _orgCodeController.text.trim().isNotEmpty && _orgError == null,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (v) => _validateField(v, 'org', _catCodeFocus),
            placeholder: 'e.g. ORG01',
          ),
        ),
        AmsField(
          label: 'Category Code',
          required: true,
          labelAbove: true,
          tooltip: 'Enter the unique Category Code (e.g. 1001)',
          child: AmsTextInput(
            controller: _catCodeController,
            focusNode: _catCodeFocus,
            errorText: _catCodeError,
            isValid: _catCodeController.text.trim().isNotEmpty && _catCodeError == null,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (v) => _validateField(v, 'code', _catNameFocus),
            placeholder: 'e.g. 1001',
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
            isValid: _catNameController.text.trim().isNotEmpty && _catNameError == null,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (v) => _validateField(v, 'name', _catTypeFocus),
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
            items: const ['Asset', 'Liability', 'Capital', 'Income', 'Expense'],
          ),
        ),
        AmsField(
          label: 'Sub Type',
          required: false,
          labelAbove: true,
          tooltip: 'Optional sub-classification type for granular filtering',
          child: AmsTextInput(
            controller: _subTypeController,
            focusNode: _subTypeFocus,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (v) {
              if (_isFormValid) {
                setState(() => _showForm = false);
                _clearFields();
              } else {
                _validateAll();
              }
            },
            placeholder: 'Optional sub-type',
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
              onPressed: () {
                if (_isFormValid) {
                  setState(() => _showForm = false);
                  _clearFields();
                } else {
                  _validateAll();
                }
              },
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
            final filteredCount = _categories.where((c) {
              if (_searchQuery.isEmpty) return true;
              final q = _searchQuery.toLowerCase();
              return c['name'].toString().toLowerCase().contains(q) || c['code'].toString().toLowerCase().contains(q);
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
              ...List.generate(((_categories.where((c) {
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                return c['name'].toString().toLowerCase().contains(q) || c['code'].toString().toLowerCase().contains(q);
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
                            _categories.where((c) {
                              if (_searchQuery.isEmpty) return true;
                              final q = _searchQuery.toLowerCase();
                              return c['name'].toString().toLowerCase().contains(q) || c['code'].toString().toLowerCase().contains(q);
                            }).length)
                        ? AppColors.ink3
                        : AppColors.border),
                onPressed: (_currentPage * _pageSize <
                        _categories.where((c) {
                          if (_searchQuery.isEmpty) return true;
                          final q = _searchQuery.toLowerCase();
                          return c['name'].toString().toLowerCase().contains(q) || c['code'].toString().toLowerCase().contains(q);
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

  void _editCategory(Map<String, dynamic> c) {
    setState(() {
      _showForm = true;
      _isViewOnly = false;
      _orgCodeController.text = c['orgCode']?.toString() ?? 'ORG01';
      _catCodeController.text = c['code']?.toString() ?? '';
      _catNameController.text = c['name']?.toString() ?? '';
      _subTypeController.text = c['subType']?.toString() ?? '';

      final type = c['type']?.toString();
      if (['Asset', 'Liability', 'Capital', 'Income', 'Expense'].contains(type)) {
        _selectedCategoryType = type;
      } else {
        _selectedCategoryType = null;
      }

      _orgError = null;
      _catCodeError = null;
      _catNameError = null;
      _catTypeError = null;
    });
  }

  void _viewCategory(Map<String, dynamic> c) {
    setState(() {
      _showForm = true;
      _isViewOnly = true;
      _viewStatus = c['status']?.toString() ?? 'Active';
      _orgCodeController.text = c['orgCode']?.toString() ?? 'ORG01';
      _catCodeController.text = c['code']?.toString() ?? '';
      _catNameController.text = c['name']?.toString() ?? '';
      _subTypeController.text = c['subType']?.toString() ?? '';

      final type = c['type']?.toString();
      if (['Asset', 'Liability', 'Capital', 'Income', 'Expense'].contains(type)) {
        _selectedCategoryType = type;
      } else {
        _selectedCategoryType = null;
      }

      _orgError = null;
      _catCodeError = null;
      _catNameError = null;
      _catTypeError = null;
    });
  }

  void _confirmDelete(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Category', style: bodyStyle(size: 16, weight: FontWeight.w700)),
        content: Text('Are you sure you want to delete ${c['name']}?', style: bodyStyle(size: 14)),
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
                _categories.removeWhere((item) => item['code'] == c['code']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${c['name']} deleted successfully', style: bodyStyle(color: Colors.white, weight: FontWeight.w600)),
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
    final filtered = _categories.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c['name'].toString().toLowerCase().contains(q) || c['code'].toString().toLowerCase().contains(q);
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
        final isAsset = c['type'] == 'Asset';
        final isLiab = c['type'] == 'Liability';
        final isCap = c['type'] == 'Capital';
        final isInc = c['type'] == 'Income';
        final isExp = c['type'] == 'Expense';

        Color typeBg = AppColors.bg;
        Color typeFg = AppColors.ink2;

        if (isAsset) {
          typeBg = AppColors.tBlueLt.withValues(alpha: 0.5);
          typeFg = AppColors.tBlue;
        } else if (isLiab) {
          typeBg = const Color(0xFFF3E8FF);
          typeFg = const Color(0xFF7E22CE);
        } else if (isCap) {
          typeBg = AppColors.nTealLt.withValues(alpha: 0.5);
          typeFg = AppColors.nTeal;
        } else if (isInc) {
          typeBg = AppColors.greenLt;
          typeFg = AppColors.green;
        } else if (isExp) {
          typeBg = AppColors.amberLt.withValues(alpha: 0.5);
          typeFg = AppColors.amber;
        }

        final isActive = c['status'] == 'Active';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.tBlueLt, shape: BoxShape.circle),
                child: Center(
                  child: Text(c['name'].toString().substring(0, 1).toUpperCase(),
                      style: bodyStyle(size: 16, color: AppColors.tBlue, weight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['name'], style: bodyStyle(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Type: ', style: bodyStyle(size: 12, color: AppColors.ink3)),
                        Text('${c['type']}', style: bodyStyle(size: 12, color: typeFg, weight: FontWeight.w600)),
                        Text('   |   Status: ', style: bodyStyle(size: 12, color: AppColors.ink3)),
                        Text('${c['status']}', style: bodyStyle(size: 12, color: isActive ? AppColors.green : AppColors.red, weight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              AmsBadge(label: c['code']),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(4)),
                child: Text(c['type'], style: bodyStyle(size: 11, color: typeFg, weight: FontWeight.w600)),
              ),
              const SizedBox(width: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _viewCategory(c),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _editCategory(c),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.tBlue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _confirmDelete(c),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.redLt, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.red.withValues(alpha: 0.2), width: 1.5)),
                      child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
