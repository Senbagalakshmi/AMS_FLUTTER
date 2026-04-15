import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ams_flutter/theme.dart';
import 'package:ams_flutter/models/models.dart';
import 'package:ams_flutter/models/menu_models.dart';
import 'package:ams_flutter/widgets/widgets.dart';
import 'package:ams_flutter/services/api_service.dart' as main;
import 'package:ams_flutter/services/menu_api_service.dart';

class MenuMasterScreen extends StatefulWidget {
  final Map<String, Auth101Config> authConfigs;
  final VoidCallback onBack;
  final VoidCallback? onBackToModule;
  final String? userName;

  const MenuMasterScreen({
    super.key,
    required this.authConfigs,
    required this.onBack,
    this.onBackToModule,
    this.userName,
  });

  @override
  State<MenuMasterScreen> createState() => _MenuMasterScreenState();
}

class _MenuMasterScreenState extends State<MenuMasterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    // Sync token from main service
    menuApiService.updateToken(main.apiService.token);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.menu_open_rounded, size: 28, color: AppColors.tBlue),
            title: 'Menu Master',
            subtitle: 'Configure and manage multilevel navigation menus.',
            badges: [
              AmsBadge(
                label: _currentTab == 0 ? 'Parent Menus' : (_currentTab == 1 ? 'Sub Menus' : 'Menu Programs'),
                background: AppColors.tBlueLt,
                color: AppColors.tBlue,
              ),
            ],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(label: 'Masters', onTap: widget.onBackToModule ?? widget.onBack),
              HeaderBreadcrumb(label: 'Menu Master'),
            ],
            onBack: widget.onBack,
          ),
          
          // Custom Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: AppColors.sidebar,
              unselectedLabelColor: AppColors.ink3,
              labelStyle: bodyStyle(weight: FontWeight.w700, size: 13),
              unselectedLabelStyle: bodyStyle(weight: FontWeight.w500, size: 13),
              tabs: const [
                Tab(text: '1. Parent Menu'),
                Tab(text: '2. Sub Menu'),
                Tab(text: '3. Menu Program'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ParentMenuTab(userName: widget.userName),
                _SubMenuTab(userName: widget.userName),
                _MenuProgramTab(userName: widget.userName),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Parent Menu Tab ---

class _ParentMenuTab extends StatefulWidget {
  final String? userName;
  const _ParentMenuTab({this.userName});

  @override
  State<_ParentMenuTab> createState() => _ParentMenuTabState();
}

class _ParentMenuTabState extends State<_ParentMenuTab> {
  bool _showForm = false;
  Map<String, dynamic>? _editingRecord;
  bool _isViewOnly = false;
  int _listVersion = 0;

  // Controllers
  final _menuCodeCtrl = TextEditingController();
  final _menuDescnCtrl = TextEditingController();
  final _menuOrderCtrl = TextEditingController();
  final _pgmIdCtrl = TextEditingController();
  final _pathCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  String? _subMenuReq = '0 - No';
  String? _location = 'L - Left';
  int _status = 1;

  void _loadRecord(Map<String, dynamic>? record, {bool viewOnly = false}) {
    _editingRecord = record;
    _isViewOnly = viewOnly;
    if (record == null) {
      _menuCodeCtrl.clear();
      _menuDescnCtrl.clear();
      _menuOrderCtrl.text = '1';
      _pgmIdCtrl.clear();
      _pathCtrl.clear();
      _logoCtrl.clear();
      _subMenuReq = '0 - No';
      _location = 'L - Left';
      _status = 1;
    } else {
      _menuCodeCtrl.text = record['menuCode']?.toString() ?? record['Menucode']?.toString() ?? '';
      _menuDescnCtrl.text = record['menuDescn']?.toString() ?? record['MENU_DESCN']?.toString() ?? '';
      _menuOrderCtrl.text = record['menuOrder']?.toString() ?? record['MENU_ORDER']?.toString() ?? '1';
      _pgmIdCtrl.text = record['parentMenuPgmId']?.toString() ?? record['Parentmenu_PGMID']?.toString() ?? '';
      _pathCtrl.text = record['programPath']?.toString() ?? record['Program Path']?.toString() ?? '';
      _logoCtrl.text = record['menuLogo']?.toString() ?? record['MENU_LOGO']?.toString() ?? '';
      _subMenuReq = (record['subMenuReq'] == 1 || record['SUBMENUREQ'] == 1) ? '1 - Yes' : '0 - No';
      
      final loc = record['menuLocation']?.toString() ?? record['MENU_LOCATION']?.toString() ?? 'L';
      switch (loc) {
        case 'L': _location = 'L - Left'; break;
        case 'R': _location = 'R - Right'; break;
        case 'C': _location = 'C - Center'; break;
        case 'T': _location = 'T - Top'; break;
        case 'B': _location = 'B - Bottom'; break;
        default: _location = 'L - Left';
      }
      _status = int.tryParse(record['menuStatus']?.toString() ?? record['MENU_STATUS']?.toString() ?? '1') ?? 1;
    }
    setState(() => _showForm = true);
  }

  Future<void> _submit() async {
    final data = {
      'menuCode': int.tryParse(_menuCodeCtrl.text),
      'menuDescn': _menuDescnCtrl.text,
      'menuOrder': int.tryParse(_menuOrderCtrl.text) ?? 1,
      'subMenuReq': _subMenuReq?.startsWith('1') == true ? 1 : 0,
      'parentMenuPgmId': _pgmIdCtrl.text,
      'programPath': _pathCtrl.text,
      'menuLogo': _logoCtrl.text,
      'menuLocation': _location?.substring(0, 1) ?? 'L',
      'menuStatus': _status,
      'orgCode': 50, // Default
      'eUser': widget.userName ?? 'admin',
    };

    bool success;
    if (_editingRecord == null) {
      success = await menuApiService.createParentMenu(data);
    } else {
      success = await menuApiService.updateParentMenu(data);
    }

    if (success) {
      showAmsSnack(context, 'Parent Menu saved successfully! ✅');
      setState(() {
        _showForm = false;
        _listVersion++;
      });
    } else {
      showAmsSnack(context, 'Failed to save parent menu. ❌', type: 'e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_showForm ? (_isViewOnly ? 'View Parent Menu' : (_editingRecord == null ? 'New Parent Menu' : 'Edit Parent Menu')) : 'Parent Menu List', 
                style: bodyStyle(weight: FontWeight.w700, size: 16, color: AppColors.sidebar)),
              if (!_showForm)
                AmsButton(
                  label: 'Add Menu',
                  icon: Icons.add_rounded,
                  small: true,
                  onPressed: () => _loadRecord(null),
                )
              else
                AmsButton(
                  label: 'Back to List',
                  icon: Icons.list_rounded,
                  variant: AmsButtonVariant.outline,
                  small: true,
                  onPressed: () => setState(() => _showForm = false),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _showForm ? _buildForm() : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return _ParentMenuListView(
      key: ValueKey('parent_list_$_listVersion'),
      onEdit: (r) => _loadRecord(r),
      onView: (r) => _loadRecord(r, viewOnly: true),
      onDelete: (r) async {
        final code = int.tryParse((r['menuCode'] ?? r['Menucode'] ?? '0').toString()) ?? 0;
        final ok = await menuApiService.deleteParentMenu(code);
        if (ok) {
          showAmsSnack(context, 'Deleted successfully');
          setState(() => _listVersion++);
        }
      },
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AmsFormGrid(
              children: [
                AmsField(label: 'MENU CODE', required: true, child: AmsTextInput(controller: _menuCodeCtrl, readOnly: _editingRecord != null || _isViewOnly, keyboardType: TextInputType.number)),
                AmsField(label: 'DESCRIPTION', required: true, child: AmsTextInput(controller: _menuDescnCtrl, readOnly: _isViewOnly)),
                AmsField(label: 'MENU ORDER', required: true, child: AmsTextInput(controller: _menuOrderCtrl, readOnly: _isViewOnly, keyboardType: TextInputType.number)),
                AmsField(label: 'SUBMENU REQUIRED', required: true, child: AmsDropdown(items: const ['1 - Yes', '0 - No'], initialValue: _subMenuReq, onChanged: _isViewOnly ? null : (v) => setState(() => _subMenuReq = v))),
                AmsField(label: 'PROGRAM ID', child: AmsTextInput(controller: _pgmIdCtrl, readOnly: _isViewOnly)),
                AmsField(label: 'PROGRAM PATH', child: AmsTextInput(controller: _pathCtrl, readOnly: _isViewOnly)),
                AmsField(label: 'MENU LOGO (ICON)', child: AmsTextInput(controller: _logoCtrl, readOnly: _isViewOnly)),
                AmsField(label: 'LOCATION', child: AmsDropdown(items: const ['L - Left', 'R - Right', 'C - Center', 'T - Top', 'B - Bottom'], initialValue: _location, onChanged: _isViewOnly ? null : (v) => setState(() => _location = v))),
                AmsField(label: 'STATUS', child: AmsDropdown(items: const ['1 - Enabled', '0 - Disabled'], initialValue: _status == 1 ? '1 - Enabled' : '0 - Disabled', onChanged: _isViewOnly ? null : (v) => setState(() => _status = v?.startsWith('1') == true ? 1 : 0))),
              ],
            ),
          ),
        ),
        if (!_isViewOnly)
          AmsSubmitBar(
            borderColor: AppColors.border,
            actions: [
              AmsButton(label: 'Save Parent Menu', onPressed: _submit),
              AmsButton(label: 'Cancel', variant: AmsButtonVariant.danger, onPressed: () => setState(() => _showForm = false)),
            ],
          ),
      ],
    );
  }
}

class _ParentMenuListView extends StatefulWidget {
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onView;
  final Function(Map<String, dynamic>) onDelete;

  const _ParentMenuListView({super.key, required this.onEdit, required this.onView, required this.onDelete});

  @override
  State<_ParentMenuListView> createState() => _ParentMenuListViewState();
}

class _ParentMenuListViewState extends State<_ParentMenuListView> {
  List<Map<String, dynamic>>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await menuApiService.getParentMenus(size: 100);
    setState(() {
      _data = res?.items ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data == null || _data!.isEmpty) return const Center(child: Text('No parent menus found.'));

    return ListView.separated(
      itemCount: _data!.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = _data![index];
        final code = (r['menuCode'] ?? r['Menucode'] ?? '—').toString();
        final descn = (r['menu_Descn'] ?? r['menuDescn'] ?? r['MENU_DESCN'] ?? '—').toString();
        final order = (r['menu_Order'] ?? r['menuOrder'] ?? r['MENU_ORDER'] ?? '—').toString();
        final isEnabled = (r['menu_Status'] == 1 || r['menuStatus'] == 1 || r['MENU_STATUS'] == 1);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.tBlueLt, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(code, style: bodyStyle(weight: FontWeight.w700, color: AppColors.tBlue))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(descn, style: bodyStyle(weight: FontWeight.w600)),
                    Text('Order: $order', style: bodyStyle(size: 12, color: AppColors.ink3)),
                  ],
                ),
              ),
              AmsBadge(label: isEnabled ? 'Active' : 'Disabled', color: isEnabled ? AppColors.green : AppColors.red, background: isEnabled ? AppColors.greenLt : AppColors.redLt),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(Icons.visibility_rounded, size: 20, color: AppColors.tBlue), onPressed: () => widget.onView(r)),
              IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.ink3), onPressed: () => widget.onEdit(r)),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.red), onPressed: () => widget.onDelete(r)),
            ],
          ),
        );
      },
    );
  }
}

