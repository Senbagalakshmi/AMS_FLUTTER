import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../services/gl_api_service.dart';
import 'package:flutter/services.dart';

class GLAttributeScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onBackToModule;
  final String? userName;

  const GLAttributeScreen({
    super.key,
    required this.onBack,
    required this.onBackToModule,
    this.userName,
  });

  @override
  State<GLAttributeScreen> createState() => _GLAttributeScreenState();
}

class _GLAttributeScreenState extends State<GLAttributeScreen> {
  bool _showForm = false;
  bool _isViewOnly = false;
  bool _isEditMode = false;

  String? _orgError;
  String? _attrIdError;
  String? _valueError;
  String? _glNoError;

  List<Map<String, dynamic>> _glMasters = [];
  bool _loadingGlMasters = false;
  Map<String, dynamic>? _selectedGlMaster;
  String? _selectedGlNoFilter;
  Map<String, dynamic>? _selectedGlMasterForm;

  List<Map<String, dynamic>> _attributeGroups = [];
  bool _loadingAttributes = false;
  bool _savingAttribute = false;

  final _orgController = TextEditingController(text: '1');
  final _attrIdController = TextEditingController();
  final _valueController = TextEditingController();
  final _descController = TextEditingController();
  final _glNameController = TextEditingController();

  final _orgFocus = FocusNode();
  final _attrIdFocus = FocusNode();
  final _valueFocus = FocusNode();
  final _descFocus = FocusNode();

