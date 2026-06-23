import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
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
  int _selectedScenario = 0;
  late AnimationController _entryController;

  final GLApiService _glApiService = GLApiService();
  int _glCategoriesCount = 0;
  int _ledgerMastersCount = 0;
  int _branchesCount = 0;
  bool _isLoading = true;

  Map<String, Map<String, int>> _submoduleRecordStats = {};
  List<Map<String, dynamic>> _glActivities = [];


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
      final results = await Future.wait([
        apiService.getAllGlCategories(size: 1000),
        apiService.getAllGlMasters(size: 1000),
        _glApiService.getGl104List(),
        _glApiService.getGl103List(),
        _glApiService.getAllGlSegments(),
        GLApiService.getAllGlAttributes(),
        apiService.getAuthQueue(page: 0, size: 100),
      ]);

      final glCategories = results[0] as PaginatedResult<Map<String, dynamic>>?;
      final glMasters = results[1] as PaginatedResult<Map<String, dynamic>>?;
      final branches = results[2] as List<dynamic>? ?? [];
      final currencies = results[3] as List<dynamic>? ?? [];
      final segments = results[4] as List<dynamic>? ?? [];
      final attributes = results[5] as List<dynamic>? ?? [];
      final authQueueRes = results[6] as PaginatedResult<AuthRecord>?;

      final dbCounts = {
        'GL-CAT': glCategories?.totalElements ?? 0,
        'GL-MST': glMasters?.totalElements ?? 0,
        'GL-BRN': branches.length,
        'GL-CUR': currencies.length,
        'GL-SEG': segments.length,
        'GL-ATT': attributes.length,
      };

      final authQueue = authQueueRes?.items ?? [];

      final Map<String, Map<String, int>> recordStats = {};
      final submodules = ['GL-CAT', 'GL-MST', 'GL-BRN', 'GL-CUR', 'GL-SEG', 'GL-ATT'];
      for (final sub in submodules) {
        recordStats[sub] = {
          'inserted': dbCounts[sub] ?? 0,
          'updated': 0,
          'deleted': 0,
          'remaining': 0,
        };
      }

      for (final rec in authQueue) {
        final sub = rec.programId == 'GL-MAT' ? 'GL-MST' : rec.programId;
        if (recordStats.containsKey(sub)) {
          final remarks = rec.displayRemarks.toLowerCase();
          if (remarks.contains('delete') || remarks.contains('remove')) {
            recordStats[sub]!['deleted'] = (recordStats[sub]!['deleted'] ?? 0) + 1;
          } else if (remarks.contains('update') || remarks.contains('modify') || remarks.contains('edit') || remarks.contains('change')) {
            recordStats[sub]!['updated'] = (recordStats[sub]!['updated'] ?? 0) + 1;
          } else {
            recordStats[sub]!['remaining'] = (recordStats[sub]!['remaining'] ?? 0) + 1;
          }
        }
      }

      final glProgs = {'GL-CAT', 'GL-MST', 'GL-MAT', 'GL-CUR', 'GL-BRN', 'GL-SEG', 'GL-ATT'};
      final glAuthRecords = authQueue.where((r) => glProgs.contains(r.programId)).toList();
      glAuthRecords.sort((a, b) => b.eDate.compareTo(a.eDate));

      final List<Map<String, dynamic>> glActivities = [];
      for (final rec in glAuthRecords) {
        IconData icon = Icons.pending_actions_rounded;
        Color color = AppColors.tBlue;
        final remarks = rec.displayRemarks.toLowerCase();
        
        if (remarks.contains('delete') || remarks.contains('remove')) {
          icon = Icons.delete_outline_rounded;
          color = AppColors.red;
        } else if (remarks.contains('update') || remarks.contains('modify') || remarks.contains('edit') || remarks.contains('change')) {
          icon = Icons.edit_calendar_rounded;
          color = AppColors.purple;
        } else if (remarks.contains('create') || remarks.contains('insert') || remarks.contains('add') || remarks.contains('new')) {
          icon = Icons.add_circle_outline_rounded;
          color = AppColors.green;
        }
        
        glActivities.add({
          'icon': icon,
          'color': color,
          'title': rec.displayRemarks.isNotEmpty ? rec.displayRemarks : 'Auth Request: ${rec.programId}',
          'time': _formatRelativeTime(rec.eDate),
          'subtitle': 'By ${rec.eUser} • ${rec.programId}',
        });
      }

      if (glActivities.isEmpty) {
        if ((dbCounts['GL-CAT'] ?? 0) > 0) {
          glActivities.add({
            'icon': Icons.category_rounded,
            'color': AppColors.green,
            'title': 'GL Categories Configured',
            'time': 'Active',
            'subtitle': '${dbCounts['GL-CAT']} categories found in database',
          });
        }
        if ((dbCounts['GL-MST'] ?? 0) > 0) {
          glActivities.add({
            'icon': Icons.account_balance_rounded,
            'color': AppColors.green,
            'title': 'GL Masters Configured',
            'time': 'Active',
            'subtitle': '${dbCounts['GL-MST']} master ledgers found in database',
          });
        }
        if ((dbCounts['GL-BRN'] ?? 0) > 0) {
          glActivities.add({
            'icon': Icons.location_city_rounded,
            'color': AppColors.green,
            'title': 'Allowed Branches Set',
            'time': 'Active',
            'subtitle': '${dbCounts['GL-BRN']} branches configured for GL access',
          });
        }
        if ((dbCounts['GL-CUR'] ?? 0) > 0) {
          glActivities.add({
            'icon': Icons.currency_exchange_rounded,
            'color': AppColors.green,
            'title': 'Allowed Currencies Set',
            'time': 'Active',
            'subtitle': '${dbCounts['GL-CUR']} currencies configured',
          });
        }
      }

      if (mounted) {
        setState(() {
          _glCategoriesCount = glCategories?.totalElements ?? 0;
          _ledgerMastersCount = glMasters?.totalElements ?? 0;
          _branchesCount = branches.length;
          _submoduleRecordStats = recordStats;
          _glActivities = glActivities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr.split(' ').first;

    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('dd MMM yyyy').format(date);
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

          const Divider(height: 1, color: AppColors.border),

          // 🔹 VIEW CONTENT
          Expanded(
            child: _buildOverview(),
          ),
        ],
      ),
    );
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
            ],
          ),
        ],
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
        gradientColors: const [Color(0xFF818CF8), Color(0xFF6366F1)],
        delay: 0,
      ),
      _SummaryCard3D(
        title: 'GL Masters',
        value: _isLoading ? '...' : _ledgerMastersCount.toString(),
        icon: Icons.account_balance_rounded,
        gradientColors: const [Color(0xFF34D399), Color(0xFF10B981)],
        delay: 0.05,
      ),
      _SummaryCard3D(
        title: 'Configuration',
        value: '4',
        icon: Icons.settings_rounded,
        gradientColors: const [Color(0xFF67E8F9), Color(0xFF0EA5E9)],
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
                  title: 'GL Module Activity',
                  onRefresh: _fetchDashboardData,
                  child: _ModuleIntelligencePanel(
                    submoduleStats: _submoduleRecordStats,
                    activities: _glActivities,
                  ),
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
                    title: 'GL Module Activity',
                    onRefresh: _fetchDashboardData,
                    child: _ModuleIntelligencePanel(
                      submoduleStats: _submoduleRecordStats,
                      activities: _glActivities,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }


}