// --- Sub Menu Tab ---

class _SubMenuTab extends StatefulWidget {
  final String? userName;
  const _SubMenuTab({this.userName});

  @override
  State<_SubMenuTab> createState() => _SubMenuTabState();
}

class _SubMenuTabState extends State<_SubMenuTab> {
  bool _showForm = false;
  Map<String, dynamic>? _editingRecord;
  bool _isViewOnly = false;
  int _listVersion = 0;

  final _menuCodeCtrl = TextEditingController();
  final _subMenuCodeCtrl = TextEditingController();
  final _descnCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();
  final _pgmIdCtrl = TextEditingController();
  final _pathCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  int _status = 1;

  List<Map<String, dynamic>> _parentMenus = [];
  bool _loadingParents = false;

  @override
  void initState() {
    super.initState();
    _fetchParents();
  }

  Future<void> _fetchParents() async {
    setState(() => _loadingParents = true);
    final res = await menuApiService.getParentMenus(size: 200);
    setState(() {
      _parentMenus = res?.items ?? [];
      _loadingParents = false;
    });
  }

  void _loadRecord(Map<String, dynamic>? record, {bool viewOnly = false}) {
    _editingRecord = record;
    _isViewOnly = viewOnly;
    if (record == null) {
      _menuCodeCtrl.clear();
      _subMenuCodeCtrl.clear();
      _descnCtrl.clear();
      _orderCtrl.text = '1';
      _pgmIdCtrl.clear();
      _pathCtrl.clear();
      _logoCtrl.clear();
      _status = 1;
    } else {
      _menuCodeCtrl.text = record['menuCode']?.toString() ?? record['Menucode']?.toString() ?? '';
      _subMenuCodeCtrl.text = record['subMenuCode']?.toString() ?? record['submenucode']?.toString() ?? '';
      _descnCtrl.text = record['description']?.toString() ?? record['Decription']?.toString() ?? '';
      _orderCtrl.text = record['menuOrder']?.toString() ?? record['MENU_ORDER']?.toString() ?? '1';
      _pgmIdCtrl.text = record['subMenuPgmId']?.toString() ?? record['Submenu_PGMID']?.toString() ?? '';
      _pathCtrl.text = record['programPath']?.toString() ?? record['Program Path']?.toString() ?? '';
      _logoCtrl.text = record['menuLogo']?.toString() ?? record['MENU_LOGO']?.toString() ?? '';
      _status = int.tryParse(record['menuStatus']?.toString() ?? record['MENU_STATUS']?.toString() ?? '1') ?? 1;
    }
    setState(() => _showForm = true);
  }

