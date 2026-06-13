import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/regulatory/services/regulatory_service.dart';

void main() {
  group('RegulatoryElement', () {
    test('demo elements are valid', () {
      final els = RegulatoryElement.demoElements();
      expect(els.length, 8);
      expect(els[0].type, 'Promoter-like');
      expect(els[0].nearestGene, 'TP53');
    });

    test('location format is correct', () {
      final e = RegulatoryElement.demoElements()[0];
      expect(e.location, startsWith('chr'));
      expect(e.location, contains(':'));
    });

    test('element length is positive', () {
      for (final e in RegulatoryElement.demoElements()) {
        expect(e.length, greaterThan(0));
      }
    });

    test('filter by gene works', () {
      final tp53 = RegulatoryElement.demoElements().where((e) =>
        e.nearestGene == 'TP53').toList();
      expect(tp53.length, 2);
    });

    test('filter by type works', () {
      final promoters = RegulatoryElement.demoElements().where((e) =>
        e.type.contains('Promoter')).toList();
      expect(promoters.length, greaterThanOrEqualTo(2));
    });
  });

  group('TranscriptionFactor', () {
    test('demo TFs are valid', () {
      final tfs = TranscriptionFactor.demoTFs();
      expect(tfs.length, 7);
      expect(tfs[0].name, 'SP1');
      expect(tfs[0].target, 'TP53');
    });

    test('TF scores are between 0 and 1', () {
      for (final tf in TranscriptionFactor.demoTFs()) {
        expect(tf.score, greaterThanOrEqualTo(0));
        expect(tf.score, lessThanOrEqualTo(1));
      }
    });

    test('filter TFs by gene works', () {
      final tp53tfs = TranscriptionFactor.demoTFs().where((tf) =>
        tf.target == 'TP53').toList();
      expect(tp53tfs.length, 3);
    });
  });
}