// -----------------------------------------------------------------------------
// UI COMPONENTS
// -----------------------------------------------------------------------------


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
              _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.tBlue),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.sync_rounded, color: AppColors.ink4, size: 20),
                    onPressed: _handleRefresh,
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
  final List<Color> gradientColors;
  final double delay;

  const _SummaryCard3D({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    required this.delay,
  });

  @override
  State<_SummaryCard3D> createState() => _SummaryCard3DState();
}
class _SummaryCard3DState extends State<_SummaryCard3D> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.gradientColors.last;
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
                      colors: [Colors.white, _isHovered ? activeColor.withValues(alpha: 0.05) : Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isHovered ? activeColor : AppColors.border, width: _isHovered ? 2 : 1),
                    boxShadow: [
                      BoxShadow(
                        color: _isHovered ? activeColor.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
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
                          gradient: LinearGradient(
                            colors: widget.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 28),
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
      _pieSection(0, 35.0 + (s % 12), 'Income', const Color(0xFF0D9488), Icons.trending_up_rounded),
      _pieSection(1, 25.0 - (s % 8), 'Asset', const Color(0xFF3B82F6), Icons.account_balance_rounded),
      _pieSection(2, 25.0 + (s % 5), 'Liability', const Color(0xFF818CF8), Icons.account_balance_wallet_rounded),
      _pieSection(3, 15.0 - (s % 3), 'Expense', const Color(0xFFF43F5E), Icons.trending_down_rounded),
    ];
  }

  List<PieChartSectionData> _getAuthSections() {
    final s = widget.seed;
    return [
      _pieSection(0, 40.0 - (s % 10), 'Approver', AppColors.tBlue, Icons.verified_user_rounded),
      _pieSection(1, 30.0 + (s % 5), 'Checker', const Color(0xFF3A57E8), Icons.fact_check_rounded),
      _pieSection(2, 20.0 + (s % 8), 'Maker', const Color(0xFF6366F1), Icons.edit_note_rounded),
      _pieSection(3, 10.0, 'Posted', const Color(0xFF93C5FD), Icons.cloud_done_rounded),
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
    if (label == 'Maker') color = const Color(0xFF3A57E8);
    else if (label == 'Approver') color = AppColors.purple;
    else color = active ? AppColors.tBlue : (done ? AppColors.green : AppColors.border);
    
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
        color: active ? AppColors.green : AppColors.border2,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ORIGINAL TABLE COMPONENTS (Refined)
// -----------------------------------------------------------------------------



class _ModuleIntelligencePanel extends StatelessWidget {
  final Map<String, Map<String, int>> submoduleStats;
  final List<Map<String, dynamic>> activities;

  const _ModuleIntelligencePanel({
    required this.submoduleStats,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final subList = [
      {'id': 'GL-CAT', 'name': 'GL Category', 'icon': Icons.category_rounded},
      {'id': 'GL-MST', 'name': 'GL Master', 'icon': Icons.account_balance_wallet_rounded},
      {'id': 'GL-BRN', 'name': 'Allowed Branches', 'icon': Icons.location_city_rounded},
      {'id': 'GL-CUR', 'name': 'Allowed Currencies', 'icon': Icons.currency_exchange_rounded},
      {'id': 'GL-SEG', 'name': 'GL Segments', 'icon': Icons.segment_rounded},
      {'id': 'GL-ATT', 'name': 'GL Attributes', 'icon': Icons.settings_input_component_rounded},
    ];

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 GL SUBMODULES OVERVIEW SECTION (Data Table)
          Text(
            'GL Submodules Overview',
            style: bodyStyle(size: 13, weight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.6),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.0),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header Row
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Submodule', style: bodyStyle(size: 10, weight: FontWeight.w800, color: AppColors.ink3)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Center(child: Text('Ins', style: bodyStyle(size: 10, weight: FontWeight.w800, color: AppColors.ink3))),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Center(child: Text('Upd', style: bodyStyle(size: 10, weight: FontWeight.w800, color: AppColors.ink3))),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Center(child: Text('Del', style: bodyStyle(size: 10, weight: FontWeight.w800, color: AppColors.ink3))),
                  ),
                ],
              ),
              // Data Rows
              ...subList.map((sub) {
                final id = sub['id'] as String;
                final name = sub['name'] as String;
                final icon = sub['icon'] as IconData;
                final stats = submoduleStats[id] ?? {'inserted': 0, 'updated': 0, 'deleted': 0};

                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(icon, size: 13, color: AppColors.ink3),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              name,
                              style: bodyStyle(size: 11, weight: FontWeight.w800, color: AppColors.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: _badge('${stats['inserted']}', const Color(0xFF10B981))),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: _badge('${stats['updated']}', const Color(0xFF3B82F6))),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: _badge('${stats['deleted']}', const Color(0xFFEF4444))),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 20),

          // 🔹 GL RECENT ACTIVITIES FEED
          Row(
            children: [
              Text(
                'Recent Activities',
                style: bodyStyle(size: 13, weight: FontWeight.w800, color: AppColors.ink),
              ),
              const Spacer(),
              const _StatusBadge(label: 'LIVE', color: Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No recent activities',
                  style: bodyStyle(size: 11, color: AppColors.ink4),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length > 5 ? 5 : activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _activityItem(
                  activity['icon'] as IconData,
                  activity['title'] as String,
                  activity['subtitle'] as String,
                  activity['time'] as String,
                  activity['color'] as Color,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: bodyStyle(size: 9, weight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _activityItem(
    IconData icon,
    String title,
    String msg,
    String time,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
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
                    Expanded(
                      child: Text(
                        title,
                        style: bodyStyle(size: 11, weight: FontWeight.w800, color: AppColors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: bodyStyle(size: 9, color: AppColors.ink4),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  msg,
                  style: bodyStyle(size: 10, color: AppColors.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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



