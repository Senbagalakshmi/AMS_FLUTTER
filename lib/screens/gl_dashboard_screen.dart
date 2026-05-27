import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/widgets.dart';
import '../theme.dart';
import '../data.dart';
import '../screens/submenu_dashboard_screen.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import '../services/gl_api_service.dart';

class GlDashboardScreen extends StatefulWidget {
  final List<SubmenuItem> items;
  final void Function(String screen, String? prog) onNavigate;
  final VoidCallback onBack;
  final String? userName;

  const GlDashboardScreen({
    super.key,
    required this.items,
    required this.onNavigate,
    required this.onBack,
    this.userName,
  });

  @override
  State<GlDashboardScreen> createState() => _GlDashboardScreenState();
}

class _GlDashboardScreenState extends State<GlDashboardScreen> with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0: Overview, 1: Table, 2: Gantt
  int _selectedScenario = 0;
  late AnimationController _entryController;

  final GLApiService _glApiService = GLApiService();
  int _glCategoriesCount = 0;
  int _ledgerMastersCount = 0;
  int _branchesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedScenario = 0; // Explicitly ensure 0 on start
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final glCategories = await apiService.getAllGlCategories(size: 1);
      final ledgerMasters = await _glApiService.getGlList();
      final branches = await _glApiService.getGl104List();

      if (mounted) {
        setState(() {
          _glCategoriesCount = glCategories?.totalElements ?? 0;
          _ledgerMastersCount = ledgerMasters?.length ?? 0;
          _branchesCount = branches.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 PREMIUM HEADER
          _buildHeader(),

          // 🔹 TAB NAV
          _buildTabNav(),

          const Divider(height: 1, color: AppColors.border),

          // 🔹 VIEW CONTENT
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_activeTab) {
      case 0: return _buildOverview();
      case 1: return _buildMainTable();
      case 2: return _buildGanttView();
      default: return _buildOverview();
    }
  }

  Widget _buildHeader() {
    final isMobile = Responsive.isMobile(context);
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 16, isMobile ? 12 : 20, 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.ink2, size: 20),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 4),
              _Animated3DIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GL Intelligence Dashboard',
                      style: bodyStyle(size: isMobile ? 16 : 20, weight: FontWeight.w800, color: AppColors.ink),
                    ),
                    Text(
                      isMobile ? 'Financial ledger control' : 'Real-time financial analysis & ledger control',
                      style: bodyStyle(size: 11, color: AppColors.ink3),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                _HeaderMetric(label: 'Health', value: '${96 + (_selectedScenario % 4)}%'),
                const SizedBox(width: 16),
                _HeaderMetric(
                  label: 'Status', 
                  value: _selectedScenario % 2 == 0 ? 'Syncing' : 'Optimized'
                ),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _HeaderMetric(label: 'Health', value: '${96 + (_selectedScenario % 4)}%'),
                _HeaderMetric(
                  label: 'Status', 
                  value: _selectedScenario % 2 == 0 ? 'Syncing' : 'Optimized'
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabNav() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _TabItem(
              label: 'Overview',
              icon: Icons.dashboard_customize_rounded,
              isActive: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
            ),
            const SizedBox(width: 8),
            _TabItem(
              label: 'Data Grid',
              icon: Icons.table_chart_rounded,
              isActive: _activeTab == 1,
              onTap: () => setState(() => _activeTab = 1),
            ),
            const SizedBox(width: 8),
            _TabItem(
              label: 'Timeline',
              icon: Icons.analytics_rounded,
              isActive: _activeTab == 2,
              onTap: () => setState(() => _activeTab = 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final List<SubmenuItem> scenarios = widget.items;
    final isMobile = Responsive.isMobile(context);
    
    if (scenarios.isEmpty) {
      return Center(child: Text('No GL Scenarios available', style: bodyStyle(size: 16, color: AppColors.ink4)));
    }

    final int itemsCount = scenarios.length;
    final int safeIndex = (_selectedScenario >= 0 && _selectedScenario < itemsCount) 
        ? _selectedScenario 
        : 0;
    
    final selectedItem = scenarios[safeIndex];

    final summaryCards = [
      _SummaryCard3D(
        title: 'GL Categories',
        value: _isLoading ? '...' : _glCategoriesCount.toString(),
        icon: Icons.category_rounded,
        color: const Color(0xFF6366F1),
        delay: 0,
      ),
      _SummaryCard3D(
        title: 'Ledger Masters',
        value: _isLoading ? '...' : _ledgerMastersCount.toString(),
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF10B981),
        delay: 0.05,
      ),
      _SummaryCard3D(
        title: 'Branches',
        value: _isLoading ? '...' : _branchesCount.toString(),
        icon: Icons.business_rounded,
        color: const Color(0xFFEF4444),
        delay: 0.1,
      ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            ...summaryCards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c))
          else
            Row(
              children: summaryCards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: c))).toList(),
            ),
          const SizedBox(height: 20),

          if (isMobile)
            Column(
              children: [
                _ChartFrame(
                  title: 'Ledger Composition',
                  onRefresh: _fetchDashboardData,
                  child: _ModernPieChart(items: widget.items, type: PieType.distribution, seed: safeIndex.abs()),
                ),
                const SizedBox(height: 16),
                _ChartFrame(
                  title: 'Authorization Integrity',
                  onRefresh: _fetchDashboardData,
                  child: _ModernPieChart(items: widget.items, type: PieType.authorization, seed: (safeIndex + 10).abs()),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ChartFrame(
                    title: 'Ledger Composition: ${selectedItem.label}',
                    onRefresh: _fetchDashboardData,
                    child: _ModernPieChart(items: widget.items, type: PieType.distribution, seed: safeIndex.abs()),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _ChartFrame(
                    title: 'Authorization Integrity: ${selectedItem.label}',
                    onRefresh: _fetchDashboardData,
                    child: _ModernPieChart(items: widget.items, type: PieType.authorization, seed: (safeIndex + 10).abs()),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),

          if (isMobile)
            Column(
              children: [
                _ChartFrame(
                  title: 'Top GL Scenarios',
                  onRefresh: _fetchDashboardData,
                  child: _ScenarioAuthorizationPipeline(
                    items: widget.items.take(5).toList(),
                    selectedIndex: safeIndex,
                    onSelect: (idx) => setState(() => _selectedScenario = idx),
                  ),
                ),
                const SizedBox(height: 16),
                _ChartFrame(
                  title: 'Module Intelligence',
                  onRefresh: _fetchDashboardData,
                  child: _ModuleIntelligencePanel(selectedItem: selectedItem),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _ChartFrame(
                    title: 'Top GL Scenarios',
                    onRefresh: _fetchDashboardData,
                    child: _ScenarioAuthorizationPipeline(
                      items: widget.items.take(5).toList(),
                      selectedIndex: safeIndex,
                      onSelect: (idx) => setState(() => _selectedScenario = idx),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _ChartFrame(
                    title: 'Module Intelligence',
                    onRefresh: _fetchDashboardData,
                    child: _ModuleIntelligencePanel(selectedItem: selectedItem),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMainTable() {
    final setupItems = widget.items.where((i) => ['GL-CAT', 'GL-MST', 'GL-MAT', 'GL-SEG'].contains(i.programId)).toList();
    final controlItems = widget.items.where((i) => !setupItems.contains(i)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _MondayGroup(
            title: 'Core Ledger Setup',
            color: const Color(0xFF579BFF),
            items: setupItems,
            onNavigate: widget.onNavigate,
          ),
          const SizedBox(height: 32),
          _MondayGroup(
            title: 'Control Parameters',
            color: const Color(0xFF00C875),
            items: controlItems,
            onNavigate: widget.onNavigate,
          ),
        ],
      ),
    );
  }

  Widget _buildGanttView() {
    return _GanttChart(items: widget.items);
  }
}

// -----------------------------------------------------------------------------
// UI COMPONENTS
// -----------------------------------------------------------------------------

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: bodyStyle(size: 10, color: AppColors.ink4, weight: FontWeight.w700)),
        Text(value, style: bodyStyle(size: 14, color: AppColors.ink, weight: FontWeight.w800)),
      ],
    );
  }
}

class _Animated3DIcon extends StatefulWidget {
  @override
  State<_Animated3DIcon> createState() => _Animated3DIconState();
}

class _Animated3DIconState extends State<_Animated3DIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.005)
              ..rotateY(_ctrl.value * 6.28),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE2445C), Color(0xFFF16E80)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE2445C).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
            ),
          );
        },
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({required this.label, required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isActive ? AppColors.tBlue : Colors.transparent, width: 3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isActive ? AppColors.tBlue : AppColors.ink3),
            const SizedBox(width: 8),
            Text(label, style: bodyStyle(size: 14, weight: isActive ? FontWeight.w800 : FontWeight.w500, color: isActive ? AppColors.tBlue : AppColors.ink3)),
          ],
        ),
      ),
    );
  }
}

