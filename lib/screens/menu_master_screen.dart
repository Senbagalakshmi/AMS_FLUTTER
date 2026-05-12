import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ams_flutter/theme.dart';
import 'package:ams_flutter/models/models.dart';
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

class _MenuMasterScreenState extends State<MenuMasterScreen> {
  bool _showForm = false;
  bool _loading = false;
  int _listVersion = 0;

  // Form State
  bool _isSubMenuReq = false;
  bool _isViewOnly = false;
  Map<String, dynamic>? _selectedRecord;

  // Controllers - Parent
  final _pCodeCtrl = TextEditingController();
  final _pDescnCtrl = TextEditingController();
  final _pOrderCtrl = TextEditingController(text: '1');
  final _pPgmIdCtrl = TextEditingController();
  final _pPathCtrl = TextEditingController();
  final _pLogoCtrl = TextEditingController();
  String _pLoc = 'L - Left';
  int _pStatus = 1;

  // Controllers - Sub Menu
  final _sCodeCtrl = TextEditingController();
  final _sDescnCtrl = TextEditingController();
  final _sOrderCtrl = TextEditingController(text: '1');
  final _sPgmIdCtrl = TextEditingController();
  final _sPathCtrl = TextEditingController();
  final _sLogoCtrl = TextEditingController();
  int _sStatus = 1;

  // Controllers - Program Item
  final _pgmIdCtrl = TextEditingController();
  final _pgmDescnCtrl = TextEditingController();
  final _pgmOrderCtrl = TextEditingController(text: '1');
  final _pgmPathCtrl = TextEditingController();
  final _pgmLogoCtrl = TextEditingController();
  int _pgmStatus = 1;

  List<Map<String, dynamic>> _allPrograms = [];

  @override
  void initState() {
    super.initState();
    menuApiService.updateToken(main.apiService.token);
    _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    final res = await menuApiService.getProgramMaster(size: 1000);
    setState(() {
      _allPrograms = res?.items ?? [];
    });
  }

  void _resetForm() {
    _pCodeCtrl.clear(); _pDescnCtrl.clear(); _pOrderCtrl.text = '1';
    _pPgmIdCtrl.clear(); _pPathCtrl.clear(); _pLogoCtrl.clear();
    _pLoc = 'L - Left'; _pStatus = 1;

    _sCodeCtrl.clear(); _sDescnCtrl.clear(); _sOrderCtrl.text = '1';
    _sPgmIdCtrl.clear(); _sPathCtrl.clear(); _sLogoCtrl.clear();
    _sStatus = 1;

    _pgmIdCtrl.clear(); _pgmDescnCtrl.clear(); _pgmOrderCtrl.text = '1';
    _pgmPathCtrl.clear(); _pgmLogoCtrl.clear();
    _pgmStatus = 1;

    _isSubMenuReq = false;
    _isViewOnly = false;
    _selectedRecord = null;
  }

