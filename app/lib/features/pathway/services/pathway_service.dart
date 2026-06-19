import '../../../core/services/api_service.dart';
import '../../../core/services/rate_limiter.dart';
import '../../../core/services/cache_service.dart';

class PathwayInfo {
  final String id;
  final String name;
  final String description;
  final String organism;
  final List<String> genes;

  const PathwayInfo({
    required this.id,
    required this.name,
    required this.description,
    this.organism = 'hsa',
    this.genes = const [],
  });

  String get keggUrl => 'https://www.kegg.jp/pathway/$id';

  /// Demo pathways for offline mode
  static List<PathwayInfo> demoPathways() => const [
    PathwayInfo(id: 'hsa04110', name: 'Cell cycle', description: 'Cell cycle regulation and checkpoints',
      genes: ['TP53', 'RB1', 'CDK2', 'CDK4', 'CCND1', 'CCNE1', 'E2F1', 'MYC']),
    PathwayInfo(id: 'hsa04151', name: 'PI3K-Akt signaling', description: 'PI3K-Akt signaling pathway',
      genes: ['PIK3CA', 'AKT1', 'PTEN', 'MTOR', 'TSC1', 'TSC2', 'EGFR', 'ERBB2']),
    PathwayInfo(id: 'hsa04010', name: 'MAPK signaling', description: 'MAPK signaling pathway',
      genes: ['BRAF', 'KRAS', 'NRAS', 'MAP2K1', 'MAPK1', 'MAPK3', 'RAF1', 'EGFR']),
    PathwayInfo(id: 'hsa04115', name: 'p53 signaling', description: 'p53 signaling pathway',
      genes: ['TP53', 'MDM2', 'CDKN1A', 'BAX', 'BBC3', 'PMAIP1', 'GADD45A']),
    PathwayInfo(id: 'hsa05200', name: 'Pathways in cancer', description: 'Overview of cancer-related pathways',
      genes: ['TP53', 'KRAS', 'BRAF', 'PIK3CA', 'AKT1', 'PTEN', 'EGFR', 'MYC', 'RB1']),
    PathwayInfo(id: 'hsa04210', name: 'Apoptosis', description: 'Programmed cell death pathways',
      genes: ['BCL2', 'BAX', 'CASP3', 'CASP9', 'CYCS', 'APAF1', 'BID', 'TP53']),
    PathwayInfo(id: 'hsa03030', name: 'DNA replication', description: 'DNA replication machinery',
      genes: ['MCM2', 'MCM3', 'MCM4', 'MCM5', 'MCM6', 'MCM7', 'PCNA', 'RFC1']),
    PathwayInfo(id: 'hsa04310', name: 'Wnt signaling', description: 'Wnt signaling pathway',
      genes: ['CTNNB1', 'APC', 'GSK3B', 'AXIN1', 'WNT1', 'FZD1', 'LEF1', 'TCF7']),
  ];
}

class InteractionPartner {
  final String gene;
  final double score;
  final String source;

  const InteractionPartner({
    required this.gene,
    required this.score,
    this.source = 'STRING',
  });
}

class PathwayService {
  static const _keggBase = 'https://rest.kegg.jp';
  static const _stringBase = 'https://string-db.org/api';

  /// Search KEGG pathways by keyword
  static Future<List<PathwayInfo>> searchPathways(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      await RateLimiter.throttle('kegg');
      final resp = await ApiService.getRaw(
        '$_keggBase/find/pathway/$query',
      );

      final results = <PathwayInfo>[];
      for (final line in resp.split('\n')) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('\t');
        if (parts.length < 2) continue;

        final id = parts[0].trim().replaceAll('path:', '');
        final name = parts[1].trim().split(' - ')[0];

        // Only human pathways
        if (!id.startsWith('hsa')) {
          // Try to convert map to hsa
          final hsaId = 'hsa${id.replaceAll(RegExp(r'[a-zA-Z]+'), '')}';
          results.add(PathwayInfo(id: hsaId, name: name, description: name));
        } else {
          results.add(PathwayInfo(id: id, name: name, description: name));
        }
      }