class _ChartFrame extends StatefulWidget {
  final String title;
  final Widget child;
  final VoidCallback? onRefresh;
  const _ChartFrame({required this.title, required this.child, this.onRefresh});

  @override
  State<_ChartFrame> createState() => _ChartFrameState();
}

class _ChartFrameState extends State<_ChartFrame> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    widget.onRefresh?.call();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: bodyStyle(size: 16, weight: FontWeight.w800, color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: _isRefreshing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.tBlue)))
                  : const Icon(Icons.more_horiz_rounded, color: AppColors.ink4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'export', child: Row(children: [const Icon(Icons.download_rounded, size: 18), const SizedBox(width: 8), Text('Export Data', style: bodyStyle(size: 13))])),
                  PopupMenuItem(value: 'refresh', child: Row(children: [const Icon(Icons.refresh_rounded, size: 18), const SizedBox(width: 8), Text('Refresh', style: bodyStyle(size: 13))])),
                ],
                onSelected: (val) {
                  if (val == 'refresh') _handleRefresh();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isRefreshing ? 0.3 : 1.0,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard3D extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double delay;

  const _SummaryCard3D({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  State<_SummaryCard3D> createState() => _SummaryCard3DState();
}
class _SummaryCard3DState extends State<_SummaryCard3D> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Interval(widget.delay, 1.0, curve: Curves.easeOutBack),
        builder: (context, anim, _) {
          return Opacity(
            opacity: anim.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - anim.clamp(0.0, 1.0))),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 120,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, _isHovered ? widget.color.withOpacity(0.05) : Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isHovered ? widget.color : AppColors.border, width: _isHovered ? 2 : 1),
                    boxShadow: [
                      BoxShadow(
                        color: _isHovered ? widget.color.withOpacity(0.1) : Colors.black.withOpacity(0.03),
                        blurRadius: _isHovered ? 20 : 10,
                        offset: Offset(0, _isHovered ? 12 : 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title, style: bodyStyle(size: 13, color: AppColors.ink2, weight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            Text(widget.value, style: bodyStyle(size: 24, weight: FontWeight.w900, color: AppColors.ink)),
                          ],
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
    );
  }
}

// -----------------------------------------------------------------------------
// CHARTS
// -----------------------------------------------------------------------------

enum PieType { distribution, authorization }

class _ModernPieChart extends StatefulWidget {
  final List<SubmenuItem> items;
  final PieType type;
  final int seed;
  const _ModernPieChart({required this.items, required this.type, this.seed = 0});

  @override
  State<_ModernPieChart> createState() => _ModernPieChartState();
}

class _ModernPieChartState extends State<_ModernPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final bool isDist = widget.type == PieType.distribution;
    return RepaintBoundary(
      child: SizedBox(
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              key: ValueKey('pie_${widget.type}_${widget.seed}'),
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 8.0,
                centerSpaceRadius: 70.0,
                startDegreeOffset: -90.0,
                sections: isDist ? _getDistSections() : _getAuthSections(),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isDist ? 'STRUCTURE' : 'INTEGRITY', style: bodyStyle(size: 10, color: AppColors.ink4, weight: FontWeight.w800, letterSpacing: 1)),
                Text(isDist ? 'Global' : 'Secure', style: bodyStyle(size: 18, color: AppColors.ink, weight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getDistSections() {
    final s = widget.seed;
    return [
      _pieSection(0, 35.0 + (s % 12), 'Income', const Color(0xFF34D399), Icons.trending_up_rounded), // Lighter Green
      _pieSection(1, 25.0 - (s % 8), 'Asset', const Color(0xFF818CF8), Icons.account_balance_rounded), // Lighter Indigo
      _pieSection(2, 25.0 + (s % 5), 'Liability', const Color(0xFFFBBF24), Icons.account_balance_wallet_rounded), // Lighter Amber
      _pieSection(3, 15.0 - (s % 3), 'Expense', const Color(0xFFFB7185), Icons.trending_down_rounded), // Lighter Rose/Red
    ];
  }

  List<PieChartSectionData> _getAuthSections() {
    final s = widget.seed;
    return [
      _pieSection(0, 40.0 - (s % 10), 'Approver', const Color(0xFF818CF8), Icons.verified_user_rounded), // Lighter Purple
      _pieSection(1, 30.0 + (s % 5), 'Checker', const Color(0xFFFDBA74), Icons.fact_check_rounded), // Lighter Orange
      _pieSection(2, 20.0 + (s % 8), 'Maker', const Color(0xFF38BDF8), Icons.edit_note_rounded), // Lighter Sky Blue
      _pieSection(3, 10.0, 'Posted', const Color(0xFFF472B6), Icons.cloud_done_rounded), // Lighter Pink
    ];
  }

  PieChartSectionData _pieSection(int index, double val, String title, Color color, IconData icon) {
    final isTouched = index == touchedIndex;
    final double radius = isTouched ? 55.0 : 40.0;
    
    return PieChartSectionData(
      color: color,
      value: val,
      title: title,
      radius: radius,
      badgeWidget: _PieBadge(icon: icon, color: color, isTouched: isTouched),
      badgePositionPercentageOffset: isTouched ? 1.45 : 1.35,
      titleStyle: bodyStyle(size: isTouched ? 12 : 10, weight: FontWeight.w900, color: Colors.white),
    );
  }
}

class _PieBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isTouched;
  const _PieBadge({required this.icon, required this.color, this.isTouched = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isTouched ? 12 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isTouched ? 0.5 : 0.3), 
            blurRadius: isTouched ? 20 : 12, 
            spreadRadius: isTouched ? 4 : 2
          ),
        ],
        border: Border.all(color: color.withOpacity(isTouched ? 0.8 : 0.5), width: isTouched ? 2 : 1),
      ),
      child: Icon(icon, color: color, size: isTouched ? 20 : 16),
    );
  }
}

