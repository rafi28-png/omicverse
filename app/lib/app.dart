// lib/app.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/app_navigator.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/colors.dart';
import 'core/widgets/error_boundary.dart';
import 'core/widgets/error_state.dart';

final routerProvider = Provider<GoRouter>((ref) => createRouter(ref));

class OmicVerseApp extends ConsumerStatefulWidget {
  final bool supabaseConfigured;
  const OmicVerseApp({super.key, required this.supabaseConfigured});

  @override
  ConsumerState<OmicVerseApp> createState() => _OmicVerseAppState();
}

class _OmicVerseAppState extends ConsumerState<OmicVerseApp>
    with WidgetsBindingObserver {

  StreamSubscription<dynamic>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Register global error widget builder to intercept rendering errors
    ErrorWidget.builder = (FlutterErrorDetails details) {
      final handled = ErrorBoundary.reportError(details);
      if (handled) return const SizedBox.shrink();
      return Scaffold(
        backgroundColor: kBackground,
        body: ErrorState(
          message: 'An unexpected rendering error occurred: ${details.exception}',
        ),
      );
    };

    // ── Auth state listener ────────────────────────────────────────────────
    // Runs OUTSIDE the router redirect so we can safely mutate state.
    // When the user signs out (or the session expires), we:
    //   1. Reset isDemoMode → true in both Riverpod and Hive.
    //   2. Tell the router to re-evaluate its redirect (→ /login).
    if (widget.supabaseConfigured) {
      try {
        _authSub = Supabase.instance.client.auth.onAuthStateChange
            .listen((data) {
          if (!mounted) return;

          switch (data.event) {
            // ── User confirmed their email OR signed in normally ─────────────
            case AuthChangeEvent.signedIn:
              if (data.session != null && mounted) {
                // Enable live mode — home screen rebuilds with LIVE badge.
                // login_screen.dart already handles navigation for explicit
                // sign-in; this also handles auto-login after email confirmation
                // (user lands at /home, state flips, badge updates instantly).
                ref.read(isDemoModeProvider.notifier).state = false;
                Hive.box<dynamic>('preferences').put('isDemoMode', false);
                ref.read(routerRefreshProvider).notify();
              }

            // ── User clicked a password reset link ────────────────────────
            case AuthChangeEvent.passwordRecovery:
              final ctx = rootNavigatorKey.currentContext;
              if (ctx != null && ctx.mounted) ctx.go('/reset-password');

            // ── Session ended (sign-out, expiry) ───────────────────────────
            case AuthChangeEvent.signedOut:
              final isDemoMode = ref.read(isDemoModeProvider);
              if (!isDemoMode) {
                ref.read(isDemoModeProvider.notifier).state = true;
                Hive.box<dynamic>('preferences').put('isDemoMode', true);
              }
              ref.read(routerRefreshProvider).notify();

            default:
              // Session == null means token expired / other failure.
              if (data.session == null) {
                final isDemoMode = ref.read(isDemoModeProvider);
                if (!isDemoMode) {
                  ref.read(isDemoModeProvider.notifier).state = true;
                  Hive.box<dynamic>('preferences').put('isDemoMode', true);
                  ref.read(routerRefreshProvider).notify();
                }
              }
          }
        });
      } catch (_) {
        // Supabase not ready — safe to ignore.
      }
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Hive.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'OmicVerse',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackground,
        colorScheme: const ColorScheme.dark(
          primary: kNeonTeal,
          surface: kSurface,
        ),
      ),
    );
  }
}
