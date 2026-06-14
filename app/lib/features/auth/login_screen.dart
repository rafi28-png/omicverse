import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _loading = false;
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
      } else {
        await AuthService.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: _nameCtrl.text.trim(),
        );
      }

      // ✅ Turn off demo mode so DEMO badge disappears and real features activate
      if (mounted) {
        ref.read(isDemoModeProvider.notifier).state = false;
        Hive.box<dynamic>('preferences').put('isDemoMode', false);
        context.go('/home');
      }
    } catch (e) {
      setState(() => _error = e.toString());
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
                          validator: (v) => v != null && v.contains('@')
                              ? null
                              : 'Enter a valid email',
                        ),
                        const SizedBox(height: 16),

                        _buildField(
                          controller: _passwordCtrl,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscure: true,
                          validator: (v) => v != null && v.length >= 6
                              ? null
                              : 'Minimum 6 characters',
                        ),
                        const SizedBox(height: 24),

                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _error!,
                              style: tsBody().copyWith(color: kNeonRed, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        NeonButton(
                          label: _isLogin ? 'Sign In' : 'Create Account',
                          icon: Icons.login,
                          isLoading: _loading,
                          onPressed: _submit,
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
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
