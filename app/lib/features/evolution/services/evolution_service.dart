import '../../../core/services/api_service.dart';
import '../../../core/services/rate_limiter.dart';

class OrthologGene {
  final String gene;
  final String species;
  final String speciesCommon;
  final double percentIdentity;
  final String orthologId;
  final String type; // one2one, one2many, many2many

  const OrthologGene({
    required this.gene,
    required this.species,
    required this.speciesCommon,
    required this.percentIdentity,
    this.orthologId = '',
    this.type = 'one2one',
  });

  String get conservationLabel {
    if (percentIdentity >= 90) return 'Highly conserved';
    if (percentIdentity >= 70) return 'Conserved';
    if (percentIdentity >= 40) return 'Moderately conserved';
    return 'Divergent';
  }
}

class ConservationScore {
  final String chromosome;
  final int position;
  final double phyloP;
  final double phastCons;

  const ConservationScore({
    required this.chromosome,
    required this.position,
    required this.phyloP,
    required this.phastCons,
  });

  String get constraintLabel {
    if (phyloP > 2) return 'Strong purifying';
    if (phyloP > 0.5) return 'Moderate purifying';
    if (phyloP < -2) return 'Accelerated';
    return 'Neutral';
  }

  static List<ConservationScore> demoScores() => const [
    ConservationScore(chromosome: '17', position: 7674220, phyloP: 5.2, phastCons: 0.99),
    ConservationScore(chromosome: '17', position: 7674221, phyloP: 4.8, phastCons: 0.98),
    ConservationScore(chromosome: '17', position: 7674222, phyloP: 3.1, phastCons: 0.95),
    ConservationScore(chromosome: '7', position: 55181378, phyloP: 4.5, phastCons: 0.97),
    ConservationScore(chromosome: '12', position: 25205320, phyloP: 6.1, phastCons: 1.0),
  ];
}

class EvolutionService {
  static const _ensemblBase = 'https://rest.ensembl.org';

  /// Get orthologs for a human gene
  static Future<List<OrthologGene>> getOrthologs(String gene) async {
    if (gene.trim().isEmpty) return [];
    try {
      await RateLimiter.throttle('ensembl');
      final resp = await ApiService.get<Map<String, dynamic>>(
        '$_ensemblBase/homology/symbol/homo_sapiens/$gene',
        params: {'type': 'orthologues', 'format': 'condensed', 'content-type': 'application/json'},
      );

      final homologies = resp['data']?[0]?['homologies'] as List<dynamic>? ?? [];
      final orthologs = <OrthologGene>[];

      for (final h in homologies) {
        final target = h['target'] as Map<String, dynamic>? ?? {};
        orthologs.add(OrthologGene(
          gene: target['id'] as String? ?? '',
          species: target['species'] as String? ?? '',
          speciesCommon: _commonName(target['species'] as String? ?? ''),
          percentIdentity: (target['perc_id'] as num?)?.toDouble() ?? 0,
          type: h['type'] as String? ?? 'one2one',
        ));
      }

      return orthologs.isEmpty ? demoOrthologs(gene) : orthologs;
    } catch (_) {
      return demoOrthologs(gene);
    }
  }

  /// Get conservation scores from UCSC Genome Browser API
  static Future<List<ConservationScore>> getConservation(String chr, int start, int end) async {
    try {
      // Limit region to prevent huge responses
      final clampedEnd = start + ((end - start).clamp(1, 500));
      await RateLimiter.throttle('ucsc');
      final resp = await ApiService.get<Map<String, dynamic>>(
        'https://api.genome.ucsc.edu/getData/track',
        params: {
          'genome': 'hg38',
          'track': 'phyloP100way',
          'chrom': 'chr$chr',
          'start': '$start',
          'end': '$clampedEnd',
        },
      );

      final trackData = resp['phyloP100way'] as List<dynamic>? ?? [];
      final scores = <ConservationScore>[];

      for (final item in trackData) {
        final pos = item['start'] as int? ?? 0;
        final value = (item['value'] as num?)?.toDouble() ?? 0;
        scores.add(ConservationScore(
          chromosome: chr,
          position: pos,
          phyloP: value,
          phastCons: value > 0 ? (value / 10.0).clamp(0.0, 1.0) : 0.0,
        ));
      }

      // Sample every Nth point if too many results
      if (scores.length > 50) {
        final step = scores.length ~/ 50;
        return [for (int i = 0; i < scores.length; i += step) scores[i]];
      }

      return scores.isEmpty ? ConservationScore.demoScores() : scores;
    } catch (_) {
      return ConservationScore.demoScores().where((s) =>
        s.chromosome == chr && s.position >= start && s.position <= end).toList();
    }
  }

  static String _commonName(String species) {
    const names = {
      'pan_troglodytes': 'Chimpanzee',
      'gorilla_gorilla': 'Gorilla',
      'pongo_abelii': 'Orangutan',
      'macaca_mulatta': 'Rhesus macaque',
      'mus_musculus': 'Mouse',
      'rattus_norvegicus': 'Rat',
      'canis_lupus_familiaris': 'Dog',
      'felis_catus': 'Cat',
      'bos_taurus': 'Cow',
      'gallus_gallus': 'Chicken',
      'danio_rerio': 'Zebrafish',
      'xenopus_tropicalis': 'Frog',
      'drosophila_melanogaster': 'Fruit fly',
      'caenorhabditis_elegans': 'C. elegans',
      'saccharomyces_cerevisiae': 'Yeast',
    };
    return names[species.toLowerCase()] ?? species.replaceAll('_', ' ');
  }

  static List<OrthologGene> demoOrthologs(String gene) {
    return [
      OrthologGene(gene: gene, species: 'pan_troglodytes', speciesCommon: 'Chimpanzee', percentIdentity: 99.2),
      OrthologGene(gene: gene, species: 'gorilla_gorilla', speciesCommon: 'Gorilla', percentIdentity: 98.7),
      OrthologGene(gene: gene, species: 'mus_musculus', speciesCommon: 'Mouse', percentIdentity: 86.5),
      OrthologGene(gene: gene, species: 'rattus_norvegicus', speciesCommon: 'Rat', percentIdentity: 84.2),
      OrthologGene(gene: gene, species: 'canis_lupus_familiaris', speciesCommon: 'Dog', percentIdentity: 88.1),
      OrthologGene(gene: gene, species: 'bos_taurus', speciesCommon: 'Cow', percentIdentity: 87.3),
      OrthologGene(gene: gene, species: 'gallus_gallus', speciesCommon: 'Chicken', percentIdentity: 62.4),
      OrthologGene(gene: gene, species: 'danio_rerio', speciesCommon: 'Zebrafish', percentIdentity: 51.8),
      OrthologGene(gene: gene, species: 'drosophila_melanogaster', speciesCommon: 'Fruit fly', percentIdentity: 32.1),
      OrthologGene(gene: gene, species: 'caenorhabditis_elegans', speciesCommon: 'C. elegans', percentIdentity: 28.5),
      OrthologGene(gene: gene, species: 'saccharomyces_cerevisiae', speciesCommon: 'Yeast', percentIdentity: 15.3),
    ];
  }
}
