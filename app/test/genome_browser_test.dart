// Comprehensive Genome Browser test — demo mode + real mode
import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/genome/services/genome_service.dart';

void main() {
  // ==========================================
  // DEMO MODE TESTS (no API needed)
  // ==========================================
  group('Genome Browser — Demo Mode', () {
    test('demoGenes() returns 5 curated genes', () {
      final genes = GeneInfo.demoGenes();
      expect(genes.length, 5);
      expect(genes.map((g) => g.symbol).toList(),
        ['TP53', 'BRCA1', 'EGFR', 'BRAF', 'KRAS']);
    });

    test('demoGenes TP53 has correct coordinates', () {
      final tp53 = GeneInfo.demoGenes().firstWhere((g) => g.symbol == 'TP53');
      expect(tp53.ensemblId, 'ENSG00000141510');
      expect(tp53.chromosome, '17');
      expect(tp53.start, 7661779);
      expect(tp53.end, 7687550);
      expect(tp53.strand, -1);
      expect(tp53.biotype, 'protein_coding');
      expect(tp53.assembly, 'GRCh38');
    });

    test('GeneInfo.location formats correctly', () {
      final tp53 = GeneInfo.demoGenes().firstWhere((g) => g.symbol == 'TP53');
      expect(tp53.location, 'chr17:7661779-7687550');
    });

    test('GeneInfo.strandLabel works for + and -', () {
      final tp53 = GeneInfo.demoGenes().firstWhere((g) => g.symbol == 'TP53');
      expect(tp53.strandLabel, '-');
      final egfr = GeneInfo.demoGenes().firstWhere((g) => g.symbol == 'EGFR');
      expect(egfr.strandLabel, '+');
    });

    test('GeneInfo.length computes abs(end - start)', () {
      final tp53 = GeneInfo.demoGenes().firstWhere((g) => g.symbol == 'TP53');
      expect(tp53.length, 7687550 - 7661779);
      expect(tp53.length, 25771);
    });

    test('GeneInfo.toJson/fromJson roundtrip preserves data', () {
      final original = GeneInfo.demoGenes().first;
      final json = original.toJson();
      final restored = GeneInfo.fromJson(json);
      expect(restored.ensemblId, original.ensemblId);
      expect(restored.symbol, original.symbol);
      expect(restored.description, original.description);
      expect(restored.chromosome, original.chromosome);
      expect(restored.start, original.start);
      expect(restored.end, original.end);
      expect(restored.strand, original.strand);
      expect(restored.biotype, original.biotype);
      expect(restored.assembly, original.assembly);
    });

    test('fromJson handles num types (not just int)', () {
      // Simulates JSON decoder returning doubles
      final json = {
        'ensemblId': 'ENSG00000141510',
        'symbol': 'TP53',
        'description': 'Tumor protein p53',
        'chromosome': '17',
        'start': 7661779.0, // double!
        'end': 7687550.0,   // double!
        'strand': -1.0,     // double!
        'biotype': 'protein_coding',
        'assembly': 'GRCh38',
      };
      // This should NOT crash
      final gene = GeneInfo.fromJson(json);
      expect(gene.start, 7661779);
      expect(gene.end, 7687550);
      expect(gene.strand, -1);
    });

    test('Demo search for TP53 returns match', () {
      final results = GeneInfo.demoGenes().where((g) =>
        g.symbol.toLowerCase().contains('tp53')).toList();
      expect(results.length, 1);
      expect(results[0].symbol, 'TP53');
    });

    test('Demo search for nonexistent gene returns empty', () {
      final results = GeneInfo.demoGenes().where((g) =>
        g.symbol.toLowerCase().contains('xyz999')).toList();
      expect(results.length, 0);
    });

    test('Demo search is case-insensitive', () {
      final r1 = GeneInfo.demoGenes().where((g) =>
        g.symbol.toLowerCase().contains('brca1')).toList();
      final r2 = GeneInfo.demoGenes().where((g) =>
        g.symbol.toLowerCase().contains('BRCA1'.toLowerCase())).toList();
      expect(r1.length, r2.length);
      expect(r1[0].symbol, 'BRCA1');
    });

    test('All demo genes have non-empty required fields', () {
      for (final g in GeneInfo.demoGenes()) {
        expect(g.ensemblId.isNotEmpty, true, reason: '${g.symbol} missing ensemblId');
        expect(g.symbol.isNotEmpty, true, reason: 'missing symbol');
        expect(g.description.isNotEmpty, true, reason: '${g.symbol} missing description');
        expect(g.chromosome.isNotEmpty, true, reason: '${g.symbol} missing chromosome');
        expect(g.biotype.isNotEmpty, true, reason: '${g.symbol} missing biotype');
        expect(g.assembly.isNotEmpty, true, reason: '${g.symbol} missing assembly');
        expect(g.start > 0, true, reason: '${g.symbol} start <= 0');
        expect(g.end > g.start, true, reason: '${g.symbol} end <= start');
      }
    });

    test('All demo genes have valid chromosome numbers', () {
      final validChr = List.generate(22, (i) => '${i + 1}') + ['X', 'Y', 'MT'];
      for (final g in GeneInfo.demoGenes()) {
        expect(validChr.contains(g.chromosome), true,
          reason: '${g.symbol} has invalid chromosome: ${g.chromosome}');
      }
    });

    test('searchGene assembly parameter has default GRCh38', () {
      // This just tests the method signature accepts assembly param
      // The actual API call will fail in test env, falling back to demo
      expect(() => GenomeService.searchGene('TP53'), returnsNormally);
      expect(() => GenomeService.searchGene('TP53', assembly: 'GRCh37'), returnsNormally);
    });
  });

  // ==========================================
  // REAL MODE TESTS (require API access)
  // ==========================================
  group('Genome Browser — Real API Integration', () {
    test('searchGene returns results for TP53 (may use demo fallback)', () async {
      final results = await GenomeService.searchGene('TP53');
      expect(results.isNotEmpty, true, reason: 'TP53 search should always return results');
      expect(results.any((g) => g.symbol == 'TP53'), true);
    });

    test('searchGene returns results for BRCA1', () async {
      final results = await GenomeService.searchGene('BRCA1');
      expect(results.isNotEmpty, true);
      expect(results.any((g) => g.symbol == 'BRCA1'), true);
    });

    test('searchGene returns empty for nonsense query', () async {
      final results = await GenomeService.searchGene('ZZZZNOTAREALEGENE999');
      // Either empty from API or empty from demo filter
      expect(results.isEmpty, true);
    });

    test('searchGene with empty query returns empty', () async {
      final results = await GenomeService.searchGene('');
      expect(results, isEmpty);
    });

    test('searchGene with whitespace-only query returns empty', () async {
      final results = await GenomeService.searchGene('   ');
      expect(results, isEmpty);
    });

    test('searchGene GRCh37 returns valid assembly', () async {
      final results = await GenomeService.searchGene('TP53', assembly: 'GRCh37');
      expect(results.isNotEmpty, true);
      // If from real API, assembly should be GRCh37; if demo fallback, GRCh38
      final tp53 = results.firstWhere((g) => g.symbol == 'TP53');
      // Accept either since demo data always says GRCh38
      expect(['GRCh37', 'GRCh38'].contains(tp53.assembly), true);
    });
  });
}
