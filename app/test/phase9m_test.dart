import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/genome_3d/services/genome_3d_service.dart';

void main() {
  group('TAD', () {
    test('demo TADs are valid', () {
      final tads = TAD.demoTADs();
      expect(tads.length, 5);
      expect(tads[0].name, 'TP53 TAD');
      expect(tads[0].genes, contains('TP53'));
    });

    test('size label formats correctly', () {
      final tad = TAD.demoTADs()[0];
      expect(tad.size, greaterThan(0));
      expect(tad.sizeLabel, contains('kb'));
    });

    test('location format is correct', () {
      final tad = TAD.demoTADs()[0];
      expect(tad.location, startsWith('chr'));
    });
  });

  group('ChromatinLoop', () {
    test('demo loops are valid', () {
      final loops = ChromatinLoop.demoLoops();
      expect(loops.length, 4);
      expect(loops[0].gene1, 'TP53');
    });

    test('distance calculation works', () {
      final loop = ChromatinLoop.demoLoops()[0];
      expect(loop.distance, greaterThan(0));
      expect(loop.distanceLabel, contains('kb'));
    });

    test('label shows gene pair', () {
      final loop = ChromatinLoop.demoLoops()[0];
      expect(loop.label, contains('TP53'));
      expect(loop.label, contains('↔'));
    });
  });

  group('Genome3dService', () {
    test('getByGene returns TADs and loops', () async {
      final data = await Genome3dService.getByGene('TP53');
      expect(data['tads'], isNotEmpty);
      expect(data['loops'], isNotEmpty);
    });

    test('availableChromosomes is sorted', () {
      final chrs = Genome3dService.availableChromosomes();
      expect(chrs, isNotEmpty);
    });

    test('getByGene returns empty for unknown gene', () async {
      final data = await Genome3dService.getByGene('FAKEGENE');
      expect((data['tads'] as List).isEmpty, isTrue);
    });
  });
}
