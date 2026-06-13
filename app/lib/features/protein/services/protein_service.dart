import '../../../core/services/api_service.dart';
import '../../../core/services/api_constants.dart';
import '../../../core/services/rate_limiter.dart';
import '../../../core/services/cache_service.dart';

class ProteinInfo {
  final String uniprotId;
  final String name;
  final String gene;
  final String organism;
  final int length;
  final String function;
  final String subcellularLocation;
  final List<String> keywords;
  final String? alphaFoldUrl;

  const ProteinInfo({
    required this.uniprotId,
    required this.name,
    required this.gene,
    this.organism = 'Homo sapiens',
    required this.length,
    this.function = '',
    this.subcellularLocation = '',
    this.keywords = const [],
    this.alphaFoldUrl,
  });

  String get uniprotUrl => 'https://www.uniprot.org/uniprot/$uniprotId';

  static List<ProteinInfo> demoProteins() => const [
    ProteinInfo(uniprotId: 'P04637', name: 'Cellular tumor antigen p53', gene: 'TP53',
      length: 393, function: 'Acts as a tumor suppressor in many tumor types. Induces growth arrest or apoptosis.',
      subcellularLocation: 'Nucleus, Cytoplasm', keywords: ['Tumor suppressor', 'Apoptosis', 'DNA-binding'],
      alphaFoldUrl: 'https://alphafold.ebi.ac.uk/entry/P04637'),
    ProteinInfo(uniprotId: 'P38398', name: 'Breast cancer type 1 susceptibility protein', gene: 'BRCA1',
      length: 1863, function: 'E3 ubiquitin-protein ligase. Plays a role in DNA repair and transcription.',
      subcellularLocation: 'Nucleus', keywords: ['DNA repair', 'Ubiquitin ligase', 'Tumor suppressor']),
    ProteinInfo(uniprotId: 'P00533', name: 'Epidermal growth factor receptor', gene: 'EGFR',
      length: 1210, function: 'Receptor tyrosine kinase binding ligands of the EGF family.',
      subcellularLocation: 'Cell membrane', keywords: ['Kinase', 'Receptor', 'Proto-oncogene']),
    ProteinInfo(uniprotId: 'P15056', name: 'Serine/threonine-protein kinase B-raf', gene: 'BRAF',
      length: 766, function: 'Serine/threonine-protein kinase involved in MAPK/ERK signaling.',
      subcellularLocation: 'Cytoplasm', keywords: ['Kinase', 'Proto-oncogene', 'MAPK signaling']),
    ProteinInfo(uniprotId: 'P01116', name: 'GTPase KRas', gene: 'KRAS',
      length: 189, function: 'GTPase involved in RAS/MAPK signaling. Frequently mutated in cancer.',
      subcellularLocation: 'Cell membrane', keywords: ['GTPase', 'Proto-oncogene', 'Prenylation']),
  ];
}

class ProteinDomain {
  final String name;
  final String type;
  final int start;
  final int end;

  const ProteinDomain({
    required this.name,
    required this.type,
    required this.start,
    required this.end,
  });

  int get length => end - start + 1;
}

class ProteinService {
  static const _uniprotBase = 'https://rest.uniprot.org/uniprotkb';

  /// Search proteins by gene symbol or name
  static Future<List<ProteinInfo>> searchProtein(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      await RateLimiter.throttle('uniprot');
      final resp = await ApiService.get<Map<String, dynamic>>(
        '$_uniprotBase/search',
        params: {
          'query': '(gene:$query) AND (organism_id:9606)',
          'format': 'json',
          'size': '10',
          'fields': 'accession,protein_name,gene_names,length,organism_name,cc_function,cc_subcellular_location,keyword',
        },
      );

      final results = <ProteinInfo>[];
      final items = resp['results'] as List<dynamic>? ?? [];

      for (final item in items) {
        final accession = item['primaryAccession'] as String? ?? '';
        final protName = _extractProteinName(item);
        final geneName = _extractGeneName(item);
        final length = item['sequence']?['length'] as int? ?? 0;
        final function = _extractFunction(item);
        final location = _extractLocation(item);
        final keywords = _extractKeywords(item);

        results.add(ProteinInfo(
          uniprotId: accession,
          name: protName,
          gene: geneName,
          length: length,
          function: function,
          subcellularLocation: location,
          keywords: keywords,
          alphaFoldUrl: 'https://alphafold.ebi.ac.uk/entry/$accession',
        ));
      }

      return results;
    } catch (_) {
      return ProteinInfo.demoProteins().where((p) =>
        p.gene.toLowerCase().contains(query.toLowerCase()) ||
        p.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  /// Fetch AlphaFold confidence data
  static Future<double?> fetchAlphaFoldConfidence(String uniprotId) async {
    try {
      final cached = await CacheService.get('alphafold', 'plddt:$uniprotId');
      if (cached != null) return double.tryParse(cached);

      await RateLimiter.throttle('alphafold');
      final url = ApiConstants.alphaFoldPrediction(uniprotId);
      final resp = await ApiService.get<List<dynamic>>(url);

      if (resp.isNotEmpty) {
        final plddt = resp[0]['plddt'] as num?;
        if (plddt != null) {
          await CacheService.set('alphafold', 'plddt:$uniprotId', plddt.toString());
          return plddt.toDouble();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _extractProteinName(Map<String, dynamic> item) {
    try {
      return item['proteinDescription']?['recommendedName']?['fullName']?['value'] as String? ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  static String _extractGeneName(Map<String, dynamic> item) {
    try {
      final genes = item['genes'] as List<dynamic>? ?? [];
      if (genes.isNotEmpty) {
        return genes[0]['geneName']?['value'] as String? ?? '';
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  static String _extractFunction(Map<String, dynamic> item) {
    try {
      final comments = item['comments'] as List<dynamic>? ?? [];
      for (final c in comments) {
        if (c['commentType'] == 'FUNCTION') {
          final texts = c['texts'] as List<dynamic>? ?? [];
          if (texts.isNotEmpty) return texts[0]['value'] as String? ?? '';
        }
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  static String _extractLocation(Map<String, dynamic> item) {
    try {
      final comments = item['comments'] as List<dynamic>? ?? [];
      for (final c in comments) {
        if (c['commentType'] == 'SUBCELLULAR LOCATION') {
          final locs = c['subcellularLocations'] as List<dynamic>? ?? [];
          return locs.map((l) => l['location']?['value'] ?? '').where((s) => s.isNotEmpty).join(', ');
        }
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  static List<String> _extractKeywords(Map<String, dynamic> item) {
    try {
      final kw = item['keywords'] as List<dynamic>? ?? [];
      return kw.map((k) => k['name'] as String? ?? '').where((s) => s.isNotEmpty).take(8).toList();
    } catch (_) {
      return [];
    }
  }
}
