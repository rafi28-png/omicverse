import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_navigator.dart';
import '../services/auth_service.dart';
import '../providers/app_providers.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/variant/variant_screen.dart';
import '../../features/expression/expression_screen.dart';
import '../../features/genome/genome_screen.dart';
import '../../features/pathway/pathway_screen.dart';
import '../../features/protein/protein_screen.dart';
import '../../features/regulatory/regulatory_screen.dart';
import '../../features/population/population_screen.dart';
import '../../features/prs/prs_screen.dart';
import '../../features/methylation/methylation_screen.dart';
import '../../features/crispr/crispr_screen.dart';
import '../../features/cancer/cancer_screen.dart';
import '../../features/evolution/evolution_screen.dart';
import '../../features/splicing/splicing_screen.dart';
import '../../features/drug/drug_screen.dart';
import '../../features/genome_3d/genome_3d_screen.dart';
import '../../features/multi_omics/multi_omics_screen.dart';
import '../../features/collaboration/collaboration_screen.dart';

GoRouter createRouter(Ref ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isDemo = ref.read(isDemoModeProvider);
      final isLoggedIn = AuthService.isLoggedIn;
      if (!isDemo && !isLoggedIn && state.matchedLocation != '/login') {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash',      builder: (c, s) => const _PlaceholderScreen('Splash', kNeonTeal)),
      GoRoute(path: '/login',       builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/home',        builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/settings',    builder: (c, s) => const SettingsScreen()),
      GoRoute(path: '/about',       builder: (c, s) => const AboutScreen()),
      GoRoute(path: '/genome',      builder: (c, s) => const GenomeScreen()),
      GoRoute(path: '/genome_3d',   builder: (c, s) => const Genome3dScreen()),
      GoRoute(path: '/variant',     builder: (c, s) => const VariantScreen()),
      GoRoute(path: '/expression',  builder: (c, s) => const ExpressionScreen()),
      GoRoute(path: '/pathway',     builder: (c, s) => const PathwayScreen()),
      GoRoute(path: '/protein',     builder: (c, s) => const ProteinScreen()),
      GoRoute(path: '/regulatory',  builder: (c, s) => const RegulatoryScreen()),
      GoRoute(path: '/population',  builder: (c, s) => const PopulationScreen()),
      GoRoute(path: '/prs',         builder: (c, s) => const PrsScreen()),
      GoRoute(path: '/methylation', builder: (c, s) => const MethylationScreen()),
      GoRoute(path: '/crispr',      builder: (c, s) => const CrisprScreen()),
      GoRoute(path: '/cancer',      builder: (c, s) => const CancerScreen()),
      GoRoute(path: '/evolution',   builder: (c, s) => const EvolutionScreen()),
      GoRoute(path: '/splicing',    builder: (c, s) => const SplicingScreen()),
      GoRoute(path: '/drug',        builder: (c, s) => const DrugScreen()),
      GoRoute(path: '/multi_omics', builder: (c, s) => const MultiOmicsScreen()),
      GoRoute(path: '/collaboration',builder: (c, s) => const CollaborationScreen()),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String name;
  final Color accentColor;
  const _PlaceholderScreen(this.name, this.accentColor);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackground,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
              boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 30)],
            ),
            child: Icon(Icons.science_outlined, color: accentColor, size: 36),
          ),
          const SizedBox(height: 24),
          Text(name, style: tsTitle(accentColor)),
          const SizedBox(height: 8),
          Text('Coming soon', style: tsSubtitle()),
        ],
      ),
    ),
  );
}
