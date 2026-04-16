import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ams_flutter/theme.dart';
import 'package:ams_flutter/models/models.dart';
import 'package:ams_flutter/widgets/widgets.dart';
import 'package:ams_flutter/services/prm_api_service.dart' as prm;
import 'package:ams_flutter/services/api_service.dart' as main;
import 'package:ams_flutter/services/menu_api_service.dart';
class ProgramMasterScreen extends StatefulWidget {
  final Map<String, Auth101Config> authConfigs;
  final String? initialProg;
  final void Function(String prog, Auth101Config cfg, String authsl, Map<String, dynamic> data) onSubmit;
  final VoidCallback onBack;
  final VoidCallback? onBackToModule;
  final String? userName;
  

  const ProgramMasterScreen({
    super.key,
    required this.authConfigs,
    this.initialProg,
    required this.onSubmit,
    required this.onBack,
    this.onBackToModule,
    this.userName,
  });

  @override
  State<ProgramMasterScreen> createState() => _ProgramMasterScreenState();
}

class _ProgramMasterScreenState extends State<ProgramMasterScreen> {
  bool _showForm = false;
  Map<String, dynamic>? _viewRecord;
  final Map<String, dynamic> _dynamicData = {};
  final Map<String, String?> _errors = {};
  int _listVersion = 0;

  // Controllers
  final _pgmIdCtrl = TextEditingController();
  final _pgmNameCtrl = TextEditingController();
  final _pgmRemarksCtrl = TextEditingController();
  final _moduleCtrl = TextEditingController();
  final _subModuleCtrl = TextEditingController();
  final _orgcodeCtrl = TextEditingController();

  String? _pgmClass;
  int _pgmStatus = 1;

  List<Map<String, dynamic>> _modules = [];
  List<Map<String, dynamic>> _subModules = [];
  bool _loadingDropdowns = false;
  bool _isViewOnly = false;

  @override
  void initState() {
    super.initState();
    // Sync token from main service
    prm.apiService.updateToken(main.apiService.token);
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    setState(() => _loadingDropdowns = true);
    final mods = await prm.apiService.getModules();
    setState(() {
      _modules = mods;
      _loadingDropdowns = false;
    });
  }

  Future<void> _fetchSubModules(String moduleId, {bool clearDropdown = true}) async {
    final subMods = await prm.apiService.getSubModules(moduleId);
    setState(() {
      _subModules = subMods;
      if (clearDropdown) {
        _subModuleCtrl.clear();
        _dynamicData['subModuleCd'] = null;
      }
    });
  }

  Auth101Config get _cfg => widget.authConfigs['PROG-CRT'] ?? const Auth101Config(
    id: 'PROG-CRT',
    name: 'Program Master',
    approvalReq: true,
    isTran: false,
    levels: 1,
  );

  @override
  void dispose() {
    _pgmIdCtrl.dispose();
    _pgmNameCtrl.dispose();
    _pgmRemarksCtrl.dispose();
    _moduleCtrl.dispose();
    _subModuleCtrl.dispose();
    _orgcodeCtrl.dispose();
    super.dispose();
  }

