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

  void _doSubmit() {
    if (_selProg == null) {
      showAmsToast(context, '⚠', 'Please select a program first.', type: 'w');
      return;
    }
    final authsl =
        '2026-${(100 + (DateTime.now().millisecondsSinceEpoch % 900)).toString().padLeft(4, '0')}';

    final fullData = {
      'orgCode': (_selProg == 'USR-CRT' || _selProg == 'ROLE-CRT' || _selProg == 'USR-ROLE') ? 50 : 1,
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
    final isProgramScreenList = _selProg == 'PGM-CRT' && !_showForm;

    final isAnyList = isUserScreenList ||
        isRoleScreenList ||
        isUserRoleScreenList ||
        isModuleScreenList ||
        isMenuScreenList ||
        isAuthCtrlScreenList ||
        isProgramScreenList;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Section (Identity)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _cfg != null
                          ? (isAnyList ? _cfg!.name : 'New ${_cfg!.name}')
                          : 'New Record',
                      style: bodyStyle(
                        size: 22,
                        weight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    if (isAnyList)
                      AmsButton(
                        label: 'New ${_cfg?.name ?? 'Record'}',
                        icon: Icons.add_rounded,
                        onPressed: () => setState(() {
                          _viewRecord = null;
                          _showForm = true;
                        }),
                      )
                    else
                      AmsButton(
                        label: 'Back',
                        variant: AmsButtonVariant.outline,
                        small: true,
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: [
                                  'USR-CRT',
                                  'USR-ROLE',
                                  'ROLE-CRT',
                                  'MOD-CRT',
                                  'MENU-CRT',
                                  'AUTHCTL',
                                  'PGM-CRT'
                                ].contains(_selProg) &&
                                _showForm
                            ? () => setState(() => _showForm = false)
                            : widget.onBack,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content Area (Single Scrollable View)
          Expanded(
            child: () {
              void handleView(Map<String, dynamic> record) {
                setState(() {
                  _viewRecord = record;
                  _showForm = true;
                });
              }

              if (isUserScreenList) return _UserListView(onView: handleView);
              if (isRoleScreenList) return _RoleListView(onView: handleView);
              if (isUserRoleScreenList)
                return _UserRoleListView(onView: handleView);
              if (isModuleScreenList)
                return _ModuleListView(onView: handleView);
              if (isMenuScreenList) return _MenuListView(onView: handleView);
              if (isAuthCtrlScreenList)
                return _AuthCtrlListView(onView: handleView);
              if (isProgramScreenList)
                return _ProgramListView(onView: handleView);

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selProg != null) ...[
                      DynamicNTFields(
                        prog: _selProg!,
                        initialData: _viewRecord,
                        isViewMode: _viewRecord != null,
                        onChanged: (key, val) => _dynamicData[key] = val,
                      ),
                    ],
                  ],
                ),
              );
            }(),
          ),

          // Footer Submit Bar
          if (!isAnyList)
            AmsSubmitBar(
              borderColor: AppColors.nTealMd,
              actions: [
                AmsButton(
                    label: _viewRecord != null ? 'Back to List' : 'Cancel',
                    variant: AmsButtonVariant.ghost,
                    onPressed: () {
                      if ([
                            'USR-CRT',
                            'USR-ROLE',
                            'ROLE-CRT',
                            'MOD-CRT',
                            'MENU-CRT',
                            'AUTHCTL'
                          ].contains(_selProg) &&
                          _showForm) {
                        setState(() {
                          _showForm = false;
                          _viewRecord = null;
                        });
                      } else {
                        widget.onBack();
                      }
                    }),
                if (_viewRecord == null) const SizedBox(width: 12),
                if (_viewRecord == null)
                  AmsButton(
                      label: isDirectSave ? 'Save' : 'Submit',
                      variant: isDirectSave
                          ? AmsButtonVariant.green
                          : AmsButtonVariant.primary,
                      onPressed: _doSubmit),
              ],
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await apiService.getUsers();
    setState(() {
      _users = users ??
          [
            {
              'usersCd': 'USR001',
              'fName': 'Arjun',
              'lName': 'Mehta',
              'email': 'arjun.m@example.com',
              'mobile': '9876543210'
            },
            {
              'usersCd': 'USR002',
              'fName': 'Priya',
              'lName': 'R',
              'email': 'priya.r@example.com',
              'mobile': '9876543211'
            },
            {
              'usersCd': 'USR003',
              'fName': 'Ravi',
              'lName': 'K',
              'email': 'ravi.k@example.com',
              'mobile': '9876543212'
            },
          ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return AmsPaginatedView<Map<String, dynamic>>(
      items: _users!,
      builder: (ctx, currentItems) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: currentItems.length,
        itemBuilder: (ctx, idx) {
          final u = currentItems[idx];
          final String fName = u['fName'] ?? u['fname'] ?? '';
          final String lName = u['lName'] ?? u['lname'] ?? '';
          final String email = u['email'] ?? 'No Email';
          final String mobile = u['mobile'] ?? 'No Mobile';
          final String userCd = u['userScd'] ?? u['usersCd'] ?? 'Unknown';
          final String initial = fName.isNotEmpty
              ? fName[0].toUpperCase()
              : (userCd.isNotEmpty ? userCd[0].toUpperCase() : 'U');

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
                      Text('$fName $lName'.trim(),
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final roles = await apiService.getRoles();
    setState(() {
      _roles = roles ??
          [
            {
              'roleCd': '101',
              'roleName': 'System Admin',
              'roleType': 'M - Master',
              'roleSubtype': 'ALL'
            },
            {
              'roleCd': '102',
              'roleName': 'Branch Manager',
              'roleType': 'O - Operator',
              'roleSubtype': 'BRN'
            },
            {
              'roleCd': '103',
              'roleName': 'Teller',
              'roleType': 'B - Batch',
              'roleSubtype': 'TRX'
            },
          ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return AmsPaginatedView<Map<String, dynamic>>(
      items: _roles!,
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
                      child: Text(r['roleName'][0].toString().toUpperCase(),
                          style: bodyStyle(
                              weight: FontWeight.bold,
                              color: AppColors.tBlue))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r['roleName']}',
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                          'Type: ${r['roleType']}  |  Subtype: ${r['roleSubtype']}',
                          style: bodyStyle(color: AppColors.ink3)),
                    ],
                  ),
                ),
                AmsBadge(label: 'Role ${r['roleCd']}'),
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await apiService.getUserRoleAssigns();
    setState(() {
      _data = data ??
          [
            {
              'usersCd': 'USR001',
              'roleName': 'System Admin',
              'status': 'Active'
            },
            {
              'usersCd': 'USR002',
              'roleName': 'Branch Manager',
              'status': 'Active'
            },
          ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return AmsPaginatedView<Map<String, dynamic>>(
      items: _data!,
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
                AmsBadge(label: d['usersCd']),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${d['roleName']}',
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Status: ${d['status']}',
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

class _ModuleListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  const _ModuleListView({this.onView});
  @override
  State<_ModuleListView> createState() => _ModuleListViewState();
}

class _ModuleListViewState extends State<_ModuleListView> {
  List<Map<String, dynamic>>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await apiService.getModules();
    setState(() {
      _data = data ??
          [
            {'moduleCd': 'CORE', 'moduleName': 'Core Banking'},
            {'moduleCd': 'AUTH', 'moduleName': 'Authorization App'},
          ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return AmsPaginatedView<Map<String, dynamic>>(
      items: _data!,
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
                      Text('${d['moduleName']}',
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Module Code: ${d['moduleCd']}',
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await apiService.getMenus();
    setState(() {
      _data = data ??
          [
            {'menuId': 'M01', 'menuName': 'Dashboard', 'type': 'Link'},
            {'menuId': 'M02', 'menuName': 'User Management', 'type': 'Parent'},
          ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return AmsPaginatedView<Map<String, dynamic>>(
      items: _data!,
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
                      Text('${d['menuName']}',
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Type: ${d['type']}',
                          style: bodyStyle(color: AppColors.ink3)),
                    ],
                  ),
                ),
                AmsBadge(label: d['menuId']),
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

class _ProgramListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  const _ProgramListView({this.onView});
  @override
  State<_ProgramListView> createState() => _ProgramListViewState();
}

class _ProgramListViewState extends State<_ProgramListView> {
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
                      'programId': c.id,
                      'isTranPgm': c.isTran ? 1 : 0,
                      'orgCode': 50,
                    })
                : null,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.id,
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                          'Type: ${c.isTran ? 'Financial' : 'Non-Financial'}',
                          style: bodyStyle(color: AppColors.ink3)),
                    ],
                  ),
                ),
                AmsBadge(
                    label: c.isTran ? 'TRAN' : 'N-TRAN',
                    color: c.isTran ? AppColors.tBlue : AppColors.ink4),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DynamicNTFields extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Map<String, dynamic> data =
        initialData?.map((k, v) => MapEntry(k.toLowerCase(), v)) ?? {};

    switch (prog) {
      case 'USR-CRT':
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
              AmsField(
                label: 'ORGCODE',
                tooltip: 'Unique organization code assigned to this user.',
                child: AmsTextInput(
                  initialValue: data['orgcode']?.toString() ?? '50',
                  readOnly: true,
                ),
              ),
              AmsField(
                label: 'USERSCD',
                required: true,
                tooltip: 'Unique identification code for the user.',
                child: AmsTextInput(
                  initialValue: data['userscd']?.toString(),
                  readOnly: isViewMode,
                  placeholder: 'User Code (e.g. USR001)',
                  onChanged: isViewMode ? null : (v) => onChanged('usersCd', v),
                ),
              ),
              AmsField(
                label: 'MENUTYPE',
                required: true,
                tooltip:
                    'Method of menu assignment (Role-based vs User-based).',
                child: AmsDropdown(
                  initialValue: data['menutype']?.toString() == '2' || data['menutype']?.toString() == '2 - Userwise'
                      ? '2 - Userwise'
                      : (data['menutype'] != null ? '1 - Rolewise' : null),
                  items: const ['1 - Rolewise', '2 - Userwise'],
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged(
                          'menuType', (v ?? '1').startsWith('1') ? 1 : 2),
                ),
              ),
              AmsField(
                label: 'GENDER',
                required: true,
                tooltip: 'The user\'s gender for profile identification.',
                child: AmsDropdown(
                  initialValue: data['gender']?.toString().toLowerCase().startsWith('f') == true
                      ? 'Female'
                      : (data['gender']?.toString().toLowerCase().startsWith('o') == true
                          ? 'Other'
                          : (data['gender'] != null ? 'Male' : null)),
                  items: const ['Male', 'Female', 'Other'],
                  onChanged: isViewMode ? null : (v) => onChanged('gender', v),
                ),
              ),
              AmsField(
                label: 'Primary Contact',
                required: true,
                tooltip:
                    'Salutation and full name of the primary contact person.',
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AmsDropdown(
                        initialValue: const [
                          'Mr.',
                          'Ms.',
                          'Mrs.',
                          'Dr.',
                          'Prof.'
                        ].contains(data['title']?.toString())
                            ? (data['title']?.toString())
                            : null,
                        items: const ['Mr.', 'Ms.', 'Mrs.', 'Dr.', 'Prof.'],
                        placeholder: 'TITLE',
                        onChanged:
                            isViewMode ? null : (v) => onChanged('title', v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: AmsTextInput(
                        initialValue: data['fname']?.toString(),
                        readOnly: isViewMode,
                        placeholder: 'FNAME',
                        onChanged:
                            isViewMode ? null : (v) => onChanged('fName', v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: AmsTextInput(
                        initialValue: data['mname']?.toString(),
                        readOnly: isViewMode,
                        placeholder: 'MNAME',
                        onChanged:
                            isViewMode ? null : (v) => onChanged('mName', v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: AmsTextInput(
                        initialValue: data['lname']?.toString(),
                        readOnly: isViewMode,
                        placeholder: 'LNAME',
                        onChanged:
                            isViewMode ? null : (v) => onChanged('lName', v),
                      ),
                    ),
                  ],
                ),
              ),
              AmsField(
                label: 'EMAIL',
                required: true,
                tooltip: 'User\'s primary work email address.',
                child: AmsTextInput(
                  initialValue: data['email']?.toString(),
                  readOnly: isViewMode,
                  placeholder: 'Work Email ID',
                  onChanged: isViewMode ? null : (v) => onChanged('email', v),
                  icon: Icons.email_outlined,
                ),
              ),
              AmsField(
                label: 'MOBILE',
                tooltip: 'Primary mobile number for the user.',
                child: AmsTextInput(
                  initialValue: data['mobile']?.toString(),
                  readOnly: isViewMode,
                  placeholder: 'Contact Number',
                  onChanged: isViewMode ? null : (v) => onChanged('mobile', v),
                  icon: Icons.phone_android_rounded,
                ),
              ),
              AmsField(
                label: 'COUNTRY',
                required: true,
                tooltip: 'Country of residence (2-digit code).',
                child: AmsTextInput(
                  initialValue: data['country']?.toString(),
                  readOnly: isViewMode,
                  placeholder: '2 Digit country code',
                  onChanged: isViewMode ? null : (v) => onChanged('country', v),
                ),
              ),
            ],
          ),
        );
      case 'USR-ROLE': // User-Role Assignment
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
              AmsField(
                label: 'ORGCODE',
                tooltip: 'Unique organization code.',
                child: AmsTextInput(
                  initialValue: data['orgcode']?.toString() ?? '50',
                  readOnly: true,
                ),
              ),
              AmsField(
                label: 'USERSCD',
                required: true,
                tooltip: 'Target User ID for role assignment.',
                child: AmsTextInput(
                  initialValue: data['userscd']?.toString(),
                  readOnly: isViewMode,
                  placeholder: 'e.g. arjun_m',
                  onChanged: isViewMode ? null : (v) => onChanged('usersCd', v),
                ),
              ),
              AmsField(
                label: 'ROLECD',
                required: true,
                tooltip: 'Role ID to be assigned.',
                child: AmsTextInput(
                  initialValue: data['rolecd']?.toString() ?? '10',
                  readOnly: isViewMode,
                  placeholder: 'e.g. 10',
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged('roleCd', int.tryParse(v) ?? 10),
                ),
              ),
            ],
          ),
        );
      case 'ROLE-CRT': // Role Creation
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
              AmsField(
                label: 'ORGCODE',
                tooltip: 'Unique organization code for this role.',
                child: AmsTextInput(
                  initialValue: data['orgcode']?.toString() ?? '50',
                  readOnly: true,
                ),
              ),
              AmsField(
                label: 'ROLECD',
                required: true,
                tooltip: 'Unique numerical identifier for the role.',
                child: AmsTextInput(
                  initialValue: data['rolecd']?.toString(),
                  readOnly: isViewMode,
                  placeholder: 'e.g. 101',
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged('roleCd', int.tryParse(v) ?? 0),
                ),
              ),
              AmsField(
                label: 'ROLENAME',
                required: true,
                tooltip: 'Descriptive name for the role.',
                child: AmsTextInput(
                  initialValue: initialData?['roleName']?.toString(),
                  readOnly: isViewMode,
                  placeholder: 'e.g. Senior Auditor',
                  onChanged:
                      isViewMode ? null : (v) => onChanged('roleName', v),
                ),
              ),
              AmsField(
                label: 'ROLETYPE',
                required: true,
                tooltip: 'Primary categorization of the role.',
                child: AmsDropdown(
                  initialValue: initialData?['roleType'] != null
                      ? '${initialData!['roleType']} - ${initialData!['roleType'] == 'M' ? 'Master' : (initialData!['roleType'] == 'S' ? 'System' : 'Transaction')}'
                      : null,
                  items: const ['M - Master', 'S - System', 'T - Transaction'],
                  onChanged:
                      isViewMode ? null : (v) => onChanged('roleType', v?[0]),
                ),
              ),
              AmsField(
                label: 'ROLESUBTYPE',
                tooltip: 'Secondary categorization for future usage.',
                child: AmsTextInput(
                  initialValue: initialData?['roleSubType']?.toString(),
                  readOnly: isViewMode,
                  placeholder: 'e.g. AUDIT',
                  onChanged:
                      isViewMode ? null : (v) => onChanged('roleSubType', v),
                ),
              ),
              AmsField(
                label: 'VIEWACCESS',
                tooltip: 'Whether this role is to view the data.',
                child: AmsDropdown(
                  initialValue: initialData?['viewAccess']?.toString() == '1'
                      ? '1 - Enable'
                      : (initialData?['viewAccess'] != null
                          ? '0 - Disable'
                          : null),
                  items: const ['1 - Enable', '0 - Disable'],
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged(
                          'viewAccess', (v ?? '0').startsWith('1') ? 1 : 0),
                ),
              ),
              AmsField(
                label: 'AUTHACCESS',
                tooltip: 'Whether this role is allowed to authorize.',
                child: AmsDropdown(
                  initialValue: initialData?['authAccess']?.toString() == '1'
                      ? '1 - Enable'
                      : (initialData?['authAccess'] != null
                          ? '0 - Disable'
                          : null),
                  items: const ['1 - Enable', '0 - Disable'],
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged(
                          'authAccess', (v ?? '0').startsWith('1') ? 1 : 0),
                ),
              ),
              AmsField(
                label: 'MAKERACCESS',
                tooltip: 'Whether this role is allowed to make entries.',
                child: AmsDropdown(
                  initialValue: initialData?['makerAccess']?.toString() == '1'
                      ? '1 - Enable'
                      : (initialData?['makerAccess'] != null
                          ? '0 - Disable'
                          : null),
                  items: const ['1 - Enable', '0 - Disable'],
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged(
                          'makerAccess', (v ?? '0').startsWith('1') ? 1 : 0),
                ),
              ),
              AmsField(
                label: 'ADMINACCESS',
                tooltip: 'Administration access for configuration.',
                child: AmsDropdown(
                  initialValue: initialData?['adminAccess']?.toString() == '1'
                      ? '1 - Enable'
                      : (initialData?['adminAccess'] != null
                          ? '0 - Disable'
                          : null),
                  items: const ['1 - Enable', '0 - Disable'],
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged(
                          'adminAccess', (v ?? '0').startsWith('1') ? 1 : 0),
                ),
              ),
              AmsField(
                label: 'SYSADMINACCESS',
                tooltip: 'System administration access.',
                child: AmsDropdown(
                  initialValue:
                      initialData?['sysAdminAccess']?.toString() == '1'
                          ? '1 - Enable'
                          : (initialData?['sysAdminAccess'] != null
                              ? '0 - Disable'
                              : null),
                  items: const ['1 - Enable', '0 - Disable'],
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged(
                          'sysAdminAccess', (v ?? '0').startsWith('1') ? 1 : 0),
                ),
              ),
            ],
          ),
        );

      case 'MOD-CRT':
        return _ModCrtFields(
          onChanged: onChanged,
          initialData: initialData,
          isViewMode: isViewMode,
        );
      case 'MENU-CRT':
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
              AmsField(
                  label: 'Menu Identification',
                  required: true,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: AmsTextInput(
                            initialValue: initialData?['pgmId']?.toString(),
                            readOnly: isViewMode,
                            placeholder: 'ID (Code)',
                            onChanged: isViewMode
                                ? null
                                : (v) => onChanged('pgmId', v)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AmsTextInput(
                            initialValue: initialData?['descn']?.toString(),
                            readOnly: isViewMode,
                            placeholder: 'Program Name (e.g. Reports)',
                            onChanged: isViewMode
                                ? null
                                : (v) => onChanged('descn', v)),
                      ),
                    ],
                  )),
              AmsField(
                  label: 'Module Association',
                  required: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: AmsTextInput(
                            initialValue: initialData?['module']?.toString(),
                            readOnly: isViewMode,
                            placeholder: 'Module ID',
                            onChanged: isViewMode
                                ? null
                                : (v) =>
                                    onChanged('module', int.tryParse(v) ?? 1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AmsTextInput(
                            initialValue: initialData?['subModule']?.toString(),
                            readOnly: isViewMode,
                            placeholder: 'Sub-Module ID',
                            onChanged: isViewMode
                                ? null
                                : (v) => onChanged(
                                    'subModule', int.tryParse(v) ?? 0)),
                      ),
                    ],
                  )),
              AmsField(
                  label: 'Menu Status',
                  required: true,
                  child: AmsDropdown(
                      initialValue: initialData?['status']?.toString() == '1'
                          ? 'Active'
                          : (initialData?['status'] != null
                              ? 'Inactive'
                              : null),
                      placeholder: 'Status',
                      items: const ['Active', 'Inactive'],
                      onChanged: isViewMode
                          ? null
                          : (v) => onChanged('status', v == 'Active' ? 1 : 0))),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmsField(
                label: 'Program ID',
                required: true,
                tooltip: 'Unique identifier for the program. e.g. LOAN, NEFT',
                child: AmsTextInput(
                  initialValue: initialData?['programId']?.toString(),
                  readOnly: isViewMode,
                  placeholder: 'e.g. LOAN',
                  onChanged:
                      isViewMode ? null : (v) => onChanged('programId', v),
                ),
              ),
              AmsField(
                label: 'Approval Required',
                required: true,
                tooltip:
                    'Whether this program requires authorization approval.',
                child: AmsDropdown(
                  initialValue: initialData?['approvalReq']?.toString() == '1'
                      ? 'Yes'
                      : (initialData?['approvalReq'] != null ? 'No' : null),
                  placeholder: 'Select...',
                  items: const ['Yes', 'No'],
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged('approvalReq', v == 'Yes' ? 1 : 0),
                ),
              ),
              AmsField(
                label: 'Pre-Approve',
                tooltip:
                    'Run a procedure before the authorization is approved.',
                child: AmsDropdown(
                  initialValue: initialData?['preApproveProc']?.toString() ==
                          '1'
                      ? 'Yes'
                      : (initialData?['preApproveProc'] != null ? 'No' : null),
                  placeholder: 'Select...',
                  items: const ['Yes', 'No'],
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged('preApproveProc', v == 'Yes' ? 1 : 0),
                ),
              ),
              AmsField(
                label: 'Post-Approve',
                tooltip: 'Run a procedure after the authorization is approved.',
                child: AmsDropdown(
                  initialValue: initialData?['postApproveProc']?.toString() ==
                          '1'
                      ? 'Yes'
                      : (initialData?['postApproveProc'] != null ? 'No' : null),
                  placeholder: 'Select...',
                  items: const ['Yes', 'No'],
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged('postApproveProc', v == 'Yes' ? 1 : 0),
                ),
              ),
              AmsField(
                label: 'Execution Type',
                required: true,
                tooltip: 'Whether this is a Transaction Program (ISTRANPGM).',
                child: AmsDropdown(
                  initialValue: initialData?['isTranPgm']?.toString() == '1'
                      ? 'Yes'
                      : (initialData?['isTranPgm'] != null ? 'No' : null),
                  placeholder: 'Is Transaction Program?',
                  items: const ['Yes', 'No'],
                  onChanged: isViewMode
                      ? null
                      : (v) => onChanged('isTranPgm', v == 'Yes' ? 1 : 0),
                ),
              ),
              AmsField(
                label: 'Authorization Levels',
                child: _Auth102LevelGrid(
                    initialData: initialData?['authLevels'],
                    isViewMode: isViewMode,
                    onChanged: (levels) => onChanged('authLevels', levels)),
              ),
            ],
          ),
        );
      case 'PGM-CRT':
        return _ProgramFields(
            onChanged: onChanged,
            initialData: initialData,
            isViewMode: isViewMode);
      default:
        return const SizedBox();
    }
  }
}

