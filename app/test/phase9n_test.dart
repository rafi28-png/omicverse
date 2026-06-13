import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/multi_omics/services/multi_omics_service.dart';

void main() {
  group('OmicsLayer', () {
    test('all layers are defined', () {
      final layers = OmicsLayer.allLayers();
      expect(layers.length, 7);
      expect(layers[0].name, 'Genomics');
    });

    test('layers have feature counts', () {
      for (final l in OmicsLayer.allLayers()) {
        expect(l.featureCount, greaterThan(0));
        expect(l.icon, isNotEmpty);
        expect(l.summary, isNotNull);
      }
    });
  });

  group('GeneProfile', () {
    test('demo TP53 profile is valid', () {
      final p = GeneProfile.demoProfile('TP53');
      expect(p.gene, 'TP53');
      expect(p.layers.keys, isNotEmpty);
      expect(p.layers.containsKey('genomics'), isTrue);
      expect(p.layers.containsKey('cancer'), isTrue);
    });

    test('demo BRCA1 profile has different values', () {
      final tp53 = GeneProfile.demoProfile('TP53');
      final brca1 = GeneProfile.demoProfile('BRCA1');
      expect(tp53.gene, isNot(brca1.gene));
      final tp53Genomics = tp53.layers['genomics'] as Map<String, dynamic>;
      final brca1Genomics = brca1.layers['genomics'] as Map<String, dynamic>;
      expect(tp53Genomics['position'], isNot(brca1Genomics['position']));
    });

    test('profile has all expected layers', () {
      final p = GeneProfile.demoProfile('EGFR');
      expect(p.layers.containsKey('genomics'), isTrue);
      expect(p.layers.containsKey('expression'), isTrue);
      expect(p.layers.containsKey('protein'), isTrue);
      expect(p.layers.containsKey('epigenomics'), isTrue);
      expect(p.layers.containsKey('cancer'), isTrue);
      expect(p.layers.containsKey('population'), isTrue);
      expect(p.layers.containsKey('evolution'), isTrue);
    });
  });

  group('MultiOmicsService', () {
    test('getGeneProfile returns valid profile', () async {
      final p = await MultiOmicsService.getGeneProfile('TP53');
      expect(p.gene, 'TP53');
      expect(p.layers, isNotEmpty);
    });

    test('completenessScore is 100% for demo', () {
      final p = GeneProfile.demoProfile('TP53');
      final score = MultiOmicsService.completenessScore(p);
      expect(score, equals(1.0));
    });

    test('moduleRoutes has all 16 modules', () {
      final routes = MultiOmicsService.moduleRoutes();
      expect(routes.length, 16);
      expect(routes['Genome'], '/genome');
      expect(routes['Drug'], '/drug');
    });

    test('getLayers returns all layers', () {
      final layers = MultiOmicsService.getLayers();
      expect(layers.length, 7);
    });
  });
}
