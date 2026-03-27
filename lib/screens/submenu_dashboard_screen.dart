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
}

class SubmenuDashboardScreen extends StatelessWidget {
  final String title;
  final List<SubmenuItem> items;
  final void Function(String screen, String? prog) onNavigate;

  const SubmenuDashboardScreen({
    super.key,
    required this.title,
    required this.items,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: bodyStyle(
                        size: 28,
                        weight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '(${items.length} Modules)',
                        style: bodyStyle(size: 14, color: AppColors.ink4, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage and monitor your system configurations and security protocols.',
                  style: bodyStyle(size: 14, color: AppColors.ink3),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.border2),
              ],
            ),
          ),

          // 🔹 GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280, // Increased for subtitle
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 0.82,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _MenuCard(
                  item: item,
                  onTap: () => onNavigate(item.screen, item.programId),
                );
              },
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
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered 
                  ? AppColors.tBlue.withValues(alpha: 0.1) 
                  : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHovered ? 15 : 10,
                offset: Offset(0, _isHovered ? 6 : 4),
              ),
            ],
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
                      size: 24,
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
