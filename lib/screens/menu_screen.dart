import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../models/menu_models.dart';
import '../models/models.dart';
import '../theme.dart';

class MenuScreen extends StatefulWidget {
  final VoidCallback onBack;
  final String? userName;

  const MenuScreen({
    super.key,
    required this.onBack,
    this.userName,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
            title: 'Menu Designer',
            subtitle: 'Structure dynamic navigation and UI programs.',
            badges: const [AmsBadge(label: 'System Config')],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: widget.onBack),
              HeaderBreadcrumb(label: 'Masters', onTap: widget.onBack),
              HeaderBreadcrumb(label: 'Menu Designer'),
            ],
            onBack: widget.onBack,
          ),
          
          // Tab Bar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.tBlue,
              unselectedLabelColor: AppColors.ink3,
              indicatorColor: AppColors.tBlue,
              indicatorWeight: 3,
              labelStyle: bodyStyle(weight: FontWeight.w700, size: 14),
              unselectedLabelStyle: bodyStyle(weight: FontWeight.w500, size: 14),
              tabs: const [
                Tab(text: 'Programs (MENU001)'),
                Tab(text: 'Parent Menus (MENU002)'),
                Tab(text: 'Sub Menus (MENU003)'),
                Tab(text: 'Menu Items (MENU004)'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ProgramMasterTab(userName: widget.userName),
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

// ─── TAB 1: PROGRAM MASTER ───────────────────────────────────
class _ProgramMasterTab extends StatefulWidget {
  final String? userName;
  const _ProgramMasterTab({this.userName});

  @override
  State<_ProgramMasterTab> createState() => _ProgramMasterTabState();
}

class _ProgramMasterTabState extends State<_ProgramMasterTab> {
  bool _showForm = false;
  List<Map<String, dynamic>> _items = [];
  int _total = 0;
  bool _loading = true;
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() => _loading = true);
    final res = await apiService.getProgramMaster(page: page - 1);
    if (mounted) {
      setState(() {
        _items = res?.items ?? [];
        _total = res?.totalElements ?? 0;
        _loading = false;
      });
    }
  }

  void _doSubmit() async {
    final success = await apiService.createProgramMaster(_formData);
    if (success) {
      showAmsSnack(context, 'Program created successfully!', type: 's');
      setState(() => _showForm = false);
      _load(1);
    } else {
      showAmsSnack(context, 'Failed to create program.', type: 'e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return _buildForm();
    }
    return _buildList();
  }

  Widget _buildList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Programs: $_total', style: bodyStyle(weight: FontWeight.w600)),
              AmsButton(
                label: 'New Program',
                icon: Icons.add_rounded,
                small: true,
                onPressed: () => setState(() => _showForm = true),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading 
            ? const Center(child: CircularProgressIndicator())
            : AmsPaginatedView<Map<String, dynamic>>(
                items: _items,
                totalRecords: _total,
                onPageChanged: _load,
                builder: (ctx, items) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (ctx, idx) {
                    final p = ProgramMaster.fromJson(items[idx]);
                    return AmsCard(
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: const BoxDecoration(color: AppColors.tBlueLt, shape: BoxShape.circle),
                            child: const Icon(Icons.code_rounded, size: 18, color: AppColors.tBlue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${p.pgmId} - ${p.descn}', style: bodyStyle(weight: FontWeight.w700, size: 14)),
                                Text('Module: ${p.module} | Class: ${p.pgmClass}', style: bodyStyle(color: AppColors.ink3, size: 12)),
                              ],
                            ),
                          ),
                          AmsBadge(label: p.status == 1 ? 'Enabled' : 'Disabled', 
                                   color: p.status == 1 ? AppColors.green : AppColors.red,
                                   background: p.status == 1 ? AppColors.greenLt : AppColors.redLt),
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

  Widget _buildForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AmsCard(
              headLeft: Text('NEW PROGRAM MASTER', style: monoStyle(size: 13, weight: FontWeight.w800, color: AppColors.tBlue)),
              child: AmsFormGrid(
                children: [
                  AmsField(label: 'PGM_ID', required: true, child: AmsTextInput(onChanged: (v) => _formData['pgmId'] = v)),
                  AmsField(label: 'DESCRIPTION', required: true, child: AmsTextInput(onChanged: (v) => _formData['descn'] = v)),
                  AmsField(label: 'MODULE (INT)', required: true, child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['module'] = v)),
                  AmsField(label: 'SUB_MODULE (INT)', child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['subModule'] = v)),
                  AmsField(label: 'PGM_CLASS (INT)', child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['pgmClass'] = v)),
                  AmsField(label: 'STATUS', child: AmsDropdown(items: const ['1 - Enable', '0 - Disable'], onChanged: (v) => _formData['status'] = v?.startsWith('1') == true ? 1 : 0)),
                  AmsField(label: 'REMARKS', child: AmsTextInput(onChanged: (v) => _formData['remarks'] = v)),
                ],
              ),
            ),
          ),
        ),
        AmsSubmitBar(
          borderColor: AppColors.border,
          actions: [
            AmsButton(label: 'Submit', variant: AmsButtonVariant.primary, onPressed: _doSubmit),
            AmsButton(label: 'Cancel', variant: AmsButtonVariant.danger, onPressed: () => setState(() => _showForm = false)),
          ],
        ),
      ],
    );
  }
}

