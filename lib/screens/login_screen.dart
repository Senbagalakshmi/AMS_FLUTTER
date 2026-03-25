import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(String token, String userName) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  String _org = 'ORG001';
  final _uidCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final Map<String, String?> _errors = {};
  bool _isLoading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _uidCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final uid = _uidCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();

    setState(() {
      _errors['org'] = _org.isEmpty ? 'Organization is required' : null;
      _errors['uid'] = uid.isEmpty ? 'Email ID is required' : null;
      _errors['pwd'] = pwd.isEmpty ? 'Password is required' : null;
    });

    if (_errors.values.every((e) => e == null)) {
      setState(() => _isLoading = true);

      final token = await apiService.login(uid, pwd);

      if (mounted) {
        setState(() => _isLoading = false);
        if (token != null) {
           apiService.updateToken(token);
          widget.onLogin(token, uid);
        } else {
          setState(() {
            _errors['pwd'] = 'Invalid credentials or server error';
          });
        }
      }
    }
  }

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
              Color.fromARGB(255, 232, 233, 234), // Deep space navy
              Color.fromARGB(255, 22, 48, 98), // Mid navy
              Color.fromARGB(255, 244, 245, 247), // Back to deep
            ],
          ),
        ),
        child: Stack(
          children: [
            // Grid overlay
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            // Radial glows
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.8, -0.6),
                    radius: 1.5,
                    colors: [
                      Color(0x221447E6), // Brand Blue glow
                      Color(0x110B7A6E), // Brand Teal glow
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SizedBox(
                      width: 440,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x731447E6),
                                    blurRadius: 32,
                                    offset: Offset(0, 8))
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
                          const SizedBox(height: 16),
                          Text('BBOTS Management',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 5),
                          Text('LOGIN TO YOUR ACCOUNT',
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: const Color(0xFF5D7FA0))),
                          const SizedBox(height: 24),
                          // Login card
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DarkLabel('Organization (ORGCODE)'),
                                const SizedBox(height: 5),
                                _DarkDropdown(
                                  value: _org,
                                  items: const {
                                    'ORG001': 'ORG001 — Head Office, Chennai',
                                    'ORG002': 'ORG002 — Head Office, Bangalore',
                                    'ORG003': 'ORG003 — Head Office, Hyderabad',
                                  },
                                  hasError: _errors['org'] != null,
                                  onChanged: (v) =>
                                      setState(() => _org = v ?? _org),
                                ),
                                if (_errors['org'] != null)
                                  _errorText(_errors['org']!),
                                const SizedBox(height: 14),
                                _DarkLabel('Email ID'),
                                const SizedBox(height: 5),
                                _DarkInput(
                                    controller: _uidCtrl,
                                    placeholder: 'e.g. arjun@bbots.com',
                                    hasError: _errors['uid'] != null),
                                if (_errors['uid'] != null)
                                  _errorText(_errors['uid']!),
                                const SizedBox(height: 14),
                                _DarkLabel('Password'),
                                const SizedBox(height: 5),
                                _DarkInput(
                                    controller: _pwdCtrl,
                                    placeholder: '••••••••',
                                    obscure: true,
                                    hasError: _errors['pwd'] != null,
                                    onSubmit: _submit),
                                if (_errors['pwd'] != null)
                                  _errorText(_errors['pwd']!),
                                const SizedBox(height: 18),
                                Container(
                                    height: 1,
                                    color: Colors.white.withValues(alpha: 0.1)),
                                const SizedBox(height: 18),
                                // Sign in button
                                GestureDetector(
                                  onTap: _submit,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    decoration: BoxDecoration(
                                      color: _isLoading
                                          ? AppColors.tBlue
                                              .withValues(alpha: 0.7)
                                          : AppColors.tBlue,
                                      borderRadius: BorderRadius.circular(11),
                                      boxShadow: [
                                        if (!_isLoading)
                                          const BoxShadow(
                                              color: Color(0x601447E6),
                                              blurRadius: 18,
                                              offset: Offset(0, 4))
                                      ],
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white))
                                          : Text('Sign In →',
                                              style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('ADMIN SYSTEM',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  color: const Color(0xFF253D54),
                                  height: 1.8)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorText(String msg) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text('⚠ $msg',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF87171))),
      );
}

class _DarkLabel extends StatelessWidget {
  final String text;
  const _DarkLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF7FA0C0)));
}

class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool obscure;
  final bool hasError;
  final VoidCallback? onSubmit;

  const _DarkInput({
    required this.controller,
    required this.placeholder,
    this.obscure = false,
    this.hasError = false,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.spaceGrotesk(fontSize: 13, color: Colors.white),
      onFieldSubmitted: (_) => onSubmit?.call(),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: GoogleFonts.spaceGrotesk(
            fontSize: 13, color: const Color.fromARGB(255, 199, 219, 236)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(
              color: hasError
                  ? const Color(0xFFF87171)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        ),
      ),
    );
  }
}

class _DarkDropdown extends StatelessWidget {
  final String value;
  final Map<String, String> items;
  final bool hasError;
  final void Function(String?) onChanged;

  const _DarkDropdown({
    required this.value,
    required this.items,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      style: GoogleFonts.spaceGrotesk(fontSize: 13, color: Colors.white),
      dropdownColor: const Color(0xFF0D2040),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(
              color: hasError
                  ? const Color(0xFFF87171)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        ),
      ),
      items: items.entries
          .map((e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, color: Colors.white))))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 52) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 52) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
