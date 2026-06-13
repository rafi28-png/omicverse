import 'dart:convert';
import '../../../core/services/api_service.dart';
import '../../../core/services/rate_limiter.dart';
import '../../../core/services/cache_service.dart';

class PopulationFrequency {
  final String population;
  final String abbreviation;
  final double alleleFrequency;
  final int alleleCount;
  final int alleleNumber;
  final int homozygoteCount;

  const PopulationFrequency({
    required this.population,
    required this.abbreviation,
    required this.alleleFrequency,
    this.alleleCount = 0,
    this.alleleNumber = 0,
    this.homozygoteCount = 0,
  });

  String get frequencyLabel {
    if (alleleFrequency == 0) return '0';
    if (alleleFrequency < 0.0001) return alleleFrequency.toStringAsExponential(1);
    return alleleFrequency.toStringAsFixed(4);
  }

  String get rarityLabel {
    if (alleleFrequency == 0) return 'Absent';
    if (alleleFrequency < 0.0001) return 'Ultra-rare';
    if (alleleFrequency < 0.01) return 'Rare';
    if (alleleFrequency < 0.05) return 'Low frequency';
    return 'Common';
  }

  Map<String, dynamic> toJson() => {
    'population': population,
    'abbreviation': abbreviation,
    'alleleFrequency': alleleFrequency,
    'alleleCount': alleleCount,
    'alleleNumber': alleleNumber,
    'homozygoteCount': homozygoteCount,
  };

  factory PopulationFrequency.fromJson(Map<String, dynamic> j) => PopulationFrequency(
    population: j['population'] as String,
    abbreviation: j['abbreviation'] as String,
    alleleFrequency: (j['alleleFrequency'] as num).toDouble(),
    alleleCount: j['alleleCount'] as int? ?? 0,
    alleleNumber: j['alleleNumber'] as int? ?? 0,
    homozygoteCount: j['homozygoteCount'] as int? ?? 0,
  );
}

class PopulationVariant {
  final String variantId;
  final String chromosome;
  final int position;
  final String reference;
  final String alternate;
  final String rsid;
  final double globalFrequency;
  final List<PopulationFrequency> populations;
  final String? consequence;
  final String? gene;

  const PopulationVariant({
    required this.variantId,
    required this.chromosome,
    required this.position,
    required this.reference,
    required this.alternate,
    this.rsid = '',
    required this.globalFrequency,
    required this.populations,
    this.consequence,
    this.gene,
  });

  String get location => 'chr$chromosome:$position';

  Map<String, dynamic> toJson() => {
    'variantId': variantId,
    'chromosome': chromosome,
    'position': position,
    'reference': reference,
    'alternate': alternate,
    'rsid': rsid,
    'globalFrequency': globalFrequency,
    'populations': populations.map((p) => p.toJson()).toList(),
    'consequence': consequence,
    'gene': gene,
  };

  factory PopulationVariant.fromJson(Map<String, dynamic> j) => PopulationVariant(
    variantId: j['variantId'] as String,
    chromosome: j['chromosome'] as String,
    position: j['position'] as int,
    reference: j['reference'] as String,
    alternate: j['alternate'] as String,
    rsid: j['rsid'] as String? ?? '',
    globalFrequency: (j['globalFrequency'] as num).toDouble(),
    populations: (j['populations'] as List<dynamic>)
        .map((p) => PopulationFrequency.fromJson(p as Map<String, dynamic>))
        .toList(),
    consequence: j['consequence'] as String?,
    gene: j['gene'] as String?,
  );

