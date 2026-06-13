import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/evolution/services/evolution_service.dart';

void main() {
  group('OrthologGene', () {
    test('demo orthologs are valid', () {
      final orthologs = EvolutionService.demoOrthologs('TP53');
      expect(orthologs.length, 11);
      expect(orthologs[0].speciesCommon, 'Chimpanzee');
      expect(orthologs[0].percentIdentity, 99.2);
    });

    test('conservation labels are correct', () {
      const highly = OrthologGene(gene: 'X', species: 'a', speciesCommon: 'A', percentIdentity: 95);
      expect(highly.conservationLabel, 'Highly conserved');

      const conserved = OrthologGene(gene: 'X', species: 'b', speciesCommon: 'B', percentIdentity: 75);
      expect(conserved.conservationLabel, 'Conserved');

      const moderate = OrthologGene(gene: 'X', species: 'c', speciesCommon: 'C', percentIdentity: 50);
      expect(moderate.conservationLabel, 'Moderately conserved');

      const divergent = OrthologGene(gene: 'X', species: 'd', speciesCommon: 'D', percentIdentity: 20);
      expect(divergent.conservationLabel, 'Divergent');
    });

    test('orthologs sorted by identity shows chimp first', () {
      final orthologs = EvolutionService.demoOrthologs('BRCA1');
      orthologs.sort((a, b) => b.percentIdentity.compareTo(a.percentIdentity));
      expect(orthologs.first.speciesCommon, 'Chimpanzee');
      expect(orthologs.last.speciesCommon, 'Yeast');
    });
  });

  group('ConservationScore', () {
    test('demo scores are valid', () {
      final scores = ConservationScore.demoScores();
      expect(scores.length, 5);
      expect(scores[0].phyloP, greaterThan(0));
    });

    test('constraint labels are correct', () {
      const strong = ConservationScore(chromosome: '1', position: 1, phyloP: 5.0, phastCons: 0.99);
      expect(strong.constraintLabel, 'Strong purifying');

      const neutral = ConservationScore(chromosome: '1', position: 1, phyloP: 0.1, phastCons: 0.3);
      expect(neutral.constraintLabel, 'Neutral');

      const accel = ConservationScore(chromosome: '1', position: 1, phyloP: -3.0, phastCons: 0.1);
      expect(accel.constraintLabel, 'Accelerated');
    });
  });
}
