import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/protein/services/protein_service.dart';

void main() {
  group('ProteinInfo', () {
    test('demo proteins are valid', () {
      final proteins = ProteinInfo.demoProteins();
      expect(proteins.length, 5);
      expect(proteins[0].gene, 'TP53');
      expect(proteins[0].uniprotId, 'P04637');
      expect(proteins[0].length, 393);
    });

    test('UniProt URL is correct', () {
      final p = ProteinInfo.demoProteins()[0];
      expect(p.uniprotUrl, 'https://www.uniprot.org/uniprot/P04637');
    });

    test('all demo proteins have function', () {
      for (final p in ProteinInfo.demoProteins()) {
        expect(p.function, isNotEmpty);
        expect(p.gene, isNotEmpty);
        expect(p.length, greaterThan(0));
      }
    });

    test('all demo proteins have keywords', () {
      for (final p in ProteinInfo.demoProteins()) {
        expect(p.keywords, isNotEmpty);
      }
    });

    test('demo search by gene works', () {
      final results = ProteinInfo.demoProteins().where((p) =>
        p.gene.toLowerCase().contains('tp53')
      ).toList();
      expect(results.length, 1);
      expect(results[0].uniprotId, 'P04637');
    });

    test('demo search returns empty for unknown', () {
      final results = ProteinInfo.demoProteins().where((p) =>
        p.gene.toLowerCase().contains('zzzzz')
      ).toList();
      expect(results, isEmpty);
    });

    test('AlphaFold URL exists for TP53', () {
      final tp53 = ProteinInfo.demoProteins()[0];
      expect(tp53.alphaFoldUrl, isNotNull);
      expect(tp53.alphaFoldUrl, contains('P04637'));
    });
  });
}
