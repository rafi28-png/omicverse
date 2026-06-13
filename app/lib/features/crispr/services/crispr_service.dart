class GuideRna {
  final String sequence; // 20nt + PAM
  final String pam;
  final String targetGene;
  final String chromosome;
  final int position;
  final String strand;
  final double onTargetScore; // Doench 2016 / Rule Set 2
  final double offTargetScore; // CFD or MIT score
  final int offTargetCount;
  final double gcContent;

  const GuideRna({
    required this.sequence,
    this.pam = 'NGG',
    required this.targetGene,
    required this.chromosome,
    required this.position,
    this.strand = '+',
    required this.onTargetScore,
    required this.offTargetScore,
    this.offTargetCount = 0,
    required this.gcContent,
  });

  String get location => 'chr$chromosome:$position';

  String get efficiencyLabel {
    if (onTargetScore >= 0.7) return 'High';
    if (onTargetScore >= 0.4) return 'Medium';
    return 'Low';
  }

  String get safetyLabel {
    if (offTargetScore >= 0.8 && offTargetCount <= 2) return 'Safe';
    if (offTargetScore >= 0.5) return 'Moderate';
    return 'Risky';
  }

  static List<GuideRna> demoGuides() => const [
    GuideRna(sequence: 'AGCTGTATCGTCAAGGCACT', targetGene: 'TP53',
      chromosome: '17', position: 7674220, strand: '+',
      onTargetScore: 0.85, offTargetScore: 0.92, offTargetCount: 1, gcContent: 0.50),
    GuideRna(sequence: 'TCCTCAGCATCTTATCCGAG', targetGene: 'TP53',
      chromosome: '17', position: 7674300, strand: '-',
      onTargetScore: 0.72, offTargetScore: 0.88, offTargetCount: 3, gcContent: 0.50),
    GuideRna(sequence: 'GACCTGATTTCCTTACTGCC', targetGene: 'BRCA1',
      chromosome: '17', position: 43045680, strand: '+',
      onTargetScore: 0.78, offTargetScore: 0.95, offTargetCount: 0, gcContent: 0.50),
    GuideRna(sequence: 'CTCCATCCTGTGCTGAACAA', targetGene: 'EGFR',
      chromosome: '7', position: 55181400, strand: '+',
      onTargetScore: 0.65, offTargetScore: 0.72, offTargetCount: 5, gcContent: 0.50),
    GuideRna(sequence: 'GAATATAAACTTGTGGTAGT', targetGene: 'KRAS',
      chromosome: '12', position: 25205320, strand: '-',
      onTargetScore: 0.58, offTargetScore: 0.65, offTargetCount: 8, gcContent: 0.35),
    GuideRna(sequence: 'TGATTTTGGTCTAGCTACAG', targetGene: 'BRAF',
      chromosome: '7', position: 140753340, strand: '+',
      onTargetScore: 0.81, offTargetScore: 0.90, offTargetCount: 2, gcContent: 0.40),
  ];
}

class CrisprExperiment {
  final String name;
  final String system; // Cas9, Cas12a, base editor, prime editor
  final String targetGene;
  final List<GuideRna> guides;
  final String status;

  const CrisprExperiment({
    required this.name,
    required this.system,
    required this.targetGene,
    required this.guides,
    this.status = 'designed',
  });
}

class CrisprService {
  /// Design guide RNAs for a gene (demo mode)
  static Future<List<GuideRna>> designGuides(String gene) async {
    // In production: call CRISPRscan or Benchling API
    await Future.delayed(const Duration(milliseconds: 300));
    return GuideRna.demoGuides().where((g) =>
      g.targetGene.toLowerCase() == gene.toLowerCase()).toList();
  }

  /// Calculate GC content
  static double calculateGC(String sequence) {
    if (sequence.isEmpty) return 0;
    final gc = sequence.toUpperCase().split('').where((c) => c == 'G' || c == 'C').length;
    return gc / sequence.length;
  }

  /// Validate guide RNA sequence
  static String? validateGuide(String sequence) {
    if (sequence.length < 18 || sequence.length > 25) {
      return 'Guide must be 18-25 nucleotides';
    }
    final valid = RegExp(r'^[ACGTacgt]+$');
    if (!valid.hasMatch(sequence)) {
      return 'Invalid nucleotides detected';
    }
    final gc = calculateGC(sequence);
    if (gc < 0.2 || gc > 0.8) {
      return 'GC content (${(gc * 100).toInt()}%) outside optimal range (20-80%)';
    }
    return null; // Valid
  }

  /// Get all available target genes in demo
  static List<String> availableGenes() {
    return GuideRna.demoGuides().map((g) => g.targetGene).toSet().toList()..sort();
  }
}
