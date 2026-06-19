import '../../../core/services/api_service.dart';
import '../../../core/services/rate_limiter.dart';

class Drug {
  final String chemblId;
  final String name;
  final String type; // Small molecule, Antibody, etc.
  final int maxPhase;
  final String? mechanism;
  final String? targetGene;
  final String? indication;
  final bool isApproved;

  const Drug({
    required this.chemblId,
    required this.name,
    required this.type,
    required this.maxPhase,
    this.mechanism,
    this.targetGene,
    this.indication,
    this.isApproved = false,
  });

  String get phaseLabel {
    switch (maxPhase) {
      case 4: return 'Approved';
      case 3: return 'Phase III';
      case 2: return 'Phase II';
      case 1: return 'Phase I';
      case 0: return 'Preclinical';
      default: return 'Unknown';
    }
  }

  static List<Drug> demoDrugs() => const [
    Drug(chemblId: 'CHEMBL83', name: 'Imatinib', type: 'Small molecule',
      maxPhase: 4, mechanism: 'Tyrosine kinase inhibitor', targetGene: 'ABL1',
      indication: 'Chronic myeloid leukemia', isApproved: true),
    Drug(chemblId: 'CHEMBL1421', name: 'Trastuzumab', type: 'Antibody',
      maxPhase: 4, mechanism: 'HER2 antagonist', targetGene: 'ERBB2',
      indication: 'Breast cancer', isApproved: true),
    Drug(chemblId: 'CHEMBL941', name: 'Vemurafenib', type: 'Small molecule',
      maxPhase: 4, mechanism: 'BRAF inhibitor', targetGene: 'BRAF',
      indication: 'Melanoma', isApproved: true),
    Drug(chemblId: 'CHEMBL1201583', name: 'Osimertinib', type: 'Small molecule',
      maxPhase: 4, mechanism: 'EGFR inhibitor', targetGene: 'EGFR',
      indication: 'Non-small cell lung cancer', isApproved: true),
    Drug(chemblId: 'CHEMBL4297085', name: 'Sotorasib', type: 'Small molecule',
      maxPhase: 4, mechanism: 'KRAS G12C inhibitor', targetGene: 'KRAS',
      indication: 'Non-small cell lung cancer', isApproved: true),
    Drug(chemblId: 'CHEMBL1336', name: 'Olaparib', type: 'Small molecule',
      maxPhase: 4, mechanism: 'PARP inhibitor', targetGene: 'PARP1',
      indication: 'Ovarian/Breast cancer', isApproved: true),
    Drug(chemblId: 'CHEMBL3545110', name: 'Pembrolizumab', type: 'Antibody',
      maxPhase: 4, mechanism: 'PD-1 antagonist', targetGene: 'PDCD1',
      indication: 'Multiple cancers', isApproved: true),
    Drug(chemblId: 'CHEMBL1237044', name: 'Alpelisib', type: 'Small molecule',
      maxPhase: 4, mechanism: 'PI3K inhibitor', targetGene: 'PIK3CA',
      indication: 'Breast cancer', isApproved: true),
  ];
}

class DrugTarget {
  final String gene;
  final String uniprotId;
  final int drugCount;
  final String targetClass;

  const DrugTarget({
    required this.gene,
    this.uniprotId = '',
    required this.drugCount,
    required this.targetClass,
  });

  static List<DrugTarget> demoTargets() => const [
    DrugTarget(gene: 'EGFR', uniprotId: 'P00533', drugCount: 45, targetClass: 'Kinase'),
    DrugTarget(gene: 'BRAF', uniprotId: 'P15056', drugCount: 18, targetClass: 'Kinase'),
    DrugTarget(gene: 'ERBB2', uniprotId: 'P04626', drugCount: 22, targetClass: 'Kinase'),
    DrugTarget(gene: 'ABL1', uniprotId: 'P00519', drugCount: 15, targetClass: 'Kinase'),
    DrugTarget(gene: 'PDCD1', uniprotId: 'Q15116', drugCount: 12, targetClass: 'Immune checkpoint'),
  ];
}

class DrugService {
  static const _chemblBase = 'https://www.ebi.ac.uk/chembl/api/data';

