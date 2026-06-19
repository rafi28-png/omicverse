class CpGSite {
  final String cpgId;
  final String chromosome;
  final int position;
  final double? betaValue;
  final String? nearestGene;
  final String? context; // CpG island, shore, shelf, open sea

  const CpGSite({
    required this.cpgId,
    required this.chromosome,
    required this.position,
    this.betaValue,
    this.nearestGene,
    this.context,
  });

  String get location => 'chr$chromosome:$position';

  String get methylationStatus {
    if (betaValue == null) return 'Unknown';
    if (betaValue! > 0.7) return 'Hypermethylated';
    if (betaValue! < 0.3) return 'Hypomethylated';
    return 'Intermediate';
  }

  static List<CpGSite> demoSites() => const [
    CpGSite(cpgId: 'cg00075967', chromosome: '1', position: 15865, betaValue: 0.85,
      nearestGene: 'DDX11L1', context: 'CpG island'),
    CpGSite(cpgId: 'cg00374717', chromosome: '1', position: 68849, betaValue: 0.12,
      nearestGene: 'OR4F5', context: 'Shore'),
    CpGSite(cpgId: 'cg00864867', chromosome: '2', position: 233284, betaValue: 0.45,
      nearestGene: 'FAM110C', context: 'Open sea'),
    CpGSite(cpgId: 'cg01027739', chromosome: '3', position: 113160, betaValue: 0.92,
      nearestGene: 'BOC', context: 'CpG island'),
    CpGSite(cpgId: 'cg01353448', chromosome: '5', position: 1293347, betaValue: 0.08,
      nearestGene: 'TERT', context: 'Shore'),
    CpGSite(cpgId: 'cg01584760', chromosome: '7', position: 55019365, betaValue: 0.67,
      nearestGene: 'EGFR', context: 'Shelf'),
    CpGSite(cpgId: 'cg02004872', chromosome: '12', position: 25205300, betaValue: 0.78,
      nearestGene: 'KRAS', context: 'CpG island'),
    CpGSite(cpgId: 'cg02367975', chromosome: '17', position: 7661800, betaValue: 0.35,
      nearestGene: 'TP53', context: 'Shore'),
  ];
}

class HorvathClock {
  final double predictedAge;
  final double ageAcceleration;
  final int cpgSitesUsed;
  final int totalCpgSites;

  const HorvathClock({
    required this.predictedAge,
    required this.ageAcceleration,
    required this.cpgSitesUsed,
    required this.totalCpgSites,
  });

  String get ageLabel => '${predictedAge.toStringAsFixed(1)} years';
  String get accelerationLabel {
    if (ageAcceleration > 2) return 'Accelerated (+${ageAcceleration.toStringAsFixed(1)}y)';
    if (ageAcceleration < -2) return 'Decelerated (${ageAcceleration.toStringAsFixed(1)}y)';
    return 'Normal (${ageAcceleration.toStringAsFixed(1)}y)';
  }

  static HorvathClock demo() => const HorvathClock(
    predictedAge: 42.3, ageAcceleration: 1.8,
    cpgSitesUsed: 353, totalCpgSites: 353,
  );
}

class MethylationService {
  /// Estimate biological age from CpG beta values
  /// NOTE: This is a simplified approximation using average methylation drift.
  /// A full Horvath clock requires 353 specific CpG weights (not bundled here).
  /// This estimate uses the known correlation between global methylation
  /// changes and aging (Hannum et al., 2013).
  static Future<HorvathClock> calculateHorvathAge(List<CpGSite> sites) async {
    final sitesWithBeta = sites.where((s) => s.betaValue != null).toList();
    if (sitesWithBeta.isEmpty) {
      return const HorvathClock(
        predictedAge: 0, ageAcceleration: 0, cpgSitesUsed: 0, totalCpgSites: 353);
    }

    // Simplified estimation using global methylation patterns:
    // - Newborns: avg beta ~0.45
    // - Young adults: avg beta ~0.50
    // - Elderly: avg beta ~0.55-0.60
    final avgBeta = sitesWithBeta.map((s) => s.betaValue!).reduce((a, b) => a + b) / sitesWithBeta.length;

    // Hyper sites (beta > 0.7) increase with age, hypo sites (beta < 0.3) decrease
    final hyperFraction = sitesWithBeta.where((s) => s.betaValue! > 0.7).length / sitesWithBeta.length;
    final hypoFraction = sitesWithBeta.where((s) => s.betaValue! < 0.3).length / sitesWithBeta.length;

    // Age estimate: combination of average beta drift and hyper/hypo ratio
    final predictedAge = 20.0 + (avgBeta - 0.45) * 200 + (hyperFraction - hypoFraction) * 30;
    final clampedAge = predictedAge.clamp(0.0, 120.0);

    // Acceleration = deviation from expected methylation pattern for estimated age
    final expectedBeta = 0.45 + (clampedAge / 200.0);
    final acceleration = (avgBeta - expectedBeta) * 100;

    return HorvathClock(
      predictedAge: clampedAge,
      ageAcceleration: acceleration.clamp(-20.0, 20.0),
      cpgSitesUsed: sitesWithBeta.length,
      totalCpgSites: 353,
    );
  }

  /// Analyze methylation patterns
  static Map<String, int> analyzeMethylation(List<CpGSite> sites) {
    int hyper = 0, hypo = 0, intermediate = 0, unknown = 0;
    for (final s in sites) {
      switch (s.methylationStatus) {
        case 'Hypermethylated': hyper++; break;
        case 'Hypomethylated': hypo++; break;
        case 'Intermediate': intermediate++; break;
        default: unknown++;
      }
    }
    return {'Hypermethylated': hyper, 'Hypomethylated': hypo,
      'Intermediate': intermediate, 'Unknown': unknown};
  }

  /// Get context distribution
  static Map<String, int> contextDistribution(List<CpGSite> sites) {
    final dist = <String, int>{};
    for (final s in sites) {
      final ctx = s.context ?? 'Unknown';
      dist[ctx] = (dist[ctx] ?? 0) + 1;
    }
    return dist;
  }
}
