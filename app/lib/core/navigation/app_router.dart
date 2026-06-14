import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../widgets/error_boundary.dart';

/// Listens to Supabase auth state changes and notifies GoRouter to
/// re-evaluate its redirect so sign-out / session-expiry automatically
/// redirects back to /login.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange
          .listen((_) => notifyListeners());
    } catch (_) {
      // Supabase not initialised (no config) — no-op.
    }
  }

  dynamic _sub;

  @override
  void dispose() {
    (_sub as dynamic)?.cancel();
    super.dispose();
  }
}

GoRouter createRouter(Ref ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: _AuthChangeNotifier(),
    redirect: (context, state) {
      final isDemo = ref.read(isDemoModeProvider);
      final isLoggedIn = AuthService.isLoggedIn;

      // If live mode is on but no session exists, revert to demo mode.
      // (Handles session expiry while the app is running.)
      if (!isDemo && !isLoggedIn) {
        ref.read(isDemoModeProvider.notifier).state = true;
        Hive.box<dynamic>('preferences').put('isDemoMode', true);
        if (state.matchedLocation != '/login') return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash',      builder: (c, s) => const _PlaceholderScreen('Splash', kNeonTeal)),
      GoRoute(path: '/login',       builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/home',        builder: (c, s) => const ErrorBoundary(moduleName: 'Home', child: HomeScreen())),
      GoRoute(path: '/settings',    builder: (c, s) => const ErrorBoundary(moduleName: 'Settings', child: SettingsScreen())),
      GoRoute(path: '/about',       builder: (c, s) => const ErrorBoundary(moduleName: 'About', child: AboutScreen())),
      GoRoute(path: '/genome',      builder: (c, s) => const ErrorBoundary(moduleName: 'Genome Browser', child: GenomeScreen())),
      GoRoute(path: '/genome_3d',   builder: (c, s) => const ErrorBoundary(moduleName: '3D Genome', child: Genome3dScreen())),
      GoRoute(path: '/variant',     builder: (c, s) => const ErrorBoundary(moduleName: 'Variant Analysis', child: VariantScreen())),
      GoRoute(path: '/expression',  builder: (c, s) => const ErrorBoundary(moduleName: 'Expression Analysis', child: ExpressionScreen())),
      GoRoute(path: '/pathway',     builder: (c, s) => const ErrorBoundary(moduleName: 'Pathway Enrichment', child: PathwayScreen())),
      GoRoute(path: '/protein',     builder: (c, s) => const ErrorBoundary(moduleName: 'Protein Explorer', child: ProteinScreen())),
      GoRoute(path: '/regulatory',  builder: (c, s) => const ErrorBoundary(moduleName: 'Regulatory Elements', child: RegulatoryScreen())),
      GoRoute(path: '/population',  builder: (c, s) => const ErrorBoundary(moduleName: 'Population Genetics', child: PopulationScreen())),
      GoRoute(path: '/prs',         builder: (c, s) => const ErrorBoundary(moduleName: 'Polygenic Risk Scores (PRS)', child: PrsScreen())),
      GoRoute(path: '/methylation', builder: (c, s) => const ErrorBoundary(moduleName: 'Epigenetics (Methylation)', child: MethylationScreen())),
      GoRoute(path: '/crispr',      builder: (c, s) => const ErrorBoundary(moduleName: 'CRISPR gRNA Design', child: CrisprScreen())),
      GoRoute(path: '/cancer',      builder: (c, s) => const ErrorBoundary(moduleName: 'Cancer Genomics', child: CancerScreen())),
      GoRoute(path: '/evolution',   builder: (c, s) => const ErrorBoundary(moduleName: 'Evolutionary Conservation', child: EvolutionScreen())),
      GoRoute(path: '/splicing',    builder: (c, s) => const ErrorBoundary(moduleName: 'Alternative Splicing', child: SplicingScreen())),
      GoRoute(path: '/drug',        builder: (c, s) => const ErrorBoundary(moduleName: 'Pharmacogenomics (Drug)', child: DrugScreen())),
      GoRoute(path: '/multi_omics', builder: (c, s) => const ErrorBoundary(moduleName: 'Multi-Omics Integration', child: MultiOmicsScreen())),
      GoRoute(path: '/collaboration',builder: (c, s) => const ErrorBoundary(moduleName: 'Real-time Collaboration', child: CollaborationScreen())),
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
