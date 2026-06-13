import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/drug/services/drug_service.dart';

void main() {
  group('Drug', () {
    test('demo drugs are valid', () {
      final drugs = Drug.demoDrugs();
      expect(drugs.length, 8);
      expect(drugs[0].name, 'Imatinib');
      expect(drugs[0].isApproved, isTrue);
    });

    test('phase labels are correct', () {
      const approved = Drug(chemblId: 'X', name: 'Y', type: 'Z', maxPhase: 4);
      expect(approved.phaseLabel, 'Approved');

      const phase3 = Drug(chemblId: 'X', name: 'Y', type: 'Z', maxPhase: 3);
      expect(phase3.phaseLabel, 'Phase III');

      const preclinical = Drug(chemblId: 'X', name: 'Y', type: 'Z', maxPhase: 0);
      expect(preclinical.phaseLabel, 'Preclinical');
    });

    test('all demo drugs are approved', () {
      for (final d in Drug.demoDrugs()) {
        expect(d.maxPhase, 4);
        expect(d.isApproved, isTrue);
      }
    });

    test('demo drugs have mechanisms', () {
      for (final d in Drug.demoDrugs()) {
        expect(d.mechanism, isNotNull);
        expect(d.mechanism, isNotEmpty);
      }
    });
  });

  group('DrugTarget', () {
    test('demo targets are valid', () {
      final targets = DrugTarget.demoTargets();
      expect(targets.length, 5);
      expect(targets[0].gene, 'EGFR');
      expect(targets[0].drugCount, greaterThan(0));
    });
  });

  group('DrugService', () {
    test('drugsByPhase groups correctly', () {
      final drugs = Drug.demoDrugs();
      final byPhase = DrugService.drugsByPhase(drugs);
      expect(byPhase['Approved'], drugs.length);
    });

    test('drugsByType groups correctly', () {
      final drugs = Drug.demoDrugs();
      final byType = DrugService.drugsByType(drugs);
      expect(byType.keys, isNotEmpty);
      final total = byType.values.reduce((a, b) => a + b);
      expect(total, drugs.length);
    });
  });
}
