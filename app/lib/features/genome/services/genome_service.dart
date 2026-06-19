import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/api_constants.dart';
import '../../../core/services/rate_limiter.dart';
import '../../../core/services/cache_service.dart';

class GeneInfo {
  final String ensemblId;
  final String symbol;
  final String description;
  final String chromosome;
  final int start;
  final int end;
  final int strand;
  final String biotype;
  final String assembly;

  const GeneInfo({
    required this.ensemblId,
    required this.symbol,
    required this.description,
    required this.chromosome,
    required this.start,
    required this.end,
    required this.strand,
    required this.biotype,
    required this.assembly,
  });

  String get location => 'chr$chromosome:$start-$end';
  String get strandLabel => strand == 1 ? '+' : '-';
  int get length => (end - start).abs();

  Map<String, dynamic> toJson() => {
    'ensemblId': ensemblId,
    'symbol': symbol,
    'description': description,
    'chromosome': chromosome,
    'start': start,
    'end': end,
    'strand': strand,
    'biotype': biotype,
    'assembly': assembly,
  };

  factory GeneInfo.fromJson(Map<String, dynamic> j) => GeneInfo(
    ensemblId: j['ensemblId'] as String,
    symbol: j['symbol'] as String,
    description: j['description'] as String,
    chromosome: j['chromosome'] as String,
    start: (j['start'] as num).toInt(),
    end: (j['end'] as num).toInt(),
    strand: (j['strand'] as num).toInt(),
    biotype: j['biotype'] as String,
    assembly: j['assembly'] as String,
  );

  /// Demo data for offline mode
  static List<GeneInfo> demoGenes() => const [
    GeneInfo(ensemblId: 'ENSG00000141510', symbol: 'TP53', description: 'Tumor protein p53',
      chromosome: '17', start: 7661779, end: 7687550, strand: -1, biotype: 'protein_coding', assembly: 'GRCh38'),
    GeneInfo(ensemblId: 'ENSG00000012048', symbol: 'BRCA1', description: 'BRCA1 DNA repair associated',
      chromosome: '17', start: 43044295, end: 43170245, strand: -1, biotype: 'protein_coding', assembly: 'GRCh38'),
    GeneInfo(ensemblId: 'ENSG00000146648', symbol: 'EGFR', description: 'Epidermal growth factor receptor',
      chromosome: '7', start: 55019017, end: 55211628, strand: 1, biotype: 'protein_coding', assembly: 'GRCh38'),
    GeneInfo(ensemblId: 'ENSG00000157764', symbol: 'BRAF', description: 'B-Raf proto-oncogene',
      chromosome: '7', start: 140719327, end: 140924929, strand: -1, biotype: 'protein_coding', assembly: 'GRCh38'),
    GeneInfo(ensemblId: 'ENSG00000133703', symbol: 'KRAS', description: 'KRAS proto-oncogene',
      chromosome: '12', start: 25205246, end: 25250929, strand: -1, biotype: 'protein_coding', assembly: 'GRCh38'),
  ];
}

class GenomeService {
  /// Search for a gene by symbol using Ensembl REST API
  static Future<List<GeneInfo>> searchGene(String query, {String assembly = 'GRCh38'}) async {
    if (query.trim().isEmpty) return [];

    final cacheKey = 'gene_search:${query.toLowerCase()}:$assembly';
    final cached = await CacheService.get('ensembl', cacheKey);

    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List<dynamic>;
        return list.map((item) => GeneInfo.fromJson(item as Map<String, dynamic>)).toList();
      } catch (_) {
        // Fall back to querying
      }
    }

    final baseUrl = assembly == 'GRCh37'
        ? 'https://grch37.rest.ensembl.org'
        : ApiConstants.ensembl;

    await RateLimiter.throttle('ensembl');

    try {
      final resp = await ApiService.get<List<dynamic>>(
        '$baseUrl/xrefs/symbol/homo_sapiens/$query',
        params: {'content-type': 'application/json'},
      );

      final results = <GeneInfo>[];
      for (final item in resp) {
        final id = item['id'] as String?;
        if (id == null || !id.startsWith('ENSG')) continue;

        // Fetch full gene info
        final gene = await _fetchGeneById(id, baseUrl: baseUrl);
        if (gene != null) results.add(gene);
      }

      if (results.isNotEmpty) {
        await CacheService.set(
          'ensembl',
          cacheKey,
          jsonEncode(results.map((g) => g.toJson()).toList()),
          ttl: const Duration(hours: 24),
        );
      }

      return results;
    } catch (_) {
      // Fallback to demo data
      return GeneInfo.demoGenes().where((g) =>
        g.symbol.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  /// Fetch gene info by Ensembl ID
  static Future<GeneInfo?> _fetchGeneById(String ensemblId, {String? baseUrl}) async {
    try {
      final base = baseUrl ?? ApiConstants.ensembl;
      await RateLimiter.throttle('ensembl');
      final resp = await ApiService.get<Map<String, dynamic>>(
        '$base/lookup/id/$ensemblId',
        params: {'content-type': 'application/json', 'expand': '0'},
      );

      return GeneInfo(
        ensemblId: resp['id'] as String? ?? ensemblId,
        symbol: resp['display_name'] as String? ?? '',
        description: resp['description'] as String? ?? '',
        chromosome: resp['seq_region_name'] as String? ?? '',
        start: (resp['start'] as num?)?.toInt() ?? 0,
        end: (resp['end'] as num?)?.toInt() ?? 0,
        strand: (resp['strand'] as num?)?.toInt() ?? 1,
        biotype: resp['biotype'] as String? ?? '',
        assembly: resp['assembly_name'] as String? ?? 'GRCh38',
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch genomic sequence for a region
  static Future<String?> fetchSequence(String chromosome, int start, int end,
      {String assembly = 'GRCh38'}) async {
    try {
      final baseUrl = assembly == 'GRCh37'
          ? 'https://grch37.rest.ensembl.org'
          : ApiConstants.ensembl;
      await RateLimiter.throttle('ensembl');
      final resp = await ApiService.get<Map<String, dynamic>>(
        '$baseUrl/sequence/region/homo_sapiens/$chromosome:$start..$end:1',
        params: {'content-type': 'application/json'},
      );
      return resp['seq'] as String?;
    } catch (_) {
      return null;
    }
  }
}
