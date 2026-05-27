import 'package:flutter/material.dart';
import 'dart:math';
import '../theme.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../data.dart';
import '../screens/submenu_dashboard_screen.dart';
import '../utils/responsive.dart';

class ReportDashboardScreen extends StatefulWidget {
  final List<SubmenuItem> items;
  final String? userName;
  final VoidCallback onBack;
  final void Function(String screen, String? prog) onNavigate;

  const ReportDashboardScreen({
    super.key,
    required this.items,
    this.userName,
    required this.onBack,
    required this.onNavigate,
  });

  @override
  State<ReportDashboardScreen> createState() => _ReportDashboardScreenState();
}

class _ReportDashboardScreenState extends State<ReportDashboardScreen>
    with SingleTickerProviderStateMixin {

  int _selectedReport = 0;
  // Track which card index is touched/active
  int? _activeIndex; 
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ================= TEXT STYLES =================
  TextStyle headerStyle({
    double size = 22,
    Color color = Colors.black,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  TextStyle bodyStyle({
    double size = 14,
    Color color = Colors.black,
    FontWeight weight = FontWeight.w500,
    double? height,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),

          Expanded(
            child: FadeTransition(
              opacity: _animationController,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: _buildDetailedView(isMobile),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.tBlue),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Reports',
                      style: headerStyle(
                        size: isMobile ? 20 : 24,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.items.length} Modules',
                        style: bodyStyle(
                          size: 11,
                          color: AppColors.tBlue,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Home',
                      style: bodyStyle(size: 13, color: Colors.grey[500]!),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                    Text(
                      'Reports',
                      style: bodyStyle(size: 13, color: Colors.grey[700]!),
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

  // ================= INTERACTIVE DYNAMIC BORDER LIST VIEW =================
  Widget _buildDetailedView(bool isMobile) {
    final double cardWidth = isMobile ? MediaQuery.of(context).size.width : 290;
    final double cardHeight = 250;

    return Align(
      alignment: Alignment.topLeft,
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: widget.items.map((item) {
          final int index = widget.items.indexOf(item);
          // Check if this specific card boundary is currently selected/touched
          final bool isActive = _activeIndex == index;

          return MouseRegion(
            onEnter: (_) => setState(() => _activeIndex = index),
            onExit: (_) => setState(() => _activeIndex = null),
            child: InkWell(
              onTapDown: (_) => setState(() => _activeIndex = index),
              onTapCancel: () => setState(() => _activeIndex = null),
              onTap: () {
                widget.onNavigate('nontran', item.programId);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: cardWidth,
                height: cardHeight,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  // Draws a crisp, distinct blue border if active/touched
                  border: Border.all(
                    color: isActive ? const Color(0xFF1E3A8A) : Colors.transparent,
                    width: isActive ? 2.5 : 2.5, 
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isActive 
                          ? const Color(0xFF1E3A8A).withOpacity(0.08)
                          : Colors.black.withOpacity(0.015),
                      blurRadius: isActive ? 14 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP: Shifting Icon Color Contexts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? const Color(0xFF1E3A8A) 
                                : AppColors.tBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.icon ?? Icons.description_rounded, 
                            color: isActive ? Colors.white : AppColors.tBlue, 
                            size: 24,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            index % 2 == 0 ? 'New' : 'Active',
                            style: bodyStyle(
                              size: 11, 
                              color: AppColors.ink.withOpacity(0.7), 
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    
                    // MIDDLE: Primary Headings
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle(
                        size: 18,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle ?? 'Open report module to look up operations.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle(
                        size: 13,
                        color: Colors.grey[500]!,
                        weight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    
                    // BOTTOM: System Context Meta Footers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.programId ?? 'GL-JRN',
                          style: bodyStyle(
                            size: 11, 
                            color: Colors.grey[400]!, 
                            weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      index % 2 == 0 ? 'Daily' : 'Standard',
                      style: bodyStyle(
                        size: 11, 
                        color: Colors.grey[500]!, 
                        weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
}