  Future<void> _submit() async {
    final data = {
      'menuCode': int.tryParse(_menuCodeCtrl.text),
      'subMenuCode': int.tryParse(_subMenuCodeCtrl.text),
      'description': _descnCtrl.text,
      'menuOrder': int.tryParse(_orderCtrl.text) ?? 1,
      'subMenuPgmId': _pgmIdCtrl.text,
      'programPath': _pathCtrl.text,
      'menuLogo': _logoCtrl.text,
      'menuStatus': _status,
      'orgCode': 50,
      'eUser': widget.userName ?? 'admin',
    };

    bool success;
    if (_editingRecord == null) {
      success = await menuApiService.createSubMenu(data);
    } else {
      success = await menuApiService.updateSubMenu(data);
    }

    if (success) {
      showAmsSnack(context, 'Sub Menu saved successfully! ✅');
      setState(() {
        _showForm = false;
        _listVersion++;
      });
    } else {
      showAmsSnack(context, 'Failed to save sub menu. ❌', type: 'e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_showForm ? (_isViewOnly ? 'View Sub Menu' : (_editingRecord == null ? 'New Sub Menu' : 'Edit Sub Menu')) : 'Sub Menu List', 
                style: bodyStyle(weight: FontWeight.w700, size: 16, color: AppColors.sidebar)),
              if (!_showForm)
                AmsButton(
                  label: 'Add Sub Menu',
                  icon: Icons.add_rounded,
                  small: true,
                  onPressed: () => _loadRecord(null),
                )
              else
                AmsButton(
                  label: 'Back to List',
                  icon: Icons.list_rounded,
                  variant: AmsButtonVariant.outline,
                  small: true,
                  onPressed: () => setState(() => _showForm = false),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
              child: _showForm ? _buildForm() : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return _SubMenuListView(
      key: ValueKey('submenu_list_$_listVersion'),
      onEdit: (r) => _loadRecord(r),
      onView: (r) => _loadRecord(r, viewOnly: true),
      onDelete: (r) async {
        final sCode = int.tryParse((r['subMenuCode'] ?? r['submenucode'] ?? '0').toString()) ?? 0;
        final ok = await menuApiService.deleteSubMenu(sCode);
        if (ok) {
           showAmsSnack(context, 'Deleted successfully');
           setState(() => _listVersion++);
        }
      },
    );
  }

  Widget _buildForm() {
    String? parentDisplay;
    if (_menuCodeCtrl.text.isNotEmpty) {
       final p = _parentMenus.where((m) => (m['menuCode'] ?? m['Menucode']).toString() == _menuCodeCtrl.text).firstOrNull;
       if (p != null) parentDisplay = "${p['menuCode'] ?? p['Menucode']} - ${p['menuDescn'] ?? p['MENU_DESCN']}";
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AmsFormGrid(
              children: [
                AmsField(label: 'PARENT MENU', required: true, child: _loadingParents ? const LinearProgressIndicator() : AmsDropdown(
                  items: _parentMenus.map((m) => "${m['menuCode'] ?? m['Menucode']} - ${m['menuDescn'] ?? m['MENU_DESCN']}").toList(),
                  initialValue: parentDisplay,
                  onChanged: _isViewOnly ? null : (v) {
                    if (v == null) return;
                    _menuCodeCtrl.text = v.split(' - ').first;
                  },
                )),
                AmsField(label: 'SUB MENU CODE', required: true, child: AmsTextInput(controller: _subMenuCodeCtrl, readOnly: _editingRecord != null || _isViewOnly, keyboardType: TextInputType.number)),
                AmsField(label: 'DESCRIPTION', required: true, child: AmsTextInput(controller: _descnCtrl, readOnly: _isViewOnly)),
                AmsField(label: 'MENU ORDER', required: true, child: AmsTextInput(controller: _orderCtrl, readOnly: _isViewOnly, keyboardType: TextInputType.number)),
                AmsField(label: 'SUBMENU PGM ID', child: AmsTextInput(controller: _pgmIdCtrl, readOnly: _isViewOnly)),
                AmsField(label: 'PROGRAM PATH', child: AmsTextInput(controller: _pathCtrl, readOnly: _isViewOnly)),
                AmsField(label: 'MENU LOGO', child: AmsTextInput(controller: _logoCtrl, readOnly: _isViewOnly)),
                AmsField(label: 'STATUS', child: AmsDropdown(items: const ['1 - Enabled', '0 - Disabled'], initialValue: _status == 1 ? '1 - Enabled' : '0 - Disabled', onChanged: _isViewOnly ? null : (v) => setState(() => _status = v?.startsWith('1') == true ? 1 : 0))),
              ],
            ),
          ),
        ),
        if (!_isViewOnly)
          AmsSubmitBar(
            borderColor: AppColors.border,
            actions: [
              AmsButton(label: 'Save Sub Menu', onPressed: _submit),
              AmsButton(label: 'Cancel', variant: AmsButtonVariant.danger, onPressed: () => setState(() => _showForm = false)),
            ],
          ),
      ],
    );
  }
}