// ─── TAB 2: PARENT MENU ──────────────────────────────────────
class _ParentMenuTab extends StatefulWidget {
  final String? userName;
  const _ParentMenuTab({this.userName});

  @override
  State<_ParentMenuTab> createState() => _ParentMenuTabState();
}

class _ParentMenuTabState extends State<_ParentMenuTab> {
  bool _showForm = false;
  List<Map<String, dynamic>> _items = [];
  int _total = 0;
  bool _loading = true;
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() => _loading = true);
    final res = await apiService.getParentMenus(page: page - 1);
    if (mounted) {
      setState(() {
        _items = res?.items ?? [];
        _total = res?.totalElements ?? 0;
        _loading = false;
      });
    }
  }

  void _doSubmit() async {
    final success = await apiService.createParentMenu(_formData);
    if (success) {
      showAmsSnack(context, 'Parent Menu created!', type: 's');
      setState(() => _showForm = false);
      _load(1);
    } else {
      showAmsSnack(context, 'Error creating parent menu.', type: 'e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) return _buildForm();
    return _buildList();
  }

  Widget _buildList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Parent Menus: $_total', style: bodyStyle(weight: FontWeight.w600)),
              AmsButton(
                label: 'New Parent Menu',
                icon: Icons.add_rounded,
                small: true,
                onPressed: () => setState(() => _showForm = true),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading 
            ? const Center(child: CircularProgressIndicator())
            : AmsPaginatedView<Map<String, dynamic>>(
                items: _items,
                totalRecords: _total,
                onPageChanged: _load,
                builder: (ctx, items) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (ctx, idx) {
                    final p = ParentMenu.fromJson(items[idx]);
                    return AmsCard(
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: const BoxDecoration(color: AppColors.tBlueLt, shape: BoxShape.circle),
                            child: const Icon(Icons.folder_rounded, size: 18, color: AppColors.tBlue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${p.menuCode} - ${p.menuDescn}', style: bodyStyle(weight: FontWeight.w700, size: 14)),
                                Text('Role: ${p.roleCd} | Order: ${p.menuOrder} | Path: ${p.programPath}', style: bodyStyle(color: AppColors.ink3, size: 12)),
                              ],
                            ),
                          ),
                          AmsBadge(label: iif(p.subMenuReq == 1, 'SubReq', 'NoSub'), color: AppColors.ink2, background: AppColors.bg),
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

  String iif(bool condition, String trueVal, String falseVal) => condition ? trueVal : falseVal;

  Widget _buildForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AmsCard(
              headLeft: Text('NEW PARENT MENU CONFIG', style: monoStyle(size: 13, weight: FontWeight.w800, color: AppColors.tBlue)),
              child: AmsFormGrid(
                children: [
                  AmsField(label: 'ROLE CODE', required: true, child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['roleCd'] = v)),
                  AmsField(label: 'MENU_CODE (2 Digit)', required: true, child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['menuCode'] = v)),
                  AmsField(label: 'DESCRIPTION', child: AmsTextInput(onChanged: (v) => _formData['menuDescn'] = v)),
                  AmsField(label: 'MENU_ORDER', child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['menuOrder'] = v)),
                  AmsField(label: 'SUB-MENU REQUIRED?', child: AmsDropdown(items: const ['1 - Yes', '0 - No'], onChanged: (v) => _formData['subMenuReq'] = v?.startsWith('1') == true ? 1 : 0)),
                  AmsField(label: 'LANDING PGM ID', child: AmsTextInput(onChanged: (v) => _formData['parentMenuPgmId'] = v)),
                  AmsField(label: 'PROGRAM PATH', child: AmsTextInput(onChanged: (v) => _formData['programPath'] = v)),
                  AmsField(label: 'MENU_LOGO', child: AmsTextInput(onChanged: (v) => _formData['menuLogo'] = v)),
                  AmsField(label: 'LOCATION', child: AmsDropdown(items: const ['L - Left', 'R - Right', 'C - Center', 'T - Top', 'B - Bottom'], onChanged: (v) => _formData['menuLocation'] = v?.split(' - ')[0])),
                  AmsField(label: 'STATUS', child: AmsDropdown(items: const ['1 - Enabled', '0 - Disabled'], onChanged: (v) => _formData['menuStatus'] = v?.startsWith('1') == true ? 1 : 0)),
                ],
              ),
            ),
          ),
        ),
        AmsSubmitBar(
          borderColor: AppColors.border,
          actions: [
            AmsButton(label: 'Submit', variant: AmsButtonVariant.primary, onPressed: _doSubmit),
            AmsButton(label: 'Cancel', variant: AmsButtonVariant.danger, onPressed: () => setState(() => _showForm = false)),
          ],
        ),
      ],
    );
  }
}

