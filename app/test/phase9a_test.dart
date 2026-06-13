import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/genome/services/genome_service.dart';

void main() {
  group('GeneInfo', () {
    test('demo genes are valid', () {
      final genes = GeneInfo.demoGenes();
      expect(genes.length, 5);
      expect(genes[0].symbol, 'TP53');
      expect(genes[0].chromosome, '17');
      expect(genes[0].ensemblId, startsWith('ENSG'));
    });

    test('location format is correct', () {
      final gene = GeneInfo.demoGenes()[0]; // TP53
      expect(gene.location, 'chr17:7661779-7687550');
    });

    test('strand label is correct', () {
      final tp53 = GeneInfo.demoGenes()[0]; // strand -1
      expect(tp53.strandLabel, '-');
      final egfr = GeneInfo.demoGenes()[2]; // strand 1
      expect(egfr.strandLabel, '+');
    });

    test('gene length is calculated', () {
      final tp53 = GeneInfo.demoGenes()[0];
      expect(tp53.length, tp53.end - tp53.start);
      expect(tp53.length, greaterThan(0));
    });

    test('all demo genes are protein_coding', () {
      for (final gene in GeneInfo.demoGenes()) {
        expect(gene.biotype, 'protein_coding');
        expect(gene.assembly, 'GRCh38');
      }
    });

    test('all demo genes have unique Ensembl IDs', () {
      final ids = GeneInfo.demoGenes().map((g) => g.ensemblId).toSet();
      expect(ids.length, 5);
    });

    test('demo search filters by symbol', () {
      final results = GeneInfo.demoGenes().where((g) =>
        g.symbol.toLowerCase().contains('tp53')
      ).toList();
      expect(results.length, 1);
      expect(results[0].symbol, 'TP53');
    });

    test('demo search returns empty for unknown gene', () {
      final results = GeneInfo.demoGenes().where((g) =>
        g.symbol.toLowerCase().contains('zzzzz')
      ).toList();
      expect(results, isEmpty);
    });
  });
}
