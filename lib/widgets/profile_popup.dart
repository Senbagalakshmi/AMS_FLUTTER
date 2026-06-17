import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import '../services/user_service.dart';
import '../services/api_service.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import 'widgets.dart';

class _WebAvatar extends StatefulWidget {
  final String url;
  final double size;
  final Widget errorFallback;

  const _WebAvatar({
    Key? key,
    required this.url,
    required this.size,
    required this.errorFallback,
  }) : super(key: key);

  @override
  State<_WebAvatar> createState() => _WebAvatarState();
}

class _WebAvatarState extends State<_WebAvatar> {
  bool _hasError = false;
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _initView();
  }

  @override
  void didUpdateWidget(covariant _WebAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _hasError = false;
      _initView();
    }
  }

  void _initView() {
    if (kIsWeb) {
      _viewId = 'img-${widget.url.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) {
          final img = html.ImageElement()
            ..src = widget.url
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover'
            ..style.borderRadius = '50%';
            
          img.onError.listen((_) {
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          });
          return img;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorFallback;
    }

    if (kIsWeb) {
      return IgnorePointer(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: HtmlElementView(viewType: _viewId),
        ),
      );
    }
    
    return IgnorePointer(
      child: ClipOval(
        child: Image.network(
          widget.url,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => widget.errorFallback,
        ),
      ),
    );
  }
}

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

  Timer? _profileTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _profileTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _loadUser();
    });
  }

  @override
  void dispose() {
    _profileTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    if (kIsWeb) {
      apiService.updateToken(
        html.window.sessionStorage['child_token'],
      );
    }
    final fetchedUser = await UserService.getUserProfile();
    
    if (fetchedUser != null) {
      final userScdRaw = fetchedUser['userScd'] ?? fetchedUser['usersCd'];
      final orgCodeRaw = fetchedUser['orgCode'];
      if (userScdRaw != null) {
        final uCode = userScdRaw.toString();
        final oCode = orgCodeRaw is int ? orgCodeRaw : int.tryParse(orgCodeRaw?.toString() ?? '0') ?? 0;
        final userDetails = await apiService.getUserDetails(uCode, oCode);
        if (userDetails != null) {
          fetchedUser.addAll(userDetails);
          if (kIsWeb) {
            html.window.sessionStorage['user_data'] = jsonEncode(fetchedUser);
          }
        }
      }
    }

    if (mounted && fetchedUser != null) {
      setState(() {
        user = UserProfile.fromJson(fetchedUser);
      });
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: _EditProfileContent(
            user: user,
            userName: widget.userName,
            email: widget.email,
            onLogout: widget.onLogout,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showEditProfileDialog,
      behavior: HitTestBehavior.opaque,
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
          child: user?.picture != null && user!.picture!.isNotEmpty
              ? _WebAvatar(
                  url: user!.picture!,
                  size: 40,
                  errorFallback: Center(
                    child: Text(
                      (user?.username.isNotEmpty == true
                              ? user!.username[0]
                              : (widget.userName?.isNotEmpty == true
                                  ? widget.userName![0]
                                  : "A"))
                          .toUpperCase(),
                      style: bodyStyle(
                          size: 16, weight: FontWeight.w800, color: AppColors.tBlue),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    (user?.username.isNotEmpty == true
                            ? user!.username[0]
                            : (widget.userName?.isNotEmpty == true
                                ? widget.userName![0]
                                : "A"))
                        .toUpperCase(),
                    style: bodyStyle(
                        size: 16, weight: FontWeight.w800, color: AppColors.tBlue),
                  ),
                ),
        ),
      ),
    );
  }
}

class _EditProfileContent extends StatefulWidget {
  final UserProfile? user;
  final String? userName;
  final String? email;
  final VoidCallback onLogout;

  const _EditProfileContent({
    required this.user,
    required this.userName,
    required this.email,
    required this.onLogout,
  });

  @override
  _EditProfileContentState createState() => _EditProfileContentState();
}

