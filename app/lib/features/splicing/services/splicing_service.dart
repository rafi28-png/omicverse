import '../../../core/services/api_service.dart';
import '../../../core/services/rate_limiter.dart';

class Isoform {
  final String transcriptId;
  final String gene;
  final int exonCount;
  final int length;
  final String biotype;
  final bool isCanonical;
  final double? tpm; // expression level

  const Isoform({
    required this.transcriptId,
    required this.gene,
    required this.exonCount,
    required this.length,
    this.biotype = 'protein_coding',
    this.isCanonical = false,
    this.tpm,
  });

  String get label => isCanonical ? '$transcriptId (canonical)' : transcriptId;
}

class SplicingEvent {
  final String gene;
  final String type; // SE, A5SS, A3SS, MXE, RI
  final String exon;
  final double inclusionLevel; // PSI (0-1)
  final String tissue;

  const SplicingEvent({
    required this.gene,
    required this.type,
    required this.exon,
    required this.inclusionLevel,
    this.tissue = 'Multiple',
  });

  String get typeName {
    const names = {
      'SE': 'Skipped Exon',
      'A5SS': "Alt 5' Splice Site",
      'A3SS': "Alt 3' Splice Site",
      'MXE': 'Mutually Exclusive',
      'RI': 'Retained Intron',
    };
    return names[type] ?? type;
  }

  String get psiLabel => '${(inclusionLevel * 100).toStringAsFixed(0)}%';

  static List<SplicingEvent> demoEvents() => const [
    SplicingEvent(gene: 'TP53', type: 'SE', exon: 'Exon 4', inclusionLevel: 0.85, tissue: 'Brain'),
    SplicingEvent(gene: 'TP53', type: 'A3SS', exon: 'Exon 7', inclusionLevel: 0.62, tissue: 'Liver'),
    SplicingEvent(gene: 'TP53', type: 'RI', exon: 'Intron 9', inclusionLevel: 0.12, tissue: 'Lung'),
    SplicingEvent(gene: 'BRCA1', type: 'SE', exon: 'Exon 11', inclusionLevel: 0.92, tissue: 'Breast'),
    SplicingEvent(gene: 'BRCA1', type: 'MXE', exon: 'Exon 14/15', inclusionLevel: 0.45, tissue: 'Ovary'),
    SplicingEvent(gene: 'EGFR', type: 'SE', exon: 'Exon 20', inclusionLevel: 0.78, tissue: 'Lung'),
    SplicingEvent(gene: 'EGFR', type: 'A5SS', exon: 'Exon 15', inclusionLevel: 0.55, tissue: 'Brain'),
    SplicingEvent(gene: 'KRAS', type: 'MXE', exon: 'Exon 4a/4b', inclusionLevel: 0.35, tissue: 'Pancreas'),
  ];
}

class SplicingService {
  static const _ensemblBase = 'https://rest.ensembl.org';

  /// Get transcript isoforms for a gene
  static Future<List<Isoform>> getIsoforms(String gene) async {
    if (gene.trim().isEmpty) return [];
    try {
      await RateLimiter.throttle('ensembl');
      final resp = await ApiService.get<Map<String, dynamic>>(
        '$_ensemblBase/lookup/symbol/homo_sapiens/$gene',
        params: {'expand': '1', 'content-type': 'application/json'},
      );

      final transcripts = resp['Transcript'] as List<dynamic>? ?? [];
      return transcripts.map((t) => Isoform(
        transcriptId: t['id'] as String? ?? '',
        gene: gene,
        exonCount: (t['Exon'] as List<dynamic>?)?.length ?? 0,
        length: t['length'] as int? ?? 0,
        biotype: t['biotype'] as String? ?? 'unknown',
        isCanonical: t['is_canonical'] == 1,
      )).toList();
    } catch (_) {
      return demoIsoforms(gene);
    }
  }

  /// Get splicing events for a gene (demo)
  static Future<List<SplicingEvent>> getSplicingEvents(String gene) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return SplicingEvent.demoEvents().where((e) =>
      e.gene.toLowerCase() == gene.toLowerCase()).toList();
  }

  /// Get event type distribution
  static Map<String, int> eventTypeDistribution(List<SplicingEvent> events) {
    final dist = <String, int>{};
    for (final e in events) {
      dist[e.type] = (dist[e.type] ?? 0) + 1;
    }
    return dist;
  }

  static List<Isoform> demoIsoforms(String gene) {
    return [
      Isoform(transcriptId: 'ENST00000269305', gene: gene, exonCount: 11,
        length: 2629, biotype: 'protein_coding', isCanonical: true, tpm: 45.2),
      Isoform(transcriptId: 'ENST00000445888', gene: gene, exonCount: 10,
        length: 2341, biotype: 'protein_coding', tpm: 12.8),
      Isoform(transcriptId: 'ENST00000504290', gene: gene, exonCount: 7,
        length: 1520, biotype: 'protein_coding', tpm: 3.5),
      Isoform(transcriptId: 'ENST00000510385', gene: gene, exonCount: 4,
        length: 892, biotype: 'nonsense_mediated_decay', tpm: 0.8),
      Isoform(transcriptId: 'ENST00000604348', gene: gene, exonCount: 3,
        length: 451, biotype: 'retained_intron', tpm: 0.2),
    ];
  }
}
