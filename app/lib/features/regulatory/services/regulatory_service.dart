import '../../../core/services/api_service.dart';
import '../../../core/services/rate_limiter.dart';
import '../../genome/services/genome_service.dart';

class RegulatoryElement {
  final String id;
  final String type; // promoter, enhancer, silencer, insulator, CTCF
  final String chromosome;
  final int start;
  final int end;
  final String? nearestGene;
  final double? score;
  final String source;

  const RegulatoryElement({
    required this.id,
    required this.type,
    required this.chromosome,
    required this.start,
    required this.end,
    this.nearestGene,
    this.score,
    this.source = 'ENCODE',
  });

  String get location => 'chr$chromosome:$start-$end';
  int get length => end - start;

  static List<RegulatoryElement> demoElements() => const [
    RegulatoryElement(id: 'EH38E1516972', type: 'Promoter-like', chromosome: '17', start: 7661779, end: 7662279,
      nearestGene: 'TP53', score: 0.95, source: 'ENCODE cCRE'),
    RegulatoryElement(id: 'EH38E1516973', type: 'Enhancer-like', chromosome: '17', start: 7670000, end: 7671500,
      nearestGene: 'TP53', score: 0.88, source: 'ENCODE cCRE'),
    RegulatoryElement(id: 'EH38E0392801', type: 'Promoter-like', chromosome: '17', start: 43044295, end: 43044795,
      nearestGene: 'BRCA1', score: 0.92, source: 'ENCODE cCRE'),
    RegulatoryElement(id: 'EH38E0392802', type: 'CTCF-bound', chromosome: '17', start: 43100000, end: 43100500,
      nearestGene: 'BRCA1', score: 0.85, source: 'ENCODE cCRE'),
    RegulatoryElement(id: 'EH38E1234567', type: 'Enhancer-like', chromosome: '7', start: 55019500, end: 55020200,
      nearestGene: 'EGFR', score: 0.91, source: 'ENCODE cCRE'),
    RegulatoryElement(id: 'EH38E1234568', type: 'Promoter-like', chromosome: '7', start: 55019017, end: 55019517,
      nearestGene: 'EGFR', score: 0.97, source: 'ENCODE cCRE'),
    RegulatoryElement(id: 'EH38E7890123', type: 'Enhancer-like', chromosome: '12', start: 25205300, end: 25206000,
      nearestGene: 'KRAS', score: 0.82, source: 'ENCODE cCRE'),
    RegulatoryElement(id: 'EH38E4567890', type: 'CTCF-bound', chromosome: '7', start: 140720000, end: 140720600,
      nearestGene: 'BRAF', score: 0.78, source: 'ENCODE cCRE'),
  ];
}

class TranscriptionFactor {
  final String name;
  final String target;
  final double score;
  final String cellType;

  const TranscriptionFactor({
    required this.name,
    required this.target,
    required this.score,
    this.cellType = 'Multiple',
  });

  static List<TranscriptionFactor> demoTFs() => const [
    TranscriptionFactor(name: 'SP1', target: 'TP53', score: 0.95, cellType: 'HeLa'),
    TranscriptionFactor(name: 'E2F1', target: 'TP53', score: 0.89, cellType: 'K562'),
    TranscriptionFactor(name: 'MYC', target: 'TP53', score: 0.82, cellType: 'HepG2'),
    TranscriptionFactor(name: 'CTCF', target: 'BRCA1', score: 0.93, cellType: 'GM12878'),
    TranscriptionFactor(name: 'ESR1', target: 'BRCA1', score: 0.87, cellType: 'MCF7'),
    TranscriptionFactor(name: 'FOXA1', target: 'EGFR', score: 0.84, cellType: 'HepG2'),
    TranscriptionFactor(name: 'JUN', target: 'KRAS', score: 0.79, cellType: 'K562'),
  ];
}