class _EditProfileContentState extends State<_EditProfileContent> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  
  String _roleType = "Administrator";
  String _orgCode = "";
  
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    
    Map<String, dynamic> sessionUser = {};
    if (kIsWeb) {
      final str = html.window.sessionStorage['user_data'];
      if (str != null && str.isNotEmpty) {
        try {
          sessionUser = jsonDecode(str);
        } catch (_) {}
      }
    }

    String uName = widget.user?.username ??
        (widget.userName != null && widget.userName!.contains('@')
            ? widget.userName!.split('@').first
            : widget.userName) ??
        "";

    String fname = (sessionUser['fname'] ?? sessionUser['firstName'] ?? sessionUser['first_name'])?.toString() ?? '';
    if (fname == 'null') fname = '';
    
    String lname = (sessionUser['lname'] ?? sessionUser['lastName'] ?? sessionUser['last_name'])?.toString() ?? '';
    if (lname == 'null') lname = '';
    
    String email = sessionUser['email']?.toString() ?? widget.user?.email ?? widget.email ?? "";
    if (email == 'null') email = '';
    
    String callcode = sessionUser['callcode']?.toString() ?? '+91';
    if (callcode == 'null') callcode = '+91';
    
    String mobile = (sessionUser['mobile'] ?? sessionUser['phone'] ?? sessionUser['phoneNumber'])?.toString() ?? '';
    if (mobile == 'null') mobile = '';
    
    _roleType = sessionUser['roleType']?.toString() ?? widget.user?.role ?? "Administrator";
    if (_roleType == 'null' || _roleType.isEmpty) _roleType = "Administrator";
    
    _orgCode = sessionUser['orgCode']?.toString() ?? "";

    _firstNameController = TextEditingController(
        text: fname.isNotEmpty ? fname : (uName.isNotEmpty ? uName[0].toUpperCase() + uName.substring(1) : ""));
    _lastNameController = TextEditingController(text: lname);
    
    String dName = [fname, lname].where((e) => e.isNotEmpty).join(' ');
    if (dName.isEmpty) dName = uName;
    _displayNameController = TextEditingController(text: dName);
    
    _emailController = TextEditingController(text: email);
    
    _phoneController = TextEditingController(
        text: mobile.isNotEmpty ? "$callcode $mobile".trim() : " ");

    _currentPasswordController = TextEditingController(text: "........");
    _newPasswordController = TextEditingController(text: "........");
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: bodyStyle(
              size: 13,
              color: const Color(0xFF475569),
              weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            readOnly: !_isEditing,
            style: bodyStyle(
                size: 15,
                color: const Color(0xFF0F172A),
                weight: FontWeight.w500),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String uName = widget.user?.username ??
        (widget.userName != null && widget.userName!.contains('@')
            ? widget.userName!.split('@').first
            : widget.userName) ??
        "";
    String firstChar = uName.isNotEmpty ? uName[0].toUpperCase() : "A";

    return Container(
      width: 600,
      constraints: const BoxConstraints(maxHeight: 850),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: AppColors.tBlue.withValues(alpha: 0.05),
            blurRadius: 60,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.tBlueLt.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.manage_accounts_rounded,
                      size: 20, color: AppColors.tBlue),
                ),
                const SizedBox(width: 16),
                Text(
                  "Edit Profile",
                  style: bodyStyle(
                      size: 22,
                      weight: FontWeight.w800,
                      color: const Color(0xFF0F172A)),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onLogout();
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.red, size: 20),
                    tooltip: "Logout",
                    splashRadius: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF64748B), size: 20),
                    splashRadius: 20,
                  ),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 24),
              child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info Area
                        Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.tBlueLt,
                                        Color(0xFFE0E7FF)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.tBlue
                                            .withValues(alpha: 0.2),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: widget.user?.picture != null && widget.user!.picture!.isNotEmpty
                                      ? _WebAvatar(
                                          url: widget.user!.picture!,
                                          size: 88,
                                          errorFallback: Center(
                                            child: Text(
                                              firstChar,
                                              style: bodyStyle(
                                                  size: 36,
                                                  weight: FontWeight.w800,
                                                  color: AppColors.tBlue),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            firstChar,
                                            style: bodyStyle(
                                                size: 36,
                                                weight: FontWeight.w800,
                                                color: AppColors.tBlue),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.tBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.tBlue
                                                .withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.edit_rounded,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  uName,
                                  style: bodyStyle(
                                      size: 20,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFF111827)),
                                ),
                                if (_orgCode.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    "Org Code: $_orgCode",
                                    style: bodyStyle(
                                        size: 14, color: const Color(0xFF6B7280)),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                          Icons.admin_panel_settings_outlined,
                                          size: 14,
                                          color: Color(0xFF4B5563)),
                                      const SizedBox(width: 6),
                                      Text(
                                        _roleType,
                                        style: bodyStyle(
                                            size: 12,
                                            weight: FontWeight.w600,
                                            color: const Color(0xFF4B5563)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // PERSONAL INFORMATION Section
                        Text(
                          "PERSONAL INFORMATION",
                          style: bodyStyle(
                              size: 12,
                              weight: FontWeight.w700,
                              color: const Color(0xFF9CA3AF),
                              letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _buildTextField(
                                    "First name", _firstNameController)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildTextField(
                                    "Last name", _lastNameController)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField("Display name", _displayNameController),
                        const SizedBox(height: 16),
                        _buildTextField("Email address", _emailController),
                        _buildTextField("Phone number", _phoneController),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    // Handle forgot password action
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_reset_rounded,
                          size: 18, color: AppColors.tBlue),
                      const SizedBox(width: 8),
                      Text(
                        "Forgot Password?",
                        style: bodyStyle(
                            size: 14,
                            weight: FontWeight.w700,
                            color: AppColors.tBlue),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_isEditing) ...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: bodyStyle(
                          size: 15,
                          weight: FontWeight.w700,
                          color: const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.tBlue, AppColors.tBlueDk],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement actual save logic
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Save Changes",
                        style: bodyStyle(
                            size: 15,
                            weight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