  void _loadFormData(Map<String, dynamic>? record) {
    _errors.clear();
    _dynamicData.clear();
    
    if (record == null) {
      _pgmIdCtrl.clear();
      _pgmNameCtrl.clear();
      _pgmRemarksCtrl.clear();
      _moduleCtrl.clear();
      _subModuleCtrl.clear();
      _orgcodeCtrl.text = '50';
      _pgmClass = null;
      _pgmStatus = 1;
      _dynamicData['orgcode'] = 50;
      _dynamicData['status'] = 1;
    } else {
      final data = record.map((k, v) => MapEntry(k.toLowerCase(), v));
      _pgmIdCtrl.text = data['pgm_id']?.toString() ?? data['programid']?.toString() ?? data['pgmid']?.toString() ?? '';
      _pgmNameCtrl.text = data['programdescription']?.toString() ?? 
                         data['descn']?.toString() ?? 
                         data['description']?.toString() ?? 
                         data['programname']?.toString() ?? '';
      _pgmRemarksCtrl.text = data['remarks']?.toString() ?? '';
      final modIdRaw = (data['module'] ?? data['moduleid'] ?? data['modcd'] ?? data['module_id'] ?? data['modulecd'] ?? '').toString().trim();
      String modDisplay = modIdRaw;
      if (modIdRaw.isNotEmpty) {
        try {
          final matched = _modules.firstWhere((m) => m['module_id'].toString().trim() == modIdRaw);
          modDisplay = matched['display'].toString().trim();
          // 🔥 Fetch submodules for this module but DON'T clear since we're loading existing data
          _fetchSubModules(modIdRaw, clearDropdown: false);
        } catch (_) {}
      }
      _moduleCtrl.text = modDisplay;

      final subModIdRaw = (data['sub_module'] ?? data['submoduleid'] ?? data['submodule_id'] ?? data['sub_moduleid'] ?? '').toString().trim();
      _subModuleCtrl.text = subModIdRaw; // We'll try to find the display name after fetching
      _dynamicData['subModuleCd'] = subModIdRaw;

      _orgcodeCtrl.text = data['orgcode']?.toString() ?? '50';
      _pgmClass = data['pgm_class']?.toString() ?? data['programclass']?.toString() ?? data['pgmclass']?.toString();
      if (_pgmClass != null && _pgmClass!.length >= 1) {
          _pgmClass = (_pgmClass == '1' || _pgmClass!.startsWith('N')) ? 'N - Non Transaction / Master' : 'T - Transaction';
      }
      _pgmStatus = int.tryParse(data['status']?.toString() ?? '1') ?? 1;

      // Sync dynamic data
      _dynamicData['programId'] = _pgmIdCtrl.text;
      _dynamicData['programDescription'] = _pgmNameCtrl.text;
      _dynamicData['moduleCd'] = modIdRaw;
      _dynamicData['subModuleCd'] = _subModuleCtrl.text.startsWith('1') ? '1' : '0';
      _dynamicData['programClass'] = _pgmClass?.substring(0, 1);
      _dynamicData['status'] = _pgmStatus;
      _dynamicData['orgcode'] = int.tryParse(_orgcodeCtrl.text) ?? 50;
      _dynamicData['remarks'] = _pgmRemarksCtrl.text;
    }
  }

  bool _validate() {
    bool isValid = true;
    setState(() {
      _errors.clear();
      if (_orgcodeCtrl.text.trim().isEmpty) {
        _errors['orgcode'] = 'Organisation Code required';
        isValid = false;
      }
      if (_pgmIdCtrl.text.trim().isEmpty) {
        print("DEBUG: Program ID missing");
        _errors['pgmId'] = 'Program ID required';
        isValid = false;
      }
      if (_pgmNameCtrl.text.trim().isEmpty) {
        print("DEBUG: Description missing");
        _errors['pgmName'] = 'Description required';
        isValid = false;
      }
      if (_moduleCtrl.text.trim().isEmpty) {
        print("DEBUG: Module missing");
        _errors['module'] = 'Module required';
        isValid = false;
      }
      if (_pgmClass == null) {
        print("DEBUG: Program Class missing");
        _errors['pgmClass'] = 'Program Class required';
        isValid = false;
      }

      if (!isValid) {
        showAmsSnack(context, 'Please fill all mandatory fields correctly.', icon: '⚠', type: 'w');
      }
    });
    return isValid;
  }

