import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ams_flutter/theme.dart';
import 'package:ams_flutter/models/models.dart';
import 'package:ams_flutter/widgets/widgets.dart';
import 'package:ams_flutter/services/prm_api_service.dart' as prm;
import 'package:ams_flutter/services/api_service.dart' as main;
import 'package:ams_flutter/services/menu_api_service.dart';
import 'package:ams_flutter/services/org_api_service.dart'; // ← ADD THIS

class ProgramMasterScreen extends StatefulWidget {
  final Map<String, Auth101Config> authConfigs;
  final String? initialProg;
  final void Function(String prog, Auth101Config cfg, String authsl,
      Map<String, dynamic> data) onSubmit;
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

  Future<void> _fetchSubModules(String moduleId,
      {bool clearDropdown = true}) async {
    final subMods = await prm.apiService.getSubModules(moduleId);
    setState(() {
      _subModules = subMods;
      if (clearDropdown) {
        _subModuleCtrl.clear();
        _dynamicData['subModuleCd'] = null;
      }
    });
  }

  Auth101Config get _cfg =>
      widget.authConfigs['PROG-CRT'] ??
      const Auth101Config(
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
      // ── FIX: No default org code — let user select from dropdown ──
      _orgcodeCtrl.text = '';
      _pgmClass = null;
      _pgmStatus = 1;
      _dynamicData['orgcode'] = null; // ← was 50, now null
      _dynamicData['status'] = 1;
    } else {
      final data = record.map((k, v) => MapEntry(k.toLowerCase(), v));
      _pgmIdCtrl.text = data['pgm_id']?.toString() ??
          data['programid']?.toString() ??
          data['pgmid']?.toString() ??
          '';
      _pgmNameCtrl.text = data['programdescription']?.toString() ??
          data['descn']?.toString() ??
          data['description']?.toString() ??
          data['programname']?.toString() ??
          '';
      _pgmRemarksCtrl.text = data['remarks']?.toString() ?? '';
      final modIdRaw = (data['module'] ??
              data['moduleid'] ??
              data['modcd'] ??
              data['module_id'] ??
              data['modulecd'] ??
              '')
          .toString()
          .trim();
      String modDisplay = modIdRaw;
      if (modIdRaw.isNotEmpty) {
        try {
          final matched = _modules
              .firstWhere((m) => m['module_id'].toString().trim() == modIdRaw);
          modDisplay = matched['display'].toString().trim();
          _fetchSubModules(modIdRaw, clearDropdown: false);
        } catch (_) {}
      }
      _moduleCtrl.text = modDisplay;

      final subModIdRaw = (data['sub_module'] ??
              data['submoduleid'] ??
              data['submodule_id'] ??
              data['sub_moduleid'] ??
              '')
          .toString()
          .trim();
      _subModuleCtrl.text = subModIdRaw;
      _dynamicData['subModuleCd'] = subModIdRaw;

      _orgcodeCtrl.text = data['orgcode']?.toString() ?? '';
      _pgmClass = data['pgm_class']?.toString() ??
          data['programclass']?.toString() ??
          data['pgmclass']?.toString();
      if (_pgmClass != null && _pgmClass!.length >= 1) {
        _pgmClass = (_pgmClass == '1' || _pgmClass!.startsWith('N'))
            ? 'N - Non Transaction / Master'
            : 'T - Transaction';
      }
      _pgmStatus = int.tryParse(data['status']?.toString() ?? '1') ?? 1;

      _dynamicData['programId'] = _pgmIdCtrl.text;
      _dynamicData['programDescription'] = _pgmNameCtrl.text;
      _dynamicData['moduleCd'] = modIdRaw;
      _dynamicData['subModuleCd'] =
          _subModuleCtrl.text.startsWith('1') ? '1' : '0';
      _dynamicData['programClass'] = _pgmClass?.substring(0, 1);
      _dynamicData['status'] = _pgmStatus;
      _dynamicData['orgcode'] = int.tryParse(_orgcodeCtrl.text) ?? null;
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
        _errors['pgmId'] = 'Program ID required';
        isValid = false;
      }
      if (_pgmNameCtrl.text.trim().isEmpty) {
        _errors['pgmName'] = 'Description required';
        isValid = false;
      }
      if (_moduleCtrl.text.trim().isEmpty) {
        _errors['module'] = 'Module required';
        isValid = false;
      }
      if (_pgmClass == null) {
        _errors['pgmClass'] = 'Program Class required';
        isValid = false;
      }
      if (!isValid) {
        showAmsSnack(context, 'Please fill all mandatory fields correctly.',
            icon: '⚠', type: 'w');
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
      success = await prm.apiService
          .createProgram(fullData, widget.userName ?? "admin");
    } else {
      success = await prm.apiService
          .updateProgram(fullData, widget.userName ?? "admin");
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
    final pId = (record['pgm_id'] ??
            record['pgmId'] ??
            record['programId'] ??
            record['pgmid'] ??
            '—')
        .toString();
    final orgCode = (record['orgcode']?.toString() ?? '50');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text('Delete Program', style: bodyStyle(weight: FontWeight.w700)),
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
    final success = await prm.apiService
        .deleteProgram(pgmId, orgcode, widget.userName ?? 'admin');
    if (success) {
      showAmsSnack(context, "Deleted successfully ✅");
      setState(() => _listVersion++);
    } else {
      showAmsSnack(context, "Delete failed ❌", type: 'e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListView = (_showForm == false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.settings_applications_rounded,
                size: 28, color: AppColors.tBlue),
            title: (isListView == true)
                ? 'Program Master'
                : (_viewRecord != null ? 'View Program' : 'New Program Master'),
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
              HeaderBreadcrumb(
                  label: 'Masters',
                  onTap: widget.onBackToModule ?? widget.onBack),
              HeaderBreadcrumb(label: 'Program Master'),
            ],
            onBack: (_showForm == true)
                ? () => setState(() => _showForm = false)
                : widget.onBack,
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
                            (isListView == true)
                                ? 'Program List'
                                : 'Program Details',
                            style: bodyStyle(
                                size: 14,
                                color: Colors.white,
                                weight: FontWeight.w700),
                          ),
                          if (isListView == true)
                            const Icon(Icons.table_rows_rounded,
                                color: Colors.white, size: 18)
                          else
                            const Icon(Icons.edit_note_rounded,
                                color: Colors.white, size: 20),
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
                              onDelete: (record) => _confirmDelete(record),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: ProgramMasterFields(
                                isViewMode: _isViewOnly,
                                initialData: _viewRecord ?? _dynamicData,
                                onChanged: (k, v) {
                                  _dynamicData[k] = v;
                                  if (k == 'orgcode')
                                    _orgcodeCtrl.text = v?.toString() ?? '';
                                  if (k == 'programId')
                                    _pgmIdCtrl.text = v.toString();
                                  if (k == 'programDescription')
                                    _pgmNameCtrl.text = v.toString();
                                  if (k == 'moduleCd')
                                    _moduleCtrl.text = v.toString();
                                  if (k == 'subModuleCd')
                                    _subModuleCtrl.text = v.toString();
                                  if (k == 'programClass')
                                    _pgmClass = v.toString();
                                  if (k == 'status')
                                    _pgmStatus =
                                        int.tryParse(v.toString()) ?? 1;
                                  if (k == 'remarks')
                                    _pgmRemarksCtrl.text = v.toString();
                                },
                              ),
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
                              variant: _cfg.approvalReq
                                  ? AmsButtonVariant.primary
                                  : AmsButtonVariant.green,
                              backgroundColor: _cfg.approvalReq
                                  ? AppColors.sidebar
                                  : const Color(0xFF22C55E),
                              onPressed: _doSubmit,
                            ),
                            AmsButton(
                              label: 'Clear',
                              icon: Icons.clear_all_rounded,
                              variant: AmsButtonVariant.outline,
                              onPressed: () =>
                                  setState(() => _loadFormData(null)),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// ProgramMasterFields — with Org Code searchable overlay dropdown
// ═══════════════════════════════════════════════════════════════════════════════

class ProgramMasterFields extends StatefulWidget {
  final bool isViewMode;
  final Map<String, dynamic>? initialData;
  final void Function(String, dynamic) onChanged;

  const ProgramMasterFields({
    super.key,
    required this.isViewMode,
    this.initialData,
    required this.onChanged,
  });

  @override
  State<ProgramMasterFields> createState() => ProgramMasterFieldsState();
}

class ProgramMasterFieldsState extends State<ProgramMasterFields> {
  // ── Regular controllers ─────────────────────────────────────────────────────
  final _pgmIdCtrl = TextEditingController();
  final _pgmNameCtrl = TextEditingController();
  final _pgmRemarksCtrl = TextEditingController();
  final _moduleCtrl = TextEditingController();
  final _subModuleCtrl = TextEditingController();

  // ── Org-code searchable dropdown (same as BranchScreenFields) ───────────────
  final _brnOrgCtrl = TextEditingController(); // displays "50 – Org Name"
  final _orgSearchCtrl = TextEditingController(); // search text inside overlay
  final _orgLayerLink = LayerLink();
  OverlayEntry? _orgOverlay;
  List<Map<String, dynamic>> _orgList = [];
  bool _orgLoading = false;
  int? _selectedOrgCode;

  // ── Other state ─────────────────────────────────────────────────────────────
  String? _pgmClass;
  int _pgmStatus = 1;
  List<Map<String, dynamic>> _modules = [];
  List<Map<String, dynamic>> _subModules = [];
  bool _loadingDropdowns = false;
  final Map<String, String?> _errors = {};

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchModules();
    _loadOrganisations();
    _loadInitialData();
  }

  @override
  void didUpdateWidget(ProgramMasterFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _pgmIdCtrl.dispose();
    _pgmNameCtrl.dispose();
    _pgmRemarksCtrl.dispose();
    _moduleCtrl.dispose();
    _subModuleCtrl.dispose();
    _brnOrgCtrl.dispose();
    _orgSearchCtrl.dispose();
    _orgOverlay?.remove();
    super.dispose();
  }

  // ── Load initial form data ──────────────────────────────────────────────────
  void _loadInitialData() {
    if (widget.initialData == null) return;
    final data =
        widget.initialData!.map((k, v) => MapEntry(k.toLowerCase(), v));

    // ── FIX: No default '50' — empty string if no orgcode present ──
    final orgCodeRaw = (data['orgcode'] ?? data['orgCode'] ?? '').toString();
    if (orgCodeRaw.isNotEmpty) {
      _selectedOrgCode = int.tryParse(orgCodeRaw);
      _refreshOrgDisplay(orgCodeRaw);
    } else {
      // New form — clear org selection
      _selectedOrgCode = null;
      _brnOrgCtrl.clear();
    }

    _pgmIdCtrl.text = data['programid']?.toString() ??
        data['pgm_id']?.toString() ??
        data['pgmid']?.toString() ??
        '';
    _pgmNameCtrl.text = data['programdescription']?.toString() ??
        data['descn']?.toString() ??
        data['programname']?.toString() ??
        '';
    _pgmRemarksCtrl.text = data['remarks']?.toString() ?? '';

    final modId = (data['modulecd'] ??
            data['module'] ??
            data['moduleid'] ??
            data['modcd'] ??
            '')
        .toString();
    _moduleCtrl.text = modId;
    final subModId =
        (data['submodulecd'] ?? data['sub_module'] ?? data['submoduleid'] ?? '')
            .toString();
    _subModuleCtrl.text = subModId;

    _pgmClass = data['programclass']?.toString() ??
        data['pgm_class']?.toString() ??
        data['pgmclass']?.toString();
    if (_pgmClass != null &&
        _pgmClass!.isNotEmpty &&
        !_pgmClass!.contains(' - ')) {
      _pgmClass = (_pgmClass == '1' || _pgmClass!.startsWith('N'))
          ? 'N - Non Transaction / Master'
          : 'T - Transaction';
    }
    _pgmStatus = int.tryParse(data['status']?.toString() ?? '1') ?? 1;
  }

  /// Updates the display field once we have the org list loaded.
  void _refreshOrgDisplay(String orgCodeRaw) {
    if (orgCodeRaw.isEmpty) {
      _brnOrgCtrl.clear();
      return;
    }
    if (_orgList.isNotEmpty) {
      try {
        final match = _orgList.firstWhere(
          (o) => (o['orgcode'] ?? o['orgCode'] ?? '').toString() == orgCodeRaw,
        );
        final name = (match['name'] ?? '').toString();
        _brnOrgCtrl.text = name.isNotEmpty ? '$orgCodeRaw – $name' : orgCodeRaw;
        return;
      } catch (_) {}
    }
    _brnOrgCtrl.text = orgCodeRaw;
  }

  // ── Fetch modules ───────────────────────────────────────────────────────────
  Future<void> _fetchModules() async {
    setState(() => _loadingDropdowns = true);
    final mods = await prm.apiService.getModules();
    setState(() {
      _modules = mods;
      _loadingDropdowns = false;
    });
    if (_moduleCtrl.text.isNotEmpty) {
      _fetchSubModules(_moduleCtrl.text, clear: false);
    }
  }

  Future<void> _fetchSubModules(String moduleId, {bool clear = true}) async {
    final subMods = await prm.apiService.getSubModules(moduleId);
    setState(() => _subModules = subMods);
  }

  // ── Fetch organisations ─────────────────────────────────────────────────────
  Future<void> _loadOrganisations() async {
    if (_orgLoading || _orgList.isNotEmpty) return;
    setState(() => _orgLoading = true);
    try {
      final res = await orgApiService.getAllOrganisations(page: 0, size: 200);
      if (res != null && mounted) {
        setState(() {
          _orgList = res.items;
          // Refresh display only if an org is already selected
          final cur = _selectedOrgCode?.toString() ?? '';
          if (cur.isNotEmpty) _refreshOrgDisplay(cur);
        });
      }
    } catch (_) {
      // silent — user can still type manually
    } finally {
      if (mounted) setState(() => _orgLoading = false);
    }
  }

  // ── Org overlay dropdown ────────────────────────────────────────────────────
  void _openOrgDropdown() {
    if (widget.isViewMode) return;
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
                onTap: () {}, // stop bubble
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
                            // ── Search bar ──────────────────────────────────
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

                            // ── List ────────────────────────────────────────
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
                                                    // Code badge
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

                            // ── Footer: total count ─────────────────────────
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

  /// Called when user selects an org from the overlay.
  void _selectOrg(Map<String, dynamic> org) {
    final code = (org['orgcode'] ?? org['orgCode'] ?? '').toString();
    final name = (org['name'] ?? '').toString();
    setState(() {
      _selectedOrgCode = int.tryParse(code);
      _brnOrgCtrl.text = name.isNotEmpty ? '$code – $name' : code;
      _errors['orgcode'] = null;
    });
    widget.onChanged('orgcode', int.tryParse(code) ?? 0);
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmsFormGrid(
          children: [
            // ── ORGANISATION CODE — searchable overlay dropdown ──────────────
            AmsField(
              label: 'Organisation Code',
              required: true,
              labelAbove: true,
              child: CompositedTransformTarget(
                link: _orgLayerLink,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.isViewMode ? null : _openOrgDropdown,
                  child: AbsorbPointer(
                    child: AmsTextInput(
                      controller: _brnOrgCtrl,
                      readOnly: true,
                      placeholder: _orgLoading
                          ? 'Loading organisations…'
                          : 'Select Organisation',
                      icon: _orgLoading
                          ? Icons.hourglass_empty_rounded
                          : Icons.business_rounded,
                      errorText: _errors['orgcode'],
                      isValid: _errors['orgcode'] == null &&
                          _brnOrgCtrl.text.isNotEmpty,
                    ),
                  ),
                ),
              ),
            ),

            _field('Program Id', _pgmIdCtrl,
                required: true,
                readOnly: widget.initialData != null &&
                    widget.initialData!['programId'] != null,
                error: _errors['pgmId'],
                onChanged: (v) => widget.onChanged('programId', v)),

            _field('Description', _pgmNameCtrl,
                required: true, error: _errors['pgmName'], onChanged: (v) {
              widget.onChanged('programDescription', v);
              widget.onChanged('programName', v);
            }),

            _dropdown('Module', _moduleCtrl, _modules, required: true,
                onChanged: (val, id) {
              widget.onChanged('moduleCd', id);
              _fetchSubModules(id);
            }),

            _dropdown('Sub Module', _subModuleCtrl, _subModules,
                onChanged: (val, id) => widget.onChanged('subModuleCd', id)),

            AmsField(
              label: 'Program Class',
              required: true,
              labelAbove: true,
              child: widget.isViewMode
                  ? AmsTextInput(initialValue: _pgmClass ?? '—', readOnly: true)
                  : AmsDropdown(
                      initialValue: _pgmClass,
                      placeholder: 'Select Class',
                      items: const [
                        'N - Non Transaction / Master',
                        'T - Transaction'
                      ],
                      errorText: _errors['pgmClass'],
                      onChanged: (v) {
                        setState(() => _pgmClass = v);
                        widget.onChanged('programClass', v?.substring(0, 1));
                      },
                    ),
            ),

            AmsField(
              label: 'Status',
              labelAbove: true,
              child: widget.isViewMode
                  ? AmsTextInput(
                      initialValue:
                          _pgmStatus == 1 ? '1 - Enable' : '0 - Disable',
                      readOnly: true)
                  : AmsDropdown(
                      initialValue:
                          _pgmStatus == 1 ? '1 - Enable' : '0 - Disable',
                      items: const ['1 - Enable', '0 - Disable'],
                      onChanged: (v) {
                        final st = v?.startsWith('1') == true ? 1 : 0;
                        setState(() => _pgmStatus = st);
                        widget.onChanged('status', st);
                      },
                    ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _field('Remarks', _pgmRemarksCtrl,
            maxLines: 3, onChanged: (v) => widget.onChanged('remarks', v)),
      ],
    );
  }

  // ── Helper widgets ──────────────────────────────────────────────────────────
  Widget _field(String label, TextEditingController ctrl,
      {bool required = false,
      bool isNum = false,
      bool readOnly = false,
      String? error,
      int maxLines = 1,
      void Function(String)? onChanged}) {
    return AmsField(
      label: label,
      required: required,
      labelAbove: true,
      child: AmsTextInput(
        controller: ctrl,
        readOnly: widget.isViewMode || readOnly,
        placeholder: 'Enter $label',
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        errorText: error,
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdown(String label, TextEditingController ctrl,
      List<Map<String, dynamic>> items,
      {bool required = false, void Function(String, String)? onChanged}) {
    String? currentVal;
    if (ctrl.text.isNotEmpty) {
      try {
        final matched = items.firstWhere((m) =>
            m['display'].toString().trim() == ctrl.text.trim() ||
            (m['module_id'] ?? m['subModuleId'] ?? m['id']).toString() ==
                ctrl.text.trim());
        currentVal = matched['display'].toString();
      } catch (_) {
        currentVal = widget.isViewMode ? ctrl.text : null;
      }
    }

    return AmsField(
      label: label,
      required: required,
      labelAbove: true,
      child: widget.isViewMode
          ? AmsTextInput(initialValue: currentVal ?? ctrl.text, readOnly: true)
          : (_loadingDropdowns && label == 'Module'
              ? const Center(child: LinearProgressIndicator())
              : AmsDropdown(
                  initialValue: currentVal,
                  placeholder: "Select $label",
                  items: items.map((m) => m['display'].toString()).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final selected =
                        items.firstWhere((m) => m['display'].toString() == val);
                    final id = (selected['module_id'] ??
                            selected['subModuleId'] ??
                            selected['id'])
                        .toString();
                    ctrl.text = val;
                    if (onChanged != null) onChanged(val, id);
                  },
                )),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _ProgramListView (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

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
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() {
      _loading = true;
      _currentPage = page;
    });
    final result =
        await prm.apiService.getProgramMaster(page: page - 1, size: 10);
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
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.tBlue),
                        )
                      : const Icon(Icons.refresh_rounded),
                  onPressed: (_loading == true) ? null : () => _load(1),
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Program Id',
                        style: bodyStyle(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.ink3))),
                Expanded(
                    flex: 4,
                    child: Text('Description',
                        style: bodyStyle(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.ink3))),
                Expanded(
                    flex: 2,
                    child: Text('Mod Id',
                        style: bodyStyle(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.ink3))),
                Expanded(
                    flex: 2,
                    child: Text('Status',
                        style: bodyStyle(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.ink3))),
                SizedBox(
                    width: 150,
                    child: Text('Actions',
                        textAlign: TextAlign.center,
                        style: bodyStyle(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.ink3))),
              ],
            ),
          ),
          Expanded(
            child: AmsPaginatedView<Map<String, dynamic>>(
              items: _data ?? [],
              totalRecords: _totalItems,
              forceShowFooter: true,
              currentPage: _currentPage,
              onPageChanged: (page) => _load(page),
              builder: (context, paginatedItems) => ListView.builder(
                itemCount: paginatedItems.length,
                itemBuilder: (context, idx) {
                  final d = paginatedItems[idx];
                  final pName = (d['descn'] ??
                          d['programName'] ??
                          d['programname'] ??
                          d['program_description'] ??
                          d['program_name'] ??
                          d['description'] ??
                          'Unknown')
                      .toString();
                  final pId = (d['pgm_id'] ??
                          d['pgmId'] ??
                          d['programId'] ??
                          d['programid'] ??
                          d['program_id'] ??
                          d['pgmid'] ??
                          '—')
                      .toString();
                  final modId = (d['module'] ??
                          d['moduleid'] ??
                          d['modcd'] ??
                          d['module_id'] ??
                          '—')
                      .toString();
                  final isEnabled =
                      (d['status'] == 1 || d['status'] == '1') == true;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Text(pId,
                                style: monoStyle(
                                    size: 12, weight: FontWeight.w600))),
                        Expanded(
                            flex: 4,
                            child: Text(pName,
                                style: bodyStyle(
                                    size: 13, weight: FontWeight.w500))),
                        Expanded(
                            flex: 2,
                            child: Text(modId, style: bodyStyle(size: 13))),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isEnabled
                                  ? AppColors.greenLt
                                  : AppColors.redLt,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isEnabled ? 'Enable' : 'Disable',
                              style: bodyStyle(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: isEnabled
                                      ? AppColors.green
                                      : AppColors.red),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.visibility_rounded,
                                      size: 20, color: AppColors.tBlue),
                                  onPressed: () => widget.onView(d),
                                  tooltip: 'View'),
                              IconButton(
                                  icon: const Icon(Icons.edit_rounded,
                                      size: 20, color: AppColors.ink3),
                                  onPressed: () => widget.onEdit(d),
                                  tooltip: 'Edit'),
                              IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: AppColors.red),
                                  onPressed: () => widget.onDelete(d),
                                  tooltip: 'Delete'),
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
        ],
      ),
    );
  }
}