class _ScenarioAuthorizationPipeline extends StatelessWidget {
  final List<SubmenuItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _ScenarioAuthorizationPipeline({required this.items, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        final i = entry.key;
        final isSelected = selectedIndex == i;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : AppColors.bg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
              boxShadow: isSelected ? [BoxShadow(color: AppColors.tBlue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))] : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: isSelected ? AppColors.tBlue.withValues(alpha: 0.1) : Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Icon(item.icon, color: isSelected ? AppColors.tBlue : AppColors.ink3, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label, style: bodyStyle(size: 15, weight: FontWeight.w800, color: isSelected ? AppColors.tBlue : AppColors.ink)),
                          Text('Prog: ${item.programId}', style: bodyStyle(size: 11, color: isSelected ? AppColors.tBlue.withValues(alpha: 0.6) : AppColors.ink3)),
                        ],
                      ),
                    ),
                    _buildPulseBadge(i == 0 ? 'Urgent' : 'In Sync', isSelected),
                  ],
                ),
                const SizedBox(height: 16),
                _AuthorizationStepper(stage: (i + 1) % 4, isSelected: isSelected),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPulseBadge(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: label == 'Urgent' ? Colors.red.withValues(alpha: 0.1) : (isSelected ? AppColors.tBlue : AppColors.tBlue.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: bodyStyle(size: 10, weight: FontWeight.w800, color: label == 'Urgent' ? Colors.red : (isSelected ? Colors.white : AppColors.tBlue))),
    );
  }
}