  void _doSubmit() async {
  if (!_validate()) return;

  final fullData = {
  ..._dynamicData,
  'orgcode': int.tryParse(_orgcodeCtrl.text.trim()) ?? 50,
};

  bool success;

  if (_viewRecord == null) {
    // CREATE
    success = await prm.apiService.createProgram(
      fullData,
      widget.userName ?? "admin",
    );
  } else {
    // UPDATE
    success = await prm.apiService.updateProgram(
      fullData,
      widget.userName ?? "admin",
    );
  }

  if (success) {
    showAmsSnack(context, "Submitted successfully ✅");
    setState(() {
      _showForm = false;
      _viewRecord = null;
    });
  } else {
    showAmsSnack(context, "Something went wrong ❌", type: 'e');
  }
}
  void _confirmDelete(Map<String, dynamic> record) {
    final pId = (record['pgm_id'] ?? record['pgmId'] ?? record['programId'] ?? record['pgmid'] ?? '—').toString();
    final orgCode = (record['orgcode']?.toString() ?? '50');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Program', style: bodyStyle(weight: FontWeight.w700)),
        content: Text('Are you sure you want to delete program $pId?'),
        actions: [
          TextButton(
            child: Text('Cancel', style: bodyStyle(color: AppColors.ink3)),
            onPressed: () => Navigator.pop(ctx),
          ),
          AmsButton(
            label: 'Delete',
            variant: AmsButtonVariant.danger,
            small: true,
            onPressed: () {
              Navigator.pop(ctx);
              _doDelete(pId, orgCode);
            },
          ),
        ],
      ),
    );
  }

  void _doDelete(String pgmId, String orgcode) async {
    final success = await prm.apiService.deleteProgram(pgmId, orgcode, widget.userName ?? 'admin');
    if (success) {
      showAmsSnack(context, "Deleted successfully ✅");
      setState(() {
        _listVersion++;
      }); 
    } else {
      showAmsSnack(context, "Delete failed ❌", type: 'e');
    }
  }

  String _shortDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isListView = (_showForm == false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.settings_applications_rounded, size: 28, color: AppColors.tBlue),
            title: (isListView == true) ? 'Program Master' : (_viewRecord != null ? 'View Program' : 'New Program Master'),
            subtitle: (isListView == true) 
                ? 'Manage and view existing records.' 
                : 'Fill in the information to create a new record.',
            badges: [
              if (isListView == true)
                const AmsBadge(label: 'List View')
              else
                AmsBadge(
                    label: 'Entry Form',
                    background: AppColors.tBlueLt,
                    color: AppColors.tBlue),
            ],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(label: 'Masters', onTap: widget.onBackToModule ?? widget.onBack),
              HeaderBreadcrumb(label: 'Program Master'),
            ],
            onBack: (_showForm == true) ? () => setState(() => _showForm = false) : widget.onBack,
            actions: [
              if (isListView == true)
                AmsButton(
                  label: 'New Program',
                  icon: Icons.add_rounded,
                  small: true,
                  backgroundColor: AppColors.sidebar,
                  onPressed: () => setState(() {
                    _loadFormData(null);
                    _showForm = true;
                    _isViewOnly = false;
                  }),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
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
                            (isListView == true) ? 'Program List' : 'Program Details',
                            style: bodyStyle(size: 14, color: Colors.white, weight: FontWeight.w700),
                          ),
                          if (isListView == true)
                             const Icon(Icons.table_rows_rounded, color: Colors.white, size: 18)
                          else
                             const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                    Expanded(
                      child: (isListView == true) 
                        ? _ProgramListView(
                            key: ValueKey('pgm_list_$_listVersion'),
                            onView: (record) {
                              setState(() {
                                _loadFormData(record);
                                _showForm = true;
                                _viewRecord = record;
                                _isViewOnly = true;
                              });
                            },
                            onEdit: (record) {
                              setState(() {
                                _loadFormData(record);
                                _showForm = true;
                                _viewRecord = record;
                                _isViewOnly = false;
                              });
                            },
                            onDelete: (record) {
                              _confirmDelete(record);
                            },
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: _buildFormFields(),
                          ),
                    ),
                    if (isListView == false)
                      AmsSubmitBar(
                        borderColor: AppColors.border,
                        actions: [
                          if (_isViewOnly == true)
                            AmsButton(
                              label: 'Back to List',
                              icon: Icons.arrow_back_rounded,
                              variant: AmsButtonVariant.ghost,
                              onPressed: () {
                                setState(() {
                                  _showForm = false;
                                  _viewRecord = null;
                                });
                              },
                            )
                          else ...[
                            AmsButton(
                              label: _cfg.approvalReq ? 'Submit' : 'Save',
                              variant: _cfg.approvalReq ? AmsButtonVariant.primary : AmsButtonVariant.green,
                              backgroundColor: _cfg.approvalReq ? AppColors.sidebar : const Color(0xFF22C55E),
                              onPressed: _doSubmit,
                            ),
                            AmsButton(
                              label: 'Clear',
                              icon: Icons.clear_all_rounded,
                              variant: AmsButtonVariant.outline,
                              onPressed: () => setState(() => _loadFormData(null)),
                            ),
                            AmsButton(
                              label: 'Cancel',
                              icon: Icons.close_rounded,
                              variant: AmsButtonVariant.danger,
                              onPressed: () => setState(() {
                                _showForm = false;
                                _viewRecord = null;
                              }),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    final isViewMode = (_isViewOnly == true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmsFormGrid(
          children: [
            AmsField(
              label: 'Organisation Code',
              required: true,
              labelAbove: true,
              child: AmsTextInput(
                controller: _orgcodeCtrl,
                readOnly: isViewMode,
                placeholder: 'e.g. 50',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                errorText: _errors['orgcode'],
                onChanged: (v) {
                  _dynamicData['orgcode'] = int.tryParse(v) ?? 50;
                  setState(() => _errors['orgcode'] = null);
                },
              ),
            ),
            AmsField(
              label: 'Program Id',
              required: true,
              labelAbove: true,
              child: AmsTextInput(
                controller: _pgmIdCtrl,
                readOnly: (_viewRecord != null),
                placeholder: 'e.g. GL101',
                inputFormatters: [LengthLimitingTextInputFormatter(15)],
                errorText: _errors['pgmId'],
                isValid: (_errors['pgmId'] == null && _pgmIdCtrl.text.isNotEmpty) == true,
                onChanged: (v) {
                   _dynamicData['programId'] = v;
                   setState(() => _errors['pgmId'] = null);
                },
              ),
            ),
            AmsField(
              label: 'Description',
              required: true,
              labelAbove: true,
              child: AmsTextInput(
                controller: _pgmNameCtrl,
                readOnly: (isViewMode == true),
                placeholder: 'e.g. Finance Dashboard Entry',
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                errorText: _errors['pgmName'],
                isValid: (_errors['pgmName'] == null && _pgmNameCtrl.text.isNotEmpty) == true,
                onChanged: (v) {
                  _dynamicData['programDescription'] = v;
                  _dynamicData['programName'] = v;
                  setState(() => _errors['pgmName'] = null);
                },
              ),
            ),
            AmsField(
              label: 'Module',
              required: true,
              labelAbove: true,
              child: (isViewMode == true)
                  ? AmsTextInput(initialValue: _moduleCtrl.text, readOnly: true)
                  : (_loadingDropdowns
                      ? const Center(child: LinearProgressIndicator())
                      : AmsDropdown(
                          initialValue: _moduleCtrl.text.isEmpty || !_modules.any((m) => m['display'].toString().trim() == _moduleCtrl.text.trim()) ? null : _moduleCtrl.text.trim(),
                          placeholder: "Select Module",
                          items: _modules.map((m) => m['display'].toString().trim()).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final selected = _modules.firstWhere(
                              (m) => m['display'].toString().trim() == val.trim(),
                              orElse: () => {},
                            );
                            if (selected.isEmpty) return;
                            final mId = (selected['module_id'] ?? selected['moduleId'] ?? selected['moduleid'] ?? selected['id']).toString();
                            setState(() {
                              _moduleCtrl.text = val;
                              _dynamicData['moduleCd'] = mId;
                            });
                            _fetchSubModules(mId);
                          },
                        )),
            ),
            AmsField(
              label: 'Sub Module',
              labelAbove: true,
              child: (isViewMode == true)
                  ? AmsTextInput(initialValue: _subModuleCtrl.text, readOnly: true)
                  : AmsDropdown(
                      initialValue: () {
                        if (_subModuleCtrl.text.isEmpty) return null;
                        // Check if it's already a display string or an ID
                        final display = _subModules.any((sm) => sm['display'].toString() == _subModuleCtrl.text)
                            ? _subModuleCtrl.text
                            : _subModules.firstWhere(
                                (sm) => sm['subModuleId'].toString() == _subModuleCtrl.text || sm['id'].toString() == _subModuleCtrl.text,
                                orElse: () => {},
                              )['display']?.toString();
                        return display;
                      }(),
                      placeholder: _subModules.isEmpty ? "No Sub-Modules" : "Select Sub-Module",
                      items: _subModules.map((sm) => sm['display'].toString()).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final selected = _subModules.firstWhere(
                          (sm) => sm['display'].toString() == v,
                          orElse: () => {},
                        );
                        if (selected.isEmpty) return;
                        final smId = (selected['subModuleId'] ?? selected['id']).toString();
                        setState(() {
                          _subModuleCtrl.text = v;
                          _dynamicData['subModuleCd'] = smId;
                        });
                      },
                    ),
            ),
            AmsField(
              label: 'Program Class',
              required: true,
              labelAbove: true,
              child: (isViewMode == true)
                  ? AmsTextInput(initialValue: _pgmClass ?? '—', readOnly: true)
                  : AmsDropdown(
                      initialValue: _pgmClass,
                      placeholder: 'Select Class',
                      items: const ['N - Non Transaction / Master', 'T - Transaction'],
                      errorText: _errors['pgmClass'],
                      isValid: (_errors['pgmClass'] == null && _pgmClass != null) == true,
                      onChanged: (v) {
                        setState(() {
                          _pgmClass = v;
                          _errors['pgmClass'] = null;
                        });
                        _dynamicData['programClass'] = v?.substring(0, 1);
                      },
                    ),
            ),
            AmsField(
              label: 'Status',
              labelAbove: true,
              child: (isViewMode == true)
                  ? AmsTextInput(initialValue: _pgmStatus == 1 ? '1 - Enable' : '0 - Disable', readOnly: true)
                  : AmsDropdown(
                      initialValue: _pgmStatus == 1 ? '1 - Enable' : '0 - Disable',
                      items: const ['1 - Enable', '0 - Disable'],
                      onChanged: (v) {
                        final st = v?.startsWith('1') == true ? 1 : 0;
                        setState(() => _pgmStatus = st);
                        _dynamicData['status'] = st;
                      },
                    ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AmsField(
          label: 'Remarks',
          labelAbove: true,
          child: AmsTextInput(
            controller: _pgmRemarksCtrl,
            readOnly: (isViewMode == true),
            placeholder: 'Enter any additional notes...',
            maxLines: 3,
            onChanged: (v) => _dynamicData['remarks'] = v,
          ),
        ),
      ],
    );
  }
}

class _ProgramListView extends StatefulWidget {
  final void Function(Map<String, dynamic>) onView;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const _ProgramListView({
    super.key,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProgramListView> createState() => _ProgramListViewState();
}

class _ProgramListViewState extends State<_ProgramListView> {
  List<Map<String, dynamic>>? _data;
  int _totalItems = 0;
  bool _loading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() => _loading = true);
    final result = await prm.apiService.getProgramMaster(page: page - 1, size: 10);
    if (mounted) {
      setState(() {
        _data = result?.items ?? [];
        _totalItems = result?.totalElements ?? 0;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: AmsTextInput(
                    icon: Icons.search_rounded,
                    placeholder: 'Search programs...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: (_loading == true)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.tBlue),
                        )
                      : const Icon(Icons.refresh_rounded),
                  onPressed: (_loading == true) ? null : () => _load(1),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            color: AppColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Program Id', style: bodyStyle(size: 11, weight: FontWeight.w700, color: AppColors.ink3))),
                Expanded(flex: 4, child: Text('Description', style: bodyStyle(size: 11, weight: FontWeight.w700, color: AppColors.ink3))),
                Expanded(flex: 2, child: Text('Mod Id', style: bodyStyle(size: 11, weight: FontWeight.w700, color: AppColors.ink3))),
                Expanded(flex: 2, child: Text('Status', style: bodyStyle(size: 11, weight: FontWeight.w700, color: AppColors.ink3))),
                SizedBox(width: 150, child: Text('Actions', textAlign: TextAlign.center, style: bodyStyle(size: 11, weight: FontWeight.w700, color: AppColors.ink3))),
              ],
            ),
          ),

          // Table Body
          Expanded(
            child: (_loading == true && _data == null)
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _data?.length ?? 0,
                    itemBuilder: (context, idx) {
                      final d = _data![idx];
                      final pName = (d['descn'] ?? d['programName'] ?? d['programname'] ?? d['program_description'] ?? d['program_name'] ?? d['description'] ?? 'Unknown').toString();
                      final pId = (d['pgm_id'] ?? d['pgmId'] ?? d['programId'] ?? d['programid'] ?? d['program_id'] ?? d['pgmid'] ?? '—').toString();
                      final modId = (d['module'] ?? d['moduleid'] ?? d['modcd'] ?? d['module_id'] ?? '—').toString();
                      final isEnabled = (d['status'] == 1 || d['status'] == '1') == true;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(pId, style: monoStyle(size: 12, weight: FontWeight.w600))),
                            Expanded(flex: 4, child: Text(pName, style: bodyStyle(size: 13, weight: FontWeight.w500))),
                            Expanded(flex: 2, child: Text(modId, style: bodyStyle(size: 13))),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isEnabled == true) ? AppColors.greenLt : AppColors.redLt,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (isEnabled == true) ? 'Enable' : 'Disable',
                                  style: bodyStyle(size: 11, weight: FontWeight.w700, color: (isEnabled == true) ? AppColors.green : AppColors.red),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_rounded, size: 20, color: AppColors.tBlue),
                                    onPressed: () => widget.onView(d),
                                    tooltip: 'View',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.ink3),
                                    onPressed: () => widget.onEdit(d),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.red),
                                    onPressed: () => widget.onDelete(d),
                                    tooltip: 'Delete',
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

          // Footer
          if (_data != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Records: $_totalItems', style: bodyStyle(size: 12, color: AppColors.ink3)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        onPressed: null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        onPressed: (_totalItems > 10) ? () => _load(2) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