  static List<PopulationVariant> demoVariants() => const [
    PopulationVariant(
      variantId: '17-7674220-G-A', chromosome: '17', position: 7674220,
      reference: 'G', alternate: 'A', rsid: 'rs28934578',
      globalFrequency: 0.00002, gene: 'TP53', consequence: 'missense_variant',
      populations: [
        PopulationFrequency(population: 'African/African American', abbreviation: 'AFR', alleleFrequency: 0.00003),
        PopulationFrequency(population: 'European (non-Finnish)', abbreviation: 'NFE', alleleFrequency: 0.00001),
        PopulationFrequency(population: 'East Asian', abbreviation: 'EAS', alleleFrequency: 0.00004),
        PopulationFrequency(population: 'South Asian', abbreviation: 'SAS', alleleFrequency: 0.00002),
        PopulationFrequency(population: 'Latino/Admixed American', abbreviation: 'AMR', alleleFrequency: 0.00001),
        PopulationFrequency(population: 'Ashkenazi Jewish', abbreviation: 'ASJ', alleleFrequency: 0.00000),
        PopulationFrequency(population: 'European (Finnish)', abbreviation: 'FIN', alleleFrequency: 0.00001),
      ],
    ),
    PopulationVariant(
      variantId: '7-55181378-T-G', chromosome: '7', position: 55181378,
      reference: 'T', alternate: 'G', rsid: 'rs121913529',
      globalFrequency: 0.00001, gene: 'EGFR', consequence: 'missense_variant',
      populations: [
        PopulationFrequency(population: 'African/African American', abbreviation: 'AFR', alleleFrequency: 0.00000),
        PopulationFrequency(population: 'European (non-Finnish)', abbreviation: 'NFE', alleleFrequency: 0.00001),
        PopulationFrequency(population: 'East Asian', abbreviation: 'EAS', alleleFrequency: 0.00003),
        PopulationFrequency(population: 'South Asian', abbreviation: 'SAS', alleleFrequency: 0.00001),
        PopulationFrequency(population: 'Latino/Admixed American', abbreviation: 'AMR', alleleFrequency: 0.00000),
      ],
    ),
    PopulationVariant(
      variantId: '7-140753336-A-T', chromosome: '7', position: 140753336,
      reference: 'A', alternate: 'T', rsid: 'rs113488022',
      globalFrequency: 0.00006, gene: 'BRAF', consequence: 'missense_variant',
      populations: [
        PopulationFrequency(population: 'African/African American', abbreviation: 'AFR', alleleFrequency: 0.00002),
        PopulationFrequency(population: 'European (non-Finnish)', abbreviation: 'NFE', alleleFrequency: 0.00008),
        PopulationFrequency(population: 'East Asian', abbreviation: 'EAS', alleleFrequency: 0.00001),
        PopulationFrequency(population: 'South Asian', abbreviation: 'SAS', alleleFrequency: 0.00005),
      ],
    ),
  ];
}

class PopulationService {
  static const _gnomadApi = 'https://gnomad.broadinstitute.org/api';

  /// Query gnomAD for variant population frequencies (GraphQL POST only)
  static Future<PopulationVariant?> queryVariant({
    required String chromosome,
    required int position,
    required String reference,
    required String alternate,
  }) async {
    final variantId = '$chromosome-$position-$reference-$alternate';
    final cacheKey = 'pop:$variantId';

    final cached = await CacheService.get('gnomad', cacheKey);
    if (cached != null) {
      try {
        return PopulationVariant.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        // Fall back to querying
      }
    }

    try {
      await RateLimiter.throttle('gnomad');

      final query = '''
      {
        variant(dataset: gnomad_r4, variantId: "$variantId") {
          variant_id
          rsids
          genome {
            ac
            an
            af
            populations {
              id
              ac
              an
              af
              homozygote_count
            }
          }
          transcript_consequences {
            major_consequence
            gene_symbol
          }
        }
      }
      ''';

      final resp = await ApiService.post(_gnomadApi, {'query': query});
      final data = resp['data']?['variant'];
      if (data == null) return null;

      final genome = data['genome'] as Map<String, dynamic>?;
      final pops = <PopulationFrequency>[];

      if (genome != null) {
        final popData = genome['populations'] as List<dynamic>? ?? [];
        for (final p in popData) {
          final id = p['id'] as String? ?? '';
          if (id.isEmpty || id.contains('_')) continue; // Skip sub-populations
          pops.add(PopulationFrequency(
            population: _popName(id),
            abbreviation: id.toUpperCase(),
            alleleFrequency: (p['af'] as num?)?.toDouble() ?? 0,
            alleleCount: p['ac'] as int? ?? 0,
            alleleNumber: p['an'] as int? ?? 0,
            homozygoteCount: p['homozygote_count'] as int? ?? 0,
          ));
        }
      }

      final consequences = data['transcript_consequences'] as List<dynamic>? ?? [];
      final consequence = consequences.isNotEmpty
        ? consequences[0]['major_consequence'] as String? : null;
      final gene = consequences.isNotEmpty
        ? consequences[0]['gene_symbol'] as String? : null;

      final rsids = data['rsids'] as List<dynamic>? ?? [];

      final pv = PopulationVariant(
        variantId: data['variant_id'] as String? ?? variantId,
        chromosome: chromosome,
        position: position,
        reference: reference,
        alternate: alternate,
        rsid: rsids.isNotEmpty ? rsids[0] as String : '',
        globalFrequency: (genome?['af'] as num?)?.toDouble() ?? 0,
        populations: pops,
        consequence: consequence,
        gene: gene,
      );

      await CacheService.set('gnomad', cacheKey, jsonEncode(pv.toJson()), ttl: const Duration(hours: 24));

      return pv;
    } catch (_) {
      return null;
    }
  }

  static String _popName(String id) {
    const names = {
      'afr': 'African/African American',
      'amr': 'Latino/Admixed American',
      'asj': 'Ashkenazi Jewish',
      'eas': 'East Asian',
      'fin': 'European (Finnish)',
      'nfe': 'European (non-Finnish)',
      'sas': 'South Asian',
      'mid': 'Middle Eastern',
      'ami': 'Amish',
      'remaining': 'Remaining',
    };
    return names[id.toLowerCase()] ?? id;
  }
}