class _SubMenuListView extends StatefulWidget {
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onView;
  final Function(Map<String, dynamic>) onDelete;

  const _SubMenuListView({super.key, required this.onEdit, required this.onView, required this.onDelete});

  @override
  State<_SubMenuListView> createState() => _SubMenuListViewState();
}

class _SubMenuListViewState extends State<_SubMenuListView> {
  List<Map<String, dynamic>>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await menuApiService.getSubMenus(size: 100);
    setState(() {
      _data = res?.items ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data == null || _data!.isEmpty) return const Center(child: Text('No sub menus found.'));

    return ListView.separated(
      itemCount: _data!.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = _data![index];
        final mCode = (r['menuCode'] ?? r['Menucode'] ?? '—').toString();
        final sCode = (r['subMenuCode'] ?? r['submenucode'] ?? '—').toString();
        final descn = (r['description'] ?? r['Decription'] ?? '—').toString();
        final isEnabled = (r['menu_Status'] == 1 || r['menuStatus'] == 1 || r['MENU_STATUS'] == 1);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Column(
                children: [
                   Text(mCode, style: bodyStyle(size: 10, color: AppColors.ink3)),
                   Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: AppColors.tBlueLt, borderRadius: BorderRadius.circular(6)),
                    child: Center(child: Text(sCode, style: bodyStyle(weight: FontWeight.w700, color: AppColors.tBlue, size: 12))),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(descn, style: bodyStyle(weight: FontWeight.w600)),
                    Text('Parent: $mCode | SubCode: $sCode', style: bodyStyle(size: 11, color: AppColors.ink3)),
                  ],
                ),
              ),
              AmsBadge(label: isEnabled ? 'Active' : 'Disabled', color: isEnabled ? AppColors.green : AppColors.red, background: isEnabled ? AppColors.greenLt : AppColors.redLt),
              IconButton(icon: const Icon(Icons.visibility_rounded, size: 20, color: AppColors.tBlue), onPressed: () => widget.onView(r)),
              IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.ink3), onPressed: () => widget.onEdit(r)),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.red), onPressed: () => widget.onDelete(r)),
            ],
          ),
        );
      },
    );
  }
}

