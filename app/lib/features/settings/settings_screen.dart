import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/navigation/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Settings', style: tsTitle(kTextPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App info
                GlowCard(
                  glowColor: kNeonTeal,
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: kGradGenome),
                        ),
                        child: const Icon(Icons.biotech, color: kVoid, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OmicVerse', style: tsTitle(kTextPrimary).copyWith(fontSize: 16)),
                          Text('Version $version', style: tsSubtitle()),
                        ],
                      ),
                      const Spacer(),
                      if (isDemoMode)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kNeonAmber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kNeonAmber.withValues(alpha: 0.35)),
                          ),
                          child: Text('DEMO', style: tsBadge().copyWith(color: kNeonAmber)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // General settings
                Text('GENERAL', style: tsLabel()),
                const SizedBox(height: 12),
                GlowCard(
                  glowColor: kNeonBlue,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle: 'Data sources, licenses, and attributions',
                        onTap: () => context.go('/about'),
                      ),
                      const Divider(color: kBorder, height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.science_outlined,
                        title: 'Demo Mode',
                        subtitle: isDemoMode
                            ? 'ON — using mock offline data'
                            : 'OFF — using live APIs (logged in)',
                        trailing: Switch(
                          value: isDemoMode,
                          onChanged: (wantsLiveMode) {
                            if (wantsLiveMode) {
                              // Turning ON demo mode (going from live → demo)
                              ref.read(isDemoModeProvider.notifier).state = true;
                              Hive.box<dynamic>('preferences').put('isDemoMode', true);
                              ref.read(routerRefreshProvider).notify();
                            } else {
                              // Turning OFF demo mode (wants live mode)
                              if (AuthService.isLoggedIn) {
                                // Already logged in — enable live mode immediately
                                ref.read(isDemoModeProvider.notifier).state = false;
                                Hive.box<dynamic>('preferences').put('isDemoMode', false);
                                ref.read(routerRefreshProvider).notify();
                              } else {
                                // NOT logged in — do NOT save false, just go to login
                                context.go('/login');
                              }
                            }
                          },
                          thumbColor: const WidgetStatePropertyAll(kNeonTeal),
                        ),
                      ),
                      const Divider(color: kBorder, height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.accessibility_new,
                        title: 'Reduce Motion',
                        subtitle: 'Disable animations throughout the app',
                        trailing: Switch(
                          value: false,
                          onChanged: (_) {},
                          thumbColor: const WidgetStatePropertyAll(kNeonTeal),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account section (only if not demo mode)
                if (!isDemoMode) ...[
                  Text('ACCOUNT', style: tsLabel()),
                  const SizedBox(height: 12),
                  GlowCard(
                    glowColor: kNeonPurple,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.logout,
                          title: 'Sign Out',
                          subtitle: 'Return to demo mode and login screen',
                          onTap: () async {
                            await AuthService.signOut();
                            if (context.mounted) {
                              // Reset demo mode before navigating
                              ref.read(isDemoModeProvider.notifier).state = true;
                              Hive.box<dynamic>('preferences').put('isDemoMode', true);
                              ref.read(routerRefreshProvider).notify();
                              context.go('/login');
                            }
                          },
                        ),
                        const Divider(color: kBorder, height: 1, indent: 56),
                        _SettingsTile(
                          icon: Icons.delete_forever,
                          title: 'Delete My App Data',
                          subtitle: 'Permanently remove all your data from the server',
                          iconColor: kNeonRed,
                          onTap: () => _confirmDelete(context),
                        ),
                      ],
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete All Data?', style: tsTitle(kNeonRed)),
        content: Text(
          'This will permanently delete all your projects, bookmarks, analyses, '
          'and account data. This action cannot be undone.',
          style: tsBody(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: tsBody().copyWith(color: kTextMuted)),
          ),
          NeonButton(
            label: 'Delete Everything',
            icon: Icons.delete_forever,
            color: kNeonRed,
            onPressed: () {
              Navigator.pop(ctx);
              AuthService.deleteAppData();
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Icon(icon, color: iconColor ?? kTextSecondary, size: 22),
      title: Text(title, style: tsBody().copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: tsBody().copyWith(fontSize: 11, color: kTextMuted)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: kTextMuted, size: 20),
      onTap: onTap,
    );
  }
}
