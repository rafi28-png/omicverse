import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/rate_limiter.dart';
import '../../../core/services/cache_service.dart';

class TissueExpression {
  final String tissue;
  final String tissueSiteDetailId;
  final double medianTpm;
  final String geneSymbol;

  const TissueExpression({
    required this.tissue,
    required this.tissueSiteDetailId,
    required this.medianTpm,
    required this.geneSymbol,
  });

  String get tpmLabel => medianTpm < 0.1
      ? '<0.1 TPM'
      : '${medianTpm.toStringAsFixed(1)} TPM';

  String get expressionLevel {
    if (medianTpm < 1) return 'Not detected';
    if (medianTpm < 5) return 'Low';
    if (medianTpm < 25) return 'Medium';
    if (medianTpm < 100) return 'High';
    return 'Very high';
  }

  /// Demo data for offline mode
  static List<TissueExpression> demoData(String gene) => [
    TissueExpression(tissue: 'Brain - Cortex', tissueSiteDetailId: 'Brain_Cortex', medianTpm: 15.2, geneSymbol: gene),
    TissueExpression(tissue: 'Liver', tissueSiteDetailId: 'Liver', medianTpm: 8.7, geneSymbol: gene),
    TissueExpression(tissue: 'Heart - Left Ventricle', tissueSiteDetailId: 'Heart_Left_Ventricle', medianTpm: 22.4, geneSymbol: gene),
    TissueExpression(tissue: 'Lung', tissueSiteDetailId: 'Lung', medianTpm: 31.5, geneSymbol: gene),
    TissueExpression(tissue: 'Kidney - Cortex', tissueSiteDetailId: 'Kidney_Cortex', medianTpm: 18.9, geneSymbol: gene),
    TissueExpression(tissue: 'Skin - Sun Exposed', tissueSiteDetailId: 'Skin_Sun_Exposed_Lower_leg', medianTpm: 12.1, geneSymbol: gene),
    TissueExpression(tissue: 'Muscle - Skeletal', tissueSiteDetailId: 'Muscle_Skeletal', medianTpm: 5.3, geneSymbol: gene),
    TissueExpression(tissue: 'Whole Blood', tissueSiteDetailId: 'Whole_Blood', medianTpm: 3.8, geneSymbol: gene),
    TissueExpression(tissue: 'Adipose - Subcutaneous', tissueSiteDetailId: 'Adipose_Subcutaneous', medianTpm: 9.4, geneSymbol: gene),
    TissueExpression(tissue: 'Thyroid', tissueSiteDetailId: 'Thyroid', medianTpm: 28.6, geneSymbol: gene),
  ];
}

class GtexService {
  static const _base = 'https://gtexportal.org/api/v2';

  /// Map tissue IDs to readable names
  static String _formatTissueId(String id) {
    return id
        .replaceAll('_', ' ')
        .replaceAll('  ', ' - ')
        .trim();
  }

  /// Look up a gene symbol and return its Gencode ID
  static Future<String?> _resolveGencodeId(String geneSymbol) async {
    final cacheKey = 'gencode:$geneSymbol';
    final cached = await CacheService.get('gtex', cacheKey);
    if (cached != null) return cached;

    try {
      await RateLimiter.throttle('gtex');
      final resp = await ApiService.get<Map<String, dynamic>>(
        '$_base/reference/gene',
        params: {
          'geneId': geneSymbol,
          'gencodeVersion': 'v26',
          'genomeBuild': 'GRCh38/hg38',
        },
      );

      final data = resp['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) return null;

      final gencodeId = data[0]['gencodeId'] as String?;
      if (gencodeId != null) {
        await CacheService.set('gtex', cacheKey, gencodeId);
      }
      return gencodeId;
    } catch (_) {
      return null;
    }
  }

  /// Get median gene expression across all GTEx tissues
  static Future<List<TissueExpression>> getTissueExpression(String geneSymbol) async {
    try {
      // Step 1: Resolve gene symbol to Gencode ID
      final gencodeId = await _resolveGencodeId(geneSymbol);
      if (gencodeId == null) {
        return TissueExpression.demoData(geneSymbol);
      }

      // Step 2: Fetch median expression across tissues
      final cacheKey = 'expr:$gencodeId';

      final cachedExpr = await CacheService.get('gtex', cacheKey);
      if (cachedExpr != null) {
        try {
          final list = jsonDecode(cachedExpr) as List<dynamic>;
          return list.map((item) => TissueExpression(
            tissue: item['tissue'] as String,
            tissueSiteDetailId: item['id'] as String,
            medianTpm: (item['tpm'] as num).toDouble(),
            geneSymbol: item['gene'] as String,
          )).toList();
        } catch (_) {}
      }

      await RateLimiter.throttle('gtex');
      final resp = await ApiService.get<Map<String, dynamic>>(
        '$_base/expression/medianGeneExpression',
        params: {
          'gencodeId': gencodeId,
          'datasetId': 'gtex_v8',
        },
      );

      final data = resp['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) {
        return TissueExpression.demoData(geneSymbol);
      }

      final results = data.map((item) {
        final tissueId = item['tissueSiteDetailId'] as String? ?? '';
        return TissueExpression(
          tissue: _formatTissueId(tissueId),
          tissueSiteDetailId: tissueId,
          medianTpm: (item['median'] as num?)?.toDouble() ?? 0.0,
          geneSymbol: item['geneSymbol'] as String? ?? geneSymbol,
        );
      }).toList();

      // Sort by expression level (highest first)
      results.sort((a, b) => b.medianTpm.compareTo(a.medianTpm));

      // Cache the actual data
      try {
        final cacheData = results.map((r) => {
          'tissue': r.tissue, 'id': r.tissueSiteDetailId,
          'tpm': r.medianTpm, 'gene': r.geneSymbol,
        }).toList();
        await CacheService.set('gtex', cacheKey,
          jsonEncode(cacheData),
          ttl: const Duration(hours: 12));
      } catch (_) {}
      return results;
    } catch (_) {
      return TissueExpression.demoData(geneSymbol);
    }
  }
}
