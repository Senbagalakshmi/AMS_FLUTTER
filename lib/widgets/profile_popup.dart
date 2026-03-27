import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import 'widgets.dart';

class ProfilePopup extends StatefulWidget {
  final VoidCallback onLogout;
  final String? userName;
  final String? email;

  const ProfilePopup({
    super.key, 
    required this.onLogout,
    this.userName,
    this.email,
  });

  @override
  _ProfilePopupState createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<ProfilePopup> {
  UserProfile? user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final fetchedUser = await UserService.getUserProfile();
    if (mounted && fetchedUser != null) {
      setState(() {
        user = UserProfile.fromJson(fetchedUser);
      });
    }
  }

  void _showProfileMenu() {
    // Show even if user is null (using fallbacks)

    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 260),
      elevation: 20,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 PROFILE HEADER
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.tBlueLt,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.tBlue, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tBlue.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (user?.username.isNotEmpty == true ? user!.username[0] : (widget.userName?.isNotEmpty == true ? widget.userName![0] : "A")).toUpperCase(),
                      style: bodyStyle(size: 26, weight: FontWeight.w800, color: AppColors.tBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.username ?? (widget.userName != null && widget.userName!.contains('@') ? widget.userName!.split('@').first : widget.userName) ?? "User",
                  style: bodyStyle(size: 18, weight: FontWeight.w800),
                ),
                Text(
                  user?.email ?? widget.email ?? "admin@bbots.com",
                  style: bodyStyle(size: 13, color: AppColors.ink3),
                ),
                const SizedBox(height: 16),
                
                // 🔹 ROLE BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.tBlueLt.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded, size: 14, color: AppColors.tBlue),
                      const SizedBox(width: 6),
                      Text(
                        user?.role ?? "Administrator",
                        style: bodyStyle(size: 12, weight: FontWeight.w700, color: AppColors.tBlue),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 8),
                
                // 🔹 ACTIONS
                _actionTile(
                  icon: Icons.person_outline_rounded,
                  label: "Account Settings",
                  onTap: () => Navigator.pop(context),
                ),
                _actionTile(
                  icon: Icons.security_outlined,
                  label: "Privacy Policy",
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                
                // 🔹 LOGOUT
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onLogout();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded, size: 20, color: AppColors.red),
                          const SizedBox(width: 14),
                          Text(
                            "Logout",
                            style: bodyStyle(size: 14, weight: FontWeight.w700, color: AppColors.red),
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
      ],
    );
  }

  Widget _actionTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.ink2),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: bodyStyle(size: 14, weight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.ink4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showProfileMenu,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.tBlueLt,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              (user?.username.isNotEmpty == true ? user!.username[0] : (widget.userName?.isNotEmpty == true ? widget.userName![0] : "A")).toUpperCase(),
              style: bodyStyle(size: 16, weight: FontWeight.w800, color: AppColors.tBlue),
            ),
          ),
        ),
      ),
    );
  }
}