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
import 'core/utils/safe_hive.dart';
import 'app.dart';

void main() {
  // Catch Flutter framework errors (widget build errors, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}\n${details.stack}');
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ── All init wrapped so runApp() ALWAYS executes ──────────────────
    bool supabaseOk = false;
    AppConfig finalConfig = AppConfig(
      supabaseUrl: '',
      supabaseAnonKey: '',
      appName: 'OmicVerse',
      appVersion: '1.0.0',
      maxVcfVariants: 1000,
      annotationBatchSize: 50,
      cacheTtlHours: 24,
      debugMode: false,
    );
    String appVersion = '1.0.0';

    try {
      // Step 1: Read --dart-define values
      const defineUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
      const defineKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

      // Step 2: Load .env (local dev only, skip on web)
      if (!kIsWeb) {
        try {
          await dotenv.load(fileName: '.env', isOptional: true);
        } catch (_) {}
      }

      // Step 3: Build config
      final config = AppConfig.fromEnvironment(
        dartDefineUrl: defineUrl,
        dartDefineKey: defineKey,
        dotenvUrl: kIsWeb ? null : dotenv.maybeGet('SUPABASE_URL'),
        dotenvKey: kIsWeb ? null : dotenv.maybeGet('SUPABASE_ANON_KEY'),
        dotenvAppName: kIsWeb ? null : dotenv.maybeGet('APP_NAME'),
        dotenvAppVersion: kIsWeb ? null : dotenv.maybeGet('APP_VERSION'),
        dotenvMaxVcf: kIsWeb ? null : dotenv.maybeGet('MAX_VCF_VARIANTS'),
        dotenvBatchSize: kIsWeb ? null : dotenv.maybeGet('ANNOTATION_BATCH_SIZE'),
        dotenvCacheTtl: kIsWeb ? null : dotenv.maybeGet('CACHE_TTL_HOURS'),
        dotenvDebug: kIsWeb ? null : dotenv.maybeGet('DEBUG_MODE'),
      );

      // Step 4: Initialize Hive
      try { await Hive.initFlutter(); } catch (e) {
        debugPrint('Hive.initFlutter failed: $e');
      }
      try {
        if (!Hive.isBoxOpen('cache')) await Hive.openBox<dynamic>('cache');
      } catch (e) {
        debugPrint('Hive openBox cache failed: $e');
      }
      try {
        if (!Hive.isBoxOpen('preferences')) await Hive.openBox<dynamic>('preferences');
      } catch (e) {
        debugPrint('Hive openBox preferences failed: $e');
      }
      try { await CacheService.init(); } catch (e) {
        debugPrint('CacheService.init failed: $e');
      }

      // Step 5: Initialize Supabase
      if (config.isSupabaseConfigured) {
        try {
          final completer = Completer<bool>();

          Supabase.initialize(
            url: config.supabaseUrl,
            publishableKey: config.supabaseAnonKey,
          ).then((_) {
            if (!completer.isCompleted) completer.complete(true);
          }).catchError((Object e) {
            debugPrint('Supabase init error: $e');
            if (!completer.isCompleted) completer.complete(false);
          });

          Future<void>.delayed(const Duration(seconds: 3), () {
            if (!completer.isCompleted) {
              debugPrint('Supabase init timed out — demo mode');
              completer.complete(false);
            }
          });

          supabaseOk = await completer.future;
        } catch (e) {
          debugPrint('Supabase initialization failed: $e');
        }
      }

      // Step 5b: Guard demo-mode state
      try {
        final storedDemoMode = safeRead<bool>('preferences', 'isDemoMode', true);
        if (!storedDemoMode) {
          bool hasSession = false;
          if (supabaseOk) {
            try {
              hasSession = Supabase.instance.client.auth.currentSession != null;
            } catch (_) {}
          }
          if (!hasSession) {
            safeWrite('preferences', 'isDemoMode', true);
          }
        }
      } catch (e) {
        debugPrint('Demo mode guard failed (non-fatal): $e');
      }

      // Step 6: Build final config
      finalConfig = supabaseOk
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

      // Step 7: App version
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = info.version;
      } catch (e) {
        debugPrint('Failed to load package info: $e');
      }

      // Step 8: Orientations
      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } catch (_) {}
    } catch (e, stack) {
      // If ANYTHING above fails catastrophically, we still call runApp below
      debugPrint('Init failed: $e\n$stack');
    }

    // ── ALWAYS call runApp — even if everything above crashed ─────────
    runApp(ProviderScope(
      overrides: [
        appVersionProvider.overrideWithValue(appVersion),
        appConfigProvider.overrideWithValue(finalConfig),
      ],
      child: OmicVerseApp(supabaseConfigured: supabaseOk),
    ));
  }, (error, stack) {
    // Catch Dart async / zone errors not caught by FlutterError.onError.
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}
