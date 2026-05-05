import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../services/branch_api_service.dart';
import '../services/org_api_service.dart';
import '../data.dart';

import 'branch_screen.dart';

const Map<String, String> _kAllCountries = {
  "Afghanistan": "93",
  "Albania": "355",
  "Algeria": "213",
  "Andorra": "376",
  "Angola": "244",
  "Argentina": "54",
  "Armenia": "374",
  "Australia": "61",
  "Austria": "43",
  "Azerbaijan": "994",
  "Bahamas": "1",
  "Bahrain": "973",
  "Bangladesh": "880",
  "Belarus": "375",
  "Belgium": "32",
  "Belize": "501",
  "Benin": "229",
  "Bhutan": "975",
  "Bolivia": "591",
  "Bosnia and Herzegovina": "387",
  "Botswana": "267",
  "Brazil": "55",
  "Brunei": "673",
  "Bulgaria": "359",
  "Burkina Faso": "226",
  "Burundi": "257",
  "Cambodia": "855",
  "Cameroon": "237",
  "Canada": "1",
  "Central African Republic": "236",
  "Chad": "235",
  "Chile": "56",
  "China": "86",
  "Colombia": "57",
  "Comoros": "269",
  "Congo": "242",
  "Costa Rica": "506",
  "Croatia": "385",
  "Cuba": "53",
  "Cyprus": "357",
  "Czech Republic": "420",
  "Denmark": "45",
  "Djibouti": "253",
  "Dominican Republic": "1",
  "Ecuador": "593",
  "Egypt": "20",
  "El Salvador": "503",
  "Equatorial Guinea": "240",
  "Eritrea": "291",
  "Estonia": "372",
  "Ethiopia": "251",
  "Fiji": "679",
  "Finland": "358",
  "France": "33",
  "Gabon": "241",
  "Gambia": "220",
  "Georgia": "995",
  "Germany": "49",
  "Ghana": "233",
  "Greece": "30",
  "Grenada": "1",
  "Guatemala": "502",
  "Guinea": "224",
  "Guyana": "592",
  "Haiti": "509",
  "Honduras": "504",
  "Hungary": "36",
  "Iceland": "354",
  "India": "91",
  "Indonesia": "62",
  "Iran": "98",
  "Iraq": "964",
  "Ireland": "353",
  "Israel": "972",
  "Italy": "39",
  "Jamaica": "1",
  "Japan": "81",
  "Jordan": "962",
  "Kazakhstan": "7",
  "Kenya": "254",
  "Kiribati": "686",
  "Kuwait": "965",
  "Kyrgyzstan": "996",
  "Laos": "856",
  "Latvia": "371",
  "Lebanon": "961",
  "Lesotho": "266",
  "Liberia": "231",
  "Libya": "218",
  "Liechtenstein": "423",
  "Lithuania": "370",
  "Luxembourg": "352",
  "Madagascar": "261",
  "Malawi": "265",
  "Malaysia": "60",
  "Maldives": "960",
  "Mali": "223",
  "Malta": "356",
  "Marshall Islands": "692",
  "Mauritania": "222",
  "Mauritius": "230",
  "Mexico": "52",
  "Micronesia": "691",
  "Moldova": "373",
  "Monaco": "377",
  "Mongolia": "976",
  "Montenegro": "382",
  "Morocco": "212",
  "Mozambique": "258",
  "Myanmar": "95",
  "Namibia": "264",
  "Nauru": "674",
  "Nepal": "977",
  "Netherlands": "31",
  "New Zealand": "64",
  "Nicaragua": "505",
  "Niger": "227",
  "Nigeria": "234",
  "North Korea": "850",
  "Norway": "47",
  "Oman": "968",
  "Pakistan": "92",
  "Palau": "680",
  "Panama": "507",
  "Papua New Guinea": "675",
  "Paraguay": "595",
  "Peru": "51",
  "Philippines": "63",
  "Poland": "48",
  "Portugal": "351",
  "Qatar": "974",
  "Romania": "40",
  "Russia": "7",
  "Rwanda": "250",
  "Samoa": "685",
  "San Marino": "378",
  "Saudi Arabia": "966",
  "Senegal": "221",
  "Serbia": "381",
  "Seychelles": "248",
  "Sierra Leone": "232",
  "Singapore": "65",
  "Slovakia": "421",
  "Slovenia": "386",
  "Solomon Islands": "677",
  "Somalia": "252",
  "South Africa": "27",
  "South Korea": "82",
  "South Sudan": "211",
  "Spain": "34",
  "Sri Lanka": "94",
  "Sudan": "249",
  "Suriname": "597",
  "Swaziland": "268",
  "Sweden": "46",
  "Switzerland": "41",
  "Syria": "963",
  "Taiwan": "886",
  "Tajikistan": "992",
  "Tanzania": "255",
  "Thailand": "66",
  "Togo": "228",
  "Tonga": "676",
  "Trinidad and Tobago": "1",
  "Tunisia": "216",
  "Turkey": "90",
  "Turkmenistan": "993",
  "Tuvalu": "688",
  "Uganda": "256",
  "Ukraine": "380",
  "United Arab Emirates": "971",
  "United Kingdom": "44",
  "United States": "1",
  "Uruguay": "598",
  "Uzbekistan": "998",
  "Vanuatu": "678",
  "Vatican City": "379",
  "Venezuela": "58",
  "Vietnam": "84",
  "Yemen": "967",
  "Zambia": "260",
  "Zimbabwe": "263"
};

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
  bool _isEditMode = false;
  bool _isLoading = false;
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
        _isEditMode = false;
        _showForm = false;
        _viewRecord = null;
      });
    }
  }

  Auth101Config? get _cfg =>
      _selProg != null ? widget.authConfigs[_selProg] : null;

  final GlobalKey<DynamicNTFieldsState> _fieldsKey =
      GlobalKey<DynamicNTFieldsState>();

  Future<void> _handleDeleteAccess(
      BuildContext context, Map<String, dynamic> record) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Access', style: bodyStyle(weight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete this record? This action cannot be undone.',
            style: bodyStyle()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: bodyStyle(color: AppColors.ink3))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: bodyStyle(
                      color: AppColors.red, weight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      final orgCode = record['orgCode'] ?? record['orgcode'] ?? 50;
      final accessCd = record['accessCd'] ?? record['accesscd'] ?? 0;
      setState(() => _isLoading = true);
      final success = await apiService.deleteAccess(
          orgCode is int ? orgCode : 50, accessCd is int ? accessCd : 0);

      if (success) {
        showAmsSnack(context, 'Record deleted successfully', icon: '✅');
        setState(() {});
      } else {
        showAmsSnack(context, 'Failed to delete record', icon: '❌');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteModule(
      BuildContext context, Map<String, dynamic> record) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Module', style: bodyStyle(weight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete this module? This action cannot be undone.',
            style: bodyStyle()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: bodyStyle(color: AppColors.ink3))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: bodyStyle(
                      color: AppColors.red, weight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      final mid = (record['modCd'] ??
              record['module_id'] ??
              record['moduleid'] ??
              record['moduleId'] ??
              '')
          .toString();
      if (mid.isEmpty || mid == '—') {
        showAmsSnack(context, 'Invalid Module ID', icon: '⚠️');
        return;
      }
      setState(() => _isLoading = true);
      final success = await apiService.deleteModule(mid);
      if (success) {
        showAmsSnack(context, 'Module deleted successfully', icon: '✅');
        setState(() {});
      } else {
        showAmsSnack(context, 'Failed to delete module - check logs.',
            icon: '❌', type: 'e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteUser(
      BuildContext context, Map<String, dynamic> record) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete User', style: bodyStyle(weight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete this user? This action cannot be undone.',
            style: bodyStyle()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: bodyStyle(color: AppColors.ink3))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: bodyStyle(
                      color: AppColors.red, weight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      final orgCode = record['orgCode'] ?? record['orgcode'] ?? 50;
      final usersCd =
          (record['usersCd'] ?? record['userScd'] ?? record['USERSCD'] ?? '')
              .toString();
      setState(() => _isLoading = true);
      final success =
          await apiService.deleteUser(orgCode is int ? orgCode : 50, usersCd);

      if (success) {
        showAmsSnack(context, 'User deleted successfully', icon: '✅');
        setState(() {});
      } else {
        showAmsSnack(context, 'Failed to delete user', icon: '❌');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeleteAuth(
      BuildContext context, Map<String, dynamic> record) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Authorization',
            style: bodyStyle(weight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete this authorization configuration? This action cannot be undone.',
            style: bodyStyle()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: bodyStyle(color: AppColors.ink3))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: bodyStyle(
                      color: AppColors.red, weight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true) {
      final pgmId = (record['programId'] ?? record['id'] ?? '').toString();
      if (pgmId.isEmpty) {
        showAmsSnack(context, 'Invalid Program ID', icon: '⚠️');
        return;
      }
      setState(() => _isLoading = true);
      final success = await apiService.deleteAuthConfig(pgmId);
      if (success) {
        showAmsSnack(context, 'Authorization deleted successfully', icon: '✅');
        setState(() {});
      } else {
        showAmsSnack(
            context, 'Failed to delete authorization. Please check logs.',
            icon: '❌', type: 'e');
      }
      setState(() => _isLoading = false);
    }
  }

  void _doSubmit() async {
    if (_selProg == null) {
      showAmsSnack(context, 'Please select a program first.',
          icon: '⚠', type: 'w');
      return;
    }

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
      if (_selProg == 'ROLE-CRT') ...{
        'orgCode': 50,
        'viewAccess': 0,
        'authAccess': 0,
        'makerAccess': 0,
        'adminAccess': 0,
        'sysAdminAccess': 0,
      },
      ...(_viewRecord ?? {}),
      ..._dynamicData,
      'isUpdate': _isEditMode,
    };

    if (_selProg == null) return;

    final safeCfg = _cfg ??
        Auth101Config(
          id: _selProg ?? 'AUTHCTL',
          name: _selProg ?? 'Authorization Control',
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
    final isAuthCtrlScreenList = _selProg == 'AUTHCTL' && !_showForm;

    final isAnyList = isUserScreenList ||
        isRoleScreenList ||
        isUserRoleScreenList ||
        isModuleScreenList ||
        isAuthCtrlScreenList;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
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
                    HeaderBreadcrumb(
                        label: _cfg?.name ?? _selProg ?? 'Unknown'),
                ],
                onBack: [
                          'USR-CRT',
                          'USR-ROLE',
                          'ROLE-CRT',
                          'MOD-CRT',
                          'MENU-CRT',
                          'AUTHCTL'
                        ].contains(_selProg ?? '') &&
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
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (!isModuleScreenList && !isUserScreenList)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: AppColors.sidebar,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isAnyList
                                      ? '${_cfg?.name ?? _selProg ?? 'Unknown'} List'
                                      : '${_viewRecord != null ? (_isEditMode ? 'Edit' : 'View') : 'New'} ${_cfg?.name ?? _selProg ?? 'Record'}',
                                  style: bodyStyle(
                                    size: 14,
                                    color: Colors.white,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                if (_showForm)
                                  IconButton(
                                    icon: const Icon(
                                        Icons.keyboard_arrow_up_rounded,
                                        color: Colors.white),
                                    onPressed: () => setState(() {
                                      _showForm = false;
                                      _viewRecord = null;
                                    }),
                                  ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: () {
                            Future<void> handleView(
                                Map<String, dynamic> record) async {
                              if (widget.initialProg == 'MOD-CRT') {
                                final mid = (record['modCd'] ??
                                        record['module_id'] ??
                                        record['moduleid'] ??
                                        record['moduleId'] ??
                                        record['modcd'] ??
                                        '')
                                    .toString();
                                if (mid.isNotEmpty) {
                                  final subms =
                                      await apiService.getSubModules(mid);
                                  record['submodules'] = subms;
                                }
                              }
                              setState(() {
                                _viewRecord = record;
                                _isEditMode = false;
                                _showForm = true;
                              });
                            }

                            Future<void> handleEdit(
                                Map<String, dynamic> record) async {
                              if (widget.initialProg == 'MOD-CRT') {
                                final mid = (record['modCd'] ??
                                        record['module_id'] ??
                                        record['moduleid'] ??
                                        record['moduleId'] ??
                                        record['modcd'] ??
                                        '')
                                    .toString();
                                if (mid.isNotEmpty) {
                                  final subms =
                                      await apiService.getSubModules(mid);
                                  record['submodules'] = subms;
                                }
                              }
                              setState(() {
                                _viewRecord = record;
                                _isEditMode = true;
                                _showForm = true;
                              });
                            }

                            if (isUserScreenList) {
                              return _UserListView(
                                key: ValueKey('user_list_$_showForm'),
                                onView: handleView,
                                onEdit: handleEdit,
                                onDelete: (rec) =>
                                    _handleDeleteUser(context, rec),
                              );
                            }
                            if (isRoleScreenList) {
                              return _RoleListView(
                                key: ValueKey('role_list_$_showForm'),
                                onView: handleView,
                                onEdit: handleEdit,
                                onDelete: (rec) =>
                                    _handleDeleteAccess(context, rec),
                              );
                            }
                            if (isUserRoleScreenList) {
                              return _UserRoleListView(
                                key: ValueKey('user_role_list_$_showForm'),
                                onView: handleView,
                              );
                            }
                            if (isModuleScreenList) {
                              return _ModuleListView(
                                key: ValueKey('module_list_$_showForm'),
                                onView: handleView,
                                onEdit: handleEdit,
                                onDelete: (rec) =>
                                    _handleDeleteModule(context, rec),
                              );
                            }
                            if (isAuthCtrlScreenList) {
                              return _AuthCtrlListView(
                                key: ValueKey('auth_list_$_showForm'),
                                onView: handleView,
                                onEdit: handleEdit,
                                onDelete: (rec) =>
                                    _handleDeleteAuth(context, rec),
                              );
                            }

                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DynamicNTFields(
                                    key: _fieldsKey,
                                    prog: _selProg ?? 'AUTHCTL',
                                    initialData: _viewRecord,
                                    isViewMode:
                                        _viewRecord != null && !_isEditMode,
                                    onChanged: (key, val) =>
                                        _dynamicData[key] = val,
                                  ),
                                ],
                              ),
                            );
                          }(),
                        ),
                        if (!isAnyList)
                          AmsSubmitBar(
                            borderColor: AppColors.border,
                            actions: [
                              if (_viewRecord != null && !_isEditMode)
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
                                  label: _isEditMode
                                      ? 'Update'
                                      : (isDirectSave ? 'Save' : 'Submit'),
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
                                        _isEditMode = false;
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
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.tBlue),
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
// List Views
// ═══════════════════════════════════════════════════════════════════════════════

class _UserListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  final void Function(Map<String, dynamic>)? onEdit;
  final Future<void> Function(Map<String, dynamic>)? onDelete;
  const _UserListView({super.key, this.onView, this.onEdit, this.onDelete});

  @override
  State<_UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<_UserListView> {
  List<Map<String, dynamic>>? _users;
  int _totalItems = 0;
  bool _loading = true;
  String _searchQuery = '';

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

    final filteredItems = (_users ?? []).where((u) {
      if (_searchQuery.isEmpty) return true;
      final fName = (u['fName'] ?? u['fname'] ?? u['FNAME'] ?? '')
          .toString()
          .toLowerCase();
      final lName = (u['lName'] ?? u['lname'] ?? u['LNAME'] ?? '')
          .toString()
          .toLowerCase();
      final email = (u['email'] ?? u['EMAIL'] ?? u['emailid'] ?? '')
          .toString()
          .toLowerCase();
      final mobile =
          (u['mobile'] ?? u['MOBILE'] ?? '').toString().toLowerCase();
      final userCd = (u['userScd'] ?? u['usersCd'] ?? u['USERSCD'] ?? '')
          .toString()
          .toLowerCase();
      final query = _searchQuery.toLowerCase();
      return fName.contains(query) ||
          lName.contains(query) ||
          email.contains(query) ||
          mobile.contains(query) ||
          userCd.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: AmsTextInput(
                  placeholder: 'Search Users by Name, Email, or Mobile...',
                  icon: Icons.search_rounded,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () => _loadUsers(1),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.refresh_rounded,
                        size: 20, color: AppColors.ink2),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AmsPaginatedView<Map<String, dynamic>>(
            items: filteredItems.reversed.toList(),
            totalRecords: _totalItems,
            onPageChanged: _loadUsers,
            builder: (ctx, currentItems) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: currentItems.length,
              itemBuilder: (ctx, idx) {
                final u = currentItems[idx];
                final String fName =
                    u['fName'] ?? u['fname'] ?? u['FNAME'] ?? '';
                final String lName =
                    u['lName'] ?? u['lname'] ?? u['LNAME'] ?? '';
                final String email =
                    u['email'] ?? u['EMAIL'] ?? u['emailid'] ?? 'No Email';
                final String mobile = u['mobile'] ?? u['MOBILE'] ?? 'No Mobile';
                final String userCd =
                    u['userScd'] ?? u['usersCd'] ?? u['USERSCD'] ?? 'Unknown';
                final String initial = fName.isNotEmpty
                    ? fName[0].toUpperCase()
                    : (userCd.isNotEmpty && userCd != 'Unknown'
                        ? userCd[0].toUpperCase()
                        : 'U');

                return AmsCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.tBlueLt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                            child: Text(initial,
                                style: bodyStyle(
                                    weight: FontWeight.bold,
                                    color: AppColors.tBlue,
                                    size: 16))),
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
                                style: bodyStyle(
                                    size: 15, weight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('$email  |  $mobile',
                                style:
                                    bodyStyle(color: AppColors.ink3, size: 12)),
                          ],
                        ),
                      ),
                      if (u['status']?.toString() == '0' ||
                          u['status']?.toString() == '2' ||
                          u['status']?.toString() == '3')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Text('Raised for Edit',
                              style: bodyStyle(
                                  color: Colors.orange[800]!,
                                  size: 12,
                                  weight: FontWeight.w600)),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionButton(
                              icon: Icons.visibility_outlined,
                              color: Colors.green,
                              onTap: () => widget.onView?.call(u),
                            ),
                            const SizedBox(width: 8),
                            _ActionButton(
                              icon: Icons.edit_outlined,
                              color: AppColors.tBlue,
                              onTap: () => widget.onEdit?.call(u),
                            ),
                            const SizedBox(width: 8),
                            _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              color: Colors.red,
                              onTap: () async {
                                if (widget.onDelete != null) {
                                  await widget.onDelete!(u);
                                  _loadUsers(1);
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  final void Function(Map<String, dynamic>)? onEdit;
  final Future<void> Function(Map<String, dynamic>)? onDelete;
  const _RoleListView({super.key, this.onView, this.onEdit, this.onDelete});

  @override
  State<_RoleListView> createState() => _RoleListViewState();
}

class _RoleListViewState extends State<_RoleListView> {
  List<Map<String, dynamic>>? _roles;
  int _totalItems = 0;
  bool _loading = true;
  String _searchQuery = '';

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

    final filteredItems = (_roles ?? []).where((r) {
      if (_searchQuery.isEmpty) return true;
      final name =
          (r['accessName'] ?? r['accessname'] ?? '').toString().toLowerCase();
      final cd =
          (r['accessCd'] ?? r['accesscd'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          cd.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: AmsTextInput(
                  placeholder: 'Search Access Name or Code...',
                  icon: Icons.search_rounded,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () => _loadRoles(1),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.refresh_rounded,
                        size: 20, color: AppColors.ink2),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AmsPaginatedView<Map<String, dynamic>>(
            items: filteredItems.reversed.toList(),
            totalRecords: _totalItems,
            onPageChanged: _loadRoles,
            builder: (ctx, currentItems) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: currentItems.length,
              itemBuilder: (ctx, idx) {
                final r = currentItems[idx];
                final accessName = r['accessName'] ??
                    r['access_name'] ??
                    r['accessname'] ??
                    'Unnamed Access';
                final accessCd = r['accessCd'] ?? r['accesscd'] ?? '—';

                return AmsCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.tBlueLt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            accessName.toString().isNotEmpty
                                ? accessName.toString()[0].toUpperCase()
                                : 'R',
                            style: bodyStyle(
                                weight: FontWeight.bold,
                                color: AppColors.tBlue,
                                size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(accessName.toString(),
                                style: bodyStyle(
                                    size: 15, weight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'Type: ${r['accessType'] ?? r['accesstype'] ?? "—"}  |  Subtype: ${r['accessSubType'] ?? r['accesssubtype'] ?? "—"}',
                              style: bodyStyle(color: AppColors.ink3, size: 12),
                            ),
                          ],
                        ),
                      ),
                      AmsBadge(
                          label: accessCd.toString(),
                          background: AppColors.grayLt,
                          color: AppColors.ink2),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: Icons.visibility_outlined,
                            color: Colors.green,
                            onTap: () => widget.onView?.call(r),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.edit_outlined,
                            color: AppColors.tBlue,
                            onTap: () => widget.onEdit?.call(r),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.delete_outline_rounded,
                            color: Colors.red,
                            onTap: () async {
                              if (widget.onDelete != null) {
                                await widget.onDelete!(r);
                                _loadRoles(1);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _UserRoleListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  const _UserRoleListView({super.key, this.onView});
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
      items: (_data ?? []).reversed.toList(),
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
  final void Function(Map<String, dynamic>)? onEdit;
  final Future<void> Function(Map<String, dynamic>)? onDelete;
  const _ModuleListView({super.key, this.onView, this.onEdit, this.onDelete});

  @override
  State<_ModuleListView> createState() => _ModuleListViewState();
}

class _ModuleListViewState extends State<_ModuleListView> {
  List<Map<String, dynamic>>? _data;
  int _totalItems = 0;
  bool _loading = true;
  String _searchQuery = '';

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

    final filteredItems = (_data ?? []).where((d) {
      if (_searchQuery.isEmpty) return true;
      final name =
          (d['moduleName'] ?? d['modulename'] ?? '').toString().toLowerCase();
      final cd =
          (d['moduleCd'] ?? d['moduleid'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          cd.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: AmsTextInput(
                  placeholder: 'Search modules...',
                  icon: Icons.search_rounded,
                  borderColor: AppColors.tBlue,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () => _load(1),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.refresh_rounded,
                        size: 20, color: AppColors.ink2),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AmsPaginatedView<Map<String, dynamic>>(
            items: filteredItems.reversed.toList(),
            totalRecords: _totalItems,
            onPageChanged: _load,
            builder: (ctx, currentItems) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.tBlueLt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            moduleName.isNotEmpty
                                ? moduleName[0].toUpperCase()
                                : 'M',
                            style: bodyStyle(
                                weight: FontWeight.bold,
                                color: AppColors.tBlue,
                                size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(moduleName,
                                style: bodyStyle(
                                    size: 15, weight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                                'Module Code: $moduleCd  |  ORG: ${d['orgCode'] ?? d['orgcode'] ?? 50}',
                                style:
                                    bodyStyle(color: AppColors.ink3, size: 12)),
                          ],
                        ),
                      ),
                      AmsBadge(
                        label: (d['status']?.toString() == '0')
                            ? 'Disabled'
                            : 'Enabled',
                        background: (d['status']?.toString() == '0')
                            ? AppColors.grayLt
                            : AppColors.nTealLt,
                        color: (d['status']?.toString() == '0')
                            ? AppColors.ink3
                            : AppColors.nTeal,
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: Icons.visibility_outlined,
                            color: Colors.green,
                            onTap: () => widget.onView?.call(d),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.edit_outlined,
                            color: AppColors.tBlue,
                            onTap: () => widget.onEdit?.call(d),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.delete_outline_rounded,
                            color: Colors.red,
                            onTap: () async {
                              if (widget.onDelete != null) {
                                await widget.onDelete!(d);
                                _load(1);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthCtrlListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  final void Function(Map<String, dynamic>)? onEdit;
  final Future<void> Function(Map<String, dynamic>)? onDelete;
  const _AuthCtrlListView({super.key, this.onView, this.onEdit, this.onDelete});
  @override
  State<_AuthCtrlListView> createState() => _AuthCtrlListViewState();
}

class _AuthCtrlListViewState extends State<_AuthCtrlListView> {
  Map<String, Auth101Config>? _configs;
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await apiService.getAuthConfigs();
    if (mounted) {
      setState(() {
        _configs = data ?? auth101;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _configs == null) {
      return const AmsListSkeleton();
    }

    final cfgList = _configs!.values.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.id.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: AmsTextInput(
                  placeholder: 'Search Authorization configurations...',
                  icon: Icons.search_rounded,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: _load,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.refresh_rounded,
                        size: 20, color: AppColors.ink2),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AmsPaginatedView<Auth101Config>(
            items: cfgList.reversed.toList(),
            builder: (ctx, currentItems) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: currentItems.length,
              itemBuilder: (ctx, idx) {
                final c = currentItems[idx];
                final rec = c.toMap();
                return AmsCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name.toString(),
                                style: bodyStyle(
                                    size: 15, weight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                                'Approval Req: ${c.approvalReq ? 'Yes' : 'No'}  |  Levels: ${c.levels}',
                                style:
                                    bodyStyle(color: AppColors.ink3, size: 12)),
                          ],
                        ),
                      ),
                      AmsBadge(label: c.id.toString()),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: Icons.visibility_outlined,
                            color: Colors.green,
                            onTap: () => widget.onView?.call(rec),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.edit_outlined,
                            color: AppColors.tBlue,
                            onTap: () => widget.onEdit?.call(rec),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.delete_outline_rounded,
                            color: Colors.red,
                            onTap: () async {
                              if (widget.onDelete != null) {
                                await widget.onDelete!(rec);
                                _load();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BranchListView extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onView;
  const _BranchListView({this.onView});
  @override
  State<_BranchListView> createState() => _BranchListViewState();
}

class _BranchListViewState extends State<_BranchListView> {
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
    final result = await branchApiService.getBranches(page: page - 1, size: 10);
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
      items: (_data ?? []).reversed.toList(),
      totalRecords: _totalItems,
      onPageChanged: _load,
      builder: (ctx, currentItems) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: currentItems.length,
        itemBuilder: (ctx, idx) {
          final d = currentItems[idx];
          final String bName = d['branchName'] ??
              d['brnName'] ??
              d['brnname'] ??
              d['branchname'] ??
              'Unknown';
          final String bCd = (d['branchCd'] ??
                  d['brnCd'] ??
                  d['brncd'] ??
                  d['branchcd'] ??
                  '—')
              .toString();

          return AmsCard(
            onTap: widget.onView != null ? () => widget.onView!(d) : null,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: AppColors.nTealLt, shape: BoxShape.circle),
                  child: const Center(
                      child: Icon(Icons.store_rounded,
                          color: AppColors.nTeal, size: 20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bName,
                          style: bodyStyle(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Branch Code: $bCd',
                          style: bodyStyle(color: AppColors.ink3)),
                    ],
                  ),
                ),
                AmsBadge(
                  label:
                      (d['status']?.toString() == '0') ? 'Disabled' : 'Enabled',
                  color: (d['status']?.toString() == '0')
                      ? AppColors.red
                      : AppColors.green,
                  background: (d['status']?.toString() == '0')
                      ? AppColors.redLt
                      : AppColors.greenLt,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DynamicNTFields
// ═══════════════════════════════════════════════════════════════════════════════

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

  String _formatDisplayDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MMM-yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  // ── User form controllers ──────────────────────────────────────────────────
  final _uScdCtrl = TextEditingController();
  final _fNameCtrl = TextEditingController();
  final _lNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _uRegDateCtrl = TextEditingController();
  final _uDobCtrl = TextEditingController();
  final _uStatusCtrl = TextEditingController();
  final _uBranchCdCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _callCodeCtrl = TextEditingController();
  final _uPictureCtrl = TextEditingController();
  String? _gender;
  String? _menuType;
  String? _title;
  bool _approvalReq = true;
  bool _preApprovalReq = false;
  bool _postApprovalReq = false;
  bool _isTran = false;
  List<Map<String, dynamic>> _authLevels = [];

  final _rScdCtrl = TextEditingController();
  final _rNameCtrl = TextEditingController();
  final _rTypeCtrl = TextEditingController();
  final _rSubtypeCtrl = TextEditingController();

  final _mScdCtrl = TextEditingController();
  final _mNameCtrl = TextEditingController();
  bool _subModuleEnabled = false;
  List<Map<String, dynamic>> _subModules = [];

  final _menuScdCtrl = TextEditingController();
  final _menuNameCtrl = TextEditingController();
  final _orgCodeCtrl = TextEditingController();

  final _authModCtrl = TextEditingController();
  final _authPgmCtrl = TextEditingController();
  int _mStatus = 1;

  List<Map<String, dynamic>> _userList = [];
  List<Map<String, dynamic>> _roleList = [];
  List<Map<String, dynamic>> _moduleList = [];

  // ── Branch dropdown ────────────────────────────────────────────────────────
  // _branchList holds ALL branches fetched from API (unfiltered)
  List<Map<String, dynamic>> _branchList = [];
  bool _loadingBranches = false;

  // ── Org searchable overlay dropdown ───────────────────────────────────────
  final _orgDisplayCtrl = TextEditingController();
  final _orgSearchCtrl = TextEditingController();
  final _orgLayerLink = LayerLink();
  OverlayEntry? _orgOverlay;
  List<Map<String, dynamic>> _orgList = [];
  bool _orgLoading = false;
  int? _selectedOrgCode;
  // ──────────────────────────────────────────────────────────────────────────

  String? _selModule;
  String? _selSubModule;
  bool _loadingDropdowns = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // ── Filtered branches: only those matching selected org code ───────────────
  List<Map<String, dynamic>> get _filteredBranchList {
    if (_selectedOrgCode == null) return _branchList;
    return _branchList.where((b) {
      final branchOrg =
          (b['orgCode'] ?? b['orgcode'] ?? b['org_code'] ?? '').toString();
      return branchOrg == _selectedOrgCode.toString();
    }).toList();
  }
  // ──────────────────────────────────────────────────────────────────────────

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void didUpdateWidget(DynamicNTFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prog != widget.prog ||
        oldWidget.initialData != widget.initialData) {
      _loadInitialData();
      _notifyDefaults();
      if (widget.prog == 'USR-ROLE' || widget.prog == 'AUTHCTL') {
        _fetchDropdownData();
      }
      if (widget.prog == 'USR-CRT') {
        _fetchBranches();
        _fetchOrgData();
      }
      if (widget.prog == 'ROLE-CRT' ||
          widget.prog == 'MOD-CRT' ||
          widget.prog == 'AUTHCTL') {
        _fetchOrgData();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _notifyDefaults();
    if (widget.prog == 'USR-ROLE' || widget.prog == 'AUTHCTL') {
      _fetchDropdownData();
    }
    if (widget.prog == 'USR-CRT') {
      _fetchBranches();
      _fetchOrgData();
    }
    if (widget.prog == 'ROLE-CRT' ||
        widget.prog == 'MOD-CRT' ||
        widget.prog == 'AUTHCTL') {
      _fetchOrgData();
    }
  }

  void _notifyDefaults() {
    if (widget.initialData != null) return;
    final prog = widget.prog.replaceAll(' ', '-').toUpperCase();
    if (prog == 'AUTHCTL') {
      widget.onChanged('approvalReq', _approvalReq ? 1 : 0);
      widget.onChanged('preApproveProc', _preApprovalReq ? 1 : 0);
      widget.onChanged('postApproveProc', _postApprovalReq ? 1 : 0);
      widget.onChanged('isTranPgm', _isTran ? 1 : 0);
      widget.onChanged('authLevels', _authLevels);
      widget.onChanged('orgCode', 50);
    } else if (prog == 'MOD-CRT') {
      widget.onChanged('orgCode', 50);
      widget.onChanged('status', _mStatus);
      widget.onChanged('subModule', _subModuleEnabled ? 1 : 0);
      widget.onChanged('subModules', _subModules);
    } else if (prog == 'USR-CRT') {
      widget.onChanged('orgCode', 50);
      widget.onChanged('status', 1);
    } else if (prog == 'ROLE-CRT') {
      widget.onChanged('orgCode', 50);
    }
  }

  Future<void> _fetchDropdownData() async {
    setState(() => _loadingDropdowns = true);
    final usersRaw = await apiService.getUsers(size: 100);
    final rolesRaw = await apiService.getRoles(size: 100);
    final modulesRaw = await apiService.getModules(size: 100);
    if (mounted) {
      setState(() {
        _userList = usersRaw?.items ?? [];
        _roleList = rolesRaw?.items ?? [];
        _moduleList = modulesRaw?.items ?? [];
        _loadingDropdowns = false;
      });
    }
  }

  // ── Fetch ALL branches (no org filter at API level) ────────────────────────
  // Filtering is done client-side via _filteredBranchList getter
  Future<void> _fetchBranches() async {
    setState(() => _loadingBranches = true);
    final result = await branchApiService.getBranches(size: 1000);
    if (mounted) {
      setState(() {
        _branchList = result?.items ?? [];
        _loadingBranches = false;
      });
    }
  }
  // ──────────────────────────────────────────────────────────────────────────

  // ── Org fetch ──────────────────────────────────────────────────────────────

  Future<void> _fetchOrgData() async {
    if (_orgLoading || _orgList.isNotEmpty) return;
    setState(() => _orgLoading = true);
    try {
      final res = await orgApiService.getAllOrganisations(page: 0, size: 200);
      if (res != null && mounted) {
        setState(() => _orgList = res.items);
        _resolveOrgDisplay();
      }
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _orgLoading = false);
    }
  }

  void _resolveOrgDisplay() {
    if (_selectedOrgCode == null) return;
    final match = _orgList.firstWhere(
      (o) =>
          (o['orgcode'] ?? o['orgCode'] ?? '').toString() ==
          _selectedOrgCode.toString(),
      orElse: () => {},
    );
    final name = (match['name'] ?? '').toString();
    if (mounted) {
      setState(() {
        _orgDisplayCtrl.text = name.isNotEmpty
            ? '$_selectedOrgCode – $name'
            : _selectedOrgCode.toString();
        if (_orgCodeCtrl.text.isEmpty) {
          _orgCodeCtrl.text = _selectedOrgCode.toString();
        }
      });
    }
  }

  // ── Org overlay dropdown ───────────────────────────────────────────────────

  void _openOrgDropdown() {
    if (widget.isViewMode) return;
    _orgOverlay?.remove();
    _orgOverlay = null;
    _orgSearchCtrl.clear();

    _orgOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
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
                  onTap: () {},
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
                          final name =
                              (o['name'] ?? '').toString().toLowerCase();
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
                                                size: 16,
                                                color: AppColors.ink3),
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
                                            child: Text(
                                              'No organisations found',
                                              style: bodyStyle(
                                                  color: AppColors.ink4),
                                            ),
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
                                              final name = (org['name'] ?? '')
                                                  .toString();
                                              final isSelected =
                                                  _selectedOrgCode
                                                          ?.toString() ==
                                                      code;

                                              return InkWell(
                                                onTap: () {
                                                  _selectOrg(org);
                                                  _orgSearchCtrl.clear();
                                                  _orgOverlay?.remove();
                                                  _orgOverlay = null;
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
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
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isSelected
                                                              ? AppColors.tBlue
                                                              : AppColors
                                                                  .tBlueLt,
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
                                                                : AppColors
                                                                    .tBlue,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          style: bodyStyle(
                                                              size: 13),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        const Icon(
                                                            Icons.check_rounded,
                                                            size: 16,
                                                            color: AppColors
                                                                .tBlue),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                              ),
                              if (!_orgLoading && _orgList.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.bg,
                                    border: Border(
                                        top: BorderSide(
                                            color: AppColors.border,
                                            width: 0.5)),
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
                                            fontSize: 11,
                                            color: AppColors.ink3),
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
        );
      },
    );
    Overlay.of(context).insert(_orgOverlay!);
  }

  // ── UPDATED: _selectOrg now resets branch selection ────────────────────────
  void _selectOrg(Map<String, dynamic> org) {
    final code = (org['orgcode'] ?? org['orgCode'] ?? '').toString();
    final name = (org['name'] ?? '').toString();
    setState(() {
      _selectedOrgCode = int.tryParse(code);
      _orgDisplayCtrl.text = name.isNotEmpty ? '$code – $name' : code;
      _orgCodeCtrl.text = code;
      _errors['orgCode'] = null;
      // ── Reset branch when org changes ─────────────────────────────────────
      _uBranchCdCtrl.clear();
    });
    widget.onChanged('orgCode', int.tryParse(code) ?? 0);
    // ── Notify parent that branch is cleared ──────────────────────────────
    widget.onChanged('branchCd', '');
  }
  // ──────────────────────────────────────────────────────────────────────────

  // ── Load initial data ──────────────────────────────────────────────────────

  void _loadInitialData() {
    if (widget.initialData == null) {
      if (widget.prog == 'AUTHCTL') {
        _approvalReq = true;
        _preApprovalReq = false;
        _postApprovalReq = false;
        _isTran = false;
      } else if (widget.prog == 'MOD-CRT') {
        _subModuleEnabled = false;
        _subModules = [];
        _mStatus = 1;
      }
      return;
    }

    final data =
        widget.initialData?.map((k, v) => MapEntry(k.toLowerCase(), v)) ?? {};
    final prog = (widget.prog).replaceAll(' ', '-').toUpperCase();

    if (prog == 'USR-CRT') {
      final orgCodeRaw =
          (data['orgcode'] ?? data['orgCode'] ?? '50').toString();
      _selectedOrgCode = int.tryParse(orgCodeRaw);
      if (_orgList.isNotEmpty && _selectedOrgCode != null) {
        final match = _orgList.firstWhere(
          (o) => (o['orgcode'] ?? o['orgCode'] ?? '').toString() == orgCodeRaw,
          orElse: () => {},
        );
        final orgName = (match['name'] ?? '').toString();
        _orgDisplayCtrl.text =
            orgName.isNotEmpty ? '$orgCodeRaw – $orgName' : orgCodeRaw;
      } else {
        _orgDisplayCtrl.text = orgCodeRaw;
      }

      _uScdCtrl.text = (data['userscd'] ?? data['usercd'] ?? '').toString();
      _fNameCtrl.text = (data['fname'] ?? data['firstname'] ?? '').toString();
      _lNameCtrl.text = (data['lname'] ?? data['lastname'] ?? '').toString();
      _uRegDateCtrl.text = _formatDisplayDate((data['regdate'] ??
              data['reg_date'] ??
              data['registrationdate'] ??
              '')
          .toString());
      _uDobCtrl.text = _formatDisplayDate(
          (data['dob'] ?? data['dateofbirth'] ?? '').toString());
      _uStatusCtrl.text = (data['status'] ?? '').toString();

      _uBranchCdCtrl.text =
          (data['branchcd'] ?? data['branchcode'] ?? data['branch_cd'] ?? '')
              .toString();

      _uPictureCtrl.text =
          (data['picture'] ?? data['profilepicture'] ?? data['pic'] ?? '')
              .toString();

      _emailCtrl.text =
          (data['email'] ?? data['emailid'] ?? data['email_id'] ?? '')
              .toString();

      final rawCountry = (data['country'] ?? '').toString();
      if (rawCountry.isNotEmpty) {
        if (_kAllCountries.containsKey(rawCountry)) {
          _countryCtrl.text = rawCountry;
        } else {
          final revMap = <String, String>{};
          _kAllCountries.forEach((name, code) => revMap[code] = name);
          if (revMap.containsKey(rawCountry)) {
            _countryCtrl.text = revMap[rawCountry]!;
          } else {
            _countryCtrl.text = rawCountry;
          }
        }
      } else {
        _countryCtrl.text = '';
      }

      _mobileCtrl.text =
          (data['mobile'] ?? data['mobileno'] ?? data['phone'] ?? '')
              .toString();
      _callCodeCtrl.text =
          (data['callcode'] ?? data['call_code'] ?? data['callingcode'] ?? '')
              .toString();

      final g = (data['gender'] ?? '').toString().toUpperCase();
      if (g == 'F' || g == 'FEMALE') {
        _gender = 'Female';
      } else if (g == 'O' || g == 'OTHER') {
        _gender = 'Other';
      } else if (g == 'M' || g == 'MALE') {
        _gender = 'Male';
      } else {
        _gender = null;
      }

      _title = (data['title'] ?? '').toString().isNotEmpty
          ? data['title'].toString()
          : null;
    } else if (prog == 'ROLE-CRT') {
      final orgCodeRaw =
          (data['orgcode'] ?? data['orgCode'] ?? '50').toString();
      _selectedOrgCode = int.tryParse(orgCodeRaw);
      if (_orgList.isNotEmpty && _selectedOrgCode != null) {
        final match = _orgList.firstWhere(
          (o) => (o['orgcode'] ?? o['orgCode'] ?? '').toString() == orgCodeRaw,
          orElse: () => {},
        );
        final orgName = (match['name'] ?? '').toString();
        _orgDisplayCtrl.text =
            orgName.isNotEmpty ? '$orgCodeRaw – $orgName' : orgCodeRaw;
      } else {
        _orgDisplayCtrl.text = orgCodeRaw;
      }

      _rScdCtrl.text =
          (data['accesscd'] ?? data['access_cd'] ?? data['rolecd'] ?? '')
              .toString();
      _rNameCtrl.text =
          (data['accessname'] ?? data['access_name'] ?? data['rolename'] ?? '')
              .toString();
      _rTypeCtrl.text =
          (data['accesstype'] ?? data['access_type'] ?? '').toString();
      _rSubtypeCtrl.text =
          (data['accesssubtype'] ?? data['access_sub_type'] ?? '').toString();
    } else if (prog == 'MOD-CRT') {
      final orgCodeRaw = (data['orgcode'] ?? '50').toString();
      _orgCodeCtrl.text = orgCodeRaw;
      _selectedOrgCode = int.tryParse(orgCodeRaw);
      if (_orgList.isNotEmpty && _selectedOrgCode != null) {
        final match = _orgList.firstWhere(
          (o) => (o['orgcode'] ?? o['orgCode'] ?? '').toString() == orgCodeRaw,
          orElse: () => {},
        );
        final orgName = (match['name'] ?? '').toString();
        _orgDisplayCtrl.text =
            orgName.isNotEmpty ? '$orgCodeRaw – $orgName' : orgCodeRaw;
      } else {
        _orgDisplayCtrl.text = orgCodeRaw;
      }
      _mScdCtrl.text = (data['modcd'] ??
              data['module_id'] ??
              data['moduleid'] ??
              data['modulecode'] ??
              '')
          .toString();
      _mNameCtrl.text =
          (data['modname'] ?? data['modulename'] ?? data['module_name'] ?? '')
              .toString();
      _mStatus = int.tryParse((data['status'] ?? '1').toString()) ?? 1;

      final sm = data['sub_module'] ?? data['submodule'];
      _subModuleEnabled = sm == 1 || sm == true || sm == '1';

      var smData = data['submodules'] ??
          data['submodulelist'] ??
          data['sub_module_list'];
      if (smData is String && smData.isNotEmpty) {
        try {
          smData = jsonDecode(smData);
        } catch (e) {
          print('Error decoding submodules: $e');
        }
      }
      if (smData is List) {
        _subModules = List<Map<String, dynamic>>.from(smData);
      } else {
        _subModules = [];
      }
    } else if (prog == 'MENU-CRT') {
      _menuScdCtrl.text = (data['menucd'] ?? data['menu_cd'] ?? '').toString();
      _menuNameCtrl.text =
          (data['menuname'] ?? data['menu_name'] ?? '').toString();
    } else if (prog == 'AUTHCTL') {
      final orgCodeRaw =
          (data['orgcode'] ?? data['org_code'] ?? '50').toString();
      _orgCodeCtrl.text = orgCodeRaw;
      _selectedOrgCode = int.tryParse(orgCodeRaw);
      if (_orgList.isNotEmpty && _selectedOrgCode != null) {
        final match = _orgList.firstWhere(
          (o) => (o['orgcode'] ?? o['orgCode'] ?? '').toString() == orgCodeRaw,
          orElse: () => {},
        );
        final orgName = (match['name'] ?? '').toString();
        _orgDisplayCtrl.text =
            orgName.isNotEmpty ? '$orgCodeRaw – $orgName' : orgCodeRaw;
      } else {
        _orgDisplayCtrl.text = orgCodeRaw;
      }
      _authModCtrl.text =
          (data['modcd'] ?? data['moduleid'] ?? data['module_id'] ?? '')
              .toString();
      _authPgmCtrl.text =
          (data['programid'] ?? data['program_id'] ?? data['pgmcd'] ?? '')
              .toString();

      bool parseBool(String key) {
        final variants = [
          key.toLowerCase(),
          key.replaceAllMapped(
              RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}'),
        ];
        for (final k in variants) {
          final val = data[k];
          if (val == true || val == 1 || val == '1') return true;
        }
        return false;
      }

      _approvalReq = parseBool('approvalReq');
      _preApprovalReq = parseBool('preApproveProc');
      _postApprovalReq = parseBool('postApproveProc');
      _isTran = parseBool('isTranPgm') || parseBool('isTran');

      if (data['authlevels'] is List) {
        _authLevels = List<Map<String, dynamic>>.from(data['authlevels']);
      } else if (data['levels_grid'] is List) {
        _authLevels = List<Map<String, dynamic>>.from(data['levels_grid']);
      } else if (data['datablock'] is List) {
        _authLevels = List<Map<String, dynamic>>.from(data['datablock']);
      }
    } else if (prog == 'USR-ROLE') {
      _uScdCtrl.text =
          (data['userscd'] ?? data['users_cd'] ?? data['usercd'] ?? '')
              .toString();
      _rScdCtrl.text = (data['rolecd'] ?? data['role_cd'] ?? '').toString();
    }
    if (mounted) setState(() {});
  }

  // ── Validate ───────────────────────────────────────────────────────────────

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
        if (_uRegDateCtrl.text.trim().isEmpty) {
          _errors['regdate'] = 'Registration Date required';
          isValid = false;
        }
        if (_uDobCtrl.text.trim().isEmpty) {
          _errors['dob'] = 'DOB required';
          isValid = false;
        }
        if (_gender == null) {
          _errors['gender'] = 'Gender required';
          isValid = false;
        }
        if (_emailCtrl.text.trim().isEmpty) {
          _errors['emailid'] = 'Email Id required';
          isValid = false;
        } else if (!_isValidEmail(_emailCtrl.text.trim())) {
          _errors['emailid'] = 'Invalid email format';
          isValid = false;
        }
        if (_mobileCtrl.text.trim().isNotEmpty) {
          final mobileStr = _mobileCtrl.text.trim();
          final callCodeStr = _callCodeCtrl.text.trim();
          if (callCodeStr.isNotEmpty) {
            try {
              final phone = PhoneNumber.parse('+$callCodeStr$mobileStr');
              if (!phone.isValid()) {
                _errors['mobile'] = 'Invalid mobile number for selected country';
                isValid = false;
              }
            } catch (e) {
              _errors['mobile'] = 'Invalid mobile number format';
              isValid = false;
            }
          } else {
            if (mobileStr.length < 5) {
               _errors['mobile'] = 'Invalid mobile number length';
               isValid = false;
            }
          }
        }
      } else if (prog == 'ROLE-CRT') {
        if (_rScdCtrl.text.trim().isEmpty) {
          _errors['accessCd'] = 'Access Code required';
          isValid = false;
        }
        if (_rNameCtrl.text.trim().isEmpty) {
          _errors['accessName'] = 'Access Name required';
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
        if (_subModuleEnabled && _subModules.isEmpty) {
          _errors['subModules'] =
              'At least one sub-module is required when enabled';
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
        if (_orgCodeCtrl.text.trim().isEmpty) {
          _errors['orgCode'] = 'Organization Code required';
          isValid = false;
        }
        if (_authPgmCtrl.text.trim().isEmpty) {
          _errors['authPgm'] = 'Program Id required';
          isValid = false;
        }
      }

      if (!isValid) {
        showAmsSnack(
          context,
          'Please fill all mandatory fields correctly.',
          icon: '⚠',
          type: 'w',
        );
      }
    });
    return isValid;
  }

  // ── Clear ──────────────────────────────────────────────────────────────────

  void clearFields() {
    _uScdCtrl.clear();
    _fNameCtrl.clear();
    _lNameCtrl.clear();
    _uRegDateCtrl.clear();
    _uDobCtrl.clear();
    _uStatusCtrl.clear();
    _uBranchCdCtrl.clear();
    _uPictureCtrl.clear();
    _rScdCtrl.clear();
    _rNameCtrl.clear();
    _mScdCtrl.clear();
    _mNameCtrl.clear();
    _menuScdCtrl.clear();
    _menuNameCtrl.clear();
    _authModCtrl.clear();
    _authPgmCtrl.clear();
    _orgDisplayCtrl.clear();
    _orgSearchCtrl.clear();
    _selectedOrgCode = null;
    setState(() {
      _gender = null;
      _menuType = null;
      _title = null;
      _selModule = null;
      _selSubModule = null;
      _errors.clear();
    });
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _orgOverlay?.remove();
    _orgDisplayCtrl.dispose();
    _orgSearchCtrl.dispose();
    _uScdCtrl.dispose();
    _fNameCtrl.dispose();
    _lNameCtrl.dispose();
    _uRegDateCtrl.dispose();
    _uDobCtrl.dispose();
    _uStatusCtrl.dispose();
    _uBranchCdCtrl.dispose();
    _uPictureCtrl.dispose();
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
    _orgCodeCtrl.dispose();
    _mobileCtrl.dispose();
    _callCodeCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
              // ── ORGANISATION CODE ─────────────────────────────────────────
              AmsField(
                label: 'Organisation Code',
                labelAbove: true,
                tooltip: 'Select the parent organisation.',
                child: CompositedTransformTarget(
                  link: _orgLayerLink,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.isViewMode ? null : _openOrgDropdown,
                    child: AbsorbPointer(
                      child: AmsTextInput(
                        controller: _orgDisplayCtrl,
                        readOnly: true,
                        placeholder: _orgLoading
                            ? 'Loading organisations…'
                            : 'Select Organisation',
                        icon: _orgLoading
                            ? Icons.hourglass_empty_rounded
                            : Icons.business_rounded,
                      ),
                    ),
                  ),
                ),
              ),

              // ── BRANCH CODE – filtered by selected org ────────────────────
              AmsField(
                label: 'Branch Code',
                labelAbove: true,
                tooltip: 'Associated branch code for the user.',
                child: widget.isViewMode
                    ? AmsTextInput(
                        controller: _uBranchCdCtrl,
                        readOnly: true,
                        placeholder: 'Branch CD',
                      )
                    : _loadingBranches
                        ? const LinearProgressIndicator()
                        : AmsDropdown(
                            // ── KEY: use filtered list based on selected org ─
                            key: ValueKey('branch_${_selectedOrgCode}'),
                            initialValue: () {
                              if (_filteredBranchList.isEmpty) return null;
                              final seek = _uBranchCdCtrl.text;
                              if (seek.isEmpty) return null;
                              final matches = _filteredBranchList.where((b) =>
                                  (b['brnCd'] ??
                                          b['branchcd'] ??
                                          b['brncd'] ??
                                          '')
                                      .toString() ==
                                  seek);
                              if (matches.isEmpty) return null;
                              final b = matches.first;
                              return '${b['brnCd'] ?? b['branchcd'] ?? ''} - ${b['brnName'] ?? b['branchname'] ?? ''}';
                            }(),
                            placeholder: _selectedOrgCode == null
                                ? 'Select Organisation first'
                                : _filteredBranchList.isEmpty
                                    ? 'No branches for this org'
                                    : 'Select Branch',
                            items: _filteredBranchList
                                .map((b) {
                                  final cd = b['brnCd'] ??
                                      b['branchcd'] ??
                                      b['brncd'] ??
                                      '';
                                  final name = b['brnName'] ??
                                      b['branchname'] ??
                                      b['brnname'] ??
                                      '';
                                  return '$cd - $name';
                                })
                                .toSet()
                                .toList(),
                            onChanged: (v) {
                              final parts = v?.split(' - ') ?? [];
                              final val = parts.isNotEmpty ? parts[0] : '';
                              setState(() => _uBranchCdCtrl.text = val);
                              widget.onChanged(
                                  'branchCd', int.tryParse(val) ?? val);
                            },
                          ),
              ),
              // ─────────────────────────────────────────────────────────────

              AmsField(
                label: 'UserCD',
                required: true,
                labelAbove: true,
                tooltip: 'Unique identification code for the user.',
                child: AmsTextInput(
                  controller: _uScdCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'User Code (e.g. USR001)',
                  textInputAction: TextInputAction.next,
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
                label: 'Full Name',
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
                              placeholder: 'Title',
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
                              placeholder: 'Title',
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
                        placeholder: 'First Name',
                        textInputAction: TextInputAction.next,
                        errorText: _errors['fName'],
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
                        initialValue: data['mname']?.toString() ??
                            data['mName']?.toString(),
                        placeholder: 'Middle Name',
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
                        placeholder: 'Last Name',
                        textInputAction: TextInputAction.next,
                        errorText: _errors['lName'],
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
                label: 'Email Id',
                required: true,
                labelAbove: true,
                tooltip: 'Official email address for communication.',
                child: AmsTextInput(
                  controller: _emailCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. john@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: _errors['emailid'],
                  onChanged: (v) {
                    setState(() {
                      if (v.trim().isEmpty) {
                        _errors['emailid'] = 'Email Id required';
                      } else if (!_isValidEmail(v)) {
                        _errors['emailid'] = 'Invalid email format';
                      } else {
                        _errors['emailid'] = null;
                      }
                    });
                    widget.onChanged('emailid', v);
                  },
                ),
              ),
              AmsField(
                label: 'Gender',
                required: true,
                labelAbove: true,
                tooltip: 'The user\'s gender for profile identification.',
                child: widget.isViewMode
                    ? AmsTextInput(
                        initialValue: _gender,
                        readOnly: true,
                      )
                    : AmsDropdown(
                        initialValue: _gender,
                        placeholder: 'Select Gender',
                        items: const ['Male', 'Female', 'Other'],
                        errorText: _errors['gender'],
                        onChanged: (v) {
                          setState(() {
                            _gender = v;
                            _errors['gender'] = null;
                          });
                          String mapped = 'M';
                          if (v == 'Female')
                            mapped = 'F';
                          else if (v == 'Other') mapped = 'O';
                          widget.onChanged('gender', mapped);
                        },
                      ),
              ),
              AmsField(
                label: 'Date Of Birth',
                required: true,
                labelAbove: true,
                tooltip: 'The user\'s date of birth.',
                child: AmsTextInput(
                  controller: _uDobCtrl,
                  readOnly: true,
                  icon: Icons.cake_rounded,
                  placeholder: 'Select Date',
                  errorText: _errors['dob'],
                  onTap: () async {
                    if (widget.isViewMode) return;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.now().subtract(const Duration(days: 6570)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      final displayFmt =
                          DateFormat('dd-MMM-yyyy').format(picked);
                      final isoFmt = DateFormat('yyyy-MM-dd').format(picked);
                      setState(() {
                        _uDobCtrl.text = displayFmt;
                        _errors['dob'] = null;
                      });
                      widget.onChanged('dob', isoFmt);
                    }
                  },
                ),
              ),
              AmsField(
                label: 'Country',
                labelAbove: true,
                tooltip: 'Select Country.',
                child: widget.isViewMode
                    ? AmsTextInput(
                        controller: _countryCtrl,
                        readOnly: true,
                      )
                    : AmsSearchableDropdown(
                        initialValue: _countryCtrl.text.isNotEmpty
                            ? _countryCtrl.text
                            : null,
                        placeholder: 'Select Country',
                        items: _kAllCountries.keys.toList(),
                        onChanged: (v) {
                          if (v == null || v.isEmpty) {
                            setState(() {
                               _countryCtrl.text = '';
                               _callCodeCtrl.text = '';
                            });
                            widget.onChanged('country', 0);
                            widget.onChanged('callCode', 0);
                            return;
                          }
                          final code = _kAllCountries[v] ?? '';
                          setState(() {
                            _countryCtrl.text = v;
                            _callCodeCtrl.text = code;
                          });
                          widget.onChanged('country', int.tryParse(code) ?? 0);
                          widget.onChanged('callCode', int.tryParse(code) ?? 0);
                        },
                      ),
              ),
              AmsField(
                label: 'Mobile Number',
                labelAbove: true,
                tooltip: 'Primary mobile number for contact.',
                child: AmsTextInput(
                  controller: _mobileCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. 9876543210',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  errorText: _errors['mobile'],
                  onChanged: (v) {
                    setState(() {
                      if (_errors['mobile'] != null) {
                        _errors.remove('mobile');
                      }
                    });
                    widget.onChanged('mobile', v);
                  },
                ),
              ),
              AmsField(
                label: 'Registration Date',
                required: true,
                labelAbove: true,
                tooltip: 'Date when the user was registered.',
                child: AmsTextInput(
                  controller: _uRegDateCtrl,
                  readOnly: true,
                  icon: Icons.calendar_today_rounded,
                  placeholder: 'Select Date',
                  errorText: _errors['regdate'],
                  onTap: () async {
                    if (widget.isViewMode) return;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      final displayFmt =
                          DateFormat('dd-MMM-yyyy').format(picked);
                      final isoFmt = DateFormat('yyyy-MM-dd').format(picked);
                      setState(() {
                        _uRegDateCtrl.text = displayFmt;
                        _errors['regdate'] = null;
                      });
                      widget.onChanged('regDate', isoFmt);
                    }
                  },
                ),
              ),
              AmsField(
                label: 'Call Code',
                labelAbove: true,
                tooltip: 'International calling code (e.g. 91).',
                child: AmsTextInput(
                  controller: _callCodeCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. 91',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  onChanged: (v) =>
                      widget.onChanged('callCode', int.tryParse(v) ?? 0),
                ),
              ),
              AmsField(
                label: 'Status',
                labelAbove: true,
                tooltip: 'Current status (1: Active, 0: Inactive).',
                child: StatefulBuilder(
                  builder: (context, setFieldState) {
                    final bool isActive =
                        _uStatusCtrl.text.isEmpty || _uStatusCtrl.text == '1';
                    return Container(
                      height: 44,
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: widget.isViewMode
                            ? null
                            : () {
                                setFieldState(() {
                                  _uStatusCtrl.text = isActive ? '0' : '1';
                                });
                                widget.onChanged('status', isActive ? 0 : 1);
                              },
                        child: MouseRegion(
                          cursor: widget.isViewMode
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            width: 64,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: isActive
                                  ? AppColors.tBlue
                                  : const Color(0xFFE2E8F0),
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: isActive
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                    child: Text(
                                      isActive ? 'Yes' : 'No',
                                      style: bodyStyle(
                                        size: 11,
                                        color: isActive
                                            ? Colors.white
                                            : AppColors.ink3,
                                        weight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedAlign(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  alignment: isActive
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Container(
                                      width: 22,
                                      height: 22,
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              AmsField(
                label: 'Picture',
                labelAbove: true,
                tooltip: 'User profile picture reference or URL.',
                child: widget.isViewMode
                    ? AmsTextInput(
                        controller: _uPictureCtrl,
                        readOnly: true,
                      )
                    : AmsFilePicker(
                  initialValue:
                      _uPictureCtrl.text.isNotEmpty ? _uPictureCtrl.text : null,
                  onFileSelected: (name, bytes) async {
                    if (bytes != null) {
                      final userscd = _uScdCtrl.text.trim();
                      if (userscd.isEmpty) {
                        showAmsSnack(context, 'Please enter User Code first to upload picture.', type: 'e');
                        return;
                      }
                      
                      showAmsSnack(context, 'Uploading picture...', type: 'i');
                      final url = await apiService.uploadUserPicture(userscd, name, bytes);
                      
                      if (url != null) {
                        setState(() {
                          _uPictureCtrl.text = url;
                        });
                        widget.onChanged('picture', url);
                        showAmsSnack(context, 'Picture uploaded successfully!', type: 's');
                      } else {
                        showAmsSnack(context, 'Failed to upload picture.', type: 'e');
                      }
                    } else {
                      setState(() {
                        _uPictureCtrl.text = name;
                      });
                      widget.onChanged('picture', name);
                    }
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
                child: widget.isViewMode
                    ? AmsTextInput(
                        controller: _uScdCtrl,
                        readOnly: true,
                      )
                    : _loadingDropdowns
                        ? const LinearProgressIndicator()
                        : AmsDropdown(
                            initialValue: () {
                              if (_userList.isEmpty) return null;
                              final seek = _uScdCtrl.text.isNotEmpty
                                  ? _uScdCtrl.text
                                  : (data['userscd']?.toString() ??
                                      data['users_cd']?.toString() ??
                                      data['usercd']?.toString() ??
                                      '');
                              if (seek.isEmpty) return null;
                              final matches = _userList.where((u) =>
                                  (u['usersCd'] ??
                                      u['userScd'] ??
                                      u['USERSCD'] ??
                                      '') ==
                                  seek);
                              if (matches.isEmpty) return null;
                              final u = matches.first;
                              return '${u['usersCd'] ?? u['userScd'] ?? u['USERSCD'] ?? ''} - ${u['fName'] ?? u['fname'] ?? ''}';
                            }(),
                            placeholder: 'Select USERSCD',
                            items: _userList
                                .map((u) {
                                  final scd = u['usersCd'] ??
                                      u['userScd'] ??
                                      u['USERSCD'] ??
                                      '';
                                  final name = u['fName'] ?? u['fname'] ?? '';
                                  return '$scd - $name';
                                })
                                .toSet()
                                .toList(),
                            errorText: _errors['usersCd'],
                            isValid: _errors['usersCd'] == null &&
                                _uScdCtrl.text.isNotEmpty,
                            onChanged: (v) {
                              final parts = v?.split(' - ') ?? [];
                              final val = parts.isNotEmpty ? parts[0] : '';
                              setState(() {
                                _uScdCtrl.text = val;
                                _errors['usersCd'] =
                                    val.isEmpty ? 'User Code required' : null;
                              });
                              widget.onChanged('usersCd', val);
                            },
                          ),
              ),
              AmsField(
                label: 'ROLECD',
                required: true,
                labelAbove: true,
                tooltip: 'Select the role to assign to the user.',
                child: widget.isViewMode
                    ? AmsTextInput(
                        controller: _rScdCtrl,
                        readOnly: true,
                      )
                    : _loadingDropdowns
                        ? const LinearProgressIndicator()
                        : AmsDropdown(
                            initialValue: () {
                              if (_roleList.isEmpty) return null;
                              final seek = _rScdCtrl.text.isNotEmpty
                                  ? _rScdCtrl.text
                                  : (data['rolecd']?.toString() ?? '');
                              if (seek.isEmpty) return null;
                              final matches = _roleList.where((r) =>
                                  (r['roleCd']?.toString() ??
                                      r['ROLECD']?.toString() ??
                                      '') ==
                                  seek);
                              if (matches.isEmpty) return null;
                              final r = matches.first;
                              return '${r['roleCd'] ?? r['ROLECD'] ?? ''} - ${r['roleName'] ?? r['rolename'] ?? ''}';
                            }(),
                            placeholder: 'Select ROLECD',
                            items: _roleList
                                .map((r) {
                                  final cd = r['roleCd'] ?? r['ROLECD'] ?? '';
                                  final name =
                                      r['roleName'] ?? r['rolename'] ?? '';
                                  return '$cd - $name';
                                })
                                .toSet()
                                .toList(),
                            errorText: _errors['roleCd'],
                            isValid: _errors['roleCd'] == null &&
                                _rScdCtrl.text.isNotEmpty,
                            onChanged: (v) {
                              final parts = v?.split(' - ') ?? [];
                              final val = parts.isNotEmpty ? parts[0] : '';
                              setState(() {
                                _rScdCtrl.text = val;
                                _errors['roleCd'] =
                                    val.isEmpty ? 'Role Code required' : null;
                              });
                              widget.onChanged('roleCd', val);
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
                label: 'Organisation Code',
                required: true,
                labelAbove: true,
                tooltip: 'Select the parent organisation.',
                child: CompositedTransformTarget(
                  link: _orgLayerLink,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.isViewMode ? null : _openOrgDropdown,
                    child: AbsorbPointer(
                      child: AmsTextInput(
                        controller: _orgDisplayCtrl,
                        readOnly: true,
                        placeholder: _orgLoading
                            ? 'Loading organisations…'
                            : 'Select Organisation',
                        icon: _orgLoading
                            ? Icons.hourglass_empty_rounded
                            : Icons.business_rounded,
                      ),
                    ),
                  ),
                ),
              ),
              AmsField(
                label: 'Access Code',
                required: true,
                labelAbove: true,
                tooltip: 'Unique code for the new access role.',
                child: AmsTextInput(
                  controller: _rScdCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. 101',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['accessCd'],
                  isValid:
                      _errors['accessCd'] == null && _rScdCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['accessCd'] =
                          v.trim().isEmpty ? 'Access Code required' : null;
                    });
                    widget.onChanged('accessCd', int.tryParse(v) ?? 0);
                  },
                ),
              ),
              AmsField(
                label: 'Access Name',
                required: true,
                labelAbove: true,
                tooltip: 'Descriptive name for the access role.',
                child: AmsTextInput(
                  controller: _rNameCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. Administrator',
                  textInputAction: TextInputAction.next,
                  errorText: _errors['accessName'],
                  isValid: _errors['accessName'] == null &&
                      _rNameCtrl.text.isNotEmpty,
                  onChanged: (v) {
                    setState(() {
                      _errors['accessName'] =
                          v.trim().isEmpty ? 'Access Name required' : null;
                    });
                    widget.onChanged('accessName', v);
                  },
                ),
              ),
              AmsField(
                label: 'Access Type',
                labelAbove: true,
                tooltip: 'Classification type for this access role.',
                child: AmsTextInput(
                  controller: _rTypeCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. SYSTEM',
                  textInputAction: TextInputAction.next,
                  onChanged: (v) => widget.onChanged('accessType', v),
                ),
              ),
              AmsField(
                label: 'Access Sub Type',
                labelAbove: true,
                tooltip: 'Further classification for this access role.',
                child: AmsTextInput(
                  controller: _rSubtypeCtrl,
                  readOnly: widget.isViewMode,
                  placeholder: 'e.g. MODULE-AUTH',
                  textInputAction: TextInputAction.next,
                  onChanged: (v) => widget.onChanged('accessSubType', v),
                ),
              ),
              _AccessToggleGroup(
                initialViewAccess: data['viewaccess'] == 1 ||
                    data['viewaccess'] == '1' ||
                    data['viewaccess'] == true,
                initialAuthAccess: data['authaccess'] == 1 ||
                    data['authaccess'] == '1' ||
                    data['authaccess'] == true,
                initialMakerAccess: data['makeraccess'] == 1 ||
                    data['makeraccess'] == '1' ||
                    data['makeraccess'] == true,
                initialAdminAccess: data['adminaccess'] == 1 ||
                    data['adminaccess'] == '1' ||
                    data['adminaccess'] == true,
                initialSysAdminAccess: data['sysadminaccess'] == 1 ||
                    data['sysadminaccess'] == '1' ||
                    data['sysadminaccess'] == true,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmsFormGrid(
                children: [
                  AmsField(
                    label: 'Organisation Code',
                    required: true,
                    labelAbove: true,
                    tooltip: 'Select the parent organisation for this module.',
                    child: CompositedTransformTarget(
                      link: _orgLayerLink,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: (widget.isViewMode || widget.initialData != null)
                            ? null
                            : _openOrgDropdown,
                        child: AbsorbPointer(
                          child: AmsTextInput(
                            controller: _orgDisplayCtrl,
                            readOnly: true,
                            placeholder: _orgLoading
                                ? 'Loading organisations…'
                                : 'Select Organisation',
                            icon: _orgLoading
                                ? Icons.hourglass_empty_rounded
                                : Icons.business_rounded,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AmsField(
                    label: 'Module Code',
                    required: true,
                    labelAbove: true,
                    tooltip: 'Unique module identifier.',
                    child: AmsTextInput(
                      controller: _mScdCtrl,
                      readOnly: widget.isViewMode || widget.initialData != null,
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
                    label: 'Module Name',
                    required: true,
                    labelAbove: true,
                    tooltip: 'Human-readable module name.',
                    child: AmsTextInput(
                      controller: _mNameCtrl,
                      readOnly: widget.isViewMode,
                      placeholder: 'e.g. Finance',
                      textInputAction: TextInputAction.done,
                      errorText: _errors['modName'],
                      isValid: _errors['modName'] == null &&
                          _mNameCtrl.text.isNotEmpty,
                      onChanged: (v) {
                        setState(() {
                          _errors['modName'] =
                              v.trim().isEmpty ? 'Module Name required' : null;
                        });
                        widget.onChanged('modName', v);
                      },
                    ),
                  ),
                  AmsField(
                    label: 'Sub Module Name',
                    labelAbove: true,
                    tooltip: 'Whether sub-module is required or not.',
                    child: widget.isViewMode
                        ? AmsTextInput(
                            initialValue:
                                _subModuleEnabled ? '1 - Yes' : '0 - No',
                            readOnly: true,
                          )
                        : AmsDropdown(
                            initialValue:
                                _subModuleEnabled ? '1 - Yes' : '0 - No',
                            items: const ['0 - No', '1 - Yes'],
                            onChanged: (v) {
                              setState(() {
                                _subModuleEnabled = v?.startsWith('1') == true;
                              });
                              widget.onChanged(
                                  'subModule', _subModuleEnabled ? 1 : 0);
                            },
                          ),
                  ),
                  AmsField(
                    label: 'Status',
                    labelAbove: true,
                    tooltip: 'To enable or disable the module.',
                    child: widget.isViewMode
                        ? AmsTextInput(
                            initialValue:
                                _mStatus == 0 ? '0 - Disable' : '1 - Enable',
                            readOnly: true,
                          )
                        : AmsDropdown(
                            initialValue:
                                _mStatus == 0 ? '0 - Disable' : '1 - Enable',
                            items: const ['1 - Enable', '0 - Disable'],
                            onChanged: (v) {
                              final st = v?.startsWith('1') == true ? 1 : 0;
                              setState(() => _mStatus = st);
                              widget.onChanged('status', st);
                            },
                          ),
                  ),
                ],
              ),
              if (_subModuleEnabled) ...[
                const SizedBox(height: 24),
                sectionTitle('SUB-MODULE LIST'),
                const SizedBox(height: 12),
                if (_errors['subModules'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(_errors['subModules']!,
                        style: bodyStyle(color: AppColors.red, size: 12)),
                  ),
                _ModSubModuleGrid(
                  subModules: _subModules,
                  isViewMode: widget.isViewMode,
                  onChanged: (list) {
                    setState(() => _subModules = list);
                    widget.onChanged('subModules', list);
                  },
                ),
              ],
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmsFormGrid(
                children: [
                  AmsField(
                    label: 'Organisation Code',
                    required: true,
                    labelAbove: true,
                    tooltip: 'Select the parent organisation.',
                    child: CompositedTransformTarget(
                      link: _orgLayerLink,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: (widget.isViewMode || widget.initialData != null)
                            ? null
                            : _openOrgDropdown,
                        child: AbsorbPointer(
                          child: AmsTextInput(
                            controller: _orgDisplayCtrl,
                            readOnly: true,
                            placeholder: _orgLoading
                                ? 'Loading organisations…'
                                : 'Select Organisation',
                            icon: _orgLoading
                                ? Icons.hourglass_empty_rounded
                                : Icons.business_rounded,
                            errorText: _errors['orgCode'],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AmsField(
                    label: 'Program Id',
                    required: true,
                    labelAbove: true,
                    child: AmsTextInput(
                      controller: _authPgmCtrl,
                      readOnly: widget.isViewMode || widget.initialData != null,
                      placeholder: 'e.g. USR-ROLE',
                      textInputAction: TextInputAction.done,
                      errorText: _errors['authPgm'],
                      isValid: _errors['authPgm'] == null &&
                          _authPgmCtrl.text.isNotEmpty,
                      onChanged: (v) {
                        setState(() {
                          _errors['authPgm'] =
                              v.trim().isEmpty ? 'Program Id required' : null;
                        });
                        widget.onChanged('programId', v);
                      },
                    ),
                  ),
                  AmsField(
                    label: 'Approval Required',
                    labelAbove: true,
                    child: Row(
                      children: [
                        Switch(
                          value: _approvalReq,
                          onChanged: widget.isViewMode
                              ? null
                              : (v) {
                                  setState(() => _approvalReq = v);
                                  widget.onChanged('approvalReq', v ? 1 : 0);
                                },
                          activeThumbColor: AppColors.tBlue,
                        ),
                        Text(_approvalReq ? 'Yes' : 'No', style: bodyStyle()),
                      ],
                    ),
                  ),
                  AmsField(
                    label: 'Pre Approval Required',
                    labelAbove: true,
                    child: Row(
                      children: [
                        Switch(
                          value: _preApprovalReq,
                          onChanged: widget.isViewMode
                              ? null
                              : (v) {
                                  setState(() => _preApprovalReq = v);
                                  widget.onChanged('preApproveProc', v ? 1 : 0);
                                },
                          activeThumbColor: AppColors.tBlue,
                        ),
                        Text(_preApprovalReq ? 'Yes' : 'No',
                            style: bodyStyle()),
                      ],
                    ),
                  ),
                  AmsField(
                    label: 'Post Approval Required',
                    labelAbove: true,
                    child: Row(
                      children: [
                        Switch(
                          value: _postApprovalReq,
                          onChanged: widget.isViewMode
                              ? null
                              : (v) {
                                  setState(() => _postApprovalReq = v);
                                  widget.onChanged(
                                      'postApproveProc', v ? 1 : 0);
                                },
                          activeThumbColor: AppColors.tBlue,
                        ),
                        Text(_postApprovalReq ? 'Yes' : 'No',
                            style: bodyStyle()),
                      ],
                    ),
                  ),
                  AmsField(
                    label: 'Transaction program',
                    labelAbove: true,
                    child: Row(
                      children: [
                        Switch(
                          value: _isTran,
                          onChanged: widget.isViewMode
                              ? null
                              : (v) {
                                  setState(() => _isTran = v);
                                  widget.onChanged('isTranPgm', v ? 1 : 0);
                                },
                          activeThumbColor: AppColors.tBlue,
                        ),
                        Text(_isTran ? 'Yes' : 'No', style: bodyStyle()),
                      ],
                    ),
                  ),
                ],
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
                userList: _userList,
                roleList: _roleList,
                loading: _loadingDropdowns,
                onChanged: (levels) {
                  setState(() => _authLevels = levels);
                  widget.onChanged('authLevels', levels);
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
  final List<Map<String, dynamic>> userList;
  final List<Map<String, dynamic>> roleList;
  final bool loading;
  const _Auth102LevelGrid({
    required this.onChanged,
    this.initialData,
    this.isViewMode = false,
    required this.userList,
    required this.roleList,
    this.loading = false,
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
          final mappedItem = Map<String, dynamic>.from(item);
          if (mappedItem['permissionType'] == 'R') {
            mappedItem['permissionType'] = 'R - Role';
          } else if (mappedItem['permissionType'] == 'U') {
            mappedItem['permissionType'] = 'U - User';
          }
          _levels.add(mappedItem);
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

  void _notify() {
    final List<Map<String, dynamic>> mappedLevels = _levels.map((lvl) {
      final newLvl = Map<String, dynamic>.from(lvl);
      if (newLvl['permissionType'] == 'R - Role') {
        newLvl['permissionType'] = 'R';
      } else if (newLvl['permissionType'] == 'U - User') {
        newLvl['permissionType'] = 'U';
      }
      return newLvl;
    }).toList();

    widget.onChanged(mappedLevels);
  }

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
                        child: widget.isViewMode ||
                                _levels[i]['permissionType'] == 'U - User'
                            ? AmsTextInput(
                                initialValue: _levels[i]['roleCd']?.toString(),
                                readOnly: true,
                              )
                            : widget.loading
                                ? const LinearProgressIndicator()
                                : AmsDropdown(
                                    initialValue: () {
                                      if (_levels[i]['roleCd'] == null ||
                                          widget.roleList.isEmpty) return null;
                                      final seek =
                                          _levels[i]['roleCd']?.toString() ??
                                              '';
                                      if (seek.isEmpty) return null;
                                      final matches = widget.roleList.where(
                                          (r) =>
                                              (r['roleCd']?.toString() ??
                                                  r['ROLECD']?.toString()) ==
                                              seek);
                                      if (matches.isEmpty) return null;
                                      final r = matches.first;
                                      final cd =
                                          r['roleCd'] ?? r['ROLECD'] ?? '';
                                      final name = r['roleName'] ??
                                          r['rolename'] ??
                                          r['ROLENAME'] ??
                                          '';
                                      return '$cd - $name';
                                    }(),
                                    placeholder: 'Select ROLECD',
                                    items: widget.roleList
                                        .map((r) {
                                          final cd =
                                              r['roleCd'] ?? r['ROLECD'] ?? '';
                                          final name = r['roleName'] ??
                                              r['rolename'] ??
                                              r['ROLENAME'] ??
                                              '';
                                          return '$cd - $name';
                                        })
                                        .where((s) => s.trim().isNotEmpty)
                                        .toSet()
                                        .toList(),
                                    onChanged: (v) {
                                      final parts = v?.split(' - ') ?? [];
                                      final val =
                                          parts.isNotEmpty ? parts[0] : '';
                                      _updateLevel(i, 'roleCd', val);
                                    },
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
                        child: widget.isViewMode ||
                                _levels[i]['permissionType'] == 'R - Role'
                            ? AmsTextInput(
                                initialValue: _levels[i]['userId']?.toString(),
                                readOnly: true,
                              )
                            : widget.loading
                                ? const LinearProgressIndicator()
                                : AmsDropdown(
                                    initialValue: () {
                                      if (_levels[i]['userId'] == null ||
                                          widget.userList.isEmpty) return null;
                                      final seek =
                                          _levels[i]['userId']?.toString() ??
                                              '';
                                      if (seek.isEmpty) return null;
                                      final matches = widget.userList.where(
                                          (u) =>
                                              (u['usersCd'] ??
                                                      u['users_cd'] ??
                                                      u['userScd'] ??
                                                      u['USERSCD'] ??
                                                      '')
                                                  .toString() ==
                                              seek);
                                      if (matches.isEmpty) return null;
                                      final u = matches.first;
                                      final scd = u['usersCd'] ??
                                          u['userScd'] ??
                                          u['USERSCD'] ??
                                          '';
                                      final name =
                                          u['fName'] ?? u['fname'] ?? '';
                                      return '$scd - $name';
                                    }(),
                                    placeholder: 'Select USERID',
                                    items: widget.userList
                                        .map((u) {
                                          final scd = u['usersCd'] ??
                                              u['userScd'] ??
                                              u['USERSCD'] ??
                                              '';
                                          final name =
                                              u['fName'] ?? u['fname'] ?? '';
                                          return '$scd - $name';
                                        })
                                        .where((s) => s.trim().isNotEmpty)
                                        .toSet()
                                        .toList(),
                                    onChanged: (v) {
                                      final parts = v?.split(' - ') ?? [];
                                      final val =
                                          parts.isNotEmpty ? parts[0] : '';
                                      _updateLevel(i, 'userId', val);
                                    },
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

class _ModSubModuleGrid extends StatefulWidget {
  final List<Map<String, dynamic>> subModules;
  final void Function(List<Map<String, dynamic>> subModules) onChanged;
  final bool isViewMode;

  const _ModSubModuleGrid({
    required this.subModules,
    required this.onChanged,
    this.isViewMode = false,
  });

  @override
  State<_ModSubModuleGrid> createState() => _ModSubModuleGridState();
}

class _ModSubModuleGridState extends State<_ModSubModuleGrid> {
  late List<Map<String, dynamic>> _list;

  @override
  void initState() {
    super.initState();
    _list = List<Map<String, dynamic>>.from(widget.subModules);
  }

  void _add() {
    setState(() {
      _list.add({
        'subModuleId': _list.length + 1,
        'subModuleName': '',
        'status': 1,
      });
    });
    widget.onChanged(_list);
  }

  void _remove(int idx) {
    setState(() {
      _list.removeAt(idx);
    });
    widget.onChanged(_list);
  }

  void _update(int idx, String key, dynamic val) {
    setState(() {
      _list[idx][key] = val;
    });
    widget.onChanged(_list);
  }

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
          if (_list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No sub-modules added.',
                    style: bodyStyle(size: 13, color: AppColors.ink3)),
              ),
            ),
          for (int i = 0; i < _list.length; i++)
            Container(
              margin: EdgeInsets.only(bottom: i == _list.length - 1 ? 0 : 16),
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
                      Text('SUB-MODULE ${i + 1}',
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
                          onPressed: () => _remove(i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AmsFormGrid(
                    cols: 3,
                    children: [
                      AmsField(
                        label: 'SUB_MODULEID',
                        child: AmsTextInput(
                          initialValue: (_list[i]['subModuleId'] ??
                                  _list[i]['sub_module_id'] ??
                                  _list[i]['sub_moduleid'] ??
                                  _list[i]['submoduleid'] ??
                                  '')
                              .toString(),
                          readOnly: true,
                        ),
                      ),
                      AmsField(
                        label: 'Sub Module Name',
                        required: true,
                        child: AmsTextInput(
                          initialValue: (_list[i]['subModuleName'] ??
                                  _list[i]['sub_modulename'] ??
                                  _list[i]['sub_module_name'] ??
                                  _list[i]['submodulename'] ??
                                  '')
                              .toString(),
                          readOnly: widget.isViewMode,
                          onChanged: (v) => _update(i, 'subModuleName', v),
                        ),
                      ),
                      AmsField(
                        label: 'Status',
                        child: AmsDropdown(
                          initialValue: (_list[i]['status']?.toString() == '0')
                              ? '0 - Disable'
                              : '1 - Enable',
                          items: const ['1 - Enable', '0 - Disable'],
                          onChanged: widget.isViewMode
                              ? null
                              : (v) => _update(i, 'status',
                                  v?.startsWith('1') == true ? 1 : 0),
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
                label: '+ Add Sub-Module',
                variant: AmsButtonVariant.outline,
                onPressed: _add,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