class _AuthorizationStepper extends StatelessWidget {
  final int stage; // 0: Maker, 1: Checker, 2: Approver, 3: Posted
  final bool isSelected;
  const _AuthorizationStepper({required this.stage, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _step('Maker', Icons.edit_rounded, stage >= 0, true),
        _connector(stage >= 1),
        _step('Checker', Icons.fact_check_rounded, stage >= 1, stage == 1),
        _connector(stage >= 2),
        _step('Approver', Icons.verified_user_rounded, stage >= 2, stage == 2),
        _connector(stage >= 3),
        _step('Posted', Icons.cloud_done_rounded, stage >= 3, stage == 3),
      ],
    );
  }

  Widget _step(String label, IconData icon, bool done, bool active) {
    Color color;
    if (label == 'Maker') color = const Color(0xFF0EA5E9);
    else if (label == 'Approver') color = const Color(0xFF8B5CF6);
    else color = active ? (isSelected ? AppColors.tBlue : AppColors.tBlue) : (done ? const Color(0xFF10B981) : AppColors.border);
    
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: done ? color.withValues(alpha: 0.1) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)] : [],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label, style: bodyStyle(size: 10, weight: FontWeight.w800, color: active ? AppColors.ink : AppColors.ink4)),
        ],
      ),
    );
  }

  Widget _connector(bool active) {
    return Container(
      width: 40,
      height: 3,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF10B981) : AppColors.border2,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ORIGINAL TABLE COMPONENTS (Refined)
// -----------------------------------------------------------------------------

class _MondayGroup extends StatelessWidget {
  final String title;
  final Color color;
  final List<SubmenuItem> items;
  final void Function(String screen, String? prog) onNavigate;

  const _MondayGroup({required this.title, required this.color, required this.items, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.ink3, size: 20),
            const SizedBox(width: 4),
            Text(title, style: bodyStyle(size: 18, weight: FontWeight.w800, color: color)),
            const SizedBox(width: 8),
            Text('(${items.length} items)', style: bodyStyle(size: 12, color: AppColors.ink4)),
          ],
        ),
        const SizedBox(height: 16),
        if (!isMobile) _buildTableHeader(),
        const SizedBox(height: 8),
        ...items.map((item) => _build3DRow(context, item)),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(flex: 4, child: Text('Account Name', style: bodyStyle(size: 13, weight: FontWeight.w700, color: AppColors.ink2))),
          Expanded(flex: 2, child: Center(child: Text('Status', style: bodyStyle(size: 13, weight: FontWeight.w700, color: AppColors.ink2)))),
          Expanded(flex: 2, child: Center(child: Text('Program ID', style: bodyStyle(size: 13, weight: FontWeight.w700, color: AppColors.ink2)))),
          Expanded(flex: 3, child: Center(child: Text('Timeline', style: bodyStyle(size: 13, weight: FontWeight.w700, color: AppColors.ink2)))),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _build3DRow(BuildContext context, SubmenuItem item) {
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return _HoverElevation(
        onTap: () => onNavigate(item.screen, item.programId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: bodyStyle(size: 15, weight: FontWeight.w800, color: AppColors.ink)),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.subtitle!, style: bodyStyle(size: 11, color: AppColors.ink3), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            border: Border.all(color: AppColors.border2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(item.programId, style: monoStyle(size: 10, color: AppColors.ink3, weight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusCell(item),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.ink4),
            ],
          ),
        ),
      );
    }

    return _HoverElevation(
      onTap: () => onNavigate(item.screen, item.programId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color, color.withValues(alpha: 0.5)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 0, 0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label, style: bodyStyle(size: 16, weight: FontWeight.w900, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text(item.subtitle ?? '', style: bodyStyle(size: 11, color: AppColors.ink3), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Expanded(flex: 2, child: _buildStatusCell(item)),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border2),
                          ),
                          child: Text(
                            item.programId ?? 'N/A', 
                            style: monoStyle(size: 10, weight: FontWeight.w800, color: AppColors.ink3)
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _buildTimelineCell(item),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.chevron_right_rounded, color: AppColors.border),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCell(SubmenuItem item) {
    final bool isDone = item.trend == 'Stable' || item.trend == 'Audited';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (isDone ? const Color(0xFF10B981) : AppColors.tBlue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isDone ? 'LIVE' : 'ACTIVE',
          style: bodyStyle(size: 10, weight: FontWeight.w800, color: isDone ? const Color(0xFF10B981) : AppColors.tBlue),
        ),
      ),
    );
  }

  Widget _buildTimelineCell(SubmenuItem item) {
    double progress = 0.7;
    if (item.programId?.contains('CAT') ?? false) progress = 1.0;
    
    return Center(
      child: Container(
        width: 140,
        height: 12,
        decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(6)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(decoration: BoxDecoration(color: color, gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]))),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverElevation extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverElevation({required this.child, required this.onTap});

  @override
  State<_HoverElevation> createState() => _HoverElevationState();
}

