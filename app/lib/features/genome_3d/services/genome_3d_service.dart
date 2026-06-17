import '../../../core/services/api_service.dart';
import '../../../core/services/api_constants.dart';
import '../../../core/services/rate_limiter.dart';

// ── Data Models ────────────────────────────────────────────────

class OmimDisease {
  final int mimNumber;
  final String title;
  final String? description;
  final String? inheritance;
  final String? genemap;
  final List<String> phenotypes;

  const OmimDisease({
    required this.mimNumber,
    required this.title,
    this.description,
    this.inheritance,
    this.genemap,
    this.phenotypes = const [],
  });

  String get url => 'https://omim.org/entry/$mimNumber';
  String get shortTitle => title.length > 80 ? '${title.substring(0, 77)}...' : title;

  static List<OmimDisease> demoData(String gene) => [
    OmimDisease(mimNumber: 191170, title: 'TUMOR PROTEIN p53; TP53', description: 'TP53 encodes a tumor suppressor protein containing transcriptional activation, DNA binding, and oligomerization domains.', inheritance: 'AD', phenotypes: ['Li-Fraumeni syndrome', 'Breast cancer', 'Colorectal cancer']),
    OmimDisease(mimNumber: 151623, title: 'LI-FRAUMENI SYNDROME; LFS', description: 'Li-Fraumeni syndrome is a cancer predisposition disorder caused by germline mutations in TP53.', inheritance: 'AD', phenotypes: ['Sarcoma', 'Breast cancer', 'Brain tumors', 'Adrenocortical carcinoma']),
  ];
}

class DiseaseAssociation {
  final String diseaseName;
  final String diseaseId;
  final double score;
  final String source;
  final int nPublications;

  const DiseaseAssociation({
    required this.diseaseName,
    required this.diseaseId,
    required this.score,
    required this.source,
    this.nPublications = 0,
  });

  String get scoreLabel => score.toStringAsFixed(3);
  String get evidenceLevel {
    if (score >= 0.7) return 'Strong';
    if (score >= 0.4) return 'Moderate';
    if (score >= 0.1) return 'Weak';
    return 'Minimal';
  }

  static List<DiseaseAssociation> demoData(String gene) => [
    DiseaseAssociation(diseaseName: 'Li-Fraumeni Syndrome', diseaseId: 'C0023379', score: 0.95, source: 'DisGeNET', nPublications: 342),
    DiseaseAssociation(diseaseName: 'Breast Cancer', diseaseId: 'C0006142', score: 0.87, source: 'DisGeNET', nPublications: 1205),
    DiseaseAssociation(diseaseName: 'Colorectal Cancer', diseaseId: 'C0009402', score: 0.72, source: 'DisGeNET', nPublications: 456),
    DiseaseAssociation(diseaseName: 'Lung Cancer', diseaseId: 'C0242379', score: 0.68, source: 'DisGeNET', nPublications: 389),
    DiseaseAssociation(diseaseName: 'Ovarian Cancer', diseaseId: 'C0029925', score: 0.61, source: 'DisGeNET', nPublications: 198),
  ];
}

// ── Service ────────────────────────────────────────────────────

class DiseaseGeneticsService {
  /// Query OMIM for gene-disease entries
  static Future<List<OmimDisease>> getOmimEntries(String gene) async {
    final apiKey = ApiConstants.omimApiKey;
    if (apiKey.isEmpty) return OmimDisease.demoData(gene);

    try {
      await RateLimiter.throttle('omim');
      final url = '${ApiConstants.omim}/entry/search'
        '?search=$gene'
        '&format=json'
        '&apiKey=$apiKey'
        '&include=geneMap,text'
        '&start=0&limit=10';

      final resp = await ApiService.get<Map<String, dynamic>>(url);
      final results = <OmimDisease>[];

      final searchResponse = resp['omim']?['searchResponse'] as Map<String, dynamic>?;
      final entryList = searchResponse?['entryList'] as List<dynamic>?;
      if (entryList == null || entryList.isEmpty) return OmimDisease.demoData(gene);

      for (final entry in entryList) {
        final e = entry['entry'] as Map<String, dynamic>?;
        if (e == null) continue;

        final mimNumber = e['mimNumber'] as int? ?? 0;
        final titles = e['titles'] as Map<String, dynamic>?;
        final title = titles?['preferredTitle'] as String? ?? 'Unknown';

        // Extract text description
        String? description;
        final textSectionList = e['textSectionList'] as List<dynamic>?;
        if (textSectionList != null && textSectionList.isNotEmpty) {
          final first = textSectionList[0]['textSection'] as Map<String, dynamic>?;
          final text = first?['textSectionContent'] as String? ?? '';
          description = text.length > 300 ? '${text.substring(0, 297)}...' : text;
        }

        // Extract phenotypes from geneMap
        final phenotypes = <String>[];
        final geneMap = e['geneMap'] as Map<String, dynamic>?;
        final phenotypeMapList = geneMap?['phenotypeMapList'] as List<dynamic>?;
        String? inheritance;
        if (phenotypeMapList != null) {
          for (final pm in phenotypeMapList) {
            final phenotypeMap = pm['phenotypeMap'] as Map<String, dynamic>?;
            final name = phenotypeMap?['phenotype'] as String?;
            if (name != null) phenotypes.add(name);
            inheritance ??= phenotypeMap?['phenotypeInheritance'] as String?;
          }
        }

        results.add(OmimDisease(
          mimNumber: mimNumber,
          title: title,
          description: description,
          inheritance: inheritance,
          phenotypes: phenotypes,
        ));
      }

      return results.isEmpty ? OmimDisease.demoData(gene) : results;
    } catch (_) {
      return OmimDisease.demoData(gene);
    }
  }

  /// Query DisGeNET for gene-disease associations
  static Future<List<DiseaseAssociation>> getDiseaseAssociations(String gene) async {
    final apiKey = ApiConstants.disgenetApiKey;
    if (apiKey.isEmpty) return DiseaseAssociation.demoData(gene);

    try {
      await RateLimiter.throttle('disgenet');
      final resp = await ApiService.getWithHeaders<List<dynamic>>(
        '${ApiConstants.disgenet}/gda/gene/$gene',
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
        },
      );

      if (resp.isEmpty) return DiseaseAssociation.demoData(gene);

      final results = resp.map((item) {
        final m = item as Map<String, dynamic>;
        return DiseaseAssociation(
          diseaseName: m['disease_name'] as String? ?? 'Unknown',
          diseaseId: m['diseaseid'] as String? ?? '',
          score: (m['score'] as num?)?.toDouble() ?? 0.0,
          source: 'DisGeNET',
          nPublications: (m['pmid_count'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      results.sort((a, b) => b.score.compareTo(a.score));
      return results.take(20).toList();
    } catch (_) {
      return DiseaseAssociation.demoData(gene);
    }
  }
}