// ─── TAB 3: SUB MENU ─────────────────────────────────────────
class _SubMenuTab extends StatefulWidget {
  final String? userName;
  const _SubMenuTab({this.userName});

  @override
  State<_SubMenuTab> createState() => _SubMenuTabState();
}

class _SubMenuTabState extends State<_SubMenuTab> {
  bool _showForm = false;
  List<Map<String, dynamic>> _items = [];
  int _total = 0;
  bool _loading = true;
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() => _loading = true);
    final res = await apiService.getSubMenus(page: page - 1);
    if (mounted) {
      setState(() {
        _items = res?.items ?? [];
        _total = res?.totalElements ?? 0;
        _loading = false;
      });
    }
  }

  void _doSubmit() async {
    final success = await apiService.createSubMenu(_formData);
    if (success) {
      showAmsSnack(context, 'Sub Menu created!', type: 's');
      setState(() => _showForm = false);
      _load(1);
    } else {
      showAmsSnack(context, 'Error creating sub menu.', type: 'e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) return _buildForm();
    return _buildList();
  }

  Widget _buildList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Sub Menus: $_total', style: bodyStyle(weight: FontWeight.w600)),
              AmsButton(
                label: 'New Sub Menu',
                icon: Icons.add_rounded,
                small: true,
                onPressed: () => setState(() => _showForm = true),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading 
            ? const Center(child: CircularProgressIndicator())
            : AmsPaginatedView<Map<String, dynamic>>(
                items: _items,
                totalRecords: _total,
                onPageChanged: _load,
                builder: (ctx, items) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (ctx, idx) {
                    final s = SubMenu.fromJson(items[idx]);
                    return AmsCard(
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: const BoxDecoration(color: AppColors.tBlueLt, shape: BoxShape.circle),
                            child: const Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: AppColors.tBlue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${s.subMenuCode} - ${s.description}', style: bodyStyle(weight: FontWeight.w700, size: 14)),
                                Text('Parent: ${s.menuCode} | Role: ${s.roleCd} | Path: ${s.programPath}', style: bodyStyle(color: AppColors.ink3, size: 12)),
                              ],
                            ),
                          ),
                          AmsBadge(label: 'Order: ${s.menuOrder}'),
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

  Widget _buildForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AmsCard(
              headLeft: Text('NEW SUB-MENU CONFIG', style: monoStyle(size: 13, weight: FontWeight.w800, color: AppColors.tBlue)),
              child: AmsFormGrid(
                children: [
                  AmsField(label: 'ROLE CODE', required: true, child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['roleCd'] = v)),
                  AmsField(label: 'PARENT MENU CODE', required: true, child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['menuCode'] = v)),
                  AmsField(label: 'SUB-MENU CODE', required: true, child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['subMenuCode'] = v)),
                  AmsField(label: 'DESCRIPTION', child: AmsTextInput(onChanged: (v) => _formData['description'] = v)),
                  AmsField(label: 'MENU_ORDER', child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['menuOrder'] = v)),
                  AmsField(label: 'SUB PGM ID', child: AmsTextInput(onChanged: (v) => _formData['subMenuPgmId'] = v)),
                  AmsField(label: 'PROGRAM PATH', child: AmsTextInput(onChanged: (v) => _formData['programPath'] = v)),
                  AmsField(label: 'MENU_LOGO', child: AmsTextInput(onChanged: (v) => _formData['menuLogo'] = v)),
                  AmsField(label: 'STATUS', child: AmsDropdown(items: const ['1 - Enabled', '0 - Disabled'], onChanged: (v) => _formData['menuStatus'] = v?.startsWith('1') == true ? 1 : 0)),
                ],
              ),
            ),
          ),
        ),
        AmsSubmitBar(
          borderColor: AppColors.border,
          actions: [
            AmsButton(label: 'Submit', variant: AmsButtonVariant.primary, onPressed: _doSubmit),
            AmsButton(label: 'Cancel', variant: AmsButtonVariant.danger, onPressed: () => setState(() => _showForm = false)),
          ],
        ),
      ],
    );
  }
}

