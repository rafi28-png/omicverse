import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/prs/services/prs_service.dart';

void main() {
  group('PgsScore', () {
    test('demo scores are valid', () {
      final scores = PgsScore.demoScores();
      expect(scores.length, 6);
      expect(scores[0].pgsId, 'PGS000001');
      expect(scores[0].trait, 'Breast cancer');
      expect(scores[0].variantCount, 313);
    });

    test('catalog URL is correct', () {
      final s = PgsScore.demoScores()[0];
      expect(s.catalogUrl, 'https://www.pgscatalog.org/score/PGS000001/');
    });

    test('all demo scores have PGS IDs', () {
      for (final s in PgsScore.demoScores()) {
        expect(s.pgsId, startsWith('PGS'));
        expect(s.trait, isNotEmpty);
        expect(s.variantCount, greaterThan(0));
      }
    });

    test('demo search by trait works', () {
      final results = PgsScore.demoScores().where((s) =>
        s.trait.toLowerCase().contains('cancer')).toList();
      expect(results.length, 2); // Breast + Prostate
    });

    test('demo search by name works', () {
      final results = PgsScore.demoScores().where((s) =>
        s.name.toLowerCase().contains('diabetes')).toList();
      expect(results.length, 1);
      expect(results[0].pgsId, 'PGS000002');
    });

    test('performance metrics are reasonable', () {
      for (final s in PgsScore.demoScores()) {
        if (s.performanceMetric != null) {
          expect(s.performanceMetric, greaterThan(0.5));
          expect(s.performanceMetric, lessThan(1.0));
        }
      }
    });
  });
}
