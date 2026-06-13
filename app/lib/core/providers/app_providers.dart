// lib/core/providers/app_providers.dart
//
// Central provider file — prevents circular imports.
// main.dart, app.dart, and any screen can import this safely.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

/// App version — overridden in main.dart from PackageInfo.
final appVersionProvider = Provider<String>((ref) => '1.0.0');

/// App configuration — overridden in main.dart after reading env.
final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig(supabaseUrl: '', supabaseAnonKey: '');
});

/// Demo mode preference — true = offline bundled data, no network calls.
/// Persisted via Hive in Phase 4. For now, defaults based on config.
final isDemoModeProvider = StateProvider<bool>((ref) {
  return true;
});
