import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/safe_hive.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _isLogin            = true;
  bool _loading            = false;
  bool _verificationPending = false;
  bool _resendLoading      = false;
  bool _resendSent         = false;
  bool _obscure            = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      if (_isLogin) {
        await AuthService.signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
        if (mounted) {
          ref.read(isDemoModeProvider.notifier).state = false;
          safeWrite('preferences', 'isDemoMode', false);
          context.go('/home');
        }
      } else {
        final result = await AuthService.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: _nameCtrl.text.trim(),
        );
        if (!mounted) return;
        if (AuthService.needsEmailVerification(result)) {
          setState(() => _verificationPending = true);
        } else {
          ref.read(isDemoModeProvider.notifier).state = false;
          safeWrite('preferences', 'isDemoMode', false);
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() { _resendLoading = true; _resendSent = false; });
    try {
      await AuthService.resendConfirmationEmail(_emailCtrl.text.trim());
      if (mounted) setState(() => _resendSent = true);
    } catch (_) {
      // Silent fail — email may already be confirmed
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials') || msg.contains('wrong password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email first. Check your inbox for a confirmation link.';
    }
    if (msg.contains('user already registered') || msg.contains('already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (msg.contains('network') || msg.contains('connection') || msg.contains('socket')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (msg.contains('weak password') || msg.contains('password should')) {
      return 'Password is too weak. Use at least 8 characters with a mix of letters and numbers.';
    }
    if (msg.contains('not initialized') || msg.contains('not initialised')) {
      return 'App is not connected to the server. Please refresh the page.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    // ── Email verification pending screen ──────────────────────────────────
    if (_verificationPending) {
      return Scaffold(
        backgroundColor: kBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kNeonTeal.withValues(alpha: 0.12),
                      border: Border.all(color: kNeonTeal.withValues(alpha: 0.4)),
                      boxShadow: [glowShadow(kNeonTeal, r: 30)],
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined, color: kNeonTeal, size: 38),
                  ),
                  const SizedBox(height: 28),
                  Text('Check your inbox!', style: tsHero().copyWith(fontSize: 26)),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a confirmation link to\n${_emailCtrl.text.trim()}',
                    style: tsSubtitle().copyWith(fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click the link in the email to activate your account, then come back and sign in.',
                    style: tsBody().copyWith(color: kTextMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  NeonButton(
                    label: 'Go to Sign In',
                    icon: Icons.login,
                    color: kNeonTeal,
                    onPressed: () => setState(() {
                      _verificationPending = false;
                      _isLogin = true;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  // Resend confirmation email
                  if (_resendSent)
                    Text(
                      '✓ A new confirmation email has been sent.',
                      style: tsBody().copyWith(color: kNeonTeal, fontSize: 12),
                      textAlign: TextAlign.center,
                    )
                  else
                    TextButton.icon(
                      onPressed: _resendLoading ? null : _resendEmail,
                      icon: _resendLoading
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: kTextMuted),
                            )
                          : const Icon(Icons.refresh, size: 16, color: kTextMuted),
                      label: Text(
                        'Didn\'t receive it? Resend email',
                        style: tsBody().copyWith(color: kTextMuted, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Normal login / signup form ─────────────────────────────────────────
    return Scaffold(
      backgroundColor: kBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: kGradGenome),
                    boxShadow: [glowShadow(kNeonTeal, r: 30)],
                  ),
                  child: const Icon(Icons.biotech, color: kVoid, size: 36),
                ),
                const SizedBox(height: 24),
                Text('OmicVerse', style: tsHero()),
                const SizedBox(height: 8),
                Text(
                  'Bioinformatics Research Suite',
                  style: tsSubtitle(),
                ),
                const SizedBox(height: 40),

                // Form card
                GlowCard(
                  glowColor: kNeonTeal,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
                          style: tsLabel().copyWith(color: kNeonTeal),
                        ),
                        const SizedBox(height: 20),

                        if (!_isLogin) ...[
                          _buildField(
                            controller: _nameCtrl,
                            label: 'Name (optional)',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildField(
                          controller: _emailCtrl,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: (v) => v != null && v.contains('@')
                              ? null
                              : 'Enter a valid email address',
                        ),
                        const SizedBox(height: 16),

                        // Password field with visibility toggle
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          autofillHints: _isLogin
                              ? const [AutofillHints.password]
                              : const [AutofillHints.newPassword],
                          validator: (v) => v != null && v.length >= 6
                              ? null
                              : 'Minimum 6 characters',
                          style: tsBody(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: tsSubtitle(),
                            prefixIcon: const Icon(Icons.lock_outline, color: kTextMuted, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: kTextMuted, size: 18,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            filled: true,
                            fillColor: kSurfaceRaised,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: kBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: kBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: kNeonTeal, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: kNeonRed),
                            ),
                          ),
                        ),

                        // Forgot password (login mode only)
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.go('/forgot-password'),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4)),
                              child: Text(
                                'Forgot password?',
                                style: tsBody().copyWith(color: kTextMuted, fontSize: 12),
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Error message
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: kNeonRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kNeonRed.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: kNeonRed, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: tsBody().copyWith(color: kNeonRed, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        NeonButton(
                          label: _isLogin ? 'Sign In' : 'Create Account',
                          icon: Icons.login,
                          isLoading: _loading,
                          onPressed: _loading ? null : _submit,
                        ),
                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () => setState(() {
                            _isLogin = !_isLogin;
                            _error = null;
                          }),
                          child: Text(
                            _isLogin
                                ? 'Don\'t have an account? Sign up'
                                : 'Already have an account? Sign in',
                            style: tsBody().copyWith(
                              color: kNeonTeal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Demo mode button
                const SizedBox(height: 24),
                NeonButton(
                  label: 'Continue in Demo Mode',
                  icon: Icons.science_outlined,
                  color: kNeonAmber,
                  onPressed: () {
                    ref.read(isDemoModeProvider.notifier).state = true;
                    context.go('/home');
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore with bundled sample data — no account needed',
                  style: tsBody().copyWith(
                    color: kTextMuted,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: tsBody(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: tsSubtitle(),
        prefixIcon: Icon(icon, color: kTextMuted, size: 20),
        filled: true,
        fillColor: kSurfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kNeonTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kNeonRed),
        ),
      ),
    );
  }
}
