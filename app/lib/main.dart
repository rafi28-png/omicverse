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
import 'app.dart';

void main() {
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

    // Step 5: Initialize Supabase only if config is present
    if (config.isSupabaseConfigured) {
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabaseAnonKey,
      );
    }

    // Step 6: App version
    final info = await PackageInfo.fromPlatform();

    // Step 7: Orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    runApp(ProviderScope(
      overrides: [
        appVersionProvider.overrideWithValue(info.version),
        appConfigProvider.overrideWithValue(config),
      ],
      child: OmicVerseApp(supabaseConfigured: config.isSupabaseConfigured),
    ));
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}
