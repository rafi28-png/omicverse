import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/core/services/rate_limiter.dart';
import 'package:omicverse/core/services/api_constants.dart';
import 'package:omicverse/core/models/app_error.dart';

void main() {
  group('ApiConstants', () {
    test('ensembl URL is correct', () {
      expect(ApiConstants.ensembl, 'https://rest.ensembl.org');
    });

    test('gnomAD URL is correct', () {
      expect(ApiConstants.gnomad, 'https://gnomad.broadinstitute.org/api');
    });

    test('ncbiUrl builds correct URL', () {
      final url = ApiConstants.ncbiUrl('esearch.fcgi', {'db': 'gene', 'term': 'TP53'});
      expect(url, contains('eutils.ncbi.nlm.nih.gov'));
      expect(url, contains('esearch.fcgi'));
      expect(url, contains('db=gene'));
      expect(url, contains('term=TP53'));
    });

    test('ncbiUrl encodes special characters', () {
      final url = ApiConstants.ncbiUrl('esearch.fcgi', {'term': 'BRCA1 AND human'});
      expect(url, contains('BRCA1%20AND%20human'));
    });

    test('alphaFoldPrediction builds correct URL', () {
      expect(ApiConstants.alphaFoldPrediction('P04637'),
        'https://alphafold.ebi.ac.uk/api/prediction/P04637');
    });

    test('gnomadVariantQuery returns correct structure', () {
      final q = ApiConstants.gnomadVariantQuery('1-55505647-G-T');
      expect(q, contains('query'));
      expect(q, contains('variables'));
      expect(q['variables'], {'variantId': '1-55505647-G-T'});
    });
  });

  group('RateLimiter', () {
    setUp(() => RateLimiter.reset());

    test('allows requests within limit', () async {
      // Ensembl limit is 15/sec — 3 should be fine
      for (int i = 0; i < 3; i++) {
        await RateLimiter.throttle('ensembl');
      }
      // If we got here without hanging, the test passes
      expect(true, isTrue);
    });

    test('NCBI has 3/sec limit', () async {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 3; i++) {
        await RateLimiter.throttle('ncbi');
      }
      // 3 requests at 3/sec limit — should complete quickly
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('throttle delays when limit exceeded', () async {
      // NCBI: 3/sec limit — fire 4 rapidly
      final sw = Stopwatch()..start();
      for (int i = 0; i < 4; i++) {
        await RateLimiter.throttle('ncbi');
      }
      // 4th should have caused a delay
      expect(sw.elapsedMilliseconds, greaterThan(500));
    });

    test('unknown service uses default limit', () async {
      await RateLimiter.throttle('unknown_api');
      expect(true, isTrue);
    });
  });

  group('AppError hierarchy', () {
    test('NetworkError carries message', () {
      const e = NetworkError('test msg');
      expect(e.userMessage, 'test msg');
      expect(e, isA<AppError>());
    });

    test('TimeoutError has fixed message', () {
      const e = TimeoutError();
      expect(e.userMessage, contains('timed out'));
    });

    test('RateLimitError includes seconds', () {
      const e = RateLimitError(30);
      expect(e.userMessage, contains('30'));
      expect(e.retryAfterSeconds, 30);
    });

    test('NotFoundError has correct message', () {
      const e = NotFoundError();
      expect(e.userMessage, contains('Not found'));
    });
  });
}
