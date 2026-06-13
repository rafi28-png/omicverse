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
  _DataSource('Ensembl', 'Genome annotation and gene structure'),
  _DataSource('UniProt', 'Protein sequences and functional annotation'),
  _DataSource('AlphaFold', 'Predicted protein structures'),
  _DataSource('ClinVar', 'Clinical variant interpretations'),
  _DataSource('gnomAD', 'Population allele frequencies'),
  _DataSource('GTEx', 'Tissue-specific gene expression'),
  _DataSource('KEGG', 'Metabolic and signaling pathways'),
  _DataSource('Reactome', 'Biological pathway database'),
  _DataSource('STRING', 'Protein-protein interactions'),
  _DataSource('InterPro', 'Protein domains and families'),
  _DataSource('PGS Catalog', 'Polygenic score data'),
  _DataSource('ChEMBL', 'Bioactive molecules and drug targets'),
  _DataSource('DGIdb', 'Drug-gene interaction database'),
  _DataSource('ENCODE', 'Regulatory element annotations'),
  _DataSource('JASPAR', 'Transcription factor binding profiles'),
  _DataSource('UCSC', 'Conservation scores and genome browser'),
];
