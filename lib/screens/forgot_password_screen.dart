import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  
  final Map<String, String?> _errors = {};
  bool _isLoading = false;
  
  int _step = 0; // 0: Request, 1: Verify OTP, 2: Reset Password
  String? _tokenKey;
  Map<String, dynamic>? _passwordPolicy;
  
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
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final email = _emailCtrl.text.trim();
    setState(() {
      _errors.clear();
      if (email.isEmpty) _errors['email'] = 'Email ID is required';
    });

    if (_errors.isEmpty) {
      setState(() => _isLoading = true);
      final apiService = ApiService();
      final token = await apiService.forgotPasswordRequest(email);
      if (mounted) {
        setState(() => _isLoading = false);
        if (token != null) {
          _tokenKey = token;
          setState(() => _step = 1);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to request OTP. Check your email.')),
          );
        }
      }
    }
  }

  Future<void> _submitVerify() async {
    final otp = _otpCtrl.text.trim();
    setState(() {
      _errors.clear();
      if (otp.isEmpty) _errors['otp'] = 'OTP is required';
    });

    if (_errors.isEmpty && _tokenKey != null) {
      setState(() => _isLoading = true);
      final apiService = ApiService();
      final success = await apiService.forgotPasswordVerify(_tokenKey!, otp);
      if (mounted) {
        if (success) {
          final policy = await apiService.getPasswordPolicy();
          setState(() {
            _isLoading = false;
            _passwordPolicy = policy;
            _step = 2;
          });
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid OTP. Please try again.')),
          );
        }
      }
    }
  }

  Future<void> _submitReset() async {
    final newPwd = _newPwdCtrl.text.trim();
    final confirmPwd = _confirmPwdCtrl.text.trim();
    
    setState(() {
      _errors.clear();
      if (newPwd.isEmpty) _errors['newPwd'] = 'New password is required';
      if (confirmPwd.isEmpty) _errors['confirmPwd'] = 'Confirm password is required';
      if (newPwd.isNotEmpty && confirmPwd.isNotEmpty && newPwd != confirmPwd) {
        _errors['confirmPwd'] = 'Passwords do not match';
      }
    });

    if (_errors.isEmpty && _tokenKey != null) {
      setState(() => _isLoading = true);
      final apiService = ApiService();
      final success = await apiService.forgotPasswordReset(_tokenKey!, newPwd, confirmPwd);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset successfully!')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to reset password. Please try again.')),
          );
        }
      }
    }
  }

  void _submit() {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    if (_step == 0) {
      _submitRequest().whenComplete(() {
        if (mounted && _step == 0) setState(() => _isLoading = false);
      });
    } else if (_step == 1) {
      _submitVerify().whenComplete(() {
        if (mounted && _step == 1) setState(() => _isLoading = false);
      });
    } else if (_step == 2) {
      _submitReset().whenComplete(() {
        if (mounted && _step == 2) setState(() => _isLoading = false);
      });
    }
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DarkLabel('Email ID'),
        const SizedBox(height: 5),
        _DarkInput(
          controller: _emailCtrl,
          placeholder: 'e.g. arjun@bbots.com',
          hasError: _errors['email'] != null,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmit: _submit,
        ),
        if (_errors['email'] != null) _errorText(_errors['email']!),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DarkLabel('Enter OTP'),
        const SizedBox(height: 5),
        _DarkInput(
          controller: _otpCtrl,
          placeholder: 'e.g. 123456',
          hasError: _errors['otp'] != null,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmit: _submit,
        ),
        if (_errors['otp'] != null) _errorText(_errors['otp']!),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_passwordPolicy != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Policy Note',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(height: 8),
                if (_passwordPolicy!['minLength'] != null)
                  _PolicyRow('Minimum Length', '${_passwordPolicy!['minLength']}'),
                if (_passwordPolicy!['maxLength'] != null)
                  _PolicyRow('Maximum Length', '${_passwordPolicy!['maxLength']}'),
                if (_passwordPolicy!['requireUppercase'] == true)
                  _PolicyRow('Require Uppercase', 'Yes'),
                if (_passwordPolicy!['requireLowercase'] == true)
                  _PolicyRow('Require Lowercase', 'Yes'),
                if (_passwordPolicy!['requireNumber'] == true)
                  _PolicyRow('Require Number', 'Yes'),
                if (_passwordPolicy!['requireSpecialChar'] == true)
                  _PolicyRow('Require Special Character', 'Yes'),
              ],
            ),
          ),
        ],
        const _DarkLabel('New Password'),
        const SizedBox(height: 5),
        _DarkInput(
          controller: _newPwdCtrl,
          placeholder: '••••••••',
          obscure: true,
          hasError: _errors['newPwd'] != null,
          textInputAction: TextInputAction.next,
        ),
        if (_errors['newPwd'] != null) _errorText(_errors['newPwd']!),
        const SizedBox(height: 14),
        const _DarkLabel('Confirm Password'),
        const SizedBox(height: 5),
        _DarkInput(
          controller: _confirmPwdCtrl,
          placeholder: '••••••••',
          obscure: true,
          hasError: _errors['confirmPwd'] != null,
          textInputAction: TextInputAction.done,
          onSubmit: _submit,
        ),
        if (_errors['confirmPwd'] != null) _errorText(_errors['confirmPwd']!),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Responsive breakpoints ──────────────────────────────────────────────
    final screenW = MediaQuery.of(context).size.width;
    final isCompact = screenW < 480;
    final cardWidth = isCompact
        ? double.infinity
        : screenW < 768
            ? screenW * 0.82
            : 440.0;

    final hPad = isCompact ? 16.0 : 24.0;
    final cardPad = isCompact ? 20.0 : 28.0;
    final logoSize = isCompact ? 80.0 : 100.0;
    final titleFontSize = isCompact ? 20.0 : 24.0;
    // ───────────────────────────────────────────────────────────────────────

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
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.8, -0.6),
                    radius: 1.5,
                    colors: [
                      Color(0x221447E6),
                      Color(0x110B7A6E),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF253D54)),
                  onPressed: () {
                    if (_step > 0) {
                      setState(() => _step--);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SizedBox(
                        width: cardWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x731447E6),
                                    blurRadius: 32,
                                    offset: Offset(0, 8),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Forgot Password',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _step == 0 
                                  ? 'RESET YOUR ACCOUNT PASSWORD' 
                                  : _step == 1 
                                      ? 'VERIFY YOUR IDENTITY' 
                                      : 'CREATE NEW PASSWORD',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: const Color(0xFF5D7FA0),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(cardPad),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_step == 0) _buildStep0(),
                                  if (_step == 1) _buildStep1(),
                                  if (_step == 2) _buildStep2(),
                                  
                                  const SizedBox(height: 18),
                                  Container(
                                    height: 1,
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  const SizedBox(height: 18),
                                  GestureDetector(
                                    onTap: _submit,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      decoration: BoxDecoration(
                                        color: _isLoading
                                            ? AppColors.tBlue.withValues(alpha: 0.7)
                                            : AppColors.tBlue,
                                        borderRadius: BorderRadius.circular(11),
                                        boxShadow: [
                                          if (!_isLoading)
                                            const BoxShadow(
                                              color: Color(0x601447E6),
                                              blurRadius: 18,
                                              offset: Offset(0, 4),
                                            )
                                        ],
                                      ),
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                _step == 0 
                                                    ? 'Get OTP →' 
                                                    : _step == 1 
                                                        ? 'Verify OTP →' 
                                                        : 'Reset Password →',
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'ADMIN SYSTEM',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: const Color(0xFF253D54),
                                height: 1.8,
                              ),
                            ),
                          ],
                        ),
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
        child: Text(
          '⚠ $msg',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF87171),
          ),
        ),
      );
}

class _PolicyRow extends StatelessWidget {
  final String label;
  final String value;
  const _PolicyRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 12, color: const Color(0xFF60A5FA)),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkLabel extends StatelessWidget {
  final String text;
  const _DarkLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF7FA0C0),
        ),
      );
}

class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool obscure;
  final bool hasError;
  final VoidCallback? onSubmit;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const _DarkInput({
    required this.controller,
    required this.placeholder,
    this.obscure = false,
    this.hasError = false,
    this.onSubmit,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: GoogleFonts.spaceGrotesk(fontSize: 13, color: Colors.white),
      onFieldSubmitted: (_) => onSubmit?.call(),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          color: const Color.fromARGB(255, 199, 219, 236),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFF87171) : Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        ),
      ),
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