// --- Menu Program Tab ---

class _MenuProgramTab extends StatefulWidget {
  final String? userName;
  const _MenuProgramTab({this.userName});

  @override
  State<_MenuProgramTab> createState() => _MenuProgramTabState();
}

class _MenuProgramTabState extends State<_MenuProgramTab> {
  bool _showForm = false;
  Map<String, dynamic>? _editingRecord;
  bool _isViewOnly = false;
  int _listVersion = 0;

  final _menuCodeCtrl = TextEditingController();
  final _subMenuCodeCtrl = TextEditingController();
  final _pgmIdCtrl = TextEditingController();
  final _descnCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();
  final _pathCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  int _status = 1;

  List<Map<String, dynamic>> _parentMenus = [];
  List<Map<String, dynamic>> _subMenus = [];
  List<Map<String, dynamic>> _allPrograms = [];
  bool _loadingDropdowns = false;

  @override
  void initState() {
    super.initState();
    _fetchDropdowns();
  }

  Future<void> _fetchDropdowns() async {
    setState(() => _loadingDropdowns = true);
    final pRes = await menuApiService.getParentMenus(size: 200);
    final sRes = await menuApiService.getSubMenus(size: 500);
    final pgRes = await menuApiService.getProgramMaster(size: 1000);
    setState(() {
      _parentMenus = pRes?.items ?? [];
      _subMenus = sRes?.items ?? [];
      _allPrograms = pgRes?.items ?? [];
      _loadingDropdowns = false;
    });
  }

