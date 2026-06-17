import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/genome_3d/services/genome_3d_service.dart';

void main() {
  group('OmimDisease', () {
    test('demo data is valid', () {
      final data = OmimDisease.demoData('TP53');
      expect(data.length, 2);
      expect(data[0].title, contains('TP53'));
      expect(data[0].mimNumber, 191170);
    });

    test('url format is correct', () {
      final entry = OmimDisease.demoData('TP53')[0];
      expect(entry.url, startsWith('https://omim.org/entry/'));
    });

    test('shortTitle truncates long titles', () {
      final entry = OmimDisease.demoData('TP53')[0];
      expect(entry.shortTitle.length, lessThanOrEqualTo(80));
    });
  });

  group('DiseaseAssociation', () {
    test('demo associations are valid', () {
      final assocs = DiseaseAssociation.demoData('TP53');
      expect(assocs.length, 5);
      expect(assocs[0].diseaseName, 'Li-Fraumeni Syndrome');
    });

    test('evidence levels are correct', () {
      final strong = DiseaseAssociation.demoData('TP53')[0];
      expect(strong.evidenceLevel, 'Strong');
      expect(strong.score, greaterThanOrEqualTo(0.7));
    });

    test('score label formats correctly', () {
      final assoc = DiseaseAssociation.demoData('TP53')[0];
      expect(assoc.scoreLabel, contains('.'));
    });
  });

  group('DiseaseGeneticsService', () {
    test('getOmimEntries returns demo data when no API key', () async {
      final results = await DiseaseGeneticsService.getOmimEntries('TP53');
      expect(results, isNotEmpty);
    });

    test('getDiseaseAssociations returns demo data when no API key', () async {
      final results = await DiseaseGeneticsService.getDiseaseAssociations('TP53');
      expect(results, isNotEmpty);
    });
  });
}
