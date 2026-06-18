import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/safe_hive.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/research_disclaimer.dart';
import '../../core/widgets/onboarding_overlay.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/auth_service.dart';

class _ModuleInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final List<Color> gradient;

  const _ModuleInfo(this.title, this.subtitle, this.icon, this.route, this.gradient);
}

final _modules = [
  const _ModuleInfo('Genome', 'Gene structure & annotation', Icons.schema_outlined, '/genome', kGradGenome),
  const _ModuleInfo('Variant', 'VCF analysis & annotation', Icons.compare_arrows, '/variant', kGradVariant),
  const _ModuleInfo('Expression', 'RNA-seq differential analysis', Icons.bar_chart, '/expression', kGradExpression),
  const _ModuleInfo('Pathway', 'Biological pathway enrichment', Icons.hub, '/pathway', kGradPathway),
  const _ModuleInfo('Protein', 'Structure & interactions', Icons.view_in_ar, '/protein', kGradProtein),
  const _ModuleInfo('Regulatory', 'Enhancers & TF binding', Icons.tune, '/regulatory', kGradRegulatory),
  const _ModuleInfo('Population', 'Allele frequencies & ancestry', Icons.groups, '/population', kGradPopulation),
  const _ModuleInfo('PRS', 'Polygenic risk scores', Icons.assessment, '/prs', kGradPRS),
  const _ModuleInfo('Methylation', 'Epigenetic age clocks', Icons.timelapse, '/methylation', kGradEpigenome),
  const _ModuleInfo('CRISPR', 'Guide RNA design', Icons.content_cut, '/crispr', kGradCRISPR),
  const _ModuleInfo('Cancer', 'Somatic mutations & oncoprint', Icons.coronavirus, '/cancer', kGradCancer),
  const _ModuleInfo('Evolution', 'Conservation & phylogenetics', Icons.park, '/evolution', kGradEvolution),
  const _ModuleInfo('Splicing', 'Alternative splicing events', Icons.call_split, '/splicing', kGradSplicing),
  const _ModuleInfo('Drug', 'Drug-gene interactions', Icons.medication, '/drug', kGradDrug),
  const _ModuleInfo('Disease Genetics', 'OMIM & DisGeNET diseases', Icons.local_hospital_outlined, '/genome_3d', kGrad3DGenome),
  const _ModuleInfo('Multi-Omics', 'Unified gene profiles', Icons.hub_outlined, '/multi_omics', [kNeonTeal, kNeonPurple]),
  const _ModuleInfo('Collaboration', 'Real-time project sharing', Icons.groups_outlined, '/collaboration', [kNeonPink, kNeonBlue]),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    final seen = safeRead<bool>('preferences', 'hasSeenOnboarding', false);
    if (!seen) {
      // Delay so the home screen renders first
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showOnboarding = true);
      });
    }
  }

  void _dismissOnboarding() {
    safeWrite('preferences', 'hasSeenOnboarding', true);
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    final version = ref.watch(appVersionProvider);
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = width > 1200 ? 4 : (width > 800 ? 3 : (width > 500 ? 2 : 1));

    final scaffold = Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          // App bar area
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: logo + demo badge + settings
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: kGradGenome),
                            boxShadow: [glowShadow(kNeonTeal, r: 16)],
                          ),
                          child: const Icon(Icons.biotech, color: kVoid, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('OmicVerse', style: tsTitle(kTextGlow)),
                              Text('v$version', style: tsLabel()),
                            ],
                          ),
                        ),
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
                        if (!isDemoMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kNeonTeal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kNeonTeal.withValues(alpha: 0.35)),
                            ),
                            child: Text('LIVE', style: tsBadge().copyWith(color: kNeonTeal)),
                          ),
                        const SizedBox(width: 8),
                        // Profile avatar / login shortcut
                        if (!isDemoMode) ...[
                          GestureDetector(
                            onTap: () => context.go('/profile'),
                            child: Builder(builder: (ctx) {
                              final user = AuthService.currentUser;
                              final name = (user?.userMetadata?['name'] as String?) ?? user?.email ?? 'U';
                              final initials = name.trim().split(' ')
                                  .map((w) => w.isNotEmpty ? w[0] : '')
                                  .take(2).join().toUpperCase();
                              return Tooltip(
                                message: 'My Profile',
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: kNeonTeal.withValues(alpha: 0.2),
                                  child: Text(initials,
                                    style: tsLabel().copyWith(color: kNeonTeal, fontSize: 12)),
                                ),
                              );
                            }),
                          ),
                        ] else ...[
                          Tooltip(
                            message: 'Sign in',
                            child: IconButton(
                              icon: const Icon(Icons.login, color: kTextSecondary),
                              onPressed: () => context.go('/login'),
                            ),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: kTextSecondary),
                          onPressed: () => context.go('/settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Welcome text — personalised if logged in
                    if (!isDemoMode) ...[
                      Builder(builder: (context) {
                        final user = AuthService.currentUser;
                        final name = user?.userMetadata?['name'] as String?;
                        final email = user?.email ?? '';
                        final displayName = (name != null && name.isNotEmpty) ? name : email;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: tsSubtitle(),
                            ),
                            Text(
                              displayName,
                              style: tsHero().copyWith(fontSize: 22, color: kNeonTeal),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text('Explore Modules', style: tsHero().copyWith(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to save your analyses and access live data',
                        style: tsSubtitle(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Tap a module to begin your analysis',
                      style: tsSubtitle(),
                    ),
                    const SizedBox(height: 20),
                    const ResearchDisclaimer(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Module grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ModuleCard(module: _modules[i]),
                childCount: _modules.length,
              ),
            ),
          ),

          // Footer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  const Divider(color: kBorder, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/about'),
                        child: Text('About', style: tsBody().copyWith(color: kTextMuted, fontSize: 12)),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => context.go('/settings'),
                        child: Text('Settings', style: tsBody().copyWith(color: kTextMuted, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        scaffold,
        if (_showOnboarding)
          OnboardingOverlay(onDone: _dismissOnboarding),
      ],
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final _ModuleInfo module;
  const _ModuleCard({required this.module});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    return Semantics(
      button: true,
      label: '${m.title} module — ${m.subtitle}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit:  (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: () => context.go(m.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _hovering ? kSurfaceRaised : kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovering ? m.gradient.first.withValues(alpha: 0.5) : kBorder,
                width: _hovering ? 1.5 : 1,
              ),
              boxShadow: _hovering
                  ? [BoxShadow(color: m.gradient.first.withValues(alpha: 0.15), blurRadius: 24)]
                  : [depthShadow()],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: m.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: _hovering ? [glowShadow(m.gradient.first, r: 12)] : [],
                      ),
                      child: Icon(m.icon, color: kVoid, size: 18),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _hovering ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: m.gradient.first, size: 18),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title,
                        style: tsBody().copyWith(
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _hovering ? m.gradient.first : kTextPrimary)),
                    const SizedBox(height: 4),
                    Text(m.subtitle,
                        style: tsBody().copyWith(fontSize: 11, color: kTextMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