  Future<void> _submit() async {
    if (_pCodeCtrl.text.isEmpty || _pDescnCtrl.text.isEmpty) {
      showAmsSnack(context, 'Parent Menu Code and Description are required', type: 'w');
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. Save Parent Menu
      final pData = {
        'menuCode': int.tryParse(_pCodeCtrl.text),
        'menuDescn': _pDescnCtrl.text,
        'menuOrder': int.tryParse(_pOrderCtrl.text) ?? 1,
        'subMenuReq': _isSubMenuReq ? 1 : 0,
        'pgmId': _pPgmIdCtrl.text,
        'programPath': _pPathCtrl.text,
        'menuLogo': _pLogoCtrl.text,
        'menuLocation': _pLoc.substring(0, 1),
        'menuStatus': _pStatus,
        'eUser': widget.userName ?? 'admin',
      };
      
      bool ok = await menuApiService.createParentMenu(pData);
      if (!ok) throw Exception('Failed to save Parent Menu');

      // 2. Save Sub Menu if Required
      if (_isSubMenuReq) {
        if (_sCodeCtrl.text.isEmpty || _sDescnCtrl.text.isEmpty) {
           throw Exception('Sub Menu Code and Description are required when Sub Menu is enabled');
        }
        final sData = {
          'menuCode': int.tryParse(_pCodeCtrl.text),
          'subMenuCode': int.tryParse(_sCodeCtrl.text),
          'description': _sDescnCtrl.text,
          'menuOrder': int.tryParse(_sOrderCtrl.text) ?? 1,
          'subMenuPgmId': _sPgmIdCtrl.text,
          'programPath': _sPathCtrl.text,
          'menuLogo': _sLogoCtrl.text,
          'menuStatus': _sStatus,
          'eUser': widget.userName ?? 'admin',
        };
        ok = await menuApiService.createSubMenu(sData);
        if (!ok) throw Exception('Failed to save Sub Menu');

        // 3. Save Program Item (Optional but recommended if sub menu is used)
        if (_pgmIdCtrl.text.isNotEmpty) {
           final prgData = {
              'menuCode': int.tryParse(_pCodeCtrl.text),
              'subMenuCode': int.tryParse(_sCodeCtrl.text),
              'pgmId': _pgmIdCtrl.text,
              'description': _pgmDescnCtrl.text,
              'menuOrder': int.tryParse(_pgmOrderCtrl.text) ?? 1,
              'programPath': _pgmPathCtrl.text,
              'menuLogo': _pgmLogoCtrl.text,
              'status': _pgmStatus,
              'eUser': widget.userName ?? 'admin',
           };
           await menuApiService.createMenuProgram(prgData);
        }
      }

      showAmsSnack(context, 'Menu Hierarchy saved successfully! ✅');
      setState(() {
        _showForm = false;
        _listVersion++;
      });
    } catch (e) {
      showAmsSnack(context, e.toString().replaceAll('Exception: ', ''), type: 'e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AmsIdentityHeader(
            icon: const Icon(Icons.account_tree_rounded, size: 28, color: AppColors.tBlue),
            title: 'Unified Menu Master',
            subtitle: 'Manage parent menus, submenus, and programs in a single view.',
            badges: [
              AmsBadge(
                label: _showForm ? 'Unified Entry' : 'Hierarchy List',
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
            onBack: _showForm ? () => setState(() => _showForm = false) : widget.onBack,
            actions: [
              if (!_showForm)
                AmsButton(
                  label: 'New Menu Path',
                  icon: Icons.add_circle_outline_rounded,
                  small: true,
                  backgroundColor: AppColors.sidebar,
                  onPressed: () {
                    _resetForm();
                    setState(() => _showForm = true);
                  },
                ),
            ],
          ),
          Expanded(
            child: _showForm ? _buildUnifiedForm() : _buildHierarchyList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyList() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.list_alt_rounded, size: 20, color: AppColors.ink3),
                const SizedBox(width: 12),
                Text('Navigation Explorer', style: bodyStyle(weight: FontWeight.w700, color: AppColors.sidebar)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => setState(() => _listVersion++),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _MenuHierarchyView(
              key: ValueKey('hierarchy_$_listVersion'),
              onEdit: (r) {
                // To keep it simple, we focus on NEW unified creation as requested.
                // Editing can still be done by drill down if needed.
                showAmsSnack(context, 'Edit mode: Use individual maintenance or Create New path.', type: 'i');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _formSectionHeader('1. PARENT MENU DETAILS', Icons.folder_rounded),
                AmsFormGrid(children: [
                  AmsField(label: 'MENU CODE', required: true, child: AmsTextInput(controller: _pCodeCtrl, keyboardType: TextInputType.number)),
                  AmsField(label: 'DESCRIPTION', required: true, child: AmsTextInput(controller: _pDescnCtrl)),
                  AmsField(label: 'ORDER', child: AmsTextInput(controller: _pOrderCtrl, keyboardType: TextInputType.number)),
                  AmsField(label: 'LOCATION', child: AmsDropdown(items: const ['L - Left', 'R - Right', 'T - Top'], initialValue: _pLoc, onChanged: (v) => setState(() => _pLoc = v!))),
                  AmsField(label: 'SUB MENU REQUIRED?', required: true, child: _booleanToggle(
                    value: _isSubMenuReq, 
                    onChanged: (v) => setState(() => _isSubMenuReq = v),
                  )),
                  AmsField(label: 'STATUS', child: AmsDropdown(items: const ['1 - Enabled', '0 - Disabled'], initialValue: _pStatus == 1 ? '1 - Enabled' : '0 - Disabled', onChanged: (v) => setState(() => _pStatus = v!.startsWith('1') ? 1 : 0))),
                ]),

                if (!_isSubMenuReq) ...[
                  const SizedBox(height: 24),
                  _formSectionHeader('DIRECT PROGRAM MAPPING', Icons.link_rounded),
                  AmsFormGrid(children: [
                    AmsField(label: 'PROGRAM ID', child: _programDropdown(_pPgmIdCtrl, _pPathCtrl, _pDescnCtrl)),
                    AmsField(label: 'PROGRAM PATH', child: AmsTextInput(controller: _pPathCtrl)),
                    AmsField(label: 'ICON/LOGO', child: AmsTextInput(controller: _pLogoCtrl)),
                  ]),
                ],

                if (_isSubMenuReq) ...[
                  const SizedBox(height: 32),
                  _formSectionHeader('2. SUB MENU DETAILS', Icons.folder_zip_rounded),
                  AmsFormGrid(children: [
                    AmsField(label: 'SUB CODE', required: true, child: AmsTextInput(controller: _sCodeCtrl, keyboardType: TextInputType.number)),
                    AmsField(label: 'SUB DESCRIPTION', required: true, child: AmsTextInput(controller: _sDescnCtrl)),
                    AmsField(label: 'SUB ORDER', child: AmsTextInput(controller: _sOrderCtrl, keyboardType: TextInputType.number)),
                    AmsField(label: 'SUB STATUS', child: AmsDropdown(items: const ['1 - Enabled', '0 - Disabled'], initialValue: _sStatus == 1 ? '1 - Enabled' : '0 - Disabled', onChanged: (v) => setState(() => _sStatus = v!.startsWith('1') ? 1 : 0))),
                  ]),

                  const SizedBox(height: 32),
                  _formSectionHeader('3. MENU PROGRAM ITEM', Icons.apps_rounded),
                  AmsFormGrid(children: [
                    AmsField(label: 'MODULE PROGRAM', child: _programDropdown(_pgmIdCtrl, _pgmPathCtrl, _pgmDescnCtrl)),
                    AmsField(label: 'PGM DESCRIPTION', child: AmsTextInput(controller: _pgmDescnCtrl)),
                    AmsField(label: 'PGM ORDER', child: AmsTextInput(controller: _pgmOrderCtrl, keyboardType: TextInputType.number)),
                    AmsField(label: 'PGM PATH', child: AmsTextInput(controller: _pgmPathCtrl)),
                    AmsField(label: 'PGM LOGO', child: AmsTextInput(controller: _pgmLogoCtrl)),
                  ]),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        AmsSubmitBar(
          borderColor: AppColors.border,
          actions: [
            if (_loading)
               const CircularProgressIndicator()
            else
               AmsButton(label: 'Save Unified Configuration', icon: Icons.save_rounded, backgroundColor: AppColors.sidebar, onPressed: _submit),
            AmsButton(label: 'Cancel', variant: AmsButtonVariant.outline, onPressed: () => setState(() => _showForm = false)),
          ],
        ),
      ],
    );
  }

  Widget _formSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.tBlue),
              const SizedBox(width: 8),
              Text(title, style: bodyStyle(weight: FontWeight.w800, size: 12, color: AppColors.tBlue, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 4),
          Container(width: 40, height: 2, decoration: BoxDecoration(color: AppColors.tBlue, borderRadius: BorderRadius.circular(1))),
        ],
      ),
    );
  }

  Widget _booleanToggle({required bool value, required ValueChanged<bool> onChanged}) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: value ? AppColors.tBlueLt : Colors.white,
                border: Border.all(color: value ? AppColors.tBlue : AppColors.border),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
              child: Center(child: Text('YES', style: bodyStyle(weight: value ? FontWeight.w700 : FontWeight.w500, color: value ? AppColors.tBlue : AppColors.ink3))),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: !value ? AppColors.redLt : Colors.white,
                border: Border.all(color: !value ? AppColors.red : AppColors.border),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
              ),
              child: Center(child: Text('NO', style: bodyStyle(weight: !value ? FontWeight.w700 : FontWeight.w500, color: !value ? AppColors.red : AppColors.ink3))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _programDropdown(TextEditingController idCtrl, TextEditingController pathCtrl, TextEditingController descnCtrl) {
    String? current;
    if (idCtrl.text.isNotEmpty) {
      final found = _allPrograms.where((p) => (p['pgmId'] ?? p['programId'] ?? p['PGM_ID']).toString() == idCtrl.text).firstOrNull;
      if (found != null) {
        current = "${found['pgmId'] ?? found['programId'] ?? found['PGM_ID']} - ${found['descn'] ?? found['programDescription'] ?? found['description']}";
      }
    }

    return AmsDropdown(
      items: _allPrograms.map((p) => "${p['pgmId'] ?? p['programId'] ?? p['PGM_ID']} - ${p['descn'] ?? p['programDescription'] ?? p['description']}").toList(),
      initialValue: current,
      placeholder: 'Select Program',
      onChanged: (v) {
        if (v == null) return;
        final parts = v.split(' - ');
        final id = parts.first;
        final pg = _allPrograms.firstWhere((p) => (p['pgmId'] ?? p['programId'] ?? p['PGM_ID']).toString() == id);
        setState(() {
          idCtrl.text = id;
          pathCtrl.text = (pg['programPath'] ?? pg['path'] ?? '').toString();
          descnCtrl.text = (pg['descn'] ?? pg['programDescription'] ?? pg['description'] ?? '').toString();
        });
      },
    );
  }
}

class _MenuHierarchyView extends StatefulWidget {
  final Function(Map<String, dynamic>) onEdit;
  const _MenuHierarchyView({super.key, required this.onEdit});

