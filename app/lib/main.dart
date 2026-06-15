// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/config/app_config.dart';
import 'core/providers/app_providers.dart';
import 'core/services/cache_service.dart';
import 'app.dart';

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
    // Skipped on web — production web uses --dart-define, and attempting
    // to fetch assets/.env on web causes a 404 that delays startup by ~500ms.
    if (!kIsWeb) {
      try {
        await dotenv.load(fileName: '.env', isOptional: true);
      } catch (_) {}
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

    // Step 5: Initialize Supabase only if config is present.
    // Uses a Completer to race init vs timeout — avoids orphaned futures
    // that .timeout() creates (which cause uncaught zone errors on web).
    bool supabaseInitialized = false;
    if (config.isSupabaseConfigured) {
      try {
        final completer = Completer<bool>();

        // Start Supabase init — complete true on success, false on error.
        Supabase.initialize(
          url: config.supabaseUrl,
          publishableKey: config.supabaseAnonKey,
        ).then((_) {
          if (!completer.isCompleted) completer.complete(true);
        }).catchError((Object e) {
          debugPrint('Supabase init error: $e');
          if (!completer.isCompleted) completer.complete(false);
        });

        // 3-second deadline — if init hasn't finished, start in demo mode.
        Future<void>.delayed(const Duration(seconds: 3), () {
          if (!completer.isCompleted) {
            debugPrint('Supabase init timed out — running in demo mode');
            completer.complete(false);
          }
        });

        supabaseInitialized = await completer.future;
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

