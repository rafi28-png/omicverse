// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/config/app_config.dart';
import 'core/providers/app_providers.dart';
import 'core/services/cache_service.dart';
import 'app.dart';

/// Minimal crash screen shown instead of the red Flutter error overlay.
class _CrashScreen extends StatelessWidget {
  final Object error;
  const _CrashScreen(this.error);

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF060912),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF6B6B), size: 48),
              const SizedBox(height: 20),
              const Text('Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 12),
              const Text(
                'Please refresh the page to continue.\n'
                'Your data is safe.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8899AA), fontSize: 14),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => runApp(const _ReloadingApp()),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5D4),
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReloadingApp extends StatelessWidget {
  const _ReloadingApp();
  @override
  Widget build(BuildContext context) {
    // Trigger a hot-restart equivalent by navigating to root.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: deprecated_member_use
      ServicesBinding.instance.defaultBinaryMessenger.send('flutter/platform',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('SystemNavigator.pop'),
          ));
    });
    return const SizedBox.shrink();
  }
}

void main() {
  // Catch Flutter framework errors (widget build errors, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}\n${details.stack}');
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Step 1: Read --dart-define values FIRST (used by web production builds)
    const defineUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const defineKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    // Step 2: Optionally load local .env (for local dev only).
    // MUST use try-catch so web production builds don't crash when .env is absent.
    try {
      await dotenv.load(fileName: '.env', isOptional: true);
    } catch (_) {
      // Safe: .env is optional. Production web uses --dart-define only.
    }

    // Step 3: Build config — dart-define wins, .env is local dev fallback.
    final config = AppConfig.fromEnvironment(
      dartDefineUrl: defineUrl,
      dartDefineKey: defineKey,
      dotenvUrl: dotenv.maybeGet('SUPABASE_URL'),
      dotenvKey: dotenv.maybeGet('SUPABASE_ANON_KEY'),
      dotenvAppName: dotenv.maybeGet('APP_NAME'),
      dotenvAppVersion: dotenv.maybeGet('APP_VERSION'),
      dotenvMaxVcf: dotenv.maybeGet('MAX_VCF_VARIANTS'),
      dotenvBatchSize: dotenv.maybeGet('ANNOTATION_BATCH_SIZE'),
      dotenvCacheTtl: dotenv.maybeGet('CACHE_TTL_HOURS'),
      dotenvDebug: dotenv.maybeGet('DEBUG_MODE'),
    );

    // Step 4: Initialize Hive
    await Hive.initFlutter();
    await Hive.openBox<dynamic>('cache');
    await Hive.openBox<dynamic>('preferences');
    await CacheService.init();

    // Step 5: Initialize Supabase only if config is present
    bool supabaseInitialized = false;
    if (config.isSupabaseConfigured) {
      try {
        await Supabase.initialize(
          url: config.supabaseUrl,
          publishableKey: config.supabaseAnonKey,
        );
        supabaseInitialized = true;
      } catch (e) {
        debugPrint('Supabase initialization failed: $e');
      }
    }

    // Step 5b: Guard demo-mode state.
    // If a previous user logged in (storing isDemoMode=false in Hive) but the
    // current visitor has no valid session, reset to demo mode so they cannot
    // access live features without authenticating.
    final prefBox = Hive.box<dynamic>('preferences');
    final storedDemoMode = prefBox.get('isDemoMode', defaultValue: true) as bool;
    if (!storedDemoMode) {
      // Only keep live mode if Supabase is up AND there is a current session.
      final hasSession = supabaseInitialized &&
          Supabase.instance.client.auth.currentSession != null;
      if (!hasSession) {
        prefBox.put('isDemoMode', true); // revert to demo mode
      }
    }

    final finalConfig = supabaseInitialized
        ? config
        : AppConfig(
            supabaseUrl: '',
            supabaseAnonKey: '',
            appName: config.appName,
            appVersion: config.appVersion,
            maxVcfVariants: config.maxVcfVariants,
            annotationBatchSize: config.annotationBatchSize,
            cacheTtlHours: config.cacheTtlHours,
            debugMode: config.debugMode,
          );

    // Step 6: App version
    String appVersion = '1.0.0';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    } catch (e) {
      debugPrint('Failed to load package info: $e');
    }

    // Step 7: Orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    runApp(ProviderScope(
      overrides: [
        appVersionProvider.overrideWithValue(appVersion),
        appConfigProvider.overrideWithValue(finalConfig),
      ],
      child: OmicVerseApp(supabaseConfigured: supabaseInitialized),
    ));
  }, (error, stack) {
    // Catch Dart async / zone errors not caught by FlutterError.onError.
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