class _HoverElevationState extends State<_HoverElevation> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..translate(_hover ? 0.0 : 0.0, _hover ? -8.0 : 0.0),
          child: widget.child,
        ),
      ),
    );
  }
}

class _GanttChart extends StatelessWidget {
  final List<SubmenuItem> items;
  const _GanttChart({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 260,
            decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: AppColors.border, width: 1))),
            child: Column(
              children: [
                Container(height: 60, padding: const EdgeInsets.symmetric(horizontal: 24), alignment: Alignment.centerLeft, child: Text('GL Master Plan', style: bodyStyle(size: 16, weight: FontWeight.w800, color: AppColors.ink))),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) => Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      alignment: Alignment.centerLeft,
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border2))),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: _getGanttColor(i), shape: BoxShape.circle)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(items[i].label, style: bodyStyle(size: 13, weight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1200,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 60,
                          child: Row(
                            children: List.generate(12, (i) => Container(
                              width: 100,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFFF1F5F9)))),
                              child: Text('Week ${i+1}', style: bodyStyle(size: 11, color: AppColors.ink4, weight: FontWeight.w700)),
                            )),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) => Container(
                            height: 54,
                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 80.0 * (i % 6) + 40,
                                  top: 14,
                                  bottom: 14,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 800),
                                    width: 200 + (i * 30.0),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [_getGanttColor(i), _getGanttColor(i).withValues(alpha: 0.8)]),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [BoxShadow(color: _getGanttColor(i).withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3))],
                                    ),
                                    child: Center(child: Text(items[i].metric ?? '', style: bodyStyle(size: 10, color: Colors.white, weight: FontWeight.w800))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
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
  Color _getGanttColor(int i) {
    final colors = [const Color(0xFF6366F1), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF8B5CF6), const Color(0xFFEC4899)];
    return colors[i % colors.length];
  }
}

