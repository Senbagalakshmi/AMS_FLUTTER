import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../theme.dart';
import 'widgets.dart';

class AuditLogPopup extends StatelessWidget {
  final Map<String, dynamic> record;

  const AuditLogPopup({super.key, required this.record});

  String _formatDate(dynamic dateString) {
    if (dateString == null || dateString.toString().isEmpty) {
      return 'N/A';
    }
    try {
      final dt = DateTime.parse(dateString.toString()).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return dateString.toString();
    }
  }

  String _getUser(String key1, String key2) {
    final val = record[key1] ?? record[key2] ?? record[key1.toUpperCase()] ?? record[key2.toUpperCase()];
    return val?.toString().isNotEmpty == true ? val.toString() : '—';
  }

  dynamic _getRecordValue(String key1, String key2) {
    return record[key1] ?? record[key2] ?? record[key1.toUpperCase()] ?? record[key2.toUpperCase()];
  }

  Widget _buildEventCard({
    required IconData icon,
    required String label,
    required String user,
    required String date,
    required Color color,
  }) {
    final bool isCompleted = user != '—' && user != 'N/A' && user.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Color Accent
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              ),
            ),
            // Icon & Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Glowing Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    // Text Details
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: bodyStyle(size: 15, weight: FontWeight.w800, color: AppColors.ink),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 14, color: AppColors.ink3),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isCompleted ? user : 'Pending',
                                  style: bodyStyle(size: 13, color: AppColors.ink2, weight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 14, color: AppColors.ink3),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  date,
                                  style: bodyStyle(size: 13, color: AppColors.ink3),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    if (isCompleted)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle_rounded, color: color, size: 20),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cUser = _getUser('cUser', 'cuser');
    final cDate = _formatDate(_getRecordValue('cDate', 'cdate'));
    
    final mUser = _getUser('eUser', 'euser');
    final mDate = _formatDate(_getRecordValue('eDate', 'edate'));
    
    final aUser = _getUser('aUser', 'auser');
    final aDate = _formatDate(_getRecordValue('aDate', 'adate'));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.tBlueLt,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.history_edu_rounded, color: AppColors.tBlue, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Audit Trail',
                                style: bodyStyle(size: 18, weight: FontWeight.w800, color: AppColors.ink),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Complete record lifecycle',
                                style: bodyStyle(size: 13, color: AppColors.ink3, weight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            hoverColor: AppColors.redLt,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.border.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 20, color: AppColors.ink2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildEventCard(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Record Created',
                            user: cUser,
                            date: cDate,
                            color: AppColors.green,
                          ),
                          _buildEventCard(
                            icon: Icons.edit_note_rounded,
                            label: 'Last Modified',
                            user: mUser,
                            date: mDate,
                            color: AppColors.tBlue,
                          ),
                          _buildEventCard(
                            icon: Icons.verified_user_rounded,
                            label: 'Approval Status',
                            user: aUser,
                            date: aDate,
                            color: AppColors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showAuditLogPopup(BuildContext context, Map<String, dynamic> record) {
  showDialog(
    context: context,
    builder: (context) => AuditLogPopup(record: record),
  );
}