  @override
  State<_MenuHierarchyView> createState() => _MenuHierarchyViewState();
}

class _MenuHierarchyViewState extends State<_MenuHierarchyView> {
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _subs = [];
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  int _totalItems = 0;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadAll(1);
  }

  Future<void> _loadAll(int page) async {
    setState(() {
      _loading = true;
      _currentPage = page;
    });
    // We paginate parents, but for now we fetch all subs/items for simplicity in building the tree
    final pRes = await menuApiService.getParentMenus(page: page - 1, size: 10);
    final sRes = await menuApiService.getSubMenus(size: 1000);
    final iRes = await menuApiService.getMenuPrograms(size: 1000);
    setState(() {
      _parents = pRes?.items ?? [];
      _totalItems = pRes?.totalElements ?? 0;
      _subs = sRes?.items ?? [];
      _items = iRes?.items ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_parents.isEmpty) return const Center(child: Text('No menu structure found. Click "New Menu Path" to start.'));

    return AmsPaginatedView<Map<String, dynamic>>(
      items: _parents,
      totalRecords: _totalItems,
      currentPage: _currentPage,
      forceShowFooter: true,
      onPageChanged: (page) => _loadAll(page),
      builder: (context, currentParents) => ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: currentParents.length,
        itemBuilder: (context, idx) {
          final p = currentParents[idx];
          final pCode = (p['menuCode'] ?? p['Menucode']).toString();
          final pName = (p['menu_Descn'] ?? p['menuDescn'] ?? p['MENU_DESCN'] ?? 'Untitled Parent').toString();
          final hasSub = (p['subMenuReq'] == 1 || p['SUBMENUREQ'] == 1);

          final pSubs = _subs.where((s) => (s['menuCode'] ?? s['Menucode']).toString() == pCode).toList();

          return ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.tBlueLt, borderRadius: BorderRadius.circular(4)),
              child: Text(pCode, style: bodyStyle(weight: FontWeight.w700, color: AppColors.tBlue, size: 12)),
            ),
            title: Text(pName, style: bodyStyle(weight: FontWeight.w700, size: 14)),
            subtitle: Text(hasSub ? '${pSubs.length} Submenus' : 'Direct Link', style: bodyStyle(size: 11, color: AppColors.ink3)),
            children: [
              if (!hasSub)
                 _buildDirectProgram(pCode)
              else
                 ...pSubs.map((s) => _buildSubMenuTile(pCode, s)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDirectProgram(String pCode) {
    final direct = _items.where((i) => (i['menuCode'] ?? i['Menucode']).toString() == pCode && (i['subMenuCode'] ?? i['submenucode']).toString() == '0').firstOrNull;
    if (direct == null) return const ListTile(title: Text('No program mapped', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)));
    
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      leading: const Icon(Icons.link_rounded, size: 16, color: AppColors.green),
      title: Text((direct['description'] ?? direct['Decription'] ?? 'Unknown').toString(), style: bodyStyle(size: 13, weight: FontWeight.w500)),
      trailing: Text((direct['pgmId'] ?? direct['PGM_ID'] ?? '').toString(), style: monoStyle(size: 11)),
    );
  }

  Widget _buildSubMenuTile(String pCode, Map<String, dynamic> sub) {
    final sCode = (sub['subMenuCode'] ?? sub['submenucode']).toString();
    final sName = (sub['description'] ?? sub['Decription'] ?? 'Untitled Sub').toString();
    
    final sItems = _items.where((i) => (i['menuCode'] ?? i['Menucode']).toString() == pCode && (i['subMenuCode'] ?? i['submenucode']).toString() == sCode).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: ExpansionTile(
        leading: const Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: AppColors.ink3),
        title: Text(sName, style: bodyStyle(weight: FontWeight.w600, size: 13)),
        children: sItems.map((i) => ListTile(
          contentPadding: const EdgeInsets.only(left: 60, right: 16),
          leading: const Icon(Icons.circle, size: 6, color: AppColors.tBlue),
          title: Text((i['description'] ?? i['Decription'] ?? 'Item').toString(), style: bodyStyle(size: 12)),
          trailing: Text((i['pgmId'] ?? i['PGM_ID'] ?? '').toString(), style: monoStyle(size: 10)),
        )).toList(),
      ),
    );
  }
}
