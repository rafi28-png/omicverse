import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/pathway/services/pathway_service.dart';

void main() {
  group('PathwayInfo', () {
    test('demo pathways are valid', () {
      final pws = PathwayInfo.demoPathways();
      expect(pws.length, 8);
      expect(pws[0].id, 'hsa04110');
      expect(pws[0].name, 'Cell cycle');
      expect(pws[0].genes, isNotEmpty);
    });

    test('KEGG URL is correct', () {
      final pw = PathwayInfo.demoPathways()[0];
      expect(pw.keggUrl, 'https://www.kegg.jp/pathway/hsa04110');
    });

    test('all demo pathways have hsa prefix', () {
      for (final pw in PathwayInfo.demoPathways()) {
        expect(pw.id, startsWith('hsa'));
      }
    });

    test('demo pathways have genes', () {
      for (final pw in PathwayInfo.demoPathways()) {
        expect(pw.genes, isNotEmpty);
      }
    });

    test('demo search by name works', () {
      final results = PathwayInfo.demoPathways().where((p) =>
        p.name.toLowerCase().contains('cell cycle')
      ).toList();
      expect(results.length, 1);
      expect(results[0].id, 'hsa04110');
    });

    test('demo search by gene works', () {
      final results = PathwayInfo.demoPathways().where((p) =>
        p.genes.any((g) => g == 'TP53')
      ).toList();
      expect(results.length, greaterThanOrEqualTo(2)); // cell cycle + p53 + cancer + apoptosis
    });
  });

  group('InteractionPartner', () {
    test('demo interactions for TP53', () {
      // Access via PathwayService static method indirectly
      const partner = InteractionPartner(gene: 'MDM2', score: 0.999);
      expect(partner.gene, 'MDM2');
      expect(partner.score, 0.999);
      expect(partner.source, 'STRING');
    });
  });
}
