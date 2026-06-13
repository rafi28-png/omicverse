import '../../../core/services/api_service.dart';
import '../../../core/services/rate_limiter.dart';

class CancerMutation {
  final String gene;
  final String mutation;
  final String cancerType;
  final double frequency; // % of samples
  final String consequence;
  final String? clinicalSignificance;

  const CancerMutation({
    required this.gene,
    required this.mutation,
    required this.cancerType,
    required this.frequency,
    required this.consequence,
    this.clinicalSignificance,
  });

  String get frequencyLabel => '${frequency.toStringAsFixed(1)}%';

  String get tier {
    if (frequency > 10) return 'Hotspot';
    if (frequency > 1) return 'Recurrent';
    return 'Rare';
  }

  static List<CancerMutation> demoMutations() => const [
    CancerMutation(gene: 'TP53', mutation: 'R175H', cancerType: 'Pan-cancer',
      frequency: 4.2, consequence: 'Missense', clinicalSignificance: 'Pathogenic'),
    CancerMutation(gene: 'TP53', mutation: 'R248W', cancerType: 'Pan-cancer',
      frequency: 3.1, consequence: 'Missense', clinicalSignificance: 'Pathogenic'),
    CancerMutation(gene: 'TP53', mutation: 'R273H', cancerType: 'Pan-cancer',
      frequency: 2.8, consequence: 'Missense', clinicalSignificance: 'Pathogenic'),
    CancerMutation(gene: 'KRAS', mutation: 'G12D', cancerType: 'Pancreatic',
      frequency: 32.5, consequence: 'Missense', clinicalSignificance: 'Oncogenic'),
    CancerMutation(gene: 'KRAS', mutation: 'G12V', cancerType: 'Lung',
      frequency: 21.0, consequence: 'Missense', clinicalSignificance: 'Oncogenic'),
    CancerMutation(gene: 'KRAS', mutation: 'G12C', cancerType: 'Lung',
      frequency: 13.5, consequence: 'Missense', clinicalSignificance: 'Oncogenic'),
    CancerMutation(gene: 'BRAF', mutation: 'V600E', cancerType: 'Melanoma',
      frequency: 45.0, consequence: 'Missense', clinicalSignificance: 'Oncogenic'),
    CancerMutation(gene: 'EGFR', mutation: 'L858R', cancerType: 'Lung',
      frequency: 18.7, consequence: 'Missense', clinicalSignificance: 'Oncogenic'),
    CancerMutation(gene: 'EGFR', mutation: 'T790M', cancerType: 'Lung',
      frequency: 5.2, consequence: 'Missense', clinicalSignificance: 'Drug resistance'),
    CancerMutation(gene: 'PIK3CA', mutation: 'H1047R', cancerType: 'Breast',
      frequency: 12.3, consequence: 'Missense', clinicalSignificance: 'Oncogenic'),
    CancerMutation(gene: 'BRCA1', mutation: '5382insC', cancerType: 'Breast/Ovarian',
      frequency: 0.8, consequence: 'Frameshift', clinicalSignificance: 'Pathogenic'),
  ];
}

class CancerStudy {
  final String id;
  final String name;
  final String cancerType;
  final int sampleCount;
  final String source;

  const CancerStudy({
    required this.id,
    required this.name,
    required this.cancerType,
    required this.sampleCount,
    this.source = 'cBioPortal',
  });

  static List<CancerStudy> demoStudies() => const [
    CancerStudy(id: 'brca_tcga', name: 'Breast Cancer (TCGA)', cancerType: 'Breast', sampleCount: 1084),
    CancerStudy(id: 'luad_tcga', name: 'Lung Adenocarcinoma (TCGA)', cancerType: 'Lung', sampleCount: 566),
    CancerStudy(id: 'skcm_tcga', name: 'Melanoma (TCGA)', cancerType: 'Skin', sampleCount: 472),
    CancerStudy(id: 'paad_tcga', name: 'Pancreatic Cancer (TCGA)', cancerType: 'Pancreas', sampleCount: 185),
    CancerStudy(id: 'coadread_tcga', name: 'Colorectal Cancer (TCGA)', cancerType: 'Colorectal', sampleCount: 594),
  ];
}

class CancerService {
  static const _cbioBase = 'https://www.cbioportal.org/api';

  /// Search cancer mutations for a gene
  static Future<List<CancerMutation>> getMutations(String gene) async {
    if (gene.trim().isEmpty) return [];
    try {
      await RateLimiter.throttle('cbioportal');
      final resp = await ApiService.get<List<dynamic>>(
        '$_cbioBase/genes/$gene/mutations',
        params: {'projection': 'SUMMARY'},
      );

      final mutations = <CancerMutation>[];
      for (final item in resp) {
        mutations.add(CancerMutation(
          gene: gene,
          mutation: item['proteinChange'] as String? ?? '',
          cancerType: item['cancerType'] as String? ?? 'Unknown',
          frequency: (item['mutationRate'] as num?)?.toDouble() ?? 0,
          consequence: item['mutationType'] as String? ?? '',
        ));
      }
      return mutations.isEmpty ? _demoForGene(gene) : mutations;
    } catch (_) {
      return _demoForGene(gene);
    }
  }

  /// Get cancer studies
  static Future<List<CancerStudy>> getStudies() async {
    try {
      await RateLimiter.throttle('cbioportal');
      final resp = await ApiService.get<List<dynamic>>('$_cbioBase/studies',
        params: {'projection': 'SUMMARY', 'pageSize': '10'});

      return resp.map((s) => CancerStudy(
        id: s['studyId'] as String? ?? '',
        name: s['name'] as String? ?? '',
        cancerType: s['cancerTypeId'] as String? ?? '',
        sampleCount: s['allSampleCount'] as int? ?? 0,
      )).toList();
    } catch (_) {
      return CancerStudy.demoStudies();
    }
  }

  /// Get mutation frequency by cancer type for a gene
  static Map<String, double> mutationByCancerType(List<CancerMutation> mutations) {
    final map = <String, double>{};
    for (final m in mutations) {
      map[m.cancerType] = (map[m.cancerType] ?? 0) + m.frequency;
    }
    return map;
  }

  static List<CancerMutation> _demoForGene(String gene) {
    return CancerMutation.demoMutations().where((m) =>
      m.gene.toLowerCase() == gene.toLowerCase()).toList();
  }
}
