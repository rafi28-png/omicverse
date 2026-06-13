import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/crispr/services/crispr_service.dart';

void main() {
  group('GuideRna', () {
    test('demo guides are valid', () {
      final guides = GuideRna.demoGuides();
      expect(guides.length, 6);
      expect(guides[0].targetGene, 'TP53');
      expect(guides[0].sequence.length, 20);
    });

    test('efficiency labels are correct', () {
      final high = GuideRna(sequence: 'A' * 20, targetGene: 'X',
        chromosome: '1', position: 1, onTargetScore: 0.85, offTargetScore: 0.9, gcContent: 0.5);
      expect(high.efficiencyLabel, 'High');

      final med = GuideRna(sequence: 'A' * 20, targetGene: 'X',
        chromosome: '1', position: 1, onTargetScore: 0.5, offTargetScore: 0.9, gcContent: 0.5);
      expect(med.efficiencyLabel, 'Medium');

      final low = GuideRna(sequence: 'A' * 20, targetGene: 'X',
        chromosome: '1', position: 1, onTargetScore: 0.2, offTargetScore: 0.9, gcContent: 0.5);
      expect(low.efficiencyLabel, 'Low');
    });

    test('safety labels are correct', () {
      final safe = GuideRna(sequence: 'A' * 20, targetGene: 'X',
        chromosome: '1', position: 1, onTargetScore: 0.8, offTargetScore: 0.9,
        offTargetCount: 1, gcContent: 0.5);
      expect(safe.safetyLabel, 'Safe');

      final risky = GuideRna(sequence: 'A' * 20, targetGene: 'X',
        chromosome: '1', position: 1, onTargetScore: 0.8, offTargetScore: 0.3,
        offTargetCount: 10, gcContent: 0.5);
      expect(risky.safetyLabel, 'Risky');
    });
  });

  group('CrisprService', () {
    test('calculateGC works', () {
      expect(CrisprService.calculateGC('GCGC'), 1.0);
      expect(CrisprService.calculateGC('ATAT'), 0.0);
      expect(CrisprService.calculateGC('GCAT'), 0.5);
      expect(CrisprService.calculateGC(''), 0.0);
    });

    test('validateGuide accepts valid guides', () {
      expect(CrisprService.validateGuide('AGCTGTATCGTCAAGGCACT'), isNull);
    });

    test('validateGuide rejects too short', () {
      expect(CrisprService.validateGuide('AGCT'), isNotNull);
    });

    test('validateGuide rejects invalid chars', () {
      expect(CrisprService.validateGuide('AGCTXYZABC12345678'), isNotNull);
    });

    test('availableGenes returns sorted list', () {
      final genes = CrisprService.availableGenes();
      expect(genes, isNotEmpty);
      expect(genes, contains('TP53'));
      // Check sorted
      for (int i = 1; i < genes.length; i++) {
        expect(genes[i].compareTo(genes[i - 1]), greaterThanOrEqualTo(0));
      }
    });

    test('designGuides returns guides for known gene', () async {
      final guides = await CrisprService.designGuides('TP53');
      expect(guides.length, 2);
    });
  });
}
