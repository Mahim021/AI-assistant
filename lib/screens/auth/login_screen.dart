import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const LoginScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get _isDark => widget.isDarkMode;
  Color get _bgColor =>
      _isDark ? const Color(0xFF0F0F14) : AppColors.lightBackground;
  Color get _cardColor =>
      _isDark ? const Color(0xFF1E1E2A) : AppColors.lightCard;
  Color get _borderColor =>
      _isDark ? const Color(0xFF2A2A3A) : AppColors.lightBorder;
  Color get _textPrimary =>
      _isDark ? const Color(0xFFE8E8F0) : AppColors.lightText;
  Color get _textSecondary =>
      _isDark ? const Color(0xFF9090A8) : AppColors.lightSubtext;
  Color get _accentBlue =>
      _isDark ? const Color(0xFF3D7FFF) : AppColors.primaryBlue;
  Color get _surfaceColor =>
      _isDark ? const Color(0xFF1A1A24) : AppColors.lightSurface;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Mode switch ─────────────────────────────────────────────────────────

  void _switchMode() {
    _animController.reverse().then((_) {
      setState(() {
        _isLogin = !_isLogin;
        _errorMessage = null;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
      _animController.forward();
    });
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  String? _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_isLogin && _nameController.text.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    if (email.isEmpty) return 'Please enter your email address.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email address.';
    }
    if (password.isEmpty) return 'Please enter your password.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (!_isLogin && _confirmPasswordController.text != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  // ─── Email / Password submit ──────────────────────────────────────────────

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await AuthService.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await AuthService.signUpWithEmail(
          _emailController.text,
          _passwordController.text,
          _nameController.text,
        );
      }
      // Auth state change in main.dart handles navigation automatically.
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Google sign-in ───────────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.signInWithGoogle(signUp: !_isLogin);
      // null means user dismissed the account picker — do nothing
      if (result == null && mounted) {
        setState(() => _googleLoading = false);
      }
      // On success, auth state change handles navigation.
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // ─── Forgot password ──────────────────────────────────────────────────────

  void _showForgotPassword() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
        isDark: _isDark,
        accentBlue: _accentBlue,
        cardColor: _cardColor,
        borderColor: _borderColor,
        textPrimary: _textPrimary,
        textSecondary: _textSecondary,
        surfaceColor: _surfaceColor,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildBrand(),
                  const SizedBox(height: 36),
                  _buildCard(),
                  const SizedBox(height: 24),
                  _buildToggleMode(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accentBlue, _accentBlue.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _accentBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Assistant',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          _isLogin ? 'Welcome back' : 'Get started',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isLogin
              ? 'Sign in to continue to your assistant'
              : 'Create your account to get started',
          style: TextStyle(color: _textSecondary, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: _isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field — sign-up only
          if (!_isLogin) ...[
            _buildLabel('Full Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'Alex Harrison',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),
          ],
          _buildLabel('Email Address'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildLabel('Password'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hint: _isLogin ? 'Your password' : 'At least 6 characters',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: _eyeButton(
              obscured: _obscurePassword,
              onTap: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          // Confirm password — sign-up only
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            _buildLabel('Confirm Password'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _confirmPasswordController,
              hint: 'Repeat your password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirm,
              suffixIcon: _eyeButton(
                obscured: _obscureConfirm,
                onTap: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ],
          // Forgot password — sign-in only
          if (_isLogin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _showForgotPassword,
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: _accentBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildError(),
          ],
          const SizedBox(height: 20),
          _buildSubmitButton(),
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          _buildGoogleButton(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _textPrimary,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: _textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: _textSecondary, size: 19),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentBlue, width: 1.5),
        ),
      ),
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _eyeButton({required bool obscured, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: _textSecondary,
        size: 18,
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.dangerRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.dangerRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.dangerRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accentBlue.withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                _isLogin ? 'Sign In' : 'Create Account',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _borderColor, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child:
              Text('or continue with',
                  style: TextStyle(color: _textSecondary, fontSize: 12)),
        ),
        Expanded(child: Divider(color: _borderColor, height: 1)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _googleLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: BorderSide(color: _borderColor),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          backgroundColor: _surfaceColor,
          disabledForegroundColor: _textSecondary,
        ),
        child: _googleLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: _accentBlue, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleIcon(),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin
              ? "Don't have an account?  "
              : 'Already have an account?  ',
          style: TextStyle(color: _textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: _switchMode,
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: TextStyle(
              color: _accentBlue,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Forgot password dialog ──────────────────────────────────────────────────

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  final bool isDark;
  final Color accentBlue;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color surfaceColor;

  const _ForgotPasswordDialog({
    required this.initialEmail,
    required this.isDark,
    required this.accentBlue,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.surfaceColor,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _ctrl;
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _ctrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.sendPasswordReset(email);
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + title
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.accentBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.lock_reset_rounded,
              color: widget.accentBlue, size: 22),
        ),
        const SizedBox(height: 14),
        Text(
          'Reset password',
          style: TextStyle(
            color: widget.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Enter your account email and we'll send a reset link.",
          style: TextStyle(
              color: widget.textSecondary, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 20),
        // Email field
        TextField(
          controller: _ctrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          style: TextStyle(color: widget.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'you@example.com',
            hintStyle: TextStyle(color: widget.textSecondary, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.email_outlined,
                  color: widget.textSecondary, size: 19),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: widget.surfaceColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.accentBlue, width: 1.5),
            ),
          ),
          onSubmitted: (_) => _send(),
        ),
        // Error
        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.dangerRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.dangerRed.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.dangerRed, size: 15),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppColors.dangerRed, fontSize: 12.5)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.textSecondary,
                  side: BorderSide(color: widget.borderColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      widget.accentBlue.withValues(alpha: 0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Send Link',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: AppColors.successGreen, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          'Check your inbox',
          style: TextStyle(
            color: widget.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A password reset link has been sent to\n${_ctrl.text.trim()}',
          style: TextStyle(
              color: widget.textSecondary, fontSize: 13.5, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: const Text('Done',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ─── Google logo icon ────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final red = Paint()..color = const Color(0xFFEA4335);
    final blue = Paint()..color = const Color(0xFF4285F4);
    final yellow = Paint()..color = const Color(0xFFFBBC05);
    final green = Paint()..color = const Color(0xFF34A853);

    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -0.52, 1.57, true, blue);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -2.09, 1.57, true, red);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        2.62, 0.53, true, yellow);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        1.05, 1.57, true, green);

    canvas.drawCircle(
        Offset(cx, cy), r * 0.6, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(cx - 0.1, cy - r * 0.22, r * 1.05, r * 0.44),
      blue,
    );
    canvas.drawCircle(
        Offset(cx, cy), r * 0.42, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
