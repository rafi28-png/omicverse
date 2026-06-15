import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool   _loading = false;
  bool   _sent    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.sendPasswordResetEmail(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('user not found') || msg.contains('invalid')) {
      return 'No account found with that email address.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many requests. Please wait a minute and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
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
                // Icon
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kNeonAmber.withValues(alpha: 0.12),
                    border: Border.all(color: kNeonAmber.withValues(alpha: 0.4)),
                    boxShadow: [glowShadow(kNeonAmber, r: 30)],
                  ),
                  child: const Icon(Icons.lock_reset_outlined, color: kNeonAmber, size: 36),
                ),
                const SizedBox(height: 24),
                Text('Reset Password', style: tsHero().copyWith(fontSize: 26)),
                const SizedBox(height: 8),
                Text(
                  _sent
                    ? 'Check your inbox for a reset link.'
                    : 'Enter your email and we\'ll send you a reset link.',
                  style: tsSubtitle(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (_sent) ...[
                  // ── Success state ──
                  GlowCard(
                    glowColor: kNeonTeal,
                    child: Column(
                      children: [
                        const Icon(Icons.mark_email_read_outlined, color: kNeonTeal, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Reset link sent to\n${_emailCtrl.text.trim()}',
                          style: tsBody().copyWith(fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click the link in the email, then set your new password. The link expires in 1 hour.',
                          style: tsBody().copyWith(color: kTextMuted, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  NeonButton(
                    label: 'Back to Sign In',
                    icon: Icons.login,
                    color: kNeonTeal,
                    onPressed: () => context.go('/login'),
                  ),
                ] else ...[
                  // ── Form state ──
                  GlowCard(
                    glowColor: kNeonAmber,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: _inputDecoration('Email address', Icons.email_outlined),
                            style: tsBody(),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter your email';
                              if (!v.contains('@')) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
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
                                  Expanded(child: Text(_error!, style: tsBody().copyWith(color: kNeonRed, fontSize: 13))),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: NeonButton(
                              label: _loading ? 'Sending…' : 'Send Reset Link',
                              icon: _loading ? Icons.hourglass_top : Icons.send_outlined,
                              color: kNeonAmber,
                              onPressed: _loading ? null : _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      '← Back to Sign In',
                      style: tsBody().copyWith(color: kTextMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: tsBody().copyWith(color: kTextMuted),
    prefixIcon: Icon(icon, color: kTextMuted, size: 18),
    filled: true,
    fillColor: kSurface,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: kBorder),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: kBorder),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: kNeonAmber, width: 1.5),
    ),
  );
}
