// lib/core/config/app_config.dart
//
// Safe frontend configuration. Reads from --dart-define (production)
// or .env (local dev). Private keys are NEVER read here.

class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String appName;
  final String appVersion;
  final int maxVcfVariants;
  final int annotationBatchSize;
  final int cacheTtlHours;
  final bool debugMode;

  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.appName = 'OmicVerse',
    this.appVersion = '1.0.0',
    this.maxVcfVariants = 10000,
    this.annotationBatchSize = 200,
    this.cacheTtlHours = 24,
    this.debugMode = false,
  });

  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Build config from --dart-define (priority) and optional .env fallback.
  factory AppConfig.fromEnvironment({
    required String dartDefineUrl,
    required String dartDefineKey,
    String? dotenvUrl,
    String? dotenvKey,
    String? dotenvAppName,
    String? dotenvAppVersion,
    String? dotenvMaxVcf,
    String? dotenvBatchSize,
    String? dotenvCacheTtl,
    String? dotenvDebug,
  }) {
    String rawUrl = dartDefineUrl.isNotEmpty ? dartDefineUrl : (dotenvUrl ?? '');
    String cleanUrl = rawUrl.trim();
    if (cleanUrl.isNotEmpty) {
      final uri = Uri.tryParse(cleanUrl);
      if (uri != null && uri.host.isNotEmpty) {
        cleanUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
      }
    }

    return AppConfig(
      supabaseUrl: cleanUrl,
      supabaseAnonKey: dartDefineKey.isNotEmpty
          ? dartDefineKey
          : (dotenvKey ?? ''),
      appName: dotenvAppName ?? 'OmicVerse',
      appVersion: dotenvAppVersion ?? '1.0.0',
      maxVcfVariants: int.tryParse(dotenvMaxVcf ?? '') ?? 10000,
      annotationBatchSize: int.tryParse(dotenvBatchSize ?? '') ?? 200,
      cacheTtlHours: int.tryParse(dotenvCacheTtl ?? '') ?? 24,
      debugMode: (dotenvDebug ?? 'false').toLowerCase() == 'true',
    );
  }

  /// Keys that are safe for frontend use.
  static const safeKeys = [
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'APP_NAME',
    'APP_VERSION',
    'MAX_VCF_VARIANTS',
    'ANNOTATION_BATCH_SIZE',
    'CACHE_TTL_HOURS',
    'DEBUG_MODE',
  ];
}