class _FormGrid extends StatelessWidget {
  final List<Widget> children;
  final int cols;

  const _FormGrid({required this.children, this.cols = 2});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final effectiveCols = constraints.maxWidth < 500
          ? 1
          : (constraints.maxWidth < 700 ? 2 : cols);
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: children.map((child) {
          final w =
              (constraints.maxWidth - (effectiveCols - 1) * 14) / effectiveCols;
          return SizedBox(width: w.clamp(0, double.infinity), child: child);
        }).toList(),
      );
    });
  }
}

class _Auth102LevelGrid extends StatefulWidget {
  final void Function(List<Map<String, dynamic>> levels) onChanged;
  final dynamic initialData;
  final bool isViewMode;
  const _Auth102LevelGrid(
      {required this.onChanged, this.initialData, this.isViewMode = false});

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
                  _FormGrid(
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

// ___ Module Creation Fields __________________________________________________

class _ModCrtFields extends StatefulWidget {
  final void Function(String key, dynamic val) onChanged;
  final Map<String, dynamic>? initialData;
  final bool isViewMode;
  const _ModCrtFields(
      {required this.onChanged, this.initialData, this.isViewMode = false});

  @override
  State<_ModCrtFields> createState() => _ModCrtFieldsState();
}

class _ModCrtFieldsState extends State<_ModCrtFields> {
  bool _subModuleEnabled = false;

  @override
  void initState() {
    super.initState();
    _subModuleEnabled =
        widget.initialData?['subModuleRequired']?.toString() == '1';
  }

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
          AmsField(
            label: 'MODULE_ID',
            required: true,
            tooltip: 'Unique ID for the module. e.g. 1, 2, 3, 4',
            child: AmsTextInput(
              initialValue: widget.initialData?['moduleId']?.toString(),
              readOnly: widget.isViewMode,
              placeholder: 'e.g. 1',
              keyboardType: TextInputType.number,
              onChanged: widget.isViewMode
                  ? null
                  : (v) => widget.onChanged('moduleId', int.tryParse(v) ?? 0),
            ),
          ),
          AmsField(
            label: 'MODULENAME',
            required: true,
            tooltip:
                'Display name of the module. e.g. Chat, Voice Call, Video Call',
            child: AmsTextInput(
              initialValue: widget.initialData?['moduleName']?.toString(),
              readOnly: widget.isViewMode,
              placeholder: 'e.g. Chat',
              onChanged: widget.isViewMode
                  ? null
                  : (v) => widget.onChanged('moduleName', v),
            ),
          ),
          AmsField(
            label: 'SUB_MODULE',
            required: true,
            tooltip: 'Whether a sub-module is required or not.',
            child: AmsDropdown(
              initialValue:
                  widget.initialData?['subModuleRequired']?.toString() == '1'
                      ? '1 - Enable'
                      : (widget.initialData?['subModuleRequired'] != null
                          ? '0 - Disable'
                          : null),
              items: const ['1 - Enable', '0 - Disable'],
              placeholder: 'Select...',
              onChanged: widget.isViewMode
                  ? null
                  : (v) {
                      final enabled = (v ?? '').startsWith('1');
                      setState(() => _subModuleEnabled = enabled);
                      widget.onChanged('subModuleRequired', enabled ? 1 : 0);
                    },
            ),
          ),
          AmsField(
            label: 'STATUS',
            required: true,
            tooltip: '1 - Enable, 0 - Disable the module.',
            child: AmsDropdown(
              initialValue: widget.initialData?['status']?.toString() == '1'
                  ? '1 - Enable'
                  : (widget.initialData?['status'] != null
                      ? '0 - Disable'
                      : null),
              items: const ['1 - Enable', '0 - Disable'],
              placeholder: 'Select...',
              onChanged: widget.isViewMode
                  ? null
                  : (v) => widget.onChanged(
                      'status', (v ?? '').startsWith('1') ? 1 : 0),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SizeTransition(
                  sizeFactor: anim, axisAlignment: -1, child: child),
            ),
            child: _subModuleEnabled
                ? Column(
                    key: const ValueKey('sub_module_card'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AmsField(
                        label: 'SUB_MODULEID',
                        required: true,
                        tooltip: 'Unique ID for the sub-module.',
                        child: AmsTextInput(
                          initialValue:
                              widget.initialData?['subModuleId']?.toString(),
                          readOnly: widget.isViewMode,
                          placeholder: 'e.g. 101',
                          keyboardType: TextInputType.number,
                          onChanged: widget.isViewMode
                              ? null
                              : (v) => widget.onChanged(
                                  'subModuleId', int.tryParse(v) ?? 0),
                        ),
                      ),
                      AmsField(
                        label: 'Sub Module Name',
                        required: true,
                        tooltip: 'Name of the sub-module.',
                        child: AmsTextInput(
                          initialValue:
                              widget.initialData?['subModuleName']?.toString(),
                          readOnly: widget.isViewMode,
                          placeholder: 'e.g. Group Chat',
                          onChanged: widget.isViewMode
                              ? null
                              : (v) => widget.onChanged('subModuleName', v),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }
}

class _ProgramFields extends StatelessWidget {
  final void Function(String key, dynamic val) onChanged;
  final Map<String, dynamic>? initialData;
  final bool isViewMode;
  const _ProgramFields(
      {required this.onChanged, this.initialData, this.isViewMode = false});

  @override
  Widget build(BuildContext context) {
    // Ensure all keys are lowercase for consistency with isAnyList logic if needed
    // or just use them as they come from initialData map.
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
          AmsField(
            label: 'ORGCODE',
            tooltip: 'Fixed organization code for this program.',
            child: AmsTextInput(
              initialValue: initialData?['orgCode']?.toString() ?? '50',
              readOnly: true,
            ),
          ),
          AmsField(
            label: 'PROGRAMID',
            required: true,
            tooltip: 'Unique identifier for the program (e.g. LOAN, NEFT).',
            child: AmsTextInput(
              initialValue: initialData?['programId']?.toString(),
              readOnly: isViewMode,
              placeholder: 'e.g. LOAN',
              onChanged: isViewMode ? null : (v) => onChanged('programId', v),
            ),
          ),
          AmsField(
            label: 'FINANCIAL REQUIRED',
            required: true,
            tooltip: 'Whether this program involves financial transactions.',
            child: AmsDropdown(
              initialValue: initialData?['isTranPgm']?.toString() == '1'
                  ? 'Yes'
                  : (initialData?['isTranPgm'] != null ? 'No' : null),
              placeholder: 'Required?',
              items: const ['Yes', 'No'],
              onChanged: isViewMode
                  ? null
                  : (v) {
                      final isTran = v == 'Yes' ? 1 : 0;
                      onChanged('isTranPgm', isTran);
                      onChanged('approvalReq', 1);
                      onChanged('authLevels', [
                        {
                          'level': 1,
                          'permissionType': 'R - Role',
                          'roleCd': '10',
                          'userId': '0'
                        }
                      ]);
                    },
            ),
          ),
        ],
      ),
    );
  }
}
