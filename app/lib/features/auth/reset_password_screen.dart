import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  final _formKey       = GlobalKey<FormState>();
  bool   _loading      = false;
  bool   _obscure      = true;
  bool   _done         = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.updatePassword(_passwordCtrl.text);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      setState(() {
        if (msg.contains('same password') || msg.contains('different')) {
          _error = 'New password must be different from your current password.';
        } else if (msg.contains('weak') || msg.contains('short')) {
          _error = 'Password is too weak. Use at least 8 characters.';
        } else {
          _error = 'Could not update your password. The reset link may have expired.';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kNeonTeal.withValues(alpha: 0.12),
                    border: Border.all(color: kNeonTeal.withValues(alpha: 0.4)),
                    boxShadow: [glowShadow(kNeonTeal, r: 30)],
                  ),
                  child: Icon(
                    _done ? Icons.check_circle_outline : Icons.lock_outline,
                    color: kNeonTeal, size: 36,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _done ? 'Password Updated!' : 'Set New Password',
                  style: tsHero().copyWith(fontSize: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  _done
                    ? 'Your password has been changed successfully.'
                    : 'Enter your new password below.',
                  style: tsSubtitle(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (_done) ...[
                  GlowCard(
                    glowColor: kNeonTeal,
                    child: Column(
                      children: [
                        const Icon(Icons.verified_user_outlined, color: kNeonTeal, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'You can now sign in with your new password.',
                          style: tsBody(),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  NeonButton(
                    label: 'Sign In',
                    icon: Icons.login,
                    color: kNeonTeal,
                    onPressed: () => context.go('/login'),
                  ),
                ] else ...[
                  GlowCard(
                    glowColor: kNeonTeal,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: _inputDecoration('New password', Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: kTextMuted, size: 18,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            style: tsBody(),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter a new password';
                              if (v.length < 8) return 'Password must be at least 8 characters';
                              if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least one uppercase letter';
                              if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: _inputDecoration('Confirm password', Icons.lock_outline),
                            style: tsBody(),
                            validator: (v) {
                              if (v != _passwordCtrl.text) return 'Passwords do not match';
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

                          // Password strength hints
                          _PasswordHints(password: _passwordCtrl.text),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: NeonButton(
                              label: _loading ? 'Saving…' : 'Update Password',
                              icon: _loading ? Icons.hourglass_top : Icons.save_outlined,
                              color: kNeonTeal,
                              onPressed: _loading ? null : _submit,
                            ),
                          ),
                        ],
                      ),
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
      borderSide: BorderSide(color: kNeonTeal, width: 1.5),
    ),
  );
}

class _PasswordHints extends StatelessWidget {
  final String password;
  const _PasswordHints({required this.password});

  @override
  Widget build(BuildContext context) {
    final checks = [
      ('8+ characters',      password.length >= 8),
      ('Uppercase letter',   RegExp(r'[A-Z]').hasMatch(password)),
      ('Number',             RegExp(r'[0-9]').hasMatch(password)),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: checks.map((c) => _Hint(label: c.$1, met: c.$2)).toList(),
    );
  }
}

class _Hint extends StatelessWidget {
  final String label;
  final bool met;
  const _Hint({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: met ? kNeonTeal : kTextMuted,
        ),
        const SizedBox(width: 4),
        Text(label, style: tsBody().copyWith(fontSize: 11, color: met ? kNeonTeal : kTextMuted)),
      ],
    );
  }
}
