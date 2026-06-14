import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('dart-define values take priority over dotenv', () {
      final config = AppConfig.fromEnvironment(
        dartDefineUrl: 'https://define.supabase.co',
        dartDefineKey: 'define-key-123',
        dotenvUrl: 'https://dotenv.supabase.co',
        dotenvKey: 'dotenv-key-456',
      );
      expect(config.supabaseUrl, 'https://define.supabase.co');
      expect(config.supabaseAnonKey, 'define-key-123');
    });

    test('falls back to dotenv when dart-define is empty', () {
      final config = AppConfig.fromEnvironment(
        dartDefineUrl: '',
        dartDefineKey: '',
        dotenvUrl: 'https://dotenv.supabase.co',
        dotenvKey: 'dotenv-key-456',
      );
      expect(config.supabaseUrl, 'https://dotenv.supabase.co');
      expect(config.supabaseAnonKey, 'dotenv-key-456');
    });

    test('empty config means not configured (demo mode)', () {
      final config = AppConfig.fromEnvironment(
        dartDefineUrl: '',
        dartDefineKey: '',
      );
      expect(config.isSupabaseConfigured, isFalse);
    });

    test('valid config means configured', () {
      final config = AppConfig.fromEnvironment(
        dartDefineUrl: 'https://test.supabase.co',
        dartDefineKey: 'key-abc',
      );
      expect(config.isSupabaseConfigured, isTrue);
    });

    test('numeric config values parse correctly', () {
      final config = AppConfig.fromEnvironment(
        dartDefineUrl: '',
        dartDefineKey: '',
        dotenvMaxVcf: '5000',
        dotenvBatchSize: '100',
        dotenvCacheTtl: '12',
      );
      expect(config.maxVcfVariants, 5000);
      expect(config.annotationBatchSize, 100);
      expect(config.cacheTtlHours, 12);
    });

    test('invalid numeric values use defaults', () {
      final config = AppConfig.fromEnvironment(
        dartDefineUrl: '',
        dartDefineKey: '',
        dotenvMaxVcf: 'not-a-number',
        dotenvBatchSize: '',
      );
      expect(config.maxVcfVariants, 10000);
      expect(config.annotationBatchSize, 200);
    });

    test('debug mode parses correctly', () {
      final debug = AppConfig.fromEnvironment(
        dartDefineUrl: '', dartDefineKey: '',
        dotenvDebug: 'true',
      );
      expect(debug.debugMode, isTrue);

      final release = AppConfig.fromEnvironment(
        dartDefineUrl: '', dartDefineKey: '',
        dotenvDebug: 'false',
      );
      expect(release.debugMode, isFalse);

      final defaultVal = AppConfig.fromEnvironment(
        dartDefineUrl: '', dartDefineKey: '',
      );
      expect(defaultVal.debugMode, isFalse);
    });

    test('safeKeys only contains public config keys', () {
      expect(AppConfig.safeKeys, contains('SUPABASE_URL'));
      expect(AppConfig.safeKeys, contains('SUPABASE_ANON_KEY'));
      expect(AppConfig.safeKeys, contains('APP_NAME'));
      // Verify no private keys in safeKeys list
      for (final key in AppConfig.safeKeys) {
        expect(key.toLowerCase().contains('secret'), isFalse,
            reason: '$key should not contain "secret"');
        expect(key.toLowerCase().contains('private'), isFalse,
            reason: '$key should not contain "private"');
      }
    });

    test('sanitizes supabaseUrl to strip trailing slash and /rest/v1', () {
      final config1 = AppConfig.fromEnvironment(
        dartDefineUrl: 'https://test.supabase.co/rest/v1/',
        dartDefineKey: 'key',
      );
      expect(config1.supabaseUrl, 'https://test.supabase.co');

      final config2 = AppConfig.fromEnvironment(
        dartDefineUrl: 'https://test.supabase.co/rest/v1',
        dartDefineKey: 'key',
      );
      expect(config2.supabaseUrl, 'https://test.supabase.co');

      final config3 = AppConfig.fromEnvironment(
        dartDefineUrl: 'https://test.supabase.co/',
        dartDefineKey: 'key',
      );
      expect(config3.supabaseUrl, 'https://test.supabase.co');

      // Test with quotes
      final config4 = AppConfig.fromEnvironment(
        dartDefineUrl: '"https://test.supabase.co/rest/v1/"',
        dartDefineKey: 'key',
      );
      expect(config4.supabaseUrl, 'https://test.supabase.co');

      final config5 = AppConfig.fromEnvironment(
        dartDefineUrl: "'https://test.supabase.co/rest/v1'",
        dartDefineKey: 'key',
      );
      expect(config5.supabaseUrl, 'https://test.supabase.co');

      // Test missing scheme
      final config6 = AppConfig.fromEnvironment(
        dartDefineUrl: 'test.supabase.co/rest/v1/',
        dartDefineKey: 'key',
      );
      expect(config6.supabaseUrl, 'https://test.supabase.co');
    });
  });
}