  void _loadRecord(Map<String, dynamic>? record, {bool viewOnly = false}) {
    _editingRecord = record;
    _isViewOnly = viewOnly;
    if (record == null) {
      _menuCodeCtrl.clear();
      _subMenuCodeCtrl.clear();
      _pgmIdCtrl.clear();
      _descnCtrl.clear();
      _orderCtrl.text = '1';
      _pathCtrl.clear();
      _logoCtrl.clear();
      _status = 1;
    } else {
      _menuCodeCtrl.text = record['menuCode']?.toString() ?? record['Menucode']?.toString() ?? '';
      _subMenuCodeCtrl.text = record['subMenuCode']?.toString() ?? record['submenucode']?.toString() ?? '0';
      _pgmIdCtrl.text = record['pgmId']?.toString() ?? record['PGM_ID']?.toString() ?? '';
      _descnCtrl.text = record['description']?.toString() ?? record['Decription']?.toString() ?? '';
      _orderCtrl.text = record['menuOrder']?.toString() ?? record['MENU_ORDER']?.toString() ?? '1';
      _pathCtrl.text = record['programPath']?.toString() ?? record['Program Path']?.toString() ?? '';
      _logoCtrl.text = record['menuLogo']?.toString() ?? record['MENU_LOGO']?.toString() ?? '';
      _status = int.tryParse(record['status']?.toString() ?? record['status']?.toString() ?? '1') ?? 1;
    }
    setState(() => _showForm = true);
  }

