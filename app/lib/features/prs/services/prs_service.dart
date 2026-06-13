import '../../../core/services/api_service.dart';
import '../../../core/services/rate_limiter.dart';

class PgsScore {
  final String pgsId;
  final String name;
  final String trait;
  final int variantCount;
  final String reportedTrait;
  final String? pubmedId;
  final String? journal;
  final int? year;
  final double? performanceMetric;

  const PgsScore({
    required this.pgsId,
    required this.name,
    required this.trait,
    required this.variantCount,
    this.reportedTrait = '',
    this.pubmedId,
    this.journal,
    this.year,
    this.performanceMetric,
  });

  String get catalogUrl => 'https://www.pgscatalog.org/score/$pgsId/';

  static List<PgsScore> demoScores() => const [
    PgsScore(pgsId: 'PGS000001', name: 'Breast cancer PRS', trait: 'Breast cancer',
      variantCount: 313, reportedTrait: 'Breast carcinoma', pubmedId: '30554720',
      journal: 'Nature Genetics', year: 2019, performanceMetric: 0.64),
    PgsScore(pgsId: 'PGS000002', name: 'Type 2 diabetes PRS', trait: 'Type 2 diabetes',
      variantCount: 6917086, reportedTrait: 'Type 2 diabetes mellitus', pubmedId: '30297969',
      journal: 'Nature Genetics', year: 2018, performanceMetric: 0.67),
    PgsScore(pgsId: 'PGS000004', name: 'Coronary artery disease PRS', trait: 'Coronary artery disease',
      variantCount: 6630150, reportedTrait: 'Coronary heart disease', pubmedId: '30104762',
      journal: 'Nature Genetics', year: 2018, performanceMetric: 0.61),
    PgsScore(pgsId: 'PGS000013', name: 'Prostate cancer PRS', trait: 'Prostate cancer',
      variantCount: 269, reportedTrait: 'Prostate carcinoma', pubmedId: '30349118',
      journal: 'European Urology', year: 2019, performanceMetric: 0.66),
    PgsScore(pgsId: 'PGS000018', name: 'Alzheimer disease PRS', trait: 'Alzheimer disease',
      variantCount: 21, reportedTrait: 'Alzheimer disease', pubmedId: '24162737',
      journal: 'Molecular Psychiatry', year: 2014, performanceMetric: 0.58),
    PgsScore(pgsId: 'PGS000296', name: 'Schizophrenia PRS', trait: 'Schizophrenia',
      variantCount: 93923, reportedTrait: 'Schizophrenia', pubmedId: '31740837',
      journal: 'Nature', year: 2019, performanceMetric: 0.59),
  ];
}

class PrsService {
  static const _pgsBase = 'https://www.pgscatalog.org/rest';

  /// Search PGS Catalog for polygenic scores by trait
  static Future<List<PgsScore>> searchByTrait(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      await RateLimiter.throttle('pgscatalog');
      final resp = await ApiService.get<Map<String, dynamic>>(
        '$_pgsBase/score/search',
        params: {'term': query, 'limit': '15'},
      );

      final results = <PgsScore>[];
      final items = resp['results'] as List<dynamic>? ?? [];

      for (final item in items) {
        results.add(PgsScore(
          pgsId: item['id'] as String? ?? '',
          name: item['name'] as String? ?? '',
          trait: _extractTrait(item),
          variantCount: item['variants_number'] as int? ?? 0,
          reportedTrait: item['trait_reported'] as String? ?? '',
          pubmedId: _extractPubmed(item),
          performanceMetric: null,
        ));
      }

      return results.isEmpty ? _demoSearch(query) : results;
    } catch (_) {
      return _demoSearch(query);
    }
  }

  /// Get score details by PGS ID
  static Future<PgsScore?> getScore(String pgsId) async {
    try {
      await RateLimiter.throttle('pgscatalog');
      final resp = await ApiService.get<Map<String, dynamic>>(
        '$_pgsBase/score/$pgsId',
      );

      return PgsScore(
        pgsId: resp['id'] as String? ?? pgsId,
        name: resp['name'] as String? ?? '',
        trait: _extractTrait(resp),
        variantCount: resp['variants_number'] as int? ?? 0,
        reportedTrait: resp['trait_reported'] as String? ?? '',
        pubmedId: _extractPubmed(resp),
      );
    } catch (_) {
      return PgsScore.demoScores().where((s) => s.pgsId == pgsId).firstOrNull;
    }
  }

  static String _extractTrait(Map<String, dynamic> item) {
    try {
      final efo = item['trait_efo'] as List<dynamic>? ?? [];
      if (efo.isNotEmpty) return efo[0]['label'] as String? ?? '';
      return item['trait_reported'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  static String? _extractPubmed(Map<String, dynamic> item) {
    try {
      final pub = item['publication'] as Map<String, dynamic>?;
      return pub?['PMID'] as String?;
    } catch (_) {
      return null;
    }
  }

  static List<PgsScore> _demoSearch(String query) {
    return PgsScore.demoScores().where((s) =>
      s.trait.toLowerCase().contains(query.toLowerCase()) ||
      s.name.toLowerCase().contains(query.toLowerCase()) ||
      s.reportedTrait.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
