import '../../../core/services/api_service.dart';
import '../../../core/services/api_constants.dart';
import '../../../core/services/rate_limiter.dart';
import '../../../core/services/cache_service.dart';
import 'vcf_parser.dart';

class AnnotatedVariant {
  final VcfVariant variant;
  final double? gnomadFrequency;
  final String? clinvarSignificance;
  final String? clinvarCondition;
  final String? gene;
  final String? consequence;

  const AnnotatedVariant({
    required this.variant,
    this.gnomadFrequency,
    this.clinvarSignificance,
    this.clinvarCondition,
    this.gene,
    this.consequence,
  });

  bool get isRare => (gnomadFrequency ?? 0) < 0.01;
  bool get isPathogenic =>
      clinvarSignificance?.toLowerCase().contains('pathogenic') ?? false;

  String get frequencyDisplay {
    if (gnomadFrequency == null) return 'N/A';
    if (gnomadFrequency! < 0.0001) return '<0.01%';
    return '${(gnomadFrequency! * 100).toStringAsFixed(2)}%';
  }
}

class VariantAnnotationService {
  /// Annotate a batch of variants with gnomAD frequencies and VEP consequences
  static Future<List<AnnotatedVariant>> annotate(
    List<VcfVariant> variants, {
    int batchSize = 200,
  }) async {
    final results = <AnnotatedVariant>[];

    for (int i = 0; i < variants.length; i += batchSize) {
      final batch = variants.sublist(
        i,
        i + batchSize > variants.length ? variants.length : i + batchSize,
      );

      for (final v in batch) {
        final annotated = await _annotateOne(v);
        results.add(annotated);
      }
    }

    return results;
  }

  static Future<AnnotatedVariant> _annotateOne(VcfVariant v) async {
    double? freq;
    String? clinSig;
    String? clinCond;
    String? gene;
    String? consequence;

    // Try gnomAD GraphQL
    try {
      final variantId = '${v.chromosome}-${v.position}-${v.ref}-${v.alt}';

      final cached = await CacheService.get('gnomad', variantId);
      if (cached != null) {
        freq = double.tryParse(cached);
      } else {
        await RateLimiter.throttle('gnomad');
        final body = ApiConstants.gnomadVariantQuery(variantId);
        final resp = await ApiService.post(ApiConstants.gnomad, body);

        final data = resp['data']?['variant'];
        if (data != null) {
          final genomeAc = data['genome']?['ac']?['ac'] as int? ?? 0;
          final genomeAn = data['genome']?['ac']?['an'] as int? ?? 0;
          if (genomeAn > 0) {
            freq = genomeAc / genomeAn;
            await CacheService.set('gnomad', variantId, freq.toString());
          }
        }
      }
    } catch (_) {
      // gnomAD lookup failed — continue without frequency
    }

    // Try Ensembl VEP for gene/consequence
    try {
      final vepId = '${v.chromosome}:${v.position}:${v.ref}/${v.alt}';
      final cached = await CacheService.get('ensembl', 'vep:$vepId');
      if (cached == null) {
        await RateLimiter.throttle('ensembl');
        final resp = await ApiService.get<List<dynamic>>(
          '${ApiConstants.ensembl}/vep/human/region/$vepId',
          params: {'content-type': 'application/json'},
        );
        if (resp.isNotEmpty) {
          final tc = resp[0]['transcript_consequences'] as List<dynamic>?;
          if (tc != null && tc.isNotEmpty) {
            gene = tc[0]['gene_symbol'] as String?;
            final terms = tc[0]['consequence_terms'] as List<dynamic>?;
            if (terms != null && terms.isNotEmpty) {
              consequence = (terms[0] as String).replaceAll('_', ' ');
            }
          }
          await CacheService.set('ensembl', 'vep:$vepId', 'done',
            ttl: const Duration(hours: 24));
        }
      }
    } catch (_) {
      // VEP lookup failed — continue
    }

    return AnnotatedVariant(
      variant: v,
      gnomadFrequency: freq,
      clinvarSignificance: clinSig,
      clinvarCondition: clinCond,
      gene: gene,
      consequence: consequence,
    );
  }
}