  Future<void> _submit() async {
    final data = {
      'menuCode': int.tryParse(_menuCodeCtrl.text),
      'subMenuCode': int.tryParse(_subMenuCodeCtrl.text) ?? 0,
      'pgmId': _pgmIdCtrl.text,
      'description': _descnCtrl.text,
      'menuOrder': int.tryParse(_orderCtrl.text) ?? 1,
      'programPath': _pathCtrl.text,
      'menuLogo': _logoCtrl.text,
      'status': _status,
      'orgCode': 50,
      'eUser': widget.userName ?? 'admin',
    };

    bool success;
    if (_editingRecord == null) {
      success = await menuApiService.createMenuProgram(data);
    } else {
      success = await menuApiService.updateMenuProgram(data);
    }

    if (success) {
      showAmsSnack(context, 'Menu Program saved successfully! ✅');
      setState(() {
        _showForm = false;
        _listVersion++;
      });
    } else {
      showAmsSnack(context, 'Failed to save menu program. ❌', type: 'e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_showForm ? (_isViewOnly ? 'View Menu Program' : (_editingRecord == null ? 'New Menu Program' : 'Edit Menu Program')) : 'Menu Program List', 
                style: bodyStyle(weight: FontWeight.w700, size: 16, color: AppColors.sidebar)),
              if (!_showForm)
                AmsButton(
                  label: 'Add Program',
                  icon: Icons.add_rounded,
                  small: true,
                  onPressed: () => _loadRecord(null),
                )
              else
                AmsButton(
                  label: 'Back to List',
                  icon: Icons.list_rounded,
                  variant: AmsButtonVariant.outline,
                  small: true,
                  onPressed: () => setState(() => _showForm = false),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
              child: _showForm ? _buildForm() : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return _MenuProgramListView(
      key: ValueKey('pgm_list_$_listVersion'),
      onEdit: (r) => _loadRecord(r),
      onView: (r) => _loadRecord(r, viewOnly: true),
      onDelete: (r) async {
        final pId = (r['pgmId'] ?? r['PGM_ID'] ?? r['pgm_Id'] ?? '').toString();
        final ok = await menuApiService.deleteMenuProgram(pId);
        if (ok) {
           showAmsSnack(context, 'Deleted successfully');
           setState(() => _listVersion++);
        }
      },
    );
  }

  Widget _buildForm() {
    final filteredSubs = _subMenus.where((s) => (s['menuCode'] ?? s['Menucode']).toString() == _menuCodeCtrl.text).toList();
    
    String? parentDisplay;
    if (_menuCodeCtrl.text.isNotEmpty) {
       final p = _parentMenus.where((m) => (m['menuCode'] ?? m['Menucode']).toString() == _menuCodeCtrl.text).firstOrNull;
       if (p != null) parentDisplay = "${p['menuCode'] ?? p['Menucode']} - ${p['menuDescn'] ?? p['MENU_DESCN']}";
    }
    
    String? subDisplay;
    if (_subMenuCodeCtrl.text.isNotEmpty && _subMenuCodeCtrl.text != '0') {
       final s = _subMenus.where((m) => (m['menuCode'] ?? m['Menucode']).toString() == _menuCodeCtrl.text && (m['subMenuCode'] ?? m['submenucode']).toString() == _subMenuCodeCtrl.text).firstOrNull;
       if (s != null) subDisplay = "${s['subMenuCode'] ?? s['submenucode']} - ${s['description'] ?? s['Decription']}";
    } else if (_subMenuCodeCtrl.text == '0') {
      subDisplay = "0 - No Submenu";
    }

    String? programDisplay;
    if (_pgmIdCtrl.text.isNotEmpty) {
      final pg = _allPrograms.where((p) => (p['pgmId'] ?? p['programId'] ?? p['PGM_ID']).toString() == _pgmIdCtrl.text).firstOrNull;
      if (pg != null) programDisplay = "${pg['pgmId'] ?? pg['programId'] ?? pg['PGM_ID']} - ${pg['descn'] ?? pg['programDescription'] ?? pg['description']}";
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AmsFormGrid(
              children: [
                AmsField(label: 'PARENT MENU', required: true, child: AmsDropdown(
                  items: _parentMenus.map((m) => "${m['menuCode'] ?? m['Menucode']} - ${m['menuDescn'] ?? m['MENU_DESCN']}").toList(),
                  initialValue: parentDisplay,
                  onChanged: _isViewOnly ? null : (v) {
                    if (v == null) return;
                    setState(() {
                      _menuCodeCtrl.text = v.split(' - ').first;
                      _subMenuCodeCtrl.clear();
                    });
                  },
                )),
                AmsField(label: 'SUB MENU', child: AmsDropdown(
                  items: ["0 - No Submenu", ...filteredSubs.map((m) => "${m['subMenuCode'] ?? m['submenucode']} - ${m['description'] ?? m['Decription']}")],
                  initialValue: subDisplay,
                  onChanged: _isViewOnly ? null : (v) {
                    if (v == null) return;
                    setState(() {
                      _subMenuCodeCtrl.text = v.split(' - ').first;
                    });
                  },
                )),
                AmsField(label: 'PROGRAM ID', required: true, child: AmsDropdown(
                  items: _allPrograms.map((p) => "${p['pgmId'] ?? p['programId'] ?? p['PGM_ID']} - ${p['descn'] ?? p['programDescription'] ?? p['description']}").toList(),
                  initialValue: programDisplay,
                  onChanged: _isViewOnly ? null : (v) {
                     if (v == null) return;
                     final pId = v.split(' - ').first;
                     final pg = _allPrograms.firstWhere((p) => (p['pgmId'] ?? p['programId'] ?? p['PGM_ID']).toString() == pId);
                     setState(() {
                        _pgmIdCtrl.text = pId;
                        _descnCtrl.text = (pg['descn'] ?? pg['programDescription'] ?? pg['description'] ?? '').toString();
                        _pathCtrl.text = (pg['programPath'] ?? pg['path'] ?? '').toString();
                     });
                  },
                )),
                AmsField(label: 'DESCRIPTION', required: true, child: AmsTextInput(controller: _descnCtrl, readOnly: _isViewOnly)),
                AmsField(label: 'MENU ORDER', required: true, child: AmsTextInput(controller: _orderCtrl, readOnly: _isViewOnly, keyboardType: TextInputType.number)),
                AmsField(label: 'PROGRAM PATH', child: AmsTextInput(controller: _pathCtrl, readOnly: _isViewOnly)),
                AmsField(label: 'MENU LOGO', child: AmsTextInput(controller: _logoCtrl, readOnly: _isViewOnly)),
                AmsField(label: 'STATUS', child: AmsDropdown(items: const ['1 - Enabled', '0 - Disabled'], initialValue: _status == 1 ? '1 - Enabled' : '0 - Disabled', onChanged: _isViewOnly ? null : (v) => setState(() => _status = v?.startsWith('1') == true ? 1 : 0))),
              ],
            ),
          ),
        ),
        if (!_isViewOnly)
          AmsSubmitBar(
            borderColor: AppColors.border,
            actions: [
              AmsButton(label: 'Save Program Item', onPressed: _submit),
              AmsButton(label: 'Cancel', variant: AmsButtonVariant.danger, onPressed: () => setState(() => _showForm = false)),
            ],
          ),
      ],
    );
  }
}

