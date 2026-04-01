import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../data.dart';

class NonTranEntryScreen extends StatefulWidget {
  final Map<String, Auth101Config> authConfigs;
  final List<String> nonTranPrograms;
  final void Function(String prog, Auth101Config cfg, String authsl,
      Map<String, dynamic> data) onSubmit;
  final VoidCallback onBack;
  final String? initialProg;
  final String? userName;

  const NonTranEntryScreen({
    super.key,
    required this.authConfigs,
    required this.nonTranPrograms,
    required this.onSubmit,
    required this.onBack,
    this.initialProg,
    this.userName,
  });

  @override
  State<NonTranEntryScreen> createState() => _NonTranEntryScreenState();
}

class _NonTranEntryScreenState extends State<NonTranEntryScreen> {
  String? _selProg;
  final Map<String, dynamic> _dynamicData = {};
  bool _showForm = false;
  Map<String, dynamic>? _viewRecord;

  @override
  void initState() {
    super.initState();
    _selProg = widget.initialProg;
  }

  @override
  void didUpdateWidget(NonTranEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialProg != widget.initialProg) {
      setState(() {
        _selProg = widget.initialProg;
        _dynamicData.clear();
        _showForm = false;
        _viewRecord = null;
      });
    }
  }

  Auth101Config? get _cfg =>
      _selProg != null ? widget.authConfigs[_selProg] : null;

  final GlobalKey<DynamicNTFieldsState> _fieldsKey =
      GlobalKey<DynamicNTFieldsState>();

  void _doSubmit() {
    if (_selProg == null) {
      showAmsToast(context, '⚠', 'Please select a program first.', type: 'w');
      return;
    }

    // Trigger validation in child
    if (_fieldsKey.currentState?.validate() == false) {
      return;
    }

    final authsl =
        '2026-${(100 + (DateTime.now().millisecondsSinceEpoch % 900)).toString().padLeft(4, '0')}';

    final fullData = {
      'orgCode': _dynamicData['orgCode'] ??
          (([
            'USR-CRT',
            'ROLE-CRT',
            'USR-ROLE',
            'MOD-CRT',
            'MENU-CRT',
            'AUTHCTL'
          ].contains(_selProg))
              ? 50
              : 1),
      // For ROLE-CRT: default all access fields to 0 if user never touched the toggle
      if (_selProg == 'ROLE-CRT') ...{
        'viewAccess': 0,
        'authAccess': 0,
        'makerAccess': 0,
        'adminAccess': 0,
        'sysAdminAccess': 0,
      },
      ..._dynamicData,
    };

    final safeCfg = _cfg ??
        Auth101Config(
          id: _selProg!,
          name: _selProg!,
          approvalReq: false,
          isTran: false,
          levels: 1,
        );

    widget.onSubmit(_selProg!, safeCfg, authsl, fullData);
    setState(() {
      _showForm = false;
      _viewRecord = null;
      _dynamicData.clear();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDirectSave = _cfg != null && !_cfg!.approvalReq;
    final isUserScreenList = _selProg == 'USR-CRT' && !_showForm;
    final isRoleScreenList = _selProg == 'ROLE-CRT' && !_showForm;
    final isUserRoleScreenList = _selProg == 'USR-ROLE' && !_showForm;
    final isModuleScreenList = _selProg == 'MOD-CRT' && !_showForm;
    final isMenuScreenList = _selProg == 'MENU-CRT' && !_showForm;
    final isAuthCtrlScreenList = _selProg == 'AUTHCTL' && !_showForm;

    final isAnyList = isUserScreenList ||
        isRoleScreenList ||
        isUserRoleScreenList ||
        isModuleScreenList ||
        isMenuScreenList ||
        isAuthCtrlScreenList;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: Icon(
                _selProg == 'USR-CRT' || _selProg == 'USR-ROLE'
                    ? Icons.person_rounded
                    : _selProg == 'ROLE-CRT'
                        ? Icons.admin_panel_settings_rounded
                        : _selProg == 'GL-CAT' || _selProg == 'GL-MST'
                            ? Icons.category_rounded
                            : Icons.settings_applications_rounded,
                size: 28,
                color: AppColors.tBlue),
            title: _selProg == 'USR-ROLE'
                ? (isAnyList ? 'Role Assign' : 'New Role Assign')
                : (_cfg != null
                    ? (isAnyList ? _cfg!.name : 'New ${_cfg!.name}')
                    : 'New Record'),
            subtitle: isAnyList
                ? 'Manage and view existing records.'
                : 'Fill in the information to create a new record.',
            badges: [
              if (isAnyList)
                AmsBadge(label: 'List View')
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
              HeaderBreadcrumb(label: 'Masters', onTap: widget.onBack),
              if (_selProg != null)
                HeaderBreadcrumb(label: _cfg?.name ?? _selProg!),
            ],
            onBack: [
                      'USR-CRT',
                      'USR-ROLE',
                      'ROLE-CRT',
                      'MOD-CRT',
                      'MENU-CRT',
                      'AUTHCTL'
                    ].contains(_selProg) &&
                    _showForm
                ? () => setState(() => _showForm = false)
                : widget.onBack,
            actions: [
              if (isAnyList)
                AmsButton(
                  label: 'New ${_cfg?.name ?? 'Record'}',
                  icon: Icons.add_rounded,
                  small: true,
                  backgroundColor: AppColors.sidebar,
                  onPressed: () => setState(() {
                    _viewRecord = null;
                    _showForm = true;
                  }),
                ),
            ],
          ),
          // Main Screen Area (Modern Container)
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
                    // Navy Header Bar
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
                            isAnyList
                                ? '${_cfg?.name ?? _selProg!} List'
                                : '${_viewRecord != null ? 'View' : 'New'} ${_cfg?.name ?? _selProg!}',
                            style: bodyStyle(
                              size: 14,
                              color: Colors.white,
                              weight: FontWeight.w700,
                            ),
                          ),
                          if (_showForm)
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up_rounded,
                                  color: Colors.white),
                              onPressed: () => setState(() {
                                _showForm = false;
                                _viewRecord = null;
                              }),
                            ),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(
                      child: () {
                        void handleView(Map<String, dynamic> record) {
                          setState(() {
                            _viewRecord = record;
                            _showForm = true;
                          });
                        }

                        if (isUserScreenList) {
                          return _UserListView(onView: handleView);
                        }
                        if (isRoleScreenList) {
                          return _RoleListView(onView: handleView);
                        }
                        if (isUserRoleScreenList) {
                          return _UserRoleListView(onView: handleView);
                        }
                        if (isModuleScreenList) {
                          return _ModuleListView(onView: handleView);
                        }
                        if (isMenuScreenList) {
                          return _MenuListView(onView: handleView);
                        }
                        if (isAuthCtrlScreenList) {
                          return _AuthCtrlListView(onView: handleView);
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selProg != null) ...[
                                DynamicNTFields(
                                  key: _fieldsKey,
                                  prog: _selProg!,
                                  initialData: _viewRecord,
                                  isViewMode: _viewRecord != null,
                                  onChanged: (key, val) =>
                                      _dynamicData[key] = val,
                                ),
                              ],
                            ],
                          ),
                        );
                      }(),
                    ),

                    // Fixed Footer Submit Bar (within the container)
                    if (!isAnyList)
                      AmsSubmitBar(
                        borderColor: AppColors.border,
                        actions: [
                          if (_viewRecord != null)
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
                              label: isDirectSave ? 'Save' : 'Submit',
                              variant: isDirectSave
                                  ? AmsButtonVariant.green
                                  : AmsButtonVariant.primary,
                              backgroundColor: isDirectSave
                                  ? const Color(0xFF22C55E)
                                  : AppColors.sidebar,
                              onPressed: _doSubmit,
                            ),
                            AmsButton(
                              label: 'Clear',
                              icon: Icons.clear_all_rounded,
                              variant: AmsButtonVariant.outline,
                              onPressed: () {
                                _fieldsKey.currentState?.clearFields();
                                setState(() => _dynamicData.clear());
                              },
                            ),
                            AmsButton(
                              label: 'Cancel',
                              icon: Icons.close_rounded,
                              variant: AmsButtonVariant.danger,
                              onPressed: () {
                                if ([
                                  'USR-CRT',
                                  'USR-ROLE',
                                  'ROLE-CRT',
                                  'MOD-CRT',
                                  'MENU-CRT',
                                  'AUTHCTL'
                                ].contains(_selProg)) {
                                  setState(() {
                                    _showForm = false;
                                    _viewRecord = null;
                                  });
                                } else {
                                  widget.onBack();
                                }
                              },
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

class _UserListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  const _UserListView({this.onView});

  @override
  State<_UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<_UserListView> {
  List<Map<String, dynamic>>? _users;
  int _totalItems = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers(1);
  }

  Future<void> _loadUsers(int page) async {
    setState(() => _loading = true);
    final result = await apiService.getUsers(page: page - 1, size: 10);
    if (mounted) {
      setState(() {
        _users = result?.items ?? [];
        _totalItems = result?.totalElements ?? 0;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _users == null) {
      return const AmsListSkeleton();
    }

    return AmsPaginatedView<Map<String, dynamic>>(
      items: _users ?? [],
      totalRecords: _totalItems,
      onPageChanged: _loadUsers,
      builder: (ctx, currentItems) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: currentItems.length,
        itemBuilder: (ctx, idx) {
          final u = currentItems[idx];
          final String fName = u['fName'] ?? u['fname'] ?? u['FNAME'] ?? '';
          final String lName = u['lName'] ?? u['lname'] ?? u['LNAME'] ?? '';
          final String email = u['email'] ?? u['EMAIL'] ?? 'No Email';
          final String mobile = u['mobile'] ?? u['MOBILE'] ?? 'No Mobile';
          final String userCd =
              u['userScd'] ?? u['usersCd'] ?? u['USERSCD'] ?? 'Unknown';
          final String initial = fName.isNotEmpty
              ? fName[0].toUpperCase()
              : (userCd.isNotEmpty && userCd != 'Unknown'
                  ? userCd[0].toUpperCase()
                  : 'U');

          return AmsCard(
            onTap: widget.onView != null ? () => widget.onView!(u) : null,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: AppColors.tBlueLt, shape: BoxShape.circle),
                  child: Center(
                      child: Text(initial,
                          style: bodyStyle(
                              weight: FontWeight.bold,
                              color: AppColors.tBlue))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          ('$fName $lName').trim().isNotEmpty
                              ? '$fName $lName'.trim()
                              : 'Unnamed User',
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('$email  |  $mobile',
                          style: bodyStyle(color: AppColors.ink3)),
                    ],
                  ),
                ),
                AmsBadge(label: userCd),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoleListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  const _RoleListView({this.onView});

  @override
  State<_RoleListView> createState() => _RoleListViewState();
}

class _RoleListViewState extends State<_RoleListView> {
  List<Map<String, dynamic>>? _roles;
  int _totalItems = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles(1);
  }

  Future<void> _loadRoles(int page) async {
    setState(() => _loading = true);
    final result = await apiService.getRoles(page: page - 1, size: 10);
    if (mounted) {
      setState(() {
        _roles = result?.items ?? [];
        _totalItems = result?.totalElements ?? 0;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _roles == null) {
      return const AmsListSkeleton();
    }

    return AmsPaginatedView<Map<String, dynamic>>(
      items: _roles ?? [],
      totalRecords: _totalItems,
      onPageChanged: _loadRoles,
      builder: (ctx, currentItems) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: currentItems.length,
        itemBuilder: (ctx, idx) {
          final r = currentItems[idx];
          return AmsCard(
            onTap: widget.onView != null ? () => widget.onView!(r) : null,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: AppColors.tBlueLt, shape: BoxShape.circle),
                  child: Center(
                      child: Text(
                          (r['roleName']?.toString() ?? 'R').isEmpty
                              ? 'R'
                              : r['roleName'][0].toString().toUpperCase(),
                          style: bodyStyle(
                              weight: FontWeight.bold,
                              color: AppColors.tBlue))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['roleName']?.toString() ?? 'Unnamed Role',
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                          'Type: ${r['roleType'] ?? "—"}  |  Subtype: ${r['roleSubtype'] ?? "—"}',
                          style: bodyStyle(color: AppColors.ink3)),
                    ],
                  ),
                ),
                AmsBadge(label: 'Role ${r['roleCd'] ?? "—"}'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UserRoleListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  const _UserRoleListView({this.onView});
  @override
  State<_UserRoleListView> createState() => _UserRoleListViewState();
}

class _UserRoleListViewState extends State<_UserRoleListView> {
  List<Map<String, dynamic>>? _data;
  int _totalItems = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() => _loading = true);
    final result =
        await apiService.getUserRoleAssigns(page: page - 1, size: 10);
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
    if (_loading && _data == null) {
      return const AmsListSkeleton();
    }
    return AmsPaginatedView<Map<String, dynamic>>(
      items: _data ?? [],
      totalRecords: _totalItems,
      onPageChanged: _load,
      builder: (ctx, currentItems) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: currentItems.length,
        itemBuilder: (ctx, idx) {
          final d = currentItems[idx];
          return AmsCard(
            onTap: widget.onView != null ? () => widget.onView!(d) : null,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AmsBadge(
                    label: (d['usersCd'] ?? d['users_cd'] ?? d['userCd'] ?? '—')
                        .toString()),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${d['roleName'] ?? "Unnamed"}',
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModuleListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  const _ModuleListView({this.onView});
  @override
  State<_ModuleListView> createState() => _ModuleListViewState();
}

class _ModuleListViewState extends State<_ModuleListView> {
  List<Map<String, dynamic>>? _data;
  int _totalItems = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() => _loading = true);
    final result = await apiService.getModules(page: page - 1, size: 10);
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
    if (_loading && _data == null) {
      return const AmsListSkeleton();
    }
    return AmsPaginatedView<Map<String, dynamic>>(
      items: _data ?? [],
      totalRecords: _totalItems,
      onPageChanged: _load,
      builder: (ctx, currentItems) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: currentItems.length,
        itemBuilder: (ctx, idx) {
          final d = currentItems[idx];
          final String moduleName = d['moduleName'] ??
              d['modulename'] ??
              d['module_name'] ??
              'Unknown';
          final String moduleCd =
              (d['moduleCd'] ?? d['module_id'] ?? d['moduleid'] ?? '—')
                  .toString();

          return AmsCard(
            onTap: widget.onView != null ? () => widget.onView!(d) : null,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(moduleName,
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Module Code: $moduleCd',
                          style: bodyStyle(color: AppColors.ink3)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MenuListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  const _MenuListView({this.onView});
  @override
  State<_MenuListView> createState() => _MenuListViewState();
}

class _MenuListViewState extends State<_MenuListView> {
  List<Map<String, dynamic>>? _data;
  int _totalItems = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() => _loading = true);
    final result = await apiService.getMenus(page: page - 1, size: 10);
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
    if (_loading && _data == null) {
      return const AmsListSkeleton();
    }
    return AmsPaginatedView<Map<String, dynamic>>(
      items: _data ?? [],
      totalRecords: _totalItems,
      onPageChanged: _load,
      builder: (ctx, currentItems) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: currentItems.length,
        itemBuilder: (ctx, idx) {
          final d = currentItems[idx];
          return AmsCard(
            onTap: widget.onView != null ? () => widget.onView!(d) : null,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['menuName']?.toString() ?? 'Unnamed Menu',
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Type: ${d['type'] ?? d['menuType'] ?? "—"}',
                          style: bodyStyle(color: AppColors.ink3)),
                    ],
                  ),
                ),
                AmsBadge(
                    label: (d['menuId'] ?? d['menuCd'] ?? d['menu_id'] ?? '—')
                        .toString()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuthCtrlListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  const _AuthCtrlListView({this.onView});
  @override
  State<_AuthCtrlListView> createState() => _AuthCtrlListViewState();
}

class _AuthCtrlListViewState extends State<_AuthCtrlListView> {
  Map<String, Auth101Config>? _configs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await apiService.getAuthConfigs();
    setState(() {
      _configs = data ?? auth101;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final cfgList = _configs!.values.toList();
    return AmsPaginatedView<Auth101Config>(
      items: cfgList,
      builder: (ctx, currentItems) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: currentItems.length,
        itemBuilder: (ctx, idx) {
          final c = currentItems[idx];
          return AmsCard(
            onTap: widget.onView != null
                ? () => widget.onView!({
                      'id': c.id,
                      'name': c.name,
                      'approvalReq': c.approvalReq,
                      'isTran': c.isTran,
                      'levels': c.levels
                    })
                : null,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                          'Approval Req: ${c.approvalReq ? 'Yes' : 'No'}  |  Levels: ${c.levels}',
                          style: bodyStyle(color: AppColors.ink3)),
                    ],
                  ),
                ),
                AmsBadge(label: c.id),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DynamicNTFields extends StatefulWidget {
  final String prog;
  final void Function(String key, dynamic val) onChanged;
  final Map<String, dynamic>? initialData;
  final bool isViewMode;

  const DynamicNTFields({
    super.key,
    required this.prog,
    required this.onChanged,
    this.initialData,
    this.isViewMode = false,
  });

  @override
  State<DynamicNTFields> createState() => DynamicNTFieldsState();
}

class DynamicNTFieldsState extends State<DynamicNTFields> {
  final Map<String, String?> _errors = {};

  final _uScdCtrl = TextEditingController();
  final _fNameCtrl = TextEditingController();
  final _lNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  String? _gender;
  String? _menuType;
  String? _title;
  bool _approvalReq = true;
  bool _isTran = false;
  List<Map<String, dynamic>> _authLevels = [];

  final _rScdCtrl = TextEditingController();
  final _rNameCtrl = TextEditingController();

  final _mScdCtrl = TextEditingController();
  final _mNameCtrl = TextEditingController();

  final _menuScdCtrl = TextEditingController();
  final _menuNameCtrl = TextEditingController();

  final _authModCtrl = TextEditingController();
  final _authPgmCtrl = TextEditingController();

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.initialData == null) return;
    final data =
        widget.initialData!.map((k, v) => MapEntry(k.toLowerCase(), v));
    final prog = widget.prog.replaceAll(' ', '-').toUpperCase();

    if (prog == 'USR-CRT') {
      _uScdCtrl.text = data['userscd']?.toString() ?? '';
      _fNameCtrl.text = data['fname']?.toString() ?? '';
      _lNameCtrl.text = data['lname']?.toString() ?? '';
      _emailCtrl.text = data['email']?.toString() ?? '';
      _countryCtrl.text = data['country']?.toString() ?? '';
      _gender = data['gender']?.toString();
      _menuType = data['menutype']?.toString();
      _title = data['title']?.toString();
    } else if (prog == 'ROLE-CRT') {
      _rScdCtrl.text = data['rolecd']?.toString() ?? '';
      _rNameCtrl.text = data['rolename']?.toString() ?? '';
    } else if (prog == 'MOD-CRT') {
      _mScdCtrl.text = data['modcd']?.toString() ?? '';
      _mNameCtrl.text = data['modname']?.toString() ?? '';
    } else if (prog == 'MENU-CRT') {
      _menuScdCtrl.text = data['menucd']?.toString() ?? '';
      _menuNameCtrl.text = data['menuname']?.toString() ?? '';
    } else if (prog == 'AUTHCTL') {
      _authModCtrl.text = data['modcd']?.toString() ?? '';
      _authPgmCtrl.text = data['pgmcd']?.toString() ?? '';
      _approvalReq = data['approvalreq'] == true ||
          data['approvalreq'] == 1 ||
          data['approvalreq'] == '1';
      _isTran = data['istran'] == true ||
          data['istran'] == 1 ||
          data['istran'] == '1';

      if (data['levels_grid'] is List) {
        _authLevels = List<Map<String, dynamic>>.from(data['levels_grid']);
      } else if (data['datablock'] is List) {
        _authLevels = List<Map<String, dynamic>>.from(data['datablock']);
      }
    }
  }

  bool validate() {
    bool isValid = true;
    final prog = widget.prog.replaceAll(' ', '-').toUpperCase();
    setState(() {
      _errors.clear();
      if (prog == 'USR-CRT') {
        if (_uScdCtrl.text.trim().isEmpty) {
          _errors['usersCd'] = 'User Code required';
          isValid = false;
        }
        if (_fNameCtrl.text.trim().isEmpty) {
          _errors['fName'] = 'First Name required';
          isValid = false;
        }
        if (_lNameCtrl.text.trim().isEmpty) {
          _errors['lName'] = 'Last Name required';
          isValid = false;
        }
        if (_emailCtrl.text.trim().isEmpty) {
          _errors['email'] = 'Email required';
          isValid = false;
        } else if (!_isValidEmail(_emailCtrl.text.trim())) {
          _errors['email'] = 'Invalid email format';
          isValid = false;
        }
        if (_gender == null) {
          _errors['gender'] = 'Gender required';
          isValid = false;
        }
      } else if (prog == 'ROLE-CRT') {
        if (_rScdCtrl.text.trim().isEmpty) {
          _errors['roleCd'] = 'Role Code required';
          isValid = false;
        }
        if (_rNameCtrl.text.trim().isEmpty) {
          _errors['roleName'] = 'Role Name required';
          isValid = false;
        }
      } else if (prog == 'MOD-CRT') {
        if (_mScdCtrl.text.trim().isEmpty) {
          _errors['modCd'] = 'Module Code required';
          isValid = false;
        }
        if (_mNameCtrl.text.trim().isEmpty) {
          _errors['modName'] = 'Module Name required';
          isValid = false;
        }
      } else if (prog == 'MENU-CRT') {
        if (_menuScdCtrl.text.trim().isEmpty) {
          _errors['menuCd'] = 'Menu Code required';
          isValid = false;
        }
        if (_menuNameCtrl.text.trim().isEmpty) {
          _errors['menuName'] = 'Menu Name required';
          isValid = false;
        }
      } else if (widget.prog == 'USR-ROLE') {
        if (_uScdCtrl.text.trim().isEmpty) {
          _errors['usersCd'] = 'User Code required';
          isValid = false;
        }
        if (_rScdCtrl.text.trim().isEmpty) {
          _errors['roleCd'] = 'Role Code required';
          isValid = false;
        }
      } else if (widget.prog == 'AUTHCTL') {
        if (_authModCtrl.text.trim().isEmpty) {
          _errors['authMod'] = 'Module Code required';
          isValid = false;
        }
        if (_authPgmCtrl.text.trim().isEmpty) {
          _errors['authPgm'] = 'Program Code required';
          isValid = false;
        }
      }

      if (!isValid) {
        showAmsToast(
          context,
          '⚠',
          'Please fill all mandatory fields correctly.',
          type: 'w',
        );
      }
    });
    return isValid;
  }

  void clearFields() {
    _uScdCtrl.clear();
    _fNameCtrl.clear();
    _lNameCtrl.clear();
    _emailCtrl.clear();
    _countryCtrl.clear();
    _rScdCtrl.clear();
    _rNameCtrl.clear();
    _mScdCtrl.clear();
    _mNameCtrl.clear();
    _menuScdCtrl.clear();
    _menuNameCtrl.clear();
    _authModCtrl.clear();
    _authPgmCtrl.clear();
    setState(() {
      _gender = null;
      _menuType = null;
      _title = null;
      _errors.clear();
    });
  }

  @override
  void dispose() {
    _uScdCtrl.dispose();
    _fNameCtrl.dispose();
    _lNameCtrl.dispose();
    _emailCtrl.dispose();
    _countryCtrl.dispose();
    _rScdCtrl.dispose();
    _rNameCtrl.dispose();
    _mScdCtrl.dispose();
    _mNameCtrl.dispose();
    _menuScdCtrl.dispose();
    _menuNameCtrl.dispose();
    _authModCtrl.dispose();
    _authPgmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data =
        widget.initialData?.map((k, v) => MapEntry(k.toLowerCase(), v)) ?? {};

    switch (widget.prog) {
      case 'USR-CRT':
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: AmsFormGrid(
            children: [
              AmsField(
                label: 'ORGCODE',
                labelAbove: true,
                tooltip: 'Unique organization code assigned to this user.',
                child: AmsTextInput(
                  initialValue: data['orgcode']?.toString() ?? '50',
                  readOnly: widget.isViewMode,
                  textInputAction: TextInputAction.next,
                  onChanged: widget.isViewMode
                      ? null
                      : (v) =>
                          widget.onChanged('orgCode', int.tryParse(v) ?? 50),
                ),
              ),
              AmsField(
                label: 'USERSCD',
                required: true,
                labelAbove: true,
                tooltip: 'Unique identification code for the user.',
                child: AmsTextInput(
                  controller: _uScdCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'User Code (e.g. USR001)',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['usersCd'],
                  isValid:
                      _errors['usersCd'] == null && _uScdCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['usersCd'] =
                          v.trim().isEmpty ? 'User Code required' : null;
                    });
                    widget.onChanged('usersCd', v);
                  },
                ),
              ),
              AmsField(
                label: 'MENUTYPE',
                required: true,
                labelAbove: true,
                tooltip:
                    'Method of menu assignment (Role-based vs User-based).',
                child: widget.isViewMode
                    ? AmsTextInput(
                        initialValue: (data['menutype']?.toString() == '2')
                            ? '2 - Userwise'
                            : '1 - Rolewise',
                        readOnly: true,
                      )
                    : AmsDropdown(
                        initialValue: _menuType ??
                            (data['menutype']?.toString() == '2'
                                ? '2 - Userwise'
                                : '1 - Rolewise'),
                        items: const ['1 - Rolewise', '2 - Userwise'],
                        errorText: _errors['menuType'],
                        isValid:
                            _errors['menuType'] == null && _menuType != null,
                        onChanged: (v) {
                          setState(() {
                            _menuType = v;
                            _errors['menuType'] =
                                v == null ? 'Menu Type required' : null;
                          });
                          widget.onChanged(
                              'menuType', (v ?? '1').startsWith('1') ? 1 : 2);
                        },
                      ),
              ),
              AmsField(
                label: 'GENDER',
                required: true,
                labelAbove: true,
                tooltip: 'The user\'s gender for profile identification.',
                child: widget.isViewMode
                    ? AmsTextInput(
                        initialValue: _gender ??
                            (data['gender']
                                        ?.toString()
                                        .toLowerCase()
                                        .startsWith('f') ==
                                    true
                                ? 'Female'
                                : (data['gender']
                                            ?.toString()
                                            .toLowerCase()
                                            .startsWith('o') ==
                                        true
                                    ? 'Other'
                                    : 'Male')),
                        readOnly: true,
                      )
                    : AmsDropdown(
                        initialValue: _gender ??
                            (data['gender']
                                        ?.toString()
                                        .toLowerCase()
                                        .startsWith('f') ==
                                    true
                                ? 'Female'
                                : (data['gender']
                                            ?.toString()
                                            .toLowerCase()
                                            .startsWith('o') ==
                                        true
                                    ? 'Other'
                                    : (data['gender'] != null
                                        ? 'Male'
                                        : null))),
                        items: const ['Male', 'Female', 'Other'],
                        errorText: _errors['gender'],
                        isValid: _errors['gender'] == null && _gender != null,
                        onChanged: (v) {
                          setState(() {
                            _gender = v;
                            _errors['gender'] =
                                v == null ? 'Gender required' : null;
                          });
                          widget.onChanged('gender', v);
                        },
                      ),
              ),
              AmsField(
                label: 'Primary Contact',
                required: true,
                labelAbove: true,
                tooltip:
                    'Salutation and full name of the primary contact person.',
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: widget.isViewMode
                          ? AmsTextInput(
                              initialValue:
                                  _title ?? data['title']?.toString() ?? 'Mr.',
                              readOnly: true,
                              placeholder: 'TITLE',
                            )
                          : AmsDropdown(
                              initialValue: _title ?? data['title']?.toString(),
                              items: const [
                                'Mr.',
                                'Ms.',
                                'Mrs.',
                                'Dr.',
                                'Prof.'
                              ],
                              placeholder: 'TITLE',
                              onChanged: (v) {
                                setState(() => _title = v);
                                widget.onChanged('title', v);
                              },
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: AmsTextInput(
                        controller: _fNameCtrl,
                        readOnly: widget.isViewMode,
                        placeholder: 'FNAME',
                        textInputAction: TextInputAction.next,
                        errorText: _errors['fName'],
                        isValid: _errors['fName'] == null &&
                            _fNameCtrl.text.isNotEmpty,
                        onChanged: (v) {
                          setState(() {
                            _errors['fName'] =
                                v.trim().isEmpty ? 'First Name required' : null;
                          });
                          widget.onChanged('fName', v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: AmsTextInput(
                        readOnly: widget.isViewMode,
                        initialValue: data['mname']?.toString(),
                        placeholder: 'MNAME',
                        textInputAction: TextInputAction.next,
                        onChanged: widget.isViewMode
                            ? null
                            : (v) => widget.onChanged('mName', v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: AmsTextInput(
                        controller: _lNameCtrl,
                        readOnly: widget.isViewMode,
                        placeholder: 'LNAME',
                        textInputAction: TextInputAction.next,
                        errorText: _errors['lName'],
                        isValid: _errors['lName'] == null &&
                            _lNameCtrl.text.isNotEmpty,
                        onChanged: (v) {
                          setState(() {
                            _errors['lName'] =
                                v.trim().isEmpty ? 'Last Name required' : null;
                          });
                          widget.onChanged('lName', v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              AmsField(
                label: 'EMAIL',
                required: true,
                labelAbove: true,
                tooltip: 'User\'s primary work email address.',
                child: AmsTextInput(
                  controller: _emailCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Work Email ID',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['email'],
                  isValid: _errors['email'] == null &&
                      _emailCtrl.text.isNotEmpty &&
                      _isValidEmail(_emailCtrl.text),
                  onChanged: (v) {
                    setState(() {
                      if (v.isEmpty) {
                        _errors['email'] = null;
                      } else if (!_isValidEmail(v)) {
                        _errors['email'] = 'Invalid email format';
                      } else {
                        _errors['email'] = null;
                      }
                    });
                    widget.onChanged('email', v);
                  },
                  icon: Icons.email_outlined,
                ),
              ),
              AmsField(
                label: 'MOBILE',
                labelAbove: true,
                tooltip: 'Primary mobile number for the user.',
                child: AmsTextInput(
                  readOnly: widget.isViewMode,
                  initialValue: data['mobile']?.toString(),
                  placeholder: 'Contact Number',
                  textInputAction: TextInputAction.next,
                  onChanged: widget.isViewMode
                      ? null
                      : (v) => widget.onChanged('mobile', v),
                  icon: Icons.phone_android_rounded,
                ),
              ),
              AmsField(
                label: 'COUNTRY',
                required: true,
                labelAbove: true,
                tooltip: 'User\'s registered country for localized services.',
                child: AmsTextInput(
                  controller: _countryCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: '2-Digit country code',
                  textInputAction: TextInputAction.done,
                  errorText: _errors['country'],
                  isValid: _errors['country'] == null &&
                      _countryCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['country'] =
                          v.trim().isEmpty ? 'Country required' : null;
                    });
                    widget.onChanged('country', v);
                  },
                ),
              ),
            ],
          ),
        );
      case 'USR-ROLE':
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: AmsFormGrid(
            children: [
              AmsField(
                label: 'USERSCD',
                required: true,
                labelAbove: true,
                tooltip: 'Select the user for role assignment.',
                child: AmsTextInput(
                  controller: _uScdCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. USR001',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['usersCd'],
                  isValid:
                      _errors['usersCd'] == null && _uScdCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['usersCd'] =
                          v.trim().isEmpty ? 'User Code required' : null;
                    });
                    widget.onChanged('usersCd', v);
                  },
                ),
              ),
              AmsField(
                label: 'ROLECD',
                required: true,
                labelAbove: true,
                tooltip: 'Select the role to assign to the user.',
                child: AmsTextInput(
                  controller: _rScdCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. ADM',
                  textInputAction: TextInputAction.done,
                  errorText: _errors['roleCd'],
                  isValid:
                      _errors['roleCd'] == null && _rScdCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['roleCd'] =
                          v.trim().isEmpty ? 'Role Code required' : null;
                    });
                    widget.onChanged('roleCd', v);
                  },
                ),
              ),
            ],
          ),
        );
      case 'ROLE-CRT':
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: AmsFormGrid(
            children: [
              AmsField(
                label: 'ROLECD',
                required: true,
                labelAbove: true,
                tooltip: 'Unique code for the new role.',
                child: AmsTextInput(
                  controller: _rScdCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. ADM',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['roleCd'],
                  isValid:
                      _errors['roleCd'] == null && _rScdCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['roleCd'] =
                          v.trim().isEmpty ? 'Role Code required' : null;
                    });
                    widget.onChanged('roleCd', v);
                  },
                ),
              ),
              AmsField(
                label: 'ROLENAME',
                required: true,
                labelAbove: true,
                tooltip: 'Descriptive name for the role.',
                child: AmsTextInput(
                  controller: _rNameCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. Administrator',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['roleName'],
                  isValid:
                      _errors['roleName'] == null && _rNameCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['roleName'] =
                          v.trim().isEmpty ? 'Role Name required' : null;
                    });
                    widget.onChanged('roleName', v);
                  },
                ),
              ),
              _AccessToggleGroup(
                initialViewAccess:
                    (data['viewaccess']?.toString() ?? '').startsWith('1'),
                initialAuthAccess:
                    (data['authaccess']?.toString() ?? '').startsWith('1'),
                initialMakerAccess:
                    (data['makeraccess']?.toString() ?? '').startsWith('1'),
                initialAdminAccess:
                    (data['adminaccess']?.toString() ?? '').startsWith('1'),
                initialSysAdminAccess:
                    (data['sysadminaccess']?.toString() ?? '').startsWith('1'),
                isViewMode: widget.isViewMode,
                onChanged: widget.onChanged,
              ),
            ],
          ),
        );
      case 'MOD-CRT':
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: AmsFormGrid(
            children: [
              AmsField(
                label: 'MODCD',
                required: true,
                labelAbove: true,
                tooltip: 'Unique module identifier.',
                child: AmsTextInput(
                  controller: _mScdCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. FIN',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['modCd'],
                  isValid:
                      _errors['modCd'] == null && _mScdCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['modCd'] =
                          v.trim().isEmpty ? 'Module Code required' : null;
                    });
                    widget.onChanged('modCd', v);
                  },
                ),
              ),
              AmsField(
                label: 'MODNAME',
                required: true,
                labelAbove: true,
                tooltip: 'Human-readable module name.',
                child: AmsTextInput(
                  controller: _mNameCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. Finance',
                  textInputAction: TextInputAction.done,
                  errorText: _errors['modName'],
                  isValid:
                      _errors['modName'] == null && _mNameCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['modName'] =
                          v.trim().isEmpty ? 'Module Name required' : null;
                    });
                    widget.onChanged('modName', v);
                  },
                ),
              ),
            ],
          ),
        );
      case 'MENU-CRT':
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: AmsFormGrid(
            children: [
              AmsField(
                label: 'MENUCD',
                required: true,
                labelAbove: true,
                tooltip: 'Unique menu identifier.',
                child: AmsTextInput(
                  controller: _menuScdCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. GL-CAT',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['menuCd'],
                  isValid:
                      _errors['menuCd'] == null && _menuScdCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['menuCd'] =
                          v.trim().isEmpty ? 'Menu Code required' : null;
                    });
                    widget.onChanged('menuCd', v);
                  },
                ),
              ),
              AmsField(
                label: 'MENUNAME',
                required: true,
                labelAbove: true,
                tooltip: 'Human-readable menu name.',
                child: AmsTextInput(
                  controller: _menuNameCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. GL Category',
                  textInputAction: TextInputAction.done,
                  errorText: _errors['menuName'],
                  isValid: _errors['menuName'] == null &&
                      _menuNameCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['menuName'] =
                          v.trim().isEmpty ? 'Menu Name required' : null;
                    });
                    widget.onChanged('menuName', v);
                  },
                ),
              ),
            ],
          ),
        );

      case 'AUTHCTL':
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: AmsFormGrid(
            children: [
              AmsField(
                label: 'MODCD',
                required: true,
                labelAbove: true,
                child: AmsTextInput(
                  controller: _authModCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Module Code',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['authMod'],
                  isValid: _errors['authMod'] == null &&
                      _authModCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['authMod'] =
                          v.trim().isEmpty ? 'Module Code required' : null;
                    });
                    widget.onChanged('modCd', v);
                  },
                ),
              ),
              AmsField(
                label: 'PGMCD',
                required: true,
                labelAbove: true,
                child: AmsTextInput(
                  controller: _authPgmCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'Program Code',
                  textInputAction: TextInputAction.done,
                  errorText: _errors['authPgm'],
                  isValid: _errors['authPgm'] == null &&
                      _authPgmCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['authPgm'] =
                          v.trim().isEmpty ? 'Program Code required' : null;
                    });
                    widget.onChanged('pgmCd', v);
                  },
                ),
              ),
              AmsField(
                label: 'APPROVAL REQ',
                labelAbove: true,
                child: Row(
                  children: [
                    Switch(
                      value: _approvalReq,
                      onChanged: widget.isViewMode
                          ? null
                          : (v) {
                              setState(() => _approvalReq = v);
                              widget.onChanged('approvalReq', v);
                            },
                      activeThumbColor: AppColors.tBlue,
                    ),
                    Text(_approvalReq ? 'Yes' : 'No', style: bodyStyle()),
                  ],
                ),
              ),
              AmsField(
                label: 'IS TRANSACTION',
                labelAbove: true,
                child: Row(
                  children: [
                    Switch(
                      value: _isTran,
                      onChanged: widget.isViewMode
                          ? null
                          : (v) {
                              setState(() => _isTran = v);
                              widget.onChanged('isTran', v);
                            },
                      activeThumbColor: AppColors.tBlue,
                    ),
                    Text(_isTran ? 'Yes' : 'No', style: bodyStyle()),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('AUTHORIZATION LEVELS',
                  style: bodyStyle(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.tBlue)),
              const SizedBox(height: 12),
              _Auth102LevelGrid(
                isViewMode: widget.isViewMode,
                initialData: _authLevels,
                onChanged: (levels) {
                  setState(() => _authLevels = levels);
                  widget.onChanged('levels_grid', levels);
                },
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }
}

// ─── Access Toggle Group ──────────────────────────────────────────────────────
class _AccessToggleGroup extends StatefulWidget {
  final bool initialViewAccess;
  final bool initialAuthAccess;
  final bool initialMakerAccess;
  final bool initialAdminAccess;
  final bool initialSysAdminAccess;
  final bool isViewMode;
  final void Function(String key, dynamic val) onChanged;

  const _AccessToggleGroup({
    required this.initialViewAccess,
    required this.initialAuthAccess,
    required this.initialMakerAccess,
    required this.initialAdminAccess,
    required this.initialSysAdminAccess,
    required this.isViewMode,
    required this.onChanged,
  });

  @override
  State<_AccessToggleGroup> createState() => _AccessToggleGroupState();
}

class _AccessToggleGroupState extends State<_AccessToggleGroup> {
  late bool _viewAccess;
  late bool _authAccess;
  late bool _makerAccess;
  late bool _adminAccess;
  late bool _sysAdminAccess;

  @override
  void initState() {
    super.initState();
    _viewAccess = widget.initialViewAccess;
    _authAccess = widget.initialAuthAccess;
    _makerAccess = widget.initialMakerAccess;
    _adminAccess = widget.initialAdminAccess;
    _sysAdminAccess = widget.initialSysAdminAccess;
  }

  Widget _buildToggleRow({
    required String label,
    required String tooltip,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return AmsField(
      label: label,
      labelAbove: true,
      tooltip: tooltip,
      child: GestureDetector(
        onTap: onChanged != null ? () => onChanged(!value) : null,
        child: MouseRegion(
          cursor: onChanged != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: 44,
            height: 22,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: value ? AppColors.tBlue : const Color(0xFFE2E8F0),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AmsFormGrid(
      children: [
        _buildToggleRow(
          label: 'VIEWACCESS',
          tooltip: 'Whether this role is allowed to view the data.',
          value: _viewAccess,
          onChanged: widget.isViewMode
              ? null
              : (v) {
                  setState(() => _viewAccess = v);
                  widget.onChanged('viewAccess', v ? 1 : 0);
                },
        ),
        _buildToggleRow(
          label: 'AUTHACCESS',
          tooltip: 'Whether this role is allowed to authorize.',
          value: _authAccess,
          onChanged: widget.isViewMode
              ? null
              : (v) {
                  setState(() => _authAccess = v);
                  widget.onChanged('authAccess', v ? 1 : 0);
                },
        ),
        _buildToggleRow(
          label: 'MAKERACCESS',
          tooltip: 'Whether this role is allowed to make entries.',
          value: _makerAccess,
          onChanged: widget.isViewMode
              ? null
              : (v) {
                  setState(() => _makerAccess = v);
                  widget.onChanged('makerAccess', v ? 1 : 0);
                },
        ),
        _buildToggleRow(
          label: 'ADMINACCESS',
          tooltip: 'Administration access for configuration.',
          value: _adminAccess,
          onChanged: widget.isViewMode
              ? null
              : (v) {
                  setState(() => _adminAccess = v);
                  widget.onChanged('adminAccess', v ? 1 : 0);
                },
        ),
        _buildToggleRow(
          label: 'SYSADMINACCESS',
          tooltip: 'System administration access.',
          value: _sysAdminAccess,
          onChanged: widget.isViewMode
              ? null
              : (v) {
                  setState(() => _sysAdminAccess = v);
                  widget.onChanged('sysAdminAccess', v ? 1 : 0);
                },
        ),
      ],
    );
  }
}

class _Auth102LevelGrid extends StatefulWidget {
  final void Function(List<Map<String, dynamic>> levels) onChanged;
  final dynamic initialData;
  final bool isViewMode;
  const _Auth102LevelGrid({
    required this.onChanged,
    this.initialData,
    this.isViewMode = false,
  });

  @override
  State<_Auth102LevelGrid> createState() => _Auth102LevelGridState();
}

class _Auth102LevelGridState extends State<_Auth102LevelGrid> {
  final List<Map<String, dynamic>> _levels = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData is List) {
      for (var item in widget.initialData) {
        if (item is Map) {
          _levels.add(Map<String, dynamic>.from(item));
        }
      }
    }
  }

  void _addLevel() {
    setState(() {
      _levels.add({
        'level': _levels.length + 1,
        'permissionType': 'R - Role',
        'roleCd': '',
        'userId': '0',
      });
      _notify();
    });
  }

  void _removeLevel(int index) {
    setState(() {
      _levels.removeAt(index);
      for (int i = 0; i < _levels.length; i++) {
        _levels[i]['level'] = i + 1;
      }
      _notify();
    });
  }

  void _updateLevel(int index, String key, dynamic val) {
    setState(() {
      _levels[index][key] = val;
      if (key == 'permissionType') {
        if (val == 'R - Role') {
          _levels[index]['userId'] = '0';
          _levels[index]['roleCd'] = '';
        } else {
          _levels[index]['roleCd'] = '0';
          _levels[index]['userId'] = '';
        }
      }
      _notify();
    });
  }

  void _notify() => widget.onChanged(_levels);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_levels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No authorization levels configured.',
                    style: bodyStyle(size: 13, color: AppColors.ink3)),
              ),
            ),
          for (int i = 0; i < _levels.length; i++)
            Container(
              margin: EdgeInsets.only(bottom: i == _levels.length - 1 ? 0 : 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('LEVEL ${_levels[i]['level']}',
                          style: monoStyle(
                              size: 12,
                              weight: FontWeight.w700,
                              color: AppColors.nTeal)),
                      if (!widget.isViewMode)
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: AppColors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _removeLevel(i),
                          tooltip: 'Remove Level',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AmsFormGrid(
                    cols: 3,
                    children: [
                      AmsField(
                        label: 'Permission Type',
                        child: AmsDropdown(
                          initialValue: _levels[i]['permissionType'] as String?,
                          items: const ['R - Role', 'U - User'],
                          onChanged: widget.isViewMode
                              ? null
                              : (v) => _updateLevel(i, 'permissionType', v),
                        ),
                      ),
                      AmsField(
                        label: 'Role Code (ROLECD)',
                        pill: _levels[i]['permissionType'] == 'U - User'
                            ? const AmsPill(
                                label: 'DISABLED',
                                background: AppColors.grayLt,
                                color: AppColors.ink3)
                            : null,
                        child: AmsTextInput(
                          initialValue: _levels[i]['roleCd']?.toString(),
                          placeholder: 'e.g. 101',
                          readOnly: widget.isViewMode ||
                              _levels[i]['permissionType'] == 'U - User',
                          onChanged: widget.isViewMode
                              ? null
                              : (v) => _updateLevel(i, 'roleCd', v),
                        ),
                      ),
                      AmsField(
                        label: 'User ID (USERID)',
                        pill: _levels[i]['permissionType'] == 'R - Role'
                            ? const AmsPill(
                                label: 'DISABLED',
                                background: AppColors.grayLt,
                                color: AppColors.ink3)
                            : null,
                        child: AmsTextInput(
                          initialValue: _levels[i]['userId']?.toString(),
                          placeholder: 'e.g. EMP123',
                          readOnly: widget.isViewMode ||
                              _levels[i]['permissionType'] == 'R - Role',
                          onChanged: widget.isViewMode
                              ? null
                              : (v) => _updateLevel(i, 'userId', v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (!widget.isViewMode) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: AmsButton(
                label: '+ Add Level',
                variant: AmsButtonVariant.outline,
                onPressed: _addLevel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