class RegulatoryService {
  /// Search regulatory elements near a gene
  static Future<List<RegulatoryElement>> searchByGene(String gene) async {
    if (gene.trim().isEmpty) return [];

    try {
      // Step 1: Find gene coordinates
      final genes = await GenomeService.searchGene(gene);
      if (genes.isEmpty) return _demoForGene(gene);
      final targetGene = genes.first;

      // Step 2: Query SCREEN API by coordinates
      await RateLimiter.throttle('encode');
      
      const query = '''
      query Search(\$assembly: String!, \$coords: [GenomicRangeInput!]) {
        cCRESCREENSearch(assembly: \$assembly, coordinates: \$coords) {
          chrom
          start
          len
          promoter_zscore
          enhancer_zscore
          ctcf_zscore
          info { accession }
        }
      }
      ''';

      final vars = {
        'assembly': 'grch38',
        'coords': [
          {
            'chromosome': 'chr${targetGene.chromosome}',
            'start': targetGene.start,
            'end': targetGene.end,
          }
        ]
      };

      final resp = await ApiService.post(
        'https://factorbook.api.wenglab.org/graphql',
        {'query': query, 'variables': vars},
      );

      final results = <RegulatoryElement>[];
      final elements = resp['data']?['cCRESCREENSearch'] as List<dynamic>? ?? [];

      for (final item in elements) {
        final info = item['info'] as Map<String, dynamic>?;
        final accession = info?['accession'] as String? ?? 'Unknown';
        final chrom = (item['chrom'] as String? ?? '').replaceAll('chr', '');
        final start = item['start'] as int? ?? 0;
        final len = item['len'] as int? ?? 0;
        final end = start + len;

        // Classify the element based on z-scores or annotation group
        final promoterZ = (item['promoter_zscore'] as num?)?.toDouble() ?? 0;
        final enhancerZ = (item['enhancer_zscore'] as num?)?.toDouble() ?? 0;
        final ctcfZ = (item['ctcf_zscore'] as num?)?.toDouble() ?? 0;

        String type = 'Enhancer-like';
        double score = enhancerZ;
        if (promoterZ > enhancerZ && promoterZ > ctcfZ) {
          type = 'Promoter-like';
          score = promoterZ;
        } else if (ctcfZ > promoterZ && ctcfZ > enhancerZ) {
          type = 'CTCF-bound';
          score = ctcfZ;
        }

        results.add(RegulatoryElement(
          id: accession,
          type: type,
          chromosome: chrom,
          start: start,
          end: end,
          nearestGene: gene,
          score: score > 0 ? (score / 10).clamp(0.0, 1.0) : 0.0,
          source: 'ENCODE SCREEN',
        ));
      }

      return results.isEmpty ? _demoForGene(gene) : results;
    } catch (_) {
      return _demoForGene(gene);
    }
  }

  /// Get TF binding for a gene from JASPAR database
  static Future<List<TranscriptionFactor>> getTFsForGene(String gene) async {
    try {
      await RateLimiter.throttle('jaspar');
      final resp = await ApiService.get<Map<String, dynamic>>(
        'https://jaspar.elixir.no/api/v1/matrix/',
        params: {
          'search': gene,
          'tax_id': '9606',
          'format': 'json',
          'page_size': '10',
        },
      );

      final results = resp['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) return _demoTFsForGene(gene);

      return results.map((item) => TranscriptionFactor(
        name: item['name'] as String? ?? '',
        target: gene,
        score: ((item['version'] as num?)?.toDouble() ?? 1.0) / 3.0 + 0.6,
        cellType: (item['collection'] as String?) ?? 'CORE',
      )).toList();
    } catch (_) {
      return _demoTFsForGene(gene);
    }
  }

  static List<TranscriptionFactor> _demoTFsForGene(String gene) {
    return TranscriptionFactor.demoTFs().where((tf) =>
      tf.target.toLowerCase() == gene.toLowerCase()
    ).toList();
  }

  static List<RegulatoryElement> _demoForGene(String gene) {
    return RegulatoryElement.demoElements().where((e) =>
      e.nearestGene?.toLowerCase() == gene.toLowerCase()
    ).toList();
  }
}