class _MenuProgramListView extends StatefulWidget {
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onView;
  final Function(Map<String, dynamic>) onDelete;

  const _MenuProgramListView({super.key, required this.onEdit, required this.onView, required this.onDelete});

  @override
  State<_MenuProgramListView> createState() => _MenuProgramListViewState();
}

class _MenuProgramListViewState extends State<_MenuProgramListView> {
  List<Map<String, dynamic>>? _data;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await menuApiService.getMenuPrograms(size: 200);
    setState(() {
      _data = res?.items ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data == null || _data!.isEmpty) return const Center(child: Text('No menu programs found.'));

    return ListView.separated(
      itemCount: _data!.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = _data![index];
        final pId = (r['pgmId'] ?? r['PGM_ID'] ?? r['pgm_Id'] ?? '—').toString();
        final descn = (r['description'] ?? r['Decription'] ?? '—').toString();
        final mCode = (r['menuCode'] ?? r['Menucode'] ?? '—').toString();
        final sCode = (r['subMenuCode'] ?? r['submenucode'] ?? '—').toString();
        final isEnabled = (r['status'] == 1 || r['status'] == '1');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                child: Center(child: Text(pId, style: monoStyle(size: 11, weight: FontWeight.w700))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(descn, style: bodyStyle(weight: FontWeight.w600)),
                    Text('Menu: $mCode / $sCode', style: bodyStyle(size: 11, color: AppColors.ink3)),
                  ],
                ),
              ),
              AmsBadge(label: isEnabled ? 'Active' : 'Disabled', color: isEnabled ? AppColors.green : AppColors.red, background: isEnabled ? AppColors.greenLt : AppColors.redLt),
              IconButton(icon: const Icon(Icons.visibility_rounded, size: 20, color: AppColors.tBlue), onPressed: () => widget.onView(r)),
              IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.ink3), onPressed: () => widget.onEdit(r)),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.red), onPressed: () => widget.onDelete(r)),
            ],
          ),
        );
      },
    );
  }
}