class _ModuleIntelligencePanel extends StatelessWidget {
  final SubmenuItem selectedItem;
  const _ModuleIntelligencePanel({required this.selectedItem});

  @override
  Widget build(BuildContext context) {
    final intel = _getScenarioIntel(selectedItem);
    
    return RepaintBoundary(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 CORE PERFORMANCE METRICS
            _intelRow('Verification', '${intel.ver}%', const Color(0xFF8B5CF6)),
            _intelRow('Sync Stability', '${intel.stab}%', const Color(0xFF0EA5E9)),
            _intelRow('Anomalies', '${intel.anom}%', const Color(0xFFEF4444)),
            
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
      
            // 🔹 ANIMATED SECTOR ALLOCATION
            Text('Ledger Integrity', style: bodyStyle(size: 12, weight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _circularMeter('MAKER', 0.92, const Color(0xFF0EA5E9)),
                _circularMeter('CHECK', 0.78, const Color(0xFF10B981)),
                _circularMeter('APPROV', 0.85, const Color(0xFF8B5CF6)),
              ],
            ),
      
            const SizedBox(height: 24),
      
            // 🔹 CONTEXTUAL NARRATIVE (Dynamic)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, size: 14, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      Text('Policy Analysis: ${selectedItem.label}', style: bodyStyle(size: 11, weight: FontWeight.w800, color: const Color(0xFF6366F1))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    intel.description,
                    style: bodyStyle(size: 10, color: AppColors.ink2, height: 1.5),
                  ),
                ],
              ),
            ),
      
            const SizedBox(height: 24),
            
            // 🔹 PROFESSIONAL GL ACTIVITY FEED
            Row(
              children: [
                Text('GL Activity Feed', style: bodyStyle(size: 12, weight: FontWeight.w800, color: AppColors.ink)),
                const Spacer(),
                const _StatusBadge(label: 'LIVE', color: Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: _buildScenarioActivities(selectedItem),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScenarioActivities(SubmenuItem item) {
    // Generate minutes based on item property to keep it consistent but dynamic
    final int hash = item.label.length; 
    
    if (item.label.contains('Category')) {
      return [
        _activityItem(Icons.fact_check_rounded, 'Hierarchy Validated', 'Approver confirmed root structure', _formatAgo(2 + hash % 5), const Color(0xFF8B5CF6)),
        _activityItem(Icons.note_add_rounded, 'Maker Update', 'Added 3 sub-nodes to ${item.programId}', _formatAgo(60 + hash * 2), const Color(0xFF0EA5E9)),
        _activityItem(Icons.sync_rounded, 'Sync Complete', 'Distributed schemas aligned', _formatAgo(240 + hash * 10), const Color(0xFF10B981)),
      ];
    } else if (item.label.contains('Master')) {
      return [
        _activityItem(Icons.account_balance_wallet_rounded, 'Balance Review', 'Checker verified opening balances', 'Just now', const Color(0xFF10B981)),
        _activityItem(Icons.security_rounded, 'Policy Audit', 'Enhanced security protocols applied', _formatAgo(15 + hash % 10), const Color(0xFF8B5CF6)),
        _activityItem(Icons.rule_rounded, 'Maker Modified', 'Account mappings revised for GL-MST', _formatAgo(120 + hash * 5), const Color(0xFF0EA5E9)),
      ];
    } else if (item.label.contains('Currency')) {
      return [
        _activityItem(Icons.currency_exchange_rounded, 'Rate Flash', 'Updated base rates from Gateway', '5s ago', const Color(0xFFF59E0B)),
        _activityItem(Icons.verified_user_rounded, 'Factor Verified', 'Approver signed conversion node', _formatAgo(10 + hash % 8), const Color(0xFF8B5CF6)),
        _activityItem(Icons.history_edu_rounded, 'Log Finalized', 'Currency matrix snapshot archived', _formatAgo(90 + hash * 3), const Color(0xFF0EA5E9)),
      ];
    }
    return [
      _activityItem(Icons.bolt_rounded, 'Live Pulse', 'System is monitoring ${item.label}', 'Active', const Color(0xFF10B981)),
      _activityItem(Icons.info_outline_rounded, 'Idle Notification', 'No pending authorizations for this node', _formatAgo(120), AppColors.ink3),
    ];
  }

  String _formatAgo(int minutes) {
    if (minutes < 60) return '${minutes}m ago';
    int hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h ago';
    return '${hours ~/ 24}d ago';
  }

  _ScenarioIntel _getScenarioIntel(SubmenuItem item) {
    if (item.label.contains('Category')) {
      return _ScenarioIntel(98, 94, 0.1, 'Classification tree validated. All category hierarchies are consistent with global financial standards.');
    } else if (item.label.contains('Master')) {
      return _ScenarioIntel(99, 97, 0.05, 'Ledger sum integrity verified. The current master plan is optimized for multi-branch reconciliation.');
    } else if (item.label.contains('Currency')) {
      return _ScenarioIntel(96, 91, 0.8, 'Exchange rate gateway online. Real-time conversion factors are being pulled from authorized sources.');
    }
    return _ScenarioIntel(92, 88, 1.2, 'General ledger health is optimal. Distributed data nodes are in sync with the primary controller.');
  }

  List<PieChartSectionData> _getPieData(int seed, PieType type) {
    // Generate truly dynamic data based on the seed (safeIndex)
    final double base = 15.0 + (seed * 2.1) % 10.0;
    
    if (type == PieType.distribution) {
      return [
        PieChartSectionData(color: const Color(0xFF6366F1), value: base + 20, title: 'Inbound', radius: 55, showTitle: false),
        PieChartSectionData(color: const Color(0xFF10B981), value: base + 15, title: 'Outbound', radius: 48, showTitle: false),
        PieChartSectionData(color: const Color(0xFFF59E0B), value: base + 10, title: 'Pending', radius: 42, showTitle: false),
        PieChartSectionData(color: const Color(0xFFEF4444), value: base + 5, title: 'Internal', radius: 38, showTitle: false),
      ];
    } else {
      return [
        PieChartSectionData(color: const Color(0xFF8B5CF6), value: base + 30, title: 'Approved', radius: 55, showTitle: false),
        PieChartSectionData(color: const Color(0xFFEC4899), value: base + 12, title: 'Draft', radius: 48, showTitle: false),
        PieChartSectionData(color: const Color(0xFF0EA5E9), value: base + 18, title: 'Reviewed', radius: 42, showTitle: false),
      ];
    }
  }

  Widget _circularMeter(String label, double val, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 45, height: 45,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: val,
                strokeWidth: 4,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Center(
                child: Text('${(val * 100).toInt()}%', style: bodyStyle(size: 10, weight: FontWeight.w900, color: color)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: bodyStyle(size: 9, weight: FontWeight.w800, color: AppColors.ink3)),
      ],
    );
  }

  Widget _intelRow(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color, 
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: bodyStyle(size: 12, weight: FontWeight.w600, color: AppColors.ink2)),
          const Spacer(),
          Text(val, style: bodyStyle(size: 12, weight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _activityItem(IconData icon, String title, String msg, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: bodyStyle(size: 11, weight: FontWeight.w800, color: AppColors.ink)),
                    Text(time, style: bodyStyle(size: 9, color: AppColors.ink4)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(msg, style: bodyStyle(size: 10, color: AppColors.ink3), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: bodyStyle(size: 9, weight: FontWeight.w900, color: color, letterSpacing: 1)),
      ],
    );
  }
}

class _ScenarioIntel {
  final int ver;
  final int stab;
  final double anom;
  final String description;
  _ScenarioIntel(this.ver, this.stab, this.anom, this.description);
}