  List<Map<String, dynamic>> attributes = [{"id": "", "value": "", "desc": ""}];
  final Set<String> _expandedGls = {};

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    await _loadGlMasters();
    await _loadAllAttributes();
  }

  @override
  void dispose() {
    _orgController.dispose();
    _attrIdController.dispose();
    _valueController.dispose();
    _descController.dispose();
    _glNameController.dispose();
    _orgFocus.dispose();
    _attrIdFocus.dispose();
    _valueFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Future<void> _loadGlMasters() async {
    setState(() => _loadingGlMasters = true);
    final data = await apiService.getAllGlMasters();
    setState(() {
      _loadingGlMasters = false;
      _glMasters = data?.items ?? [];
      if (_glMasters.isNotEmpty && _selectedGlMaster == null) {
        _selectedGlMaster = _glMasters.first;
      }
    });
  }

  Future<void> _loadAllAttributes() async {
    setState(() => _loadingAttributes = true);
    final raw = await GLApiService.getAllGlAttributes();
    setState(() {
      _loadingAttributes = false;
      if (raw != null) {
        _attributeGroups = _groupByGlNo(raw);
      }
    });
  }

  Future<void> _loadAttributesByGlNo(int glNo) async {
    setState(() => _loadingAttributes = true);
    final raw = await GLApiService.getGlAttributesByGlNo(glNo);
    setState(() {
      _loadingAttributes = false;
      if (raw != null) {
        _attributeGroups = _groupByGlNo(raw);
      }
    });
  }

  List<Map<String, dynamic>> _groupByGlNo(List<Map<String, dynamic>> raw) {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final item in raw) {
      final glNo = item['glNo']?.toString() ?? '';
      if (!grouped.containsKey(glNo)) {
        final master = _glMasters.firstWhere(
          (m) => m['glNo']?.toString() == glNo,
          orElse: () => <String, dynamic>{},
        );
        grouped[glNo] = {
          'name': master['glName']?.toString() ?? 'GL $glNo',
          'glNo': glNo,
          'type': master['glType']?.toString() ?? '—',
          'status': 'Active',
          'attrs': <Map<String, dynamic>>[],
        };
      }
      grouped[glNo]!['attrs'].add({
        'id': item['glAttrid'] ?? '',
        'value': item['glAttrValue'] ?? '',
        'desc': '',
        'orgCode': item['orgCode'],
      });
    }
    // ✅ Latest inserted group shows first
    return grouped.values.toList().reversed.toList();
  }

  void _onGlMasterFormChanged(Map<String, dynamic>? gl) {
    setState(() {
      _selectedGlMasterForm = gl;
      _glNameController.text = gl?['glName']?.toString() ?? '';
      _glNoError = gl == null ? 'GL Account is required' : null;
    });
  }

  Future<void> _saveSet() async {
    if (!_validateAll()) return;
    setState(() => _savingAttribute = true);

    final orgCode = int.tryParse(_orgController.text.trim()) ?? 1;
    final glNo = int.tryParse(_selectedGlMasterForm?['glNo']?.toString() ?? '') ?? 0;
    final attrId = _attrIdController.text.trim();
    final attrValue = _valueController.text.trim();
    final currentUser = widget.userName ?? 'SYSTEM';

    bool success;
    if (_isEditMode) {
      success = await GLApiService.updateGlAttribute(
        orgCode: orgCode,
        glNo: glNo,
        glAttrid: attrId,
        glAttrValue: attrValue,
        eUser: currentUser,
      );
    } else {
      success = await GLApiService.createGlAttribute(
        orgCode: orgCode,
        glNo: glNo,
        glAttrid: attrId,
        glAttrValue: attrValue,
        eUser: currentUser,
      );
    }

    setState(() => _savingAttribute = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode
              ? 'Attribute updated successfully.'
              : 'Attribute created successfully.'),
          backgroundColor: AppColors.green,
        ),
      );
      await _loadAllAttributes();
      setState(() => _showForm = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save attribute. Organisation Code and GL already exists.'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  void _confirmDelete(String glNoStr) {
    final glNo = int.tryParse(glNoStr) ?? 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Attribute'),
        content: Text('Are you sure you want to delete all attributes for GL $glNoStr?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success =
                  await GLApiService.deleteGlAttribute(glNo);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Attribute deleted.'),
                      backgroundColor: AppColors.green),
                );
                await _loadAllAttributes();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Delete failed.'),
                      backgroundColor: AppColors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _showForm ? _buildFullFormView() : _buildListView();
  }

  Widget _buildListView() {
    final filteredSets = _selectedGlNoFilter == null
        ? _attributeGroups
        : _attributeGroups
            .where((s) => s['glNo'] == _selectedGlNoFilter)
            .toList();

    return Column(
      children: [
        AmsIdentityHeader(
          icon: const Icon(Icons.settings_rounded,
              size: 28, color: AppColors.tBlue),
          title: 'GL Attribute',
          subtitle: 'Manage custom fields for GL accounts',
          badges: const [],
          accentColor: AppColors.tBlue,
          accentLt: AppColors.tBlueLt,
          accentMd: AppColors.tBlueMd,
          breadcrumbs: [
            HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
            HeaderBreadcrumb(
                label: 'GL Module', onTap: widget.onBackToModule),
            HeaderBreadcrumb(label: 'GL Attribute'),
          ],
          onBack: widget.onBackToModule,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 4,
                      child: AmsField(
                        label: 'Filter by GL Account',
                        labelAbove: true,
                        child: _loadingAttributes
                            ? _glLoadingBox()
                            : _attributeGroups.isEmpty
                                ? _glEmptyBox()
                                : _buildFilterDropdown(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AmsButton(
                      label: 'Add New',
                      icon: Icons.add_rounded,
                      variant: AmsButtonVariant.primary,
                      onPressed: _openCreateForm,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _loadingAttributes
                      ? const Center(child: CircularProgressIndicator())
                      : filteredSets.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded,
                                      size: 48,
                                      color: AppColors.ink4
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                      'No attributes found for this account.',
                                      style:
                                          bodyStyle(color: AppColors.ink4)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredSets.length,
                              separatorBuilder: (ctx, idx) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (ctx, idx) =>
                                  _buildSetCard(filteredSets[idx]),
                            ),
                ),
                _buildPaginationFooter(filteredSets.length),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    final items = <DropdownMenuItem<String>>[];
    items.add(const DropdownMenuItem<String>(
      value: null,
      child: Text(
        'All GL Accounts',
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      ),
    ));
    for (final group in _attributeGroups) {
      final glNo = group['glNo']?.toString() ?? '';
      final name = group['name']?.toString() ?? 'GL $glNo';
      items.add(DropdownMenuItem<String>(
        value: glNo,
        child: Text(
          'GL $glNo — $name',
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
        ),
      ));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGlNoFilter,
          isExpanded: true,
          hint: const Text(
            'All GL Accounts',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF475569)),
          items: items,
          onChanged: (glNoStr) {
            setState(() => _selectedGlNoFilter = glNoStr);
            if (glNoStr != null) {
              final glNo = int.tryParse(glNoStr);
              if (glNo != null) _loadAttributesByGlNo(glNo);
            } else {
              _loadAllAttributes();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSetCard(Map<String, dynamic> item) {
    final name = item['name'] as String;
    final glNo = item['glNo'] as String;
    final type = item['type'] as String;
    final status = item['status'] as String;
    final List<Map<String, dynamic>> attrs =
        List<Map<String, dynamic>>.from(item['attrs'] ?? []);
    final isExpanded = _expandedGls.contains(glNo);

    Color typeFg =
        type == 'Liability' ? const Color(0xFF7E22CE) : AppColors.tBlue;
    Color typeBg = type == 'Liability'
        ? const Color(0xFFF3E8FF)
        : AppColors.tBlueLt.withValues(alpha: 0.5);

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
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: AppColors.tBlueLt, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
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
                        style:
                            bodyStyle(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _statusDot(status == 'Active'
                            ? AppColors.green
                            : AppColors.red),
                        const SizedBox(width: 6),
                        Text(status,
                            style:
                                bodyStyle(size: 12, color: AppColors.ink3)),
                        const SizedBox(width: 12),
                        Text('GL: $glNo',
                            style: bodyStyle(
                                size: 12,
                                color: AppColors.ink3,
                                weight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: typeBg,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(type,
                    style: bodyStyle(
                        size: 11,
                        color: typeFg,
                        weight: FontWeight.w600)),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  _actionIconButton(Icons.visibility_outlined,
                      AppColors.green, () => _viewSet(item)),
                  const SizedBox(width: 8),
                  _actionIconButton(Icons.edit_outlined, AppColors.tBlue,
                      () => _editSet(item)),
                  const SizedBox(width: 8),
                  _actionIconButton(
                    Icons.delete_outline_rounded,
                    AppColors.red,
                    () => _confirmDelete(glNo),
                    bg: AppColors.redLt,
                  ),
                ],
              ),
            ],
          ),
          if (attrs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ...(isExpanded ? attrs : attrs.take(2)).map((a) =>
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 120,
                              child: Text(a['id'] ?? '',
                                  style: bodyStyle(
                                      size: 11,
                                      weight: FontWeight.w800,
                                      color: AppColors.tBlue)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Text(a['value'] ?? '',
                                  style: bodyStyle(
                                      size: 11,
                                      weight: FontWeight.w800,
                                      color: AppColors.ink)),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(a['desc'] ?? '',
                                  style: bodyStyle(
                                      size: 11,
                                      weight: FontWeight.w500,
                                      color: AppColors.ink4),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      )),
                  if (attrs.length > 2)
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedGls.remove(glNo);
                          } else {
                            _expandedGls.add(glNo);
                          }
                        });
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.only(top: 8, left: 8),
                        child: Row(
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: AppColors.tBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isExpanded
                                  ? 'Show less'
                                  : '+ ${attrs.length - 2} more attributes...',
                              style: bodyStyle(
                                  size: 11,
                                  color: AppColors.tBlue,
                                  weight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullFormView() {
    return Column(
      children: [
        AmsIdentityHeader(
          icon: const Icon(Icons.settings_rounded,
              size: 28, color: AppColors.tBlue),
          title: 'GL Attribute',
          subtitle: 'Manage custom fields for GL accounts',
          badges: const [],
          accentColor: AppColors.tBlue,
          accentLt: AppColors.tBlueLt,
          accentMd: AppColors.tBlueMd,
          breadcrumbs: [
            HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
            HeaderBreadcrumb(
                label: 'GL Module', onTap: widget.onBackToModule),
            HeaderBreadcrumb(label: 'GL Attribute'),
          ],
          onBack: widget.onBackToModule,
          showBack: false,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // ── Form Header ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.sidebar,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isViewOnly
                            ? 'View GL Attribute'
                            : (_isEditMode
                                ? 'Edit GL Attribute'
                                : 'Create GL Attribute'),
                        style: bodyStyle(
                            color: Colors.white,
                            weight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Colors.white),
                        onPressed: () =>
                            setState(() => _showForm = false),
                      ),
                    ],
                  ),
                ),

                // ── Form Body ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AmsFormGrid(
                          cols: 2,
                          children: [
                            AmsField(
                              label: 'Organisation Code',
                              labelAbove: true,
                              required: true,
                              child: AmsTextInput(
                                controller: _orgController,
                                focusNode: _orgFocus,
                                textInputAction: TextInputAction.next,
                                 inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                                onFieldSubmitted: (_) =>
                                    FocusScope.of(context)
                                        .requestFocus(_attrIdFocus),
                                readOnly: _isViewOnly || _isEditMode,
                                errorText: _orgError,
                                onChanged: (v) => setState(() {
                                  _orgError = v.isEmpty
                                      ? 'Organisation Code is required'
                                      : null;
                                }),
                              ),
                            ),
                            AmsField(
                              label: 'GL No.',
                              labelAbove: true,
                              required: true,
                              child: _isViewOnly
                                  ? _glReadOnlyBox(
                                      _selectedGlMasterForm?['glNo']
                                              ?.toString() ??
                                          '—')
                                  : _loadingGlMasters
                                      ? _glLoadingBox()
                                      : _glMasters.isEmpty
                                          ? _glEmptyBox()
                                          : _glDropdown(
                                              value: _selectedGlMasterForm,
                                              hint: 'Select GL Account',
                                              onChanged:
                                                  _onGlMasterFormChanged,
                                              errorText: _glNoError,
                                            ),
                            ),
                            AmsField(
                              label: 'Attribute ID',
                              labelAbove: true,
                              required: true,
                              child: AmsTextInput(
                                controller: _attrIdController,
                                focusNode: _attrIdFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) =>
                                    FocusScope.of(context)
                                        .requestFocus(_valueFocus),
                                readOnly: _isViewOnly,
                                errorText: _attrIdError,
                                onChanged: (v) => setState(() {
                                  _attrIdError = v.isEmpty
                                      ? 'Attribute ID is required'
                                      : null;
                                }),
                                placeholder: 'e.g. TAX_CODE',
                              ),
                            ),
                            AmsField(
                              label: 'Value',
                              labelAbove: true,
                              required: true,
                              child: AmsTextInput(
                                controller: _valueController,
                                focusNode: _valueFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) =>
                                    FocusScope.of(context)
                                        .requestFocus(_descFocus),
                                readOnly: _isViewOnly,
                                errorText: _valueError,
                                onChanged: (v) => setState(() {
                                  _valueError = v.isEmpty
                                      ? 'Value is required'
                                      : null;
                                }),
                                placeholder: 'Enter value',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Action Bar ───────────────────────────────────────
                if (!_isViewOnly)
                  AmsSubmitBar(
                    borderColor: AppColors.border,
                    actions: [
                      _savingAttribute
                          ? const Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          : AmsButton(
                              label: 'Save Changes',
                              variant: AmsButtonVariant.primary,
                              backgroundColor: AppColors.sidebar,
                              onPressed: _saveSet,
                            ),
                      AmsButton(
                        label: 'Clear All',
                        variant: AmsButtonVariant.outline,
                        onPressed: _clearForm,
                      ),
                      AmsButton(
                        label: 'Cancel',
                        variant: AmsButtonVariant.danger,
                        onPressed: () =>
                            setState(() => _showForm = false),
                      ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AmsButton(
                        label: 'Back to List',
                        icon: Icons.arrow_back_rounded,
                        variant: AmsButtonVariant.primary,
                        backgroundColor: AppColors.red,
                        onPressed: () =>
                            setState(() => _showForm = false),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openCreateForm() {
    setState(() {
      _showForm = true;
      _isViewOnly = false;
      _isEditMode = false;
      _clearForm();
    });
  }

  void _clearForm() {
    setState(() {
      _orgController.text = '1';
      _attrIdController.clear();
      _valueController.clear();
      _descController.clear();
      _glNameController.clear();
      _selectedGlMasterForm = null;
      _orgError = null;
      _attrIdError = null;
      _valueError = null;
      _glNoError = null;
      attributes = [{"id": "", "value": "", "desc": ""}];
    });
  }

  bool _validateAll() {
    setState(() {
      _glNoError = _selectedGlMasterForm == null
          ? 'GL Account is required'
          : null;
      _attrIdError = _attrIdController.text.trim().isEmpty
          ? 'Attribute ID is required'
          : null;
      _valueError = _valueController.text.trim().isEmpty
          ? 'Value is required'
          : null;
      _orgError = null;
    });
    return _glNoError == null &&
        _attrIdError == null &&
        _valueError == null;
  }

  void _editSet(Map<String, dynamic> item) {
    final matchedGl = _glMasters.firstWhere(
      (m) => m['glNo']?.toString() == item['glNo'],
      orElse: () => <String, dynamic>{},
    );
    final List<Map<String, dynamic>> attrs =
        List<Map<String, dynamic>>.from(item['attrs'] ?? []);
    setState(() {
      _showForm = true;
      _isViewOnly = false;
      _isEditMode = true;
      _orgError = null;
      _attrIdError = null;
      _valueError = null;
      _glNoError = null;
      _selectedGlMasterForm =
          matchedGl.isNotEmpty ? matchedGl : null;
      _glNameController.text = item['name'] ?? '';
      _orgController.text = attrs.isNotEmpty
          ? attrs[0]['orgCode']?.toString() ?? '1'
          : '1';
      if (attrs.isNotEmpty) {
        _attrIdController.text = attrs[0]['id'] ?? '';
        _valueController.text = attrs[0]['value'] ?? '';
        _descController.text = attrs[0]['desc'] ?? '';
      }
      attributes = attrs;
    });
  }

  void _viewSet(Map<String, dynamic> item) {
    final matchedGl = _glMasters.firstWhere(
      (m) => m['glNo']?.toString() == item['glNo'],
      orElse: () => <String, dynamic>{},
    );
    final List<Map<String, dynamic>> attrs =
        List<Map<String, dynamic>>.from(item['attrs'] ?? []);
    setState(() {
      _showForm = true;
      _isViewOnly = true;
      _isEditMode = false;
      _orgError = null;
      _attrIdError = null;
      _valueError = null;
      _glNoError = null;
      _selectedGlMasterForm =
          matchedGl.isNotEmpty ? matchedGl : null;
      _glNameController.text = item['name'] ?? '';
      _orgController.text = attrs.isNotEmpty
          ? attrs[0]['orgCode']?.toString() ?? '1'
          : '1';
      if (attrs.isNotEmpty) {
        _attrIdController.text = attrs[0]['id'] ?? '';
        _valueController.text = attrs[0]['value'] ?? '';
        _descController.text = attrs[0]['desc'] ?? '';
      }
      attributes = attrs;
    });
  }

  Widget _glDropdown({
    required Map<String, dynamic>? value,
    required String hint,
    required ValueChanged<Map<String, dynamic>?> onChanged,
    bool includeAll = false,
    String? errorText,
  }) {
    final items = <DropdownMenuItem<Map<String, dynamic>>>[];
    if (includeAll) {
      items.add(const DropdownMenuItem<Map<String, dynamic>>(
        value: null,
        child: Text('All GL Accounts',
            style: TextStyle(
                color: Color(0xFF94A3B8), fontSize: 14)),
      ));
    }
    for (final gl in _glMasters) {
      final glNo = gl['glNo']?.toString() ?? '';
      final glName = gl['glName']?.toString() ?? '';
      items.add(DropdownMenuItem<Map<String, dynamic>>(
        value: gl,
        child: Text('GL $glNo — $glName',
            style: const TextStyle(
                color: Color(0xFF0F172A), fontSize: 14)),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null
                  ? AppColors.red.withValues(alpha: 0.6)
                  : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: value,
              isExpanded: true,
              hint: Text(hint,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 14)),
              style: const TextStyle(
                  color: Color(0xFF0F172A), fontSize: 14),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF475569)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(errorText,
                style: bodyStyle(size: 12, color: AppColors.red)),
          ),
      ],
    );
  }

  Widget _glLoadingBox() => Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Loading GL accounts…',
              style:
                  TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
        ]),
      );

  Widget _glEmptyBox() => Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline,
              size: 16, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          const Expanded(
              child: Text('No GL accounts found',
                  style: TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 14))),
          GestureDetector(
              onTap: _loadGlMasters,
              child: const Icon(Icons.refresh,
                  size: 16, color: Color(0xFF1E3A5F))),
        ]),
      );

  Widget _glReadOnlyBox(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFF475569), fontSize: 14)),
      );

  Widget _statusDot(Color color) => Container(
        width: 8,
        height: 8,
        decoration:
            BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _actionIconButton(
      IconData icon, Color color, VoidCallback onTap,
      {Color? bg}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg ?? Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: bg != null
                  ? color.withValues(alpha: 0.2)
                  : AppColors.border),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildPaginationFooter(int total) {
    if (total == 0) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing 1–$total of $total',
              style: bodyStyle(size: 13, color: AppColors.ink3)),
          Row(children: [
            IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: null),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.tBlue,
                  borderRadius: BorderRadius.circular(4)),
              child: Text('1',
                  style: bodyStyle(
                      size: 13,
                      color: Colors.white,
                      weight: FontWeight.w700)),
            ),
            IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: null),
          ]),
        ],
      ),
    );
  }
}