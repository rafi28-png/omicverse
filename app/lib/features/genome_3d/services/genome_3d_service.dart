class TAD {
  final String chromosome;
  final int start;
  final int end;
  final String? name;
  final double? insulation;
  final List<String> genes;

  const TAD({
    required this.chromosome,
    required this.start,
    required this.end,
    this.name,
    this.insulation,
    this.genes = const [],
  });

  String get location => 'chr$chromosome:$start-$end';
  int get size => end - start;
  String get sizeLabel {
    if (size >= 1000000) return '${(size / 1000000).toStringAsFixed(1)} Mb';
    return '${(size / 1000).toStringAsFixed(0)} kb';
  }

  static List<TAD> demoTADs() => const [
    TAD(chromosome: '17', start: 7500000, end: 7800000, name: 'TP53 TAD',
      insulation: -1.8, genes: ['TP53', 'WRAP53', 'EFNB3']),
    TAD(chromosome: '17', start: 43000000, end: 43300000, name: 'BRCA1 TAD',
      insulation: -2.1, genes: ['BRCA1', 'NBR1', 'NBR2']),
    TAD(chromosome: '7', start: 55000000, end: 55400000, name: 'EGFR TAD',
      insulation: -1.5, genes: ['EGFR', 'LANCL2']),
    TAD(chromosome: '12', start: 25100000, end: 25400000, name: 'KRAS TAD',
      insulation: -1.9, genes: ['KRAS', 'LYRM5']),
    TAD(chromosome: '7', start: 140700000, end: 140900000, name: 'BRAF TAD',
      insulation: -1.3, genes: ['BRAF', 'MRPS33']),
  ];
}

class ChromatinLoop {
  final String chromosome;
  final int anchor1Start;
  final int anchor1End;
  final int anchor2Start;
  final int anchor2End;
  final double score;
  final String? gene1;
  final String? gene2;

  const ChromatinLoop({
    required this.chromosome,
    required this.anchor1Start,
    required this.anchor1End,
    required this.anchor2Start,
    required this.anchor2End,
    required this.score,
    this.gene1,
    this.gene2,
  });

  String get label => '${gene1 ?? ""}↔${gene2 ?? ""}';
  int get distance => anchor2Start - anchor1End;
  String get distanceLabel {
    if (distance >= 1000000) return '${(distance / 1000000).toStringAsFixed(1)} Mb';
    return '${(distance / 1000).toStringAsFixed(0)} kb';
  }

  static List<ChromatinLoop> demoLoops() => const [
    ChromatinLoop(chromosome: '17', anchor1Start: 7650000, anchor1End: 7660000,
      anchor2Start: 7780000, anchor2End: 7790000, score: 8.5,
      gene1: 'TP53', gene2: 'WRAP53'),
    ChromatinLoop(chromosome: '17', anchor1Start: 43040000, anchor1End: 43050000,
      anchor2Start: 43200000, anchor2End: 43210000, score: 7.2,
      gene1: 'BRCA1', gene2: 'NBR1'),
    ChromatinLoop(chromosome: '7', anchor1Start: 55080000, anchor1End: 55090000,
      anchor2Start: 55250000, anchor2End: 55260000, score: 6.8,
      gene1: 'EGFR', gene2: 'LANCL2'),
    ChromatinLoop(chromosome: '12', anchor1Start: 25200000, anchor1End: 25210000,
      anchor2Start: 25350000, anchor2End: 25360000, score: 9.1,
      gene1: 'KRAS', gene2: 'LYRM5'),
  ];
}

class Compartment {
  final String chromosome;
  final int start;
  final int end;
  final String type; // A (active) or B (inactive)
  final double eigenvalue;

  const Compartment({
    required this.chromosome,
    required this.start,
    required this.end,
    required this.type,
    required this.eigenvalue,
  });

  String get label => 'Compartment $type';
  bool get isActive => type == 'A';
}

class Genome3dService {
  /// Get TADs for a chromosome region
  static Future<List<TAD>> getTADs(String chr) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return TAD.demoTADs().where((t) => t.chromosome == chr).toList();
  }

  /// Get chromatin loops
  static Future<List<ChromatinLoop>> getLoops(String chr) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return ChromatinLoop.demoLoops().where((l) => l.chromosome == chr).toList();
  }

  /// Get all demo data by gene
  static Future<Map<String, dynamic>> getByGene(String gene) async {
    final tads = TAD.demoTADs().where((t) =>
      t.genes.any((g) => g.toLowerCase() == gene.toLowerCase())).toList();
    final loops = ChromatinLoop.demoLoops().where((l) =>
      l.gene1?.toLowerCase() == gene.toLowerCase() ||
      l.gene2?.toLowerCase() == gene.toLowerCase()).toList();
    return {'tads': tads, 'loops': loops};
  }

  /// Available chromosomes in demo
  static List<String> availableChromosomes() {
    final chrs = <String>{};
    for (final t in TAD.demoTADs()) { chrs.add(t.chromosome); }
    for (final l in ChromatinLoop.demoLoops()) { chrs.add(l.chromosome); }
    return chrs.toList()..sort((a, b) {
      final ai = int.tryParse(a) ?? 99;
      final bi = int.tryParse(b) ?? 99;
      return ai.compareTo(bi);
    });
  }
}
