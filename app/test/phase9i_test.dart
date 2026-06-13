import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/cancer/services/cancer_service.dart';

void main() {
  group('CancerMutation', () {
    test('demo mutations are valid', () {
      final muts = CancerMutation.demoMutations();
      expect(muts.length, 11);
      expect(muts[0].gene, 'TP53');
      expect(muts[0].mutation, 'R175H');
    });

    test('tier classification works', () {
      const hotspot = CancerMutation(gene: 'X', mutation: 'Y', cancerType: 'Z',
        frequency: 15, consequence: 'Missense');
      expect(hotspot.tier, 'Hotspot');

      const recurrent = CancerMutation(gene: 'X', mutation: 'Y', cancerType: 'Z',
        frequency: 5, consequence: 'Missense');
      expect(recurrent.tier, 'Recurrent');

      const rare = CancerMutation(gene: 'X', mutation: 'Y', cancerType: 'Z',
        frequency: 0.5, consequence: 'Missense');
      expect(rare.tier, 'Rare');
    });

    test('frequency label formats correctly', () {
      const m = CancerMutation(gene: 'X', mutation: 'Y', cancerType: 'Z',
        frequency: 45.0, consequence: 'Missense');
      expect(m.frequencyLabel, '45.0%');
    });

    test('demo TP53 mutations exist', () {
      final tp53 = CancerMutation.demoMutations().where((m) => m.gene == 'TP53').toList();
      expect(tp53.length, 3);
    });

    test('BRAF V600E is a hotspot', () {
      final braf = CancerMutation.demoMutations().where((m) => m.mutation == 'V600E').first;
      expect(braf.tier, 'Hotspot');
      expect(braf.frequency, 45.0);
    });
  });

  group('CancerStudy', () {
    test('demo studies are valid', () {
      final studies = CancerStudy.demoStudies();
      expect(studies.length, 5);
      expect(studies[0].id, 'brca_tcga');
      expect(studies[0].sampleCount, greaterThan(0));
    });
  });

  group('CancerService', () {
    test('mutationByCancerType groups correctly', () {
      final muts = CancerMutation.demoMutations();
      final byType = CancerService.mutationByCancerType(muts);
      expect(byType.keys, isNotEmpty);
      expect(byType.containsKey('Pan-cancer'), isTrue);
    });
  });
}