// ─── TAB 4: MENU PROGRAM ──────────────────────────────────────
class _MenuProgramTab extends StatefulWidget {
  final String? userName;
  const _MenuProgramTab({this.userName});

  @override
  State<_MenuProgramTab> createState() => _MenuProgramTabState();
}

class _MenuProgramTabState extends State<_MenuProgramTab> {
  bool _showForm = false;
  List<Map<String, dynamic>> _items = [];
  int _total = 0;
  bool _loading = true;
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() => _loading = true);
    final res = await apiService.getMenuPrograms(page: page - 1);
    if (mounted) {
      setState(() {
        _items = res?.items ?? [];
        _total = res?.totalElements ?? 0;
        _loading = false;
      });
    }
  }

  void _doSubmit() async {
    final success = await apiService.createMenuProgram(_formData);
    if (success) {
      showAmsSnack(context, 'Menu Item assigned!', type: 's');
      setState(() => _showForm = false);
      _load(1);
    } else {
      showAmsSnack(context, 'Error assigning menu item.', type: 'e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) return _buildForm();
    return _buildList();
  }

  Widget _buildList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Menu Items: $_total', style: bodyStyle(weight: FontWeight.w600)),
              AmsButton(
                label: 'Assign Program',
                icon: Icons.add_link_rounded,
                small: true,
                onPressed: () => setState(() => _showForm = true),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading 
            ? const Center(child: CircularProgressIndicator())
            : AmsPaginatedView<Map<String, dynamic>>(
                items: _items,
                totalRecords: _total,
                onPageChanged: _load,
                builder: (ctx, items) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (ctx, idx) {
                    final m = MenuProgram.fromJson(items[idx]);
                    return AmsCard(
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: const BoxDecoration(color: AppColors.tBlueLt, shape: BoxShape.circle),
                            child: const Icon(Icons.link_rounded, size: 18, color: AppColors.tBlue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${m.pgmId} - ${m.description}', style: bodyStyle(weight: FontWeight.w700, size: 14)),
                                Text('Menu: ${m.menuCode} | Sub: ${m.subMenuCode} | Role: ${m.roleCd}', style: bodyStyle(color: AppColors.ink3, size: 12)),
                              ],
                            ),
                          ),
                          AmsBadge(label: 'Order: ${m.menuOrder}'),
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

  Widget _buildForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AmsCard(
              headLeft: Text('ASSIGN PROGRAM TO MENU', style: monoStyle(size: 13, weight: FontWeight.w800, color: AppColors.tBlue)),
              child: AmsFormGrid(
                children: [
                  AmsField(label: 'ROLE CODE', required: true, child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['roleCd'] = v)),
                  AmsField(label: 'PARENT MENU CODE', required: true, child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['menuCode'] = v)),
                  AmsField(label: 'SUB-MENU CODE (0 if None)', child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['subMenuCode'] = v)),
                  AmsField(label: 'PGM_ID', required: true, child: AmsTextInput(onChanged: (v) => _formData['pgmId'] = v)),
                  AmsField(label: 'DESCRIPTION', child: AmsTextInput(onChanged: (v) => _formData['description'] = v)),
                  AmsField(label: 'MENU_ORDER', child: AmsTextInput(keyboardType: TextInputType.number, onChanged: (v) => _formData['menuOrder'] = v)),
                  AmsField(label: 'PROGRAM PATH', child: AmsTextInput(onChanged: (v) => _formData['programPath'] = v)),
                  AmsField(label: 'MENU_LOGO', child: AmsTextInput(onChanged: (v) => _formData['menuLogo'] = v)),
                  AmsField(label: 'STATUS', child: AmsDropdown(items: const ['1 - Enabled', '0 - Disabled'], onChanged: (v) => _formData['status'] = v?.startsWith('1') == true ? 1 : 0)),
                ],
              ),
            ),
          ),
        ),
        AmsSubmitBar(
          borderColor: AppColors.border,
          actions: [
            AmsButton(label: 'Submit', variant: AmsButtonVariant.primary, onPressed: _doSubmit),
            AmsButton(label: 'Cancel', variant: AmsButtonVariant.danger, onPressed: () => setState(() => _showForm = false)),
          ],
        ),
      ],
    );
  }
}