  /// Search drugs by target gene
  static Future<List<Drug>> searchByTarget(String gene) async {
    if (gene.trim().isEmpty) return [];
    try {
      // Step 1: Find the target ChEMBL ID
      await RateLimiter.throttle('chembl');
      final targetResp = await ApiService.get<Map<String, dynamic>>(
        '$_chemblBase/target.json',
        params: {
          'target_synonym__icontains': gene,
          'organism': 'Homo sapiens',
          'limit': '1',
        },
      );

      final targetList = targetResp['targets'] as List<dynamic>? ?? [];
      if (targetList.isEmpty) return _demoForGene(gene);
      final targetChemblId = targetList[0]['target_chembl_id'] as String? ?? '';

      // Step 2: Query mechanisms for that target ID
      await RateLimiter.throttle('chembl');
      final resp = await ApiService.get<Map<String, dynamic>>(
        '$_chemblBase/mechanism.json',
        params: {'target_chembl_id': targetChemblId, 'limit': '15'},
      );

      final mechanisms = resp['mechanisms'] as List<dynamic>? ?? [];
      if (mechanisms.isEmpty) return _demoForGene(gene);

      // Step 3: Fetch molecule details for each unique molecule_chembl_id
      final seen = <String>{};
      final results = <Drug>[];

      for (final m in mechanisms) {
        final molId = m['molecule_chembl_id'] as String? ?? '';
        if (molId.isEmpty || seen.contains(molId)) continue;
        seen.add(molId);

        final mechanism = m['mechanism_of_action'] as String? ?? '';

        try {
          await RateLimiter.throttle('chembl');
          final molResp = await ApiService.get<Map<String, dynamic>>(
            '$_chemblBase/molecule/$molId.json',
          );

          results.add(Drug(
            chemblId: molId,
            name: (molResp['pref_name'] as String?) ?? molId,
            type: molResp['molecule_type'] as String? ?? 'Unknown',
            maxPhase: (molResp['max_phase'] as num?)?.toInt() ?? 0,
            mechanism: mechanism,
            targetGene: gene,
            isApproved: ((molResp['max_phase'] as num?)?.toInt() ?? 0) >= 4,
          ));
        } catch (_) {
          // If molecule fetch fails, still add with mechanism data
          results.add(Drug(
            chemblId: molId,
            name: molId,
            type: 'Unknown',
            maxPhase: 0,
            mechanism: mechanism,
            targetGene: gene,
          ));
        }
      }

      return results.isEmpty ? _demoForGene(gene) : results;
    } catch (_) {
      return _demoForGene(gene);
    }
  }

  /// Search drugs by name
  static Future<List<Drug>> searchByName(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      await RateLimiter.throttle('chembl');
      final resp = await ApiService.get<Map<String, dynamic>>(
        '$_chemblBase/molecule/search.json',
        params: {'q': query, 'limit': '10'},
      );

      final results = resp['molecules'] as List<dynamic>? ?? [];
      return results.map((m) => Drug(
        chemblId: m['molecule_chembl_id'] as String? ?? '',
        name: (m['pref_name'] as String?) ?? (m['molecule_chembl_id'] as String? ?? ''),
        type: m['molecule_type'] as String? ?? 'Unknown',
        maxPhase: (m['max_phase'] as num?)?.toInt() ?? 0,
        isApproved: ((m['max_phase'] as num?)?.toInt() ?? 0) >= 4,
      )).toList();
    } catch (_) {
      return Drug.demoDrugs().where((d) =>
        d.name.toLowerCase().contains(query.toLowerCase())).toList();
    }
  }

  /// Group drugs by phase
  static Map<String, int> drugsByPhase(List<Drug> drugs) {
    final map = <String, int>{};
    for (final d in drugs) {
      final phase = d.phaseLabel;
      map[phase] = (map[phase] ?? 0) + 1;
    }
    return map;
  }

  /// Group drugs by type
  static Map<String, int> drugsByType(List<Drug> drugs) {
    final map = <String, int>{};
    for (final d in drugs) {
      map[d.type] = (map[d.type] ?? 0) + 1;
    }
    return map;
  }

  static List<Drug> _demoForGene(String gene) {
    return Drug.demoDrugs().where((d) =>
      d.targetGene?.toLowerCase() == gene.toLowerCase()).toList();
  }
}
