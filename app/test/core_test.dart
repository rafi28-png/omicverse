import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/core/models/app_error.dart';
import 'package:omicverse/core/services/chromosome_normalizer.dart';

void main() {
  group('AppError', () {
    test('NetworkError has correct message', () {
      const error = NetworkError('No internet');
      expect(error.userMessage, 'No internet');
      expect(error, isA<AppError>());
    });

    test('TimeoutError has correct message', () {
      const error = TimeoutError();
      expect(error.userMessage, contains('timed out'));
    });

    test('RateLimitError includes retry seconds', () {
      const error = RateLimitError(30);
      expect(error.retryAfterSeconds, 30);
      expect(error.userMessage, contains('30'));
    });

    test('NotFoundError has correct message', () {
      const error = NotFoundError();
      expect(error.userMessage, contains('Not found'));
    });

    test('ParseError preserves message', () {
      const error = ParseError('Bad JSON');
      expect(error.userMessage, 'Bad JSON');
    });

    test('ValidationError preserves message', () {
      const error = ValidationError('File too large');
      expect(error.userMessage, 'File too large');
    });
  });

  group('ChromosomeNormalizer', () {
    test('ensemblFormat strips chr prefix', () {
      expect(ChromosomeNormalizer.ensemblFormat('chr17'), '17');
      expect(ChromosomeNormalizer.ensemblFormat('chrX'), 'X');
      expect(ChromosomeNormalizer.ensemblFormat('17'), '17');
    });

    test('ucscFormat adds chr prefix', () {
      expect(ChromosomeNormalizer.ucscFormat('17'), 'chr17');
      expect(ChromosomeNormalizer.ucscFormat('X'), 'chrX');
      expect(ChromosomeNormalizer.ucscFormat('chr17'), 'chr17');
    });

    test('isValid accepts standard chromosomes', () {
      expect(ChromosomeNormalizer.isValid('1'), isTrue);
      expect(ChromosomeNormalizer.isValid('22'), isTrue);
      expect(ChromosomeNormalizer.isValid('X'), isTrue);
      expect(ChromosomeNormalizer.isValid('Y'), isTrue);
      expect(ChromosomeNormalizer.isValid('MT'), isTrue);
      expect(ChromosomeNormalizer.isValid('chr17'), isTrue);
    });

    test('isValid rejects invalid chromosomes', () {
      expect(ChromosomeNormalizer.isValid('0'), isFalse);
      expect(ChromosomeNormalizer.isValid('23'), isFalse);
      expect(ChromosomeNormalizer.isValid('ABC'), isFalse);
    });

    test('fromVcf trims and normalizes', () {
      expect(ChromosomeNormalizer.fromVcf('  chr17  '), '17');
      expect(ChromosomeNormalizer.fromVcf('X'), 'X');
    });
  });
}
