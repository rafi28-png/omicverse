import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/population/services/population_service.dart';

void main() {
  group('PopulationFrequency', () {
    test('frequency label formats correctly', () {
      const p1 = PopulationFrequency(population: 'Test', abbreviation: 'T', alleleFrequency: 0.05);
      expect(p1.frequencyLabel, '0.0500');

      const p2 = PopulationFrequency(population: 'Test', abbreviation: 'T', alleleFrequency: 0.00001);
      expect(p2.frequencyLabel, '1.0e-5');

      const p3 = PopulationFrequency(population: 'Test', abbreviation: 'T', alleleFrequency: 0);
      expect(p3.frequencyLabel, '0');
    });

    test('rarity labels are correct', () {
      const common = PopulationFrequency(population: 'T', abbreviation: 'T', alleleFrequency: 0.1);
      expect(common.rarityLabel, 'Common');

      const rare = PopulationFrequency(population: 'T', abbreviation: 'T', alleleFrequency: 0.005);
      expect(rare.rarityLabel, 'Rare');

      const ultraRare = PopulationFrequency(population: 'T', abbreviation: 'T', alleleFrequency: 0.00005);
      expect(ultraRare.rarityLabel, 'Ultra-rare');

      const absent = PopulationFrequency(population: 'T', abbreviation: 'T', alleleFrequency: 0);
      expect(absent.rarityLabel, 'Absent');
    });
  });

  group('PopulationVariant', () {
    test('demo variants are valid', () {
      final variants = PopulationVariant.demoVariants();
      expect(variants.length, 3);
      expect(variants[0].gene, 'TP53');
      expect(variants[0].rsid, 'rs28934578');
      expect(variants[0].populations, isNotEmpty);
    });

    test('location format is correct', () {
      final v = PopulationVariant.demoVariants()[0];
      expect(v.location, startsWith('chr'));
    });

    test('all demo variants have populations', () {
      for (final v in PopulationVariant.demoVariants()) {
        expect(v.populations.length, greaterThanOrEqualTo(4));
      }
    });

    test('variant IDs are in gnomAD format', () {
      for (final v in PopulationVariant.demoVariants()) {
        final parts = v.variantId.split('-');
        expect(parts.length, 4); // chr-pos-ref-alt
      }
    });

    test('all demo variants are rare', () {
      for (final v in PopulationVariant.demoVariants()) {
        expect(v.globalFrequency, lessThan(0.01));
      }
    });
  });
}