      return results.take(20).toList();
    } catch (_) {
      // Fallback to demo
      return PathwayInfo.demoPathways().where((p) =>
        p.name.toLowerCase().contains(query.toLowerCase()) ||
        p.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  /// Search pathways for a specific gene
  static Future<List<PathwayInfo>> pathwaysForGene(String gene) async {
    try {
      // Step 1: Resolve gene to KEGG ID (e.g., TP53 → hsa:7157)
      await RateLimiter.throttle('kegg');
      final geneResp = await ApiService.getRaw(
        '$_keggBase/find/genes/$gene+homo+sapiens',
      );

      String? keggGeneId;
      for (final line in geneResp.split('\n')) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('\t');
        if (parts.isNotEmpty && parts[0].startsWith('hsa:')) {
          keggGeneId = parts[0].trim();
          break;
        }
      }

      if (keggGeneId == null) {
        // Fallback: try direct link with common KEGG ID format
        keggGeneId = 'hsa:$gene';
      }

      // Step 2: Get pathways containing this gene
      await RateLimiter.throttle('kegg');
      final resp = await ApiService.getRaw(
        '$_keggBase/link/pathway/$keggGeneId',
      );

      // link/pathway response format: hsa:7157\tpath:hsa05200
      final pathwayIds = <String>[];
      for (final line in resp.split('\n')) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('\t');
        if (parts.length < 2) continue;
        final pathId = parts[1].trim().replaceAll('path:', '');
        if (pathId.startsWith('hsa')) {
          pathwayIds.add(pathId);
        }
      }

      if (pathwayIds.isEmpty) {
        return PathwayInfo.demoPathways().where((p) =>
          p.genes.any((g) => g.toLowerCase() == gene.toLowerCase())
        ).toList();
      }

      // Step 3: Get pathway names
      final results = <PathwayInfo>[];
      for (final pathId in pathwayIds.take(15)) {
        try {
          await RateLimiter.throttle('kegg');
          final infoResp = await ApiService.getRaw('$_keggBase/get/$pathId');
          final nameMatch = RegExp(r'NAME\s+(.+)').firstMatch(infoResp);
          final descMatch = RegExp(r'DESCRIPTION\s+(.+)').firstMatch(infoResp);
          results.add(PathwayInfo(
            id: pathId,
            name: nameMatch?.group(1)?.split(' - ')[0].trim() ?? pathId,
            description: descMatch?.group(1)?.trim() ?? '',
            genes: [gene],
          ));
        } catch (_) {
          results.add(PathwayInfo(id: pathId, name: pathId, description: '', genes: [gene]));
        }
      }
      return results;
    } catch (_) {
      return PathwayInfo.demoPathways().where((p) =>
        p.genes.any((g) => g.toLowerCase() == gene.toLowerCase())
      ).toList();
    }
  }

  /// Get STRING protein-protein interactions
  static Future<List<InteractionPartner>> getInteractions(String gene) async {
    try {
      final cached = await CacheService.get('string', 'ppi:$gene');
      if (cached != null) {
        return _parseInteractionCache(cached);
      }

      await RateLimiter.throttle('string');
      final resp = await ApiService.get<List<dynamic>>(
        '$_stringBase/json/interaction_partners',
        params: {
          'identifiers': gene,
          'species': '9606',
          'limit': '10',
          'required_score': '700',
        },
      );

      final partners = <InteractionPartner>[];
      for (final item in resp) {
        final partner = item['preferredName_B'] as String? ?? '';
        final score = (item['score'] as num?)?.toDouble() ?? 0;
        if (partner.isNotEmpty && partner != gene) {
          partners.add(InteractionPartner(gene: partner, score: score));
        }
      }

      partners.sort((a, b) => b.score.compareTo(a.score));
      await CacheService.set('string', 'ppi:$gene',
        partners.map((p) => '${p.gene}:${p.score}').join(','),
        ttl: const Duration(hours: 24));

      return partners;
    } catch (_) {
      // Demo interactions
      return _demoInteractions(gene);
    }
  }

  static List<InteractionPartner> _parseInteractionCache(String cached) {
    return cached.split(',').where((s) => s.contains(':')).map((s) {
      final parts = s.split(':');
      return InteractionPartner(
        gene: parts[0],
        score: double.tryParse(parts[1]) ?? 0,
      );
    }).toList();
  }

  static List<InteractionPartner> _demoInteractions(String gene) {
    final map = {
      'TP53': [('MDM2', 0.999), ('CDKN1A', 0.998), ('BAX', 0.990), ('BCL2', 0.970), ('MDM4', 0.960)],
      'BRCA1': [('BARD1', 0.999), ('RAD51', 0.998), ('TP53', 0.980), ('BRCA2', 0.970), ('ATM', 0.960)],
      'EGFR': [('GRB2', 0.999), ('ERBB2', 0.998), ('SHC1', 0.990), ('PIK3CA', 0.980), ('SOS1', 0.960)],
      'KRAS': [('BRAF', 0.999), ('RAF1', 0.998), ('PIK3CA', 0.990), ('MAP2K1', 0.970), ('NRAS', 0.950)],
    };
    final pairs = map[gene.toUpperCase()] ?? [('UNKNOWN', 0.5)];
    return pairs.map((p) => InteractionPartner(gene: p.$1, score: p.$2)).toList();
  }
}
