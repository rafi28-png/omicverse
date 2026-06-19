import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/providers/app_providers.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text('About', style: tsTitle(kTextPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Logo section
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: kGradGenome),
                    boxShadow: [glowShadow(kNeonTeal, r: 30)],
                  ),
                  child: const Icon(Icons.biotech, color: kVoid, size: 40),
                ),
                const SizedBox(height: 16),
                Text('OmicVerse', style: tsHero()),
                const SizedBox(height: 8),
                Text('v$version', style: tsSubtitle()),
                const SizedBox(height: 8),
                Text(
                  'Bioinformatics Research Suite',
                  style: tsBody().copyWith(color: kTextSecondary),
                ),
                const SizedBox(height: 32),

                // Data sources
                GlowCard(
                  glowColor: kNeonPurple,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DATA SOURCES', style: tsLabel().copyWith(color: kNeonPurple)),
                      const SizedBox(height: 16),
                      ..._dataSources.map((ds) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle, color: kNeonPurple, size: 6),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ds.name, style: tsBody().copyWith(fontWeight: FontWeight.w600)),
                                  Text(ds.description, style: tsBody().copyWith(fontSize: 11, color: kTextMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Disclaimer
                GlowCard(
                  glowColor: kNeonAmber,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DISCLAIMER', style: tsLabel().copyWith(color: kNeonAmber)),
                      const SizedBox(height: 12),
                      Text(
                        'OmicVerse is designed for research and educational purposes only. '
                        'It is not intended for clinical diagnosis, treatment decisions, or '
                        'medical advice. Always consult qualified professionals for health-related decisions.',
                        style: tsBody().copyWith(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // KEGG attribution (required per blueprint rule 17)
                GlowCard(
                  glowColor: kNeonBlue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KEGG ATTRIBUTION', style: tsLabel().copyWith(color: kNeonBlue)),
                      const SizedBox(height: 12),
                      Text(
                        'KEGG pathway data is from the Kyoto Encyclopedia of Genes and Genomes '
                        '(Kanehisa Laboratories). KEGG data is used for academic research purposes. '
                        'Commercial use requires a license from Pathway Solutions.',
                        style: tsBody().copyWith(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DataSource {
  final String name;
  final String description;
  const _DataSource(this.name, this.description);
}

const _dataSources = [
  _DataSource('Ensembl', 'Genome annotation, gene lookup, and variant effect prediction (VEP)'),
  _DataSource('UniProt', 'Protein sequences, function, and domain annotation'),
  _DataSource('OMIM', 'Online Mendelian Inheritance in Man — disease-gene associations'),
  _DataSource('DisGeNET', 'Gene-disease association scores from biomedical literature'),
  _DataSource('gnomAD', 'Population allele frequencies across global populations'),
  _DataSource('GTEx Portal', 'Tissue-specific gene expression across 54 human tissues'),
  _DataSource('NCBI E-utilities', 'dbSNP variant lookup and ClinVar clinical significance'),
  _DataSource('KEGG', 'Metabolic and signaling pathway database'),
  _DataSource('ChEMBL', 'Bioactive molecules and drug target data'),
  _DataSource('PGS Catalog', 'Polygenic risk score publications and scoring files'),
  _DataSource('GDC / cBioPortal', 'Cancer genomics — somatic mutations and cancer studies'),
  _DataSource('ENCODE / JASPAR', 'Regulatory elements and transcription factor binding profiles'),
  _DataSource('AlphaFold', 'AI-predicted 3D protein structures and confidence scores'),
  _DataSource('STRING', 'Protein-protein interaction networks'),
  _DataSource('SpliceAI', 'Splice site prediction for alternative splicing analysis'),
  _DataSource('UCSC', 'Conservation scores (phyloP, phastCons) across species'),
];
