import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/genome/services/genome_service.dart';
import 'package:omicverse/features/population/services/population_service.dart';
import 'package:omicverse/features/crispr/services/crispr_service.dart';

void main() {
  group('GeneInfo Serialization', () {
    test('toJson and fromJson works correctly', () {
      const gene = GeneInfo(
        ensemblId: 'ENSG00000141510',
        symbol: 'TP53',
        description: 'Tumor protein p53',
        chromosome: '17',
        start: 7661779,
        end: 7687550,
        strand: -1,
        biotype: 'protein_coding',
        assembly: 'GRCh38',
      );

      final json = gene.toJson();
      expect(json['ensemblId'], 'ENSG00000141510');
      expect(json['symbol'], 'TP53');
      expect(json['start'], 7661779);
      expect(json['strand'], -1);

      final parsed = GeneInfo.fromJson(json);
      expect(parsed.ensemblId, 'ENSG00000141510');
      expect(parsed.symbol, 'TP53');
      expect(parsed.description, 'Tumor protein p53');
      expect(parsed.chromosome, '17');
      expect(parsed.start, 7661779);
      expect(parsed.end, 7687550);
      expect(parsed.strand, -1);
      expect(parsed.biotype, 'protein_coding');
      expect(parsed.assembly, 'GRCh38');
    });
  });

  group('Population Genetics Serialization', () {
    test('PopulationFrequency toJson and fromJson works', () {
      const freq = PopulationFrequency(
        population: 'East Asian',
        abbreviation: 'EAS',
        alleleFrequency: 0.0004,
        alleleCount: 4,
        alleleNumber: 10000,
        homozygoteCount: 0,
      );

      final json = freq.toJson();
      expect(json['population'], 'East Asian');
      expect(json['abbreviation'], 'EAS');
      expect(json['alleleFrequency'], 0.0004);

      final parsed = PopulationFrequency.fromJson(json);
      expect(parsed.population, 'East Asian');
      expect(parsed.abbreviation, 'EAS');
      expect(parsed.alleleFrequency, 0.0004);
      expect(parsed.alleleCount, 4);
      expect(parsed.alleleNumber, 10000);
      expect(parsed.homozygoteCount, 0);
    });

    test('PopulationVariant toJson and fromJson works', () {
      const variant = PopulationVariant(
        variantId: '17-7674220-G-A',
        chromosome: '17',
        position: 7674220,
        reference: 'G',
        alternate: 'A',
        rsid: 'rs28934578',
        globalFrequency: 0.00002,
        gene: 'TP53',
        consequence: 'missense_variant',
        populations: [
          PopulationFrequency(
            population: 'East Asian',
            abbreviation: 'EAS',
            alleleFrequency: 0.00004,
          ),
        ],
      );

      final json = variant.toJson();
      expect(json['variantId'], '17-7674220-G-A');
      expect(json['rsid'], 'rs28934578');
      expect(json['populations'], isList);

      final parsed = PopulationVariant.fromJson(json);
      expect(parsed.variantId, '17-7674220-G-A');
      expect(parsed.chromosome, '17');
      expect(parsed.position, 7674220);
      expect(parsed.reference, 'G');
      expect(parsed.alternate, 'A');
      expect(parsed.rsid, 'rs28934578');
      expect(parsed.globalFrequency, 0.00002);
      expect(parsed.gene, 'TP53');
      expect(parsed.consequence, 'missense_variant');
      expect(parsed.populations.length, 1);
      expect(parsed.populations[0].abbreviation, 'EAS');
    });
  });

  group('CRISPR Guide RNA Computation', () {
    test('calculateGC calculates correct ratios', () {
      expect(CrisprService.calculateGC(''), 0.0);
      expect(CrisprService.calculateGC('ATATATAT'), 0.0);
      expect(CrisprService.calculateGC('CGCGCGCG'), 1.0);
      expect(CrisprService.calculateGC('ATCGATCG'), 0.5);
    });

    test('validateGuide checks sequence length and characters', () {
      expect(CrisprService.validateGuide(''), isNotNull); // too short
      expect(CrisprService.validateGuide('ATCGATCGATCGATCGATCG'), null); // valid 20nt, 50% GC
      expect(CrisprService.validateGuide('ATCGATCGATCGATCGATCGX'), isNotNull); // invalid char
      expect(CrisprService.validateGuide('ATATATATATATATATATAT'), isNotNull); // GC content too low (0%)
    });
  });
}
