class OmicsLayer {
  final String name;
  final String type; // genomics, transcriptomics, proteomics, epigenomics, etc.
  final String icon;
  final int featureCount;
  final String status; // available, partial, unavailable
  final String? summary;

  const OmicsLayer({
    required this.name,
    required this.type,
    required this.icon,
    required this.featureCount,
    this.status = 'available',
    this.summary,
  });

  static List<OmicsLayer> allLayers() => const [
    OmicsLayer(name: 'Genomics', type: 'genomics', icon: '🧬', featureCount: 3,
      summary: 'Genome sequence, variants, 3D organization'),
    OmicsLayer(name: 'Transcriptomics', type: 'transcriptomics', icon: '📊', featureCount: 2,
      summary: 'Gene expression, alternative splicing'),
    OmicsLayer(name: 'Proteomics', type: 'proteomics', icon: '🔬', featureCount: 2,
      summary: 'Protein structure, pathway interactions'),
    OmicsLayer(name: 'Epigenomics', type: 'epigenomics', icon: '⏰', featureCount: 2,
      summary: 'DNA methylation, regulatory elements'),
    OmicsLayer(name: 'Population Genetics', type: 'population', icon: '🌍', featureCount: 2,
      summary: 'Allele frequencies, polygenic risk scores'),
    OmicsLayer(name: 'Cancer Genomics', type: 'cancer', icon: '🎗️', featureCount: 2,
      summary: 'Somatic mutations, drug targets'),
    OmicsLayer(name: 'Functional Genomics', type: 'functional', icon: '✂️', featureCount: 2,
      summary: 'CRISPR design, evolutionary conservation'),
  ];
}

class GeneProfile {
  final String gene;
  final Map<String, dynamic> layers;

  const GeneProfile({required this.gene, required this.layers});

  static GeneProfile demoProfile(String gene) {
    return GeneProfile(gene: gene, layers: {
      'genomics': {
        'chromosome': gene == 'TP53' ? '17' : gene == 'BRCA1' ? '17' : '7',
        'position': gene == 'TP53' ? 7674220 : gene == 'BRCA1' ? 43044295 : 55181378,
        'variants_known': gene == 'TP53' ? 1847 : gene == 'BRCA1' ? 3452 : 892,
      },
      'expression': {
        'median_tpm': gene == 'TP53' ? 45.2 : gene == 'BRCA1' ? 12.8 : 3.5,
        'top_tissue': gene == 'TP53' ? 'Liver' : gene == 'BRCA1' ? 'Breast' : 'Lung',
        'isoform_count': gene == 'TP53' ? 17 : gene == 'BRCA1' ? 23 : 8,
      },
      'protein': {
        'length_aa': gene == 'TP53' ? 393 : gene == 'BRCA1' ? 1863 : 1210,
        'domains': gene == 'TP53' ? 4 : gene == 'BRCA1' ? 6 : 5,
        'pdb_structures': gene == 'TP53' ? 312 : gene == 'BRCA1' ? 45 : 89,
      },
      'epigenomics': {
        'cpg_sites': gene == 'TP53' ? 34 : gene == 'BRCA1' ? 56 : 21,
        'regulatory_elements': gene == 'TP53' ? 8 : gene == 'BRCA1' ? 12 : 5,
      },
      'cancer': {
        'mutation_frequency': gene == 'TP53' ? 36.1 : gene == 'BRCA1' ? 3.2 : 4.5,
        'top_cancer': gene == 'TP53' ? 'Pan-cancer' : gene == 'BRCA1' ? 'Breast/Ovarian' : 'Lung',
        'drugs_targeting': gene == 'TP53' ? 0 : gene == 'BRCA1' ? 4 : 12,
      },
      'population': {
        'constraint_loeuf': gene == 'TP53' ? 0.21 : gene == 'BRCA1' ? 0.35 : 0.48,
        'prs_scores': gene == 'TP53' ? 2 : gene == 'BRCA1' ? 5 : 3,
      },
      'evolution': {
        'conservation_score': gene == 'TP53' ? 5.2 : gene == 'BRCA1' ? 3.8 : 4.1,
        'orthologs': gene == 'TP53' ? 11 : gene == 'BRCA1' ? 9 : 10,
      },
    });
  }
}

class MultiOmicsService {
  /// Get integrated gene profile
  static Future<GeneProfile> getGeneProfile(String gene) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return GeneProfile.demoProfile(gene.toUpperCase());
  }

  /// Get all omics layers
  static List<OmicsLayer> getLayers() => OmicsLayer.allLayers();

  /// Calculate completeness score (how many layers have data)
  static double completenessScore(GeneProfile profile) {
    return profile.layers.length / OmicsLayer.allLayers().length;
  }

  /// Get module routes for navigation
  static Map<String, String> moduleRoutes() => {
    'Genome': '/genome', '3D Genome': '/genome_3d',
    'Variant': '/variant', 'Expression': '/expression',
    'Pathway': '/pathway', 'Protein': '/protein',
    'Regulatory': '/regulatory', 'Population': '/population',
    'PRS': '/prs', 'Methylation': '/methylation',
    'CRISPR': '/crispr', 'Cancer': '/cancer',
    'Evolution': '/evolution', 'Splicing': '/splicing',
    'Drug': '/drug', 'Multi-Omics': '/multi_omics',
  };
}
