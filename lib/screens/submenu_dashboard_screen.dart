import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import '../theme.dart';

class SubmenuItem {
  final String label;
  final IconData icon;
  final String programId;
  final String screen;
  final String? subtitle;
  final String? metric;
  final String? trend; // e.g. "+12%" or "Healthy"

  SubmenuItem({
    required this.label,
    required this.icon,
    required this.programId,
    this.screen = 'nontran',
    this.subtitle,
    this.metric,
    this.trend,
  });

  SubmenuItem copyWith({
    String? label,
    IconData? icon,
    String? programId,
    String? screen,
    String? subtitle,
    String? metric,
    String? trend,
  }) {
    return SubmenuItem(
      label: label ?? this.label,
      icon: icon ?? this.icon,
      programId: programId ?? this.programId,
      screen: screen ?? this.screen,
      subtitle: subtitle ?? this.subtitle,
      metric: metric ?? this.metric,
      trend: trend ?? this.trend,
    );
  }
}

class SubmenuDashboardScreen extends StatelessWidget {
  final String title;
  final List<SubmenuItem> items;
  final void Function(String screen, String? prog) onNavigate;

  final VoidCallback onBack;

  const SubmenuDashboardScreen({
    super.key,
    required this.title,
    required this.items,
    required this.onNavigate,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // 🔹 HEADER (Standardized)
        Padding(
          padding: const EdgeInsets.all(20),
          child: AmsIdentityHeader(
            icon: Icon(
              title.contains('GL') ? Icons.account_balance_wallet_rounded : Icons.folder_shared_rounded,
              size: 28, 
              color: AppColors.tBlue
            ),
            title: title,
            subtitle: 'Administrative control module for system parameters.',
            badges: [
              AmsBadge(label: '${items.length} Modules'),
            ],
            accentColor: AppColors.tBlue,
            accentLt: AppColors.tBlueLt,
            accentMd: AppColors.tBlueMd,
            breadcrumbs: [
              HeaderBreadcrumb(label: 'Home', onTap: onBack),
              HeaderBreadcrumb(label: title),
            ],
            onBack: onBack,
          ),
        ),

          // 🔹 GRID
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: SizedBox(
                width: double.infinity, // Ensures left alignment inside scroll view
                child: Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: items.map((item) {
                    return SizedBox(
                      width: 260, // Optimized to 280 so 4 cards perfectly fit inline without a huge empty right gap or stretching
                      height: 260,
                      child: _MenuCard(
                        item: item,
                        onTap: () => onNavigate(item.screen, item.programId),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final SubmenuItem item;
  final VoidCallback onTap;

  const _MenuCard({required this.item, required this.onTap});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? AppColors.tBlue : AppColors.border2,
              width: _isHovered ? 2 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 TOP ROW (Icon & Metric Badge)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isHovered ? AppColors.tBlue : AppColors.tBlueLt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.item.icon,
                      size: 32,
                      color: _isHovered ? Colors.white : AppColors.tBlue,
                    ),
                  ),
                  if (widget.item.metric != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isHovered ? AppColors.tBlue.withValues(alpha: 0.1) : AppColors.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _isHovered ? AppColors.tBlue.withValues(alpha: 0.3) : AppColors.border2),
                      ),
                      child: Text(
                        widget.item.metric!,
                        style: bodyStyle(
                          size: 10,
                          weight: FontWeight.w800,
                          color: _isHovered ? AppColors.tBlue : AppColors.ink2,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              
              // 🔹 LABEL
              Text(
                widget.item.label,
                style: bodyStyle(
                  size: 15,
                  weight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              
              // 🔹 SUBTITLE
              Text(
                widget.item.subtitle ?? 'Administrative control module for system parameters.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle(
                  size: 11,
                  color: AppColors.ink3,
                  weight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 🔹 FOOTER (ID & Trend)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    widget.item.programId,
                    style: monoStyle(size: 9, color: AppColors.ink4, weight: FontWeight.w600),
                  ),
                  if (widget.item.trend != null)
                    Text(
                      widget.item.trend!,
                      style: bodyStyle(
                        size: 9, 
                        color: widget.item.trend!.contains('+') ? AppColors.green : AppColors.ink4,
                        weight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
