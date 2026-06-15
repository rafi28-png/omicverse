// lib/app.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/navigation/app_router.dart';
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
          // Reset to demo mode whenever there is no active session
          // (covers sign-out, session expiry, and any auth failure).
          final signedOut = data.event == AuthChangeEvent.signedOut ||
              data.session == null;

          if (signedOut && mounted) {
            // Reset demo mode safely (NOT inside a redirect callback).
            final isDemoMode = ref.read(isDemoModeProvider);
            if (!isDemoMode) {
              ref.read(isDemoModeProvider.notifier).state = true;
              Hive.box<dynamic>('preferences').put('isDemoMode', true);
            }
            // Trigger router refresh so redirect fires and sends to /login.
            ref.read(routerRefreshProvider).notify();
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
