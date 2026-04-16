import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

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
  // Swap these stubs for your real userAccessApiService calls.
  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600)); // simulate network
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
              // Avatar
              CircleAvatar(
                backgroundColor: AppColors.tBlueLt,
                child: Text(
                  userCode.isNotEmpty ? userCode[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: AppColors.tBlue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),

              // Info
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

              // Status badge
              AmsBadge(
                label: (status == '0') ? 'Disabled' : 'Enabled',
                color: (status == '0') ? AppColors.red : AppColors.green,
                background:
                    (status == '0') ? AppColors.redLt : AppColors.greenLt,
              ),
              const SizedBox(width: 24),

              // Actions
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
          // Form header bar
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

          // Form fields
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

          // Footer
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
  final _userCodeCtrl = TextEditingController();
  final _productCodeCtrl = TextEditingController();
  final _accessCodeCtrl = TextEditingController();

  int _status = 1; // 1=Enable, 0=Disable

  final Map<String, String?> _errors = {};

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  @override
  void didUpdateWidget(covariant UserAccessFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _populateFields();
    }
  }

  @override
  void dispose() {
    _orgCodeCtrl.dispose();
    _userCodeCtrl.dispose();
    _productCodeCtrl.dispose();
    _accessCodeCtrl.dispose();
    super.dispose();
  }

  // ── Populate / Clear ─────────────────────────────────────────────────────────
  void _populateFields() {
    final d = widget.initialData;
    if (d == null || d.isEmpty) {
      clear();
      return;
    }
    _orgCodeCtrl.text = (d['orgCode'] ?? d['orgcode'] ?? 50).toString();
    _userCodeCtrl.text = (d['userCode'] ?? d['usercode'] ?? '').toString();
    _productCodeCtrl.text =
        (d['productCode'] ?? d['productcode'] ?? '').toString();
    _accessCodeCtrl.text =
        (d['accessCode'] ?? d['accesscode'] ?? '').toString();
    _status = int.tryParse((d['status'] ?? 1).toString()) ?? 1;
    _errors.clear();
    if (mounted) setState(() {});
  }

  void clear() {
    _orgCodeCtrl.text = '50';
    _userCodeCtrl.clear();
    _productCodeCtrl.clear();
    _accessCodeCtrl.clear();
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

      if (_userCodeCtrl.text.trim().isEmpty) {
        _errors['userCode'] = 'User Code is required';
        ok = false;
      } else {
        _errors['userCode'] = null;
      }

      if (_productCodeCtrl.text.trim().isEmpty) {
        _errors['productCode'] = 'Product Code is required';
        ok = false;
      } else {
        _errors['productCode'] = null;
      }

      if (_accessCodeCtrl.text.trim().isEmpty) {
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

              // User Code
              AmsField(
                label: 'User Code',
                required: true,
                labelAbove: true,
                tooltip: 'Unique identifier for the user (e.g. USR001).',
                child: AmsTextInput(
                  controller: _userCodeCtrl,
                  readOnly: widget.isViewMode || widget.initialData != null,
                  placeholder: 'e.g. USR001',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['userCode'],
                  isValid: _errors['userCode'] == null &&
                      _userCodeCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['userCode'] =
                          v.trim().isEmpty ? 'User Code is required' : null;
                    });
                    widget.onChanged('userCode', v.trim());
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
              // Product Code
              AmsField(
                label: 'Product Code',
                required: true,
                labelAbove: true,
                tooltip: 'Product code this user is mapped to (e.g. PROD001).',
                child: AmsTextInput(
                  controller: _productCodeCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. PROD001',
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

              // Access Code
              AmsField(
                label: 'Access Code',
                required: true,
                labelAbove: true,
                tooltip:
                    'Access code that defines the permission level (e.g. ACC001).',
                child: AmsTextInput(
                  controller: _accessCodeCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. ACC001',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['accessCode'],
                  isValid: _errors['accessCode'] == null &&
                      _accessCodeCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['accessCode'] =
                          v.trim().isEmpty ? 'Access Code is required' : null;
                    });
                    widget.onChanged('accessCode', v.trim());
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
