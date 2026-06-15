import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/navigation/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl        = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _profileFormKey  = GlobalKey<FormState>();
  final _passFormKey     = GlobalKey<FormState>();

  bool _savingProfile  = false;
  bool _savingPassword = false;
  bool _obscure        = true;
  bool _profileSaved   = false;
  bool _passwordSaved  = false;
  String? _profileError;
  String? _passwordError;

  User? _user;

  @override
  void initState() {
    super.initState();
    _user = AuthService.currentUser;
    _nameCtrl.text        = (_user?.userMetadata?['name']        as String?) ?? '';
    _institutionCtrl.text = (_user?.userMetadata?['institution'] as String?) ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _institutionCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() { _savingProfile = true; _profileError = null; _profileSaved = false; });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {
          'name':        _nameCtrl.text.trim(),
          'institution': _institutionCtrl.text.trim(),
        }),
      );
      if (mounted) setState(() => _profileSaved = true);
    } catch (e) {
      setState(() => _profileError = 'Could not save profile. Please try again.');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() { _savingPassword = true; _passwordError = null; _passwordSaved = false; });
    try {
      await AuthService.updatePassword(_newPassCtrl.text);
      if (mounted) {
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        setState(() => _passwordSaved = true);
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      setState(() {
        _passwordError = msg.contains('same')
            ? 'New password must be different from your current password.'
            : 'Could not update password. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) {
      ref.read(isDemoModeProvider.notifier).state = true;
      Hive.box<dynamic>('preferences').put('isDemoMode', true);
      ref.read(routerRefreshProvider).notify();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? 'Unknown';
    final name  = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'User';
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text('My Profile', style: tsTitle(kTextPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Avatar + email card ─────────────────────────────────────
                GlowCard(
                  glowColor: kNeonTeal,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: kNeonTeal.withValues(alpha: 0.2),
                        child: Text(initials,
                          style: tsTitle(kNeonTeal).copyWith(fontSize: 22)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: tsTitle(kTextPrimary).copyWith(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(email, style: tsBody().copyWith(color: kTextMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kNeonTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kNeonTeal.withValues(alpha: 0.35)),
                        ),
                        child: Text('LIVE', style: tsBadge().copyWith(color: kNeonTeal)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Profile info form ───────────────────────────────────────
                Text('PROFILE INFO', style: tsLabel()),
                const SizedBox(height: 12),
                GlowCard(
                  glowColor: kNeonBlue,
                  child: Form(
                    key: _profileFormKey,
                    child: Column(
                      children: [
                        _field(
                          controller: _nameCtrl,
                          label: 'Display Name',
                          icon: Icons.person_outline,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        _field(
                          controller: _institutionCtrl,
                          label: 'Institution / Organisation',
                          icon: Icons.business_outlined,
                        ),
                        if (_profileError != null) ...[
                          const SizedBox(height: 12),
                          _errorBox(_profileError!),
                        ],
                        if (_profileSaved) ...[
                          const SizedBox(height: 12),
                          _successBox('Profile updated successfully.'),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: NeonButton(
                            label: _savingProfile ? 'Saving…' : 'Save Profile',
                            icon: _savingProfile ? Icons.hourglass_top : Icons.save_outlined,
                            color: kNeonBlue,
                            onPressed: _savingProfile ? null : _saveProfile,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Change password form ────────────────────────────────────
                Text('CHANGE PASSWORD', style: tsLabel()),
                const SizedBox(height: 12),
                GlowCard(
                  glowColor: kNeonPurple,
                  child: Form(
                    key: _passFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _newPassCtrl,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.newPassword],
                          style: tsBody(),
                          decoration: _decoration('New Password', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: kTextMuted, size: 18,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter a new password';
                            if (v.length < 8) return 'At least 8 characters';
                            if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include an uppercase letter';
                            if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include a number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPassCtrl,
                          obscureText: _obscure,
                          style: tsBody(),
                          decoration: _decoration('Confirm New Password', Icons.lock_outline),
                          validator: (v) =>
                              v != _newPassCtrl.text ? 'Passwords do not match' : null,
                        ),
                        if (_passwordError != null) ...[
                          const SizedBox(height: 12),
                          _errorBox(_passwordError!),
                        ],
                        if (_passwordSaved) ...[
                          const SizedBox(height: 12),
                          _successBox('Password changed successfully.'),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: NeonButton(
                            label: _savingPassword ? 'Saving…' : 'Update Password',
                            icon: _savingPassword ? Icons.hourglass_top : Icons.lock_reset,
                            color: kNeonPurple,
                            onPressed: _savingPassword ? null : _savePassword,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Account actions ─────────────────────────────────────────
                Text('ACCOUNT', style: tsLabel()),
                const SizedBox(height: 12),
                GlowCard(
                  glowColor: kNeonRed,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: const Icon(Icons.logout, color: kTextSecondary, size: 22),
                        title: Text('Sign Out', style: tsBody().copyWith(fontWeight: FontWeight.w500)),
                        subtitle: Text('Return to demo mode', style: tsBody().copyWith(fontSize: 11, color: kTextMuted)),
                        trailing: const Icon(Icons.chevron_right, color: kTextMuted, size: 20),
                        onTap: _signOut,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller: controller,
        onChanged: onChanged,
        style: tsBody(),
        decoration: _decoration(label, icon),
      );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
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
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: kNeonRed),
    ),
  );

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: kNeonRed.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: kNeonRed.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: kNeonRed, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: tsBody().copyWith(color: kNeonRed, fontSize: 13))),
    ]),
  );

  Widget _successBox(String msg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: kNeonTeal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: kNeonTeal.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.check_circle_outline, color: kNeonTeal, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: tsBody().copyWith(color: kNeonTeal, fontSize: 13))),
    ]),
  );
}
