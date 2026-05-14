import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../services/api_service.dart';
import '../theme.dart';

/// Entry point shown when the app first loads.
///
/// Flow:
///  1. If the URL contains `?token=<mother_token>` (SSO deep-link from another
///     BBOTS product), call the AM exchange-token API.
///     • Success → store child_token + session in sessionStorage, go to list.
///     • Failure → go to login.
///  2. If no URL token but a child_token is already saved in sessionStorage
///     (returning user in same session), go straight to list.
///  3. Otherwise → go to login.
class SplashScreen extends StatefulWidget {
  /// Called when exchange/session succeeds.
  /// [token]    – child token to use for all Finance API calls.
  /// [userName] – display name from session_data.
  final void Function(String token, String userName) onLoginSuccess;

  /// Called when no valid token is found → show login screen.
  final VoidCallback onGoToLogin;

  const SplashScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onGoToLogin,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  String _status = 'Initialising…';
  bool _navigated = false; // guard against double-navigation

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Give Flutter one frame to paint before running async logic.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ── Main auth check ────────────────────────────────────────────────────────

  Future<void> _checkAuth() async {
    if (_navigated) return;

    // Small delay so the browser URL is fully settled before reading it.
    // (Matches the pattern used in the working AM splash screen.)
    await Future.delayed(const Duration(milliseconds: 100));

    // ── Step 1: check URL for SSO mother token ─────────────────────────────
    String? motherToken;
    String currentPath = '/';

    if (kIsWeb) {
      final uri = Uri.base;
      currentPath = uri.path; // e.g. '/' or '/finance'

      // Standard query param: ?token=...
      motherToken = uri.queryParameters['token'];
      print('motherToken: $motherToken');
      // Also check hash-based routing: /#/...?token=...
      if ((motherToken == null || motherToken.isEmpty) &&
          uri.fragment.contains('?')) {
        final fragParams =
            Uri.splitQueryString(uri.fragment.split('?').last);
        motherToken = fragParams['token'];
      }
    }

    // ── SSO exchange takes priority ────────────────────────────────────────
    if (motherToken != null && motherToken.isNotEmpty) {
      _setStatus('Authenticating via SSO…');
      await _doExchange(motherToken);
      return;
    }

    // ── Step 2: check sessionStorage for a saved child_token ──────────────
    // This handles both:
    //   a) User refreshes /finance  → restore session → stay on /finance
    //   b) User opens /            → no token saved   → go to login
    if (kIsWeb) {
      final saved = html.window.sessionStorage['child_token'];
      if (saved != null && saved.isNotEmpty) {
        final userName =
            _extractUserName(html.window.sessionStorage['user_data']);
        _setStatus('Restoring session…');
        await Future.delayed(const Duration(milliseconds: 400));
        apiService.updateToken(saved);
        // Ensure URL shows /finance when restoring a session
        html.window.history.replaceState(null, '', '/finance');
        _goToList(saved, userName);
        return;
      }
    }

    // ── Step 3: no token found ─────────────────────────────────────────────
    // If the user typed /finance directly with no session, redirect to login
    // and correct the URL back to /
    if (kIsWeb && currentPath == '/finance') {
      html.window.history.replaceState(null, '', '/');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _goToLogin();
  }

  // ── Exchange API call ──────────────────────────────────────────────────────

  Future<void> _doExchange(String motherToken) async {
    try {
      final response = await apiService.exchangeToken(motherToken);

      if (response == null) {
        print('⚠️ Exchange API returned null → login');
        _goToLogin();
        return;
      }

      print('🔍 Exchange response: $response');

      // ── Parse child token ─────────────────────────────────────────────────
      final childToken = response['child_token'] as String? ??
          response['access_token'] as String? ??
          response['token'] as String?;

      if (childToken == null) {
        print('⚠️ Exchange response missing child_token → login');
        _goToLogin();
        return;
      }

      // ── Parse fields — handles BOTH flat and session_data-nested shapes ───
      final sessionData = response['session_data'] as Map<String, dynamic>?;

      final roleType = (response['roleType']  ??
                        response['role_type'] ??
                        sessionData?['roleType'] ??
                        sessionData?['role_type'] ?? '').toString();

      // userScd is the key used as userCode in the get-user API
      final userScd = sessionData?['userScd']  ??
                      response['userScd']       ??
                      response['usersCd'];

      final orgCode = sessionData?['orgCode']  ?? response['orgCode'];

      // ── Update ApiService token so /am/get-user call is authenticated ─────
      apiService.updateToken(childToken);

      // ── Call GET /am/get-user?userCode=<userScd> ──────────────────────────
      _setStatus('Loading user profile…');
      Map<String, dynamic>? userDetails;
      if (userScd != null) {
        final uCode = userScd is int ? userScd : int.tryParse(userScd.toString()) ?? 0;
        final oCode = orgCode is int ? orgCode : int.tryParse(orgCode?.toString() ?? '0') ?? 0;
        userDetails = await apiService.getUserDetails(uCode, oCode);
      }

      // ── Build final user record from get-user response (or fallback) ──────
      final userName = userDetails?['userName']  ??
                       userDetails?['name']       ??
                       sessionData?['userName']   ??
                       response['userName']       ??
                       response['email'] ?? '';

      final email    = userDetails?['email']     ??
                       sessionData?['email']      ??
                       response['email'] ?? '';

      final userJson = {
        'id'       : userScd?.toString() ?? '',
        'email'    : email.toString(),
        'name'     : userName.toString(),
        'userScd'  : userScd,
        'orgCode'  : orgCode,
        'roleType' : roleType,
        'role_type': roleType,
        // merge all extra fields from get-user if available
        if (userDetails != null) ...userDetails,
      };

      // ── Persist to sessionStorage ─────────────────────────────────────────
      if (kIsWeb) {
        for (final k in [
          'child_token', 'mother_token', 'user_data', 'role_type',
          'flutter.child_token', 'flutter.mother_token', 'flutter.user_data',
        ]) {
          html.window.sessionStorage.remove(k);
        }

        html.window.sessionStorage['child_token'] = childToken;
        html.window.sessionStorage['mother_token'] = motherToken;
        html.window.sessionStorage['role_type']    = roleType;
        html.window.sessionStorage['user_data']    = jsonEncode(userJson);

        // Clean ?token= from address bar, show /finance
        html.window.history.replaceState(null, '', '/finance');
        print('✅ SSO complete. user=$userName  roleType=$roleType');
      }

      _goToList(childToken, userName.toString());
    } catch (e) {
      print('❌ _doExchange error: $e');
      _goToLogin();
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _goToList(String token, String userName) {
    if (!mounted || _navigated) return;
    _navigated = true;
    widget.onLoginSuccess(token, userName);
  }

  void _goToLogin() {
    if (!mounted || _navigated) return;
    _navigated = true;
    widget.onGoToLogin();
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _status = msg);
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  String _extractUserName(String? userDataJson) {
    if (userDataJson == null) return '';
    try {
      final map = jsonDecode(userDataJson) as Map<String, dynamic>;
      return map['name']?.toString() ??
          map['userName']?.toString() ??
          map['email']?.toString() ??
          '';
    } catch (_) {
      return '';
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [
              Color.fromARGB(255, 232, 233, 234),
              Color.fromARGB(255, 22, 48, 98),
              Color.fromARGB(255, 244, 245, 247),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x731447E6),
                            blurRadius: 32,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App name
                    Text(
                      'FMS',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                        fontFamily: 'SpaceGrotesk',
                        shadows: [
                          Shadow(
                            color: AppColors.tBlue.withValues(alpha: 0.6),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Finance Management System',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5D7FA0),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Pulsing loader
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Opacity(
                        opacity: 0.5 + _pulse.value * 0.5,
                        child: const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status text
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7FA0C0),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
