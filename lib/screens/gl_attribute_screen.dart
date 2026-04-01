import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

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
  String selectedAccount = 'Select';

  final _orgController = TextEditingController(text: '1');
  final _attrIdController = TextEditingController();
  final _valueController = TextEditingController();
  final _descController = TextEditingController();

  final _orgFocus = FocusNode();
  final _attrIdFocus = FocusNode();
  final _valueFocus = FocusNode();
  final _descFocus = FocusNode();

  List<Map<String, dynamic>> attributes = [{"id": "", "value": "", "desc": ""}];
  final List<String> glAccounts = [
    'Select',
    'GL 10020 - Bank Operating A/C',
    'GL 10030 - Cash in Hand',
    'GL 20010 - Accounts Payable',
    'GL 40010 - Service Revenue',
  ];

  final List<Map<String, dynamic>> _attributeSets = [
    {
      "name": "Bank Operating A/C",
      "glNo": "10020",
      "type": "Asset",
      "status": "Active",
      "attrs": [
        {"id": "RECON_FLAG", "value": "Y", "desc": "Reconciliation required"},
        {"id": "COST_CENTER", "value": "CC-FINANCE-001", "desc": "Default cost centre"},
        {"id": "CURRENCY", "value": "USD", "desc": "Account currency"},
        {"id": "LIMIT", "value": "50000", "desc": "Daily limit"},
        {"id": "DEPT", "value": "FIN", "desc": "Finance Department"},
        {"id": "AUTH_LEVEL", "value": "3", "desc": "Auth levels"},
      ]
    },
    {
      "name": "Cash in Hand",
      "glNo": "10030",
      "type": "Asset",
      "status": "Active",
      "attrs": [
        {"id": "CASH_LIMIT", "value": "50000", "desc": "Daily cash limit"},
        {"id": "SAFE_ID", "value": "SAFE-01", "desc": "Assigned safe ID"},
      ]
    },
    {
      "name": "Accounts Payable",
      "glNo": "20010",
      "type": "Liability",
      "status": "Active",
      "attrs": [
        {"id": "PAYMENT_TERM", "value": "30_DAYS", "desc": "Default terms"},
      ]
    },
  ];

  final Set<String> _expandedGls = {};

  @override
  Widget build(BuildContext context) {
    return _showForm ? _buildFullFormView() : _buildListView();
  }

  Widget _buildListView() {
    return Column(
      children: [
        AmsIdentityHeader(
          icon: const Icon(Icons.settings_rounded, size: 28, color: AppColors.tBlue),
          title: 'GL Attribute',
          subtitle: 'Manage custom fields for GL accounts',
          badges: const [],
          accentColor: AppColors.tBlue,
          accentLt: AppColors.tBlueLt,
          accentMd: AppColors.tBlueMd,
          breadcrumbs: [
            HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
            HeaderBreadcrumb(label: 'GL Module', onTap: widget.onBackToModule),
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
                        child: AmsDropdown(
                          key: ValueKey(selectedAccount),
                          items: glAccounts,
                          initialValue: selectedAccount,
                          onChanged: (v) => setState(() => selectedAccount = v!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AmsButton(
                      label: 'Add New',
                      icon: Icons.add_rounded,
                      variant: AmsButtonVariant.primary,
                      onPressed: () {
                        setState(() {
                          _showForm = true;
                          _isViewOnly = false;
                          _isEditMode = false;
                          _orgController.text = '1';
                          _attrIdController.clear();
                          _valueController.clear();
                          _descController.clear();
                          selectedAccount = 'Select';
                          attributes = [{"id": "", "value": "", "desc": ""}];
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      // If 'Select' is chosen, show all sets
                      final List<Map<String, dynamic>> filteredSets;
                      if (selectedAccount == 'Select') {
                        filteredSets = _attributeSets;
                      } else {
                        // Extract GL No from "GL 10020 - Name"
                        final matchGl = selectedAccount.split(' - ').first.replaceAll('GL ', '');
                        filteredSets = _attributeSets.where((s) => s['glNo'] == matchGl).toList();
                      }

                      if (filteredSets.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: AppColors.ink4.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text("No attributes found for this account.", style: bodyStyle(color: AppColors.ink4)),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filteredSets.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 16),
                        itemBuilder: (ctx, idx) => _buildSetCard(filteredSets[idx]),
                      );
                    },
                  ),
                ),
                _buildPaginationFooter(_attributeSets.where((s) {
                   if (selectedAccount == 'Select') return true;
                   final matchGl = selectedAccount.split(' - ').first.replaceAll('GL ', '');
                   return s['glNo'] == matchGl;
                }).length),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetCard(Map<String, dynamic> item) {
    final name = item['name'] as String;
    final glNo = item['glNo'] as String;
    final type = item['type'] as String;
    final status = item['status'] as String;
    final List<Map<String, dynamic>> attrs = List<Map<String, dynamic>>.from(item['attrs'] ?? []);
    final isExpanded = _expandedGls.contains(glNo);

    Color typeFg = type == 'Liability' ? const Color(0xFF7E22CE) : AppColors.tBlue;
    Color typeBg = type == 'Liability' ? const Color(0xFFF3E8FF) : AppColors.tBlueLt.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: AppColors.tBlueLt, shape: BoxShape.circle),
                child: Center(child: Text(name[0].toUpperCase(), style: bodyStyle(size: 16, color: AppColors.tBlue, weight: FontWeight.w800))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: bodyStyle(size: 14, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _statusDot(status == 'Active' ? AppColors.green : AppColors.red),
                        const SizedBox(width: 6),
                        Text(status, style: bodyStyle(size: 12, color: AppColors.ink3)),
                        const SizedBox(width: 12),
                        Text('GL: $glNo', style: bodyStyle(size: 12, color: AppColors.ink3, weight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(4)),
                child: Text(type, style: bodyStyle(size: 11, color: typeFg, weight: FontWeight.w600)),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  _actionIconButton(Icons.visibility_outlined, AppColors.green, () => _viewSet(item)),
                  const SizedBox(width: 8),
                  _actionIconButton(Icons.edit_outlined, AppColors.tBlue, () => _editSet(item)),
                  const SizedBox(width: 8),
                  _actionIconButton(Icons.delete_outline_rounded, AppColors.red, () => {}, bg: AppColors.redLt),
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
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ...(isExpanded ? attrs : attrs.take(2)).map((a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          child: Text(a['id'] ?? '', style: bodyStyle(size: 11, weight: FontWeight.w800, color: AppColors.tBlue)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: Text(a['value'] ?? '', style: bodyStyle(size: 11, weight: FontWeight.w800, color: AppColors.ink)),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(a['desc'] ?? '', style: bodyStyle(size: 11, weight: FontWeight.w500, color: AppColors.ink4), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                        padding: const EdgeInsets.only(top: 8, left: 8),
                        child: Row(
                          children: [
                            Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.tBlue),
                            const SizedBox(width: 4),
                            Text(isExpanded ? 'Show less' : '+ ${attrs.length - 2} more attributes...', 
                                 style: bodyStyle(size: 11, color: AppColors.tBlue, weight: FontWeight.w800)),
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
          icon: const Icon(Icons.settings_rounded, size: 28, color: AppColors.tBlue),
          title: 'GL Attribute',
          subtitle: 'Manage custom fields for GL accounts',
          badges: const [],
          accentColor: AppColors.tBlue,
          accentLt: AppColors.tBlueLt,
          accentMd: AppColors.tBlueMd,
          breadcrumbs: [
            HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
            HeaderBreadcrumb(label: 'GL Module', onTap: widget.onBackToModule),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.sidebar,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isViewOnly ? 'View GL Attribute' : (_isEditMode ? 'Edit GL Attribute' : 'Create GL Attribute'),
                        style: bodyStyle(color: Colors.white, weight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
                        onPressed: () => setState(() => _showForm = false),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// MAIN FORM GRID (Matching GL Master 2-column style)
                        AmsFormGrid(
                          cols: 2,
                          children: [
                            AmsField(
                              label: 'Org Code', labelAbove: true, required: true,
                              child: AmsTextInput(
                                controller: _orgController,
                                focusNode: _orgFocus,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_attrIdFocus),
                                readOnly: _isViewOnly,
                                errorText: _orgError,
                                onChanged: (v) => setState(() { _orgError = v.isEmpty ? 'Org Code is required' : null; }),
                              ),
                            ),
                            if (attributes.isNotEmpty) ...[
                              AmsField(
                                label: 'Attribute ID', labelAbove: true, required: true,
                                child: AmsTextInput(
                                  controller: _attrIdController,
                                  focusNode: _attrIdFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_valueFocus),
                                  readOnly: _isViewOnly,
                                  errorText: _attrIdError,
                                  onChanged: (v) => setState(() { 
                                    attributes[0]['id'] = v;
                                    _attrIdError = v.isEmpty ? 'Attribute ID is required' : null;
                                  }),
                                  placeholder: 'e.g. TAX_CODE',
                                ),
                              ),
                              AmsField(
                                label: 'Value', labelAbove: true, required: true,
                                child: AmsTextInput(
                                  controller: _valueController,
                                  focusNode: _valueFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_descFocus),
                                  readOnly: _isViewOnly,
                                  errorText: _valueError,
                                  onChanged: (v) => setState(() { 
                                    attributes[0]['value'] = v;
                                    _valueError = v.isEmpty ? 'Value is required' : null;
                                  }),
                                  placeholder: 'Enter value',
                                ),
                              ),
                              AmsField(
                                label: 'Description', labelAbove: true,
                                child: AmsTextInput(
                                  controller: _descController,
                                  focusNode: _descFocus,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _saveSet(),
                                  readOnly: _isViewOnly,
                                  onChanged: (v) => setState(() { attributes[0]['desc'] = v; }),
                                  placeholder: 'Optional description',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_isViewOnly)
                  AmsSubmitBar(
                    borderColor: AppColors.border,
                    actions: [
                      AmsButton(label: 'Save Changes', variant: AmsButtonVariant.primary, backgroundColor: AppColors.sidebar, onPressed: _saveSet),
                      AmsButton(label: 'Clear All', variant: AmsButtonVariant.outline, onPressed: () {
                        setState(() {
                          _orgController.text = '1';
                          _attrIdController.clear();
                          _valueController.clear();
                          _descController.clear();
                          attributes[0] = {"id": "", "value": "", "desc": ""};
                          _orgError = null;
                          _attrIdError = null;
                          _valueError = null;
                        });
                      }),
                      AmsButton(label: 'Cancel', variant: AmsButtonVariant.danger, onPressed: () => setState(() => _showForm = false)),
                      const Spacer(),
                      AmsButton(
                        label: 'Back to List',
                        variant: AmsButtonVariant.primary,
                        backgroundColor: const Color(0xFFC53030),
                        // icon: Icons.chevron_left_rounded, // REMOVED PER REQUEST
                        onPressed: () => setState(() => _showForm = false),
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
                        onPressed: () => setState(() => _showForm = false)
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

  bool _validateAll() {
    setState(() {
      _attrIdError = (attributes.isEmpty || attributes[0]['id']!.isEmpty) ? 'Attribute ID is required' : null;
      _valueError = (attributes.isEmpty || attributes[0]['value']!.isEmpty) ? 'Value is required' : null;
      // Org code default 1 for now, but validating if someone cleared it
      _orgError = null; 
    });
    return _attrIdError == null && _valueError == null;
  }

  void _editSet(Map<String, dynamic> item) {
    setState(() {
      _showForm = true;
      _isViewOnly = false;
      _isEditMode = true;
      _orgError = null;
      _attrIdError = null;
      _valueError = null;
      selectedAccount = "GL ${item['glNo']} - ${item['name']}";
      attributes = List<Map<String, dynamic>>.from(item['attrs'] ?? []);
      
      // Update controllers
      _orgController.text = '1'; // Default or from item
      if (attributes.isNotEmpty) {
        _attrIdController.text = attributes[0]['id'] ?? '';
        _valueController.text = attributes[0]['value'] ?? '';
        _descController.text = attributes[0]['desc'] ?? '';
      }
    });
  }

  void _viewSet(Map<String, dynamic> item) {
    setState(() {
      _showForm = true;
      _isViewOnly = true;
      _isEditMode = false;
      _orgError = null;
      _attrIdError = null;
      _valueError = null;
      selectedAccount = "GL ${item['glNo']} - ${item['name']}";
      attributes = List<Map<String, dynamic>>.from(item['attrs'] ?? []);

      // Update controllers
      _orgController.text = '1';
      if (attributes.isNotEmpty) {
        _attrIdController.text = attributes[0]['id'] ?? '';
        _valueController.text = attributes[0]['value'] ?? '';
        _descController.text = attributes[0]['desc'] ?? '';
      }
    });
  }

  void _saveSet() {
    if (_validateAll()) {
      setState(() => _showForm = false);
      // Logic for actual save would go here
    }
  }

  Widget _statusDot(Color color) {
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _actionIconButton(IconData icon, Color color, VoidCallback onTap, {Color? bg}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg ?? Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: bg != null ? color.withValues(alpha: 0.2) : AppColors.border),
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
          Text('Showing 1–$total of $total', style: bodyStyle(size: 13, color: AppColors.ink3)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: null),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.tBlue, borderRadius: BorderRadius.circular(4)),
                child: Text('1', style: bodyStyle(size: 13, color: Colors.white, weight: FontWeight.w700)),
              ),
              IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: null),
            ],
          ),
        ],
      ),
    );
  }
}