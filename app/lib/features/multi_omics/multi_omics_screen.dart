import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/module_header.dart';
import '../../core/widgets/research_disclaimer.dart';
import '../../core/widgets/dna_loader.dart';
import '../../core/providers/app_providers.dart';
import 'services/multi_omics_service.dart';

enum _ScreenState { idle, loading, results }

class MultiOmicsScreen extends ConsumerStatefulWidget {
  const MultiOmicsScreen({super.key});
  @override
  ConsumerState<MultiOmicsScreen> createState() => _MultiOmicsScreenState();
}

class _MultiOmicsScreenState extends ConsumerState<MultiOmicsScreen> {
  _ScreenState _state = _ScreenState.idle;
  GeneProfile? _profile;
  final _geneCtrl = TextEditingController();

  @override
  void dispose() { _geneCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final gene = _geneCtrl.text.trim().toUpperCase();
    if (gene.isEmpty) return;
    setState(() => _state = _ScreenState.loading);
    final profile = await MultiOmicsService.getGeneProfile(gene);
    setState(() { _profile = profile; _state = _ScreenState.results; });
  }

  void _reset() {
    setState(() { _state = _ScreenState.idle; _profile = null; });
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('Multi-Omics', style: tsTitle(kTextPrimary))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: 'Multi-Omics Integration',
              subtitle: 'Unified gene profile across all omics layers',
              gradientColors: const [kNeonTeal, kNeonPurple], icon: Icons.hub, isDemoMode: isDemoMode),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildBody(),
            const SizedBox(height: 24),
            _buildModuleGrid(context),
            const SizedBox(height: 24),
            const ResearchDisclaimer(),
          ]),
        )),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TextField(
          controller: _geneCtrl,
          decoration: InputDecoration(
            hintText: 'Enter gene for integrated view (e.g. TP53)',
            hintStyle: tsBody().copyWith(color: kTextMuted),
            prefixIcon: const Icon(Icons.hub, color: kNeonTeal, size: 20),
            filled: true, fillColor: kSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kNeonTeal)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          style: tsBody(), onSubmitted: (_) => _search())),
        const SizedBox(width: 12),
        NeonButton(label: 'Integrate', icon: Icons.hub, color: kNeonTeal, onPressed: _search),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8,
        children: ['TP53', 'BRCA1', 'EGFR'].map((g) =>
          ActionChip(label: Text(g, style: tsMono().copyWith(fontSize: 10)),
            backgroundColor: kSurface, side: const BorderSide(color: kBorder),
            onPressed: () { _geneCtrl.text = g; _search(); })).toList()),
    ]);
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return GlowCard(glowColor: kNeonTeal, child: Column(children: [
          Icon(Icons.hub, color: kNeonTeal.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Integrated Gene Profile', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Enter a gene to see a unified view across all 16 omics modules — '
            'genomics, expression, protein, epigenomics, cancer, and more.',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
        ]));
      case _ScreenState.loading:
        return const Center(child: DnaLoader(message: 'Integrating omics data...'));
      case _ScreenState.results:
        return _buildResults();
    }
  }

  Widget _buildResults() {
    final p = _profile!;
    final score = MultiOmicsService.completenessScore(p);
    final genomics = p.layers['genomics'] as Map<String, dynamic>? ?? {};
    final expression = p.layers['expression'] as Map<String, dynamic>? ?? {};
    final protein = p.layers['protein'] as Map<String, dynamic>? ?? {};
    final epigenomics = p.layers['epigenomics'] as Map<String, dynamic>? ?? {};
    final cancer = p.layers['cancer'] as Map<String, dynamic>? ?? {};
    final population = p.layers['population'] as Map<String, dynamic>? ?? {};
    final evolution = p.layers['evolution'] as Map<String, dynamic>? ?? {};

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Gene header
      GlowCard(glowColor: kNeonTeal, child: Row(children: [
        Container(width: 64, height: 64,
          decoration: const BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [kNeonTeal, kNeonPurple])),
          child: Center(child: Text(p.gene.substring(0, 2),
            style: tsTitle(kVoid).copyWith(fontSize: 24, fontWeight: FontWeight.w900)))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.gene, style: tsTitle(kNeonTeal).copyWith(fontSize: 28)),
          Text('Multi-Omics Integration', style: tsSubtitle()),
          const SizedBox(height: 4),
          // Completeness bar
          Row(children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: score,
                backgroundColor: kSurfaceRaised, color: kNeonGreen, minHeight: 6))),
            const SizedBox(width: 8),
            Text('${(score * 100).toInt()}%', style: tsMono().copyWith(fontSize: 11, color: kNeonGreen)),
          ]),
        ])),
      ])),
      const SizedBox(height: 16),

      // Omics layers
      _layerCard('🧬', 'Genomics', kGradGenome, [
        _kv('Chromosome', 'chr${genomics['chromosome']}'),
        _kv('Position', '${genomics['position']}'),
        _kv('Known variants', '${genomics['variants_known']}'),
      ]),
      _layerCard('📊', 'Transcriptomics', kGradExpression, [
        _kv('Median TPM', '${expression['median_tpm']}'),
        _kv('Top tissue', '${expression['top_tissue']}'),
        _kv('Isoforms', '${expression['isoform_count']}'),
      ]),
      _layerCard('🔬', 'Proteomics', kGradProtein, [
        _kv('Length', '${protein['length_aa']} aa'),
        _kv('Domains', '${protein['domains']}'),
        _kv('PDB structures', '${protein['pdb_structures']}'),
      ]),
      _layerCard('⏰', 'Epigenomics', kGradEpigenome, [
        _kv('CpG sites', '${epigenomics['cpg_sites']}'),
        _kv('Regulatory elements', '${epigenomics['regulatory_elements']}'),
      ]),
      _layerCard('🎗️', 'Cancer Genomics', kGradCancer, [
        _kv('Mutation freq', '${cancer['mutation_frequency']}%'),
        _kv('Top cancer', '${cancer['top_cancer']}'),
        _kv('Drugs targeting', '${cancer['drugs_targeting']}'),
      ]),
      _layerCard('🌍', 'Population', kGradPopulation, [
        _kv('LOEUF', '${population['constraint_loeuf']}'),
        _kv('PRS scores', '${population['prs_scores']}'),
      ]),
      _layerCard('🌳', 'Evolution', kGradEvolution, [
        _kv('Conservation', '${evolution['conservation_score']}'),
        _kv('Orthologs', '${evolution['orthologs']} species'),
      ]),

      const SizedBox(height: 12),
      NeonButton(label: 'New Query', icon: Icons.hub, color: kNeonTeal, onPressed: _reset),
    ]);
  }

  Widget _layerCard(String emoji, String title, List<Color> grad, List<Widget> items) {
    return Padding(padding: const EdgeInsets.only(bottom: 10),
      child: GlowCard(glowColor: grad[0], child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(title, style: tsBody().copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(height: 3, width: 40,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(colors: grad))),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 16, runSpacing: 8, children: items),
        ],
      )),
    );
  }

  Widget _kv(String key, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$key: ', style: tsLabel()),
      Text(value, style: tsMono().copyWith(fontSize: 12)),
    ]);
  }

  Widget _buildModuleGrid(BuildContext context) {
    final routes = MultiOmicsService.moduleRoutes();
    final gradients = {
      'Genome': kGradGenome, '3D Genome': kGrad3DGenome, 'Variant': kGradVariant,
      'Expression': kGradExpression, 'Pathway': kGradPathway, 'Protein': kGradProtein,
      'Regulatory': kGradRegulatory, 'Population': kGradPopulation, 'PRS': kGradPRS,
      'Methylation': kGradEpigenome, 'CRISPR': kGradCRISPR, 'Cancer': kGradCancer,
      'Evolution': kGradEvolution, 'Splicing': kGradSplicing, 'Drug': kGradDrug,
      'Multi-Omics': [kNeonTeal, kNeonPurple],
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ALL MODULES', style: tsLabel()),
      const SizedBox(height: 8),
      Wrap(spacing: 10, runSpacing: 10,
        children: routes.entries.map((e) {
          final grad = gradients[e.key] ?? [kNeonTeal, kNeonPurple];
          return GestureDetector(
            onTap: () => context.go(e.value),
            child: Container(width: 130, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSurface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
                boxShadow: [glowShadow(grad[0], r: 10)]),
              child: Column(children: [
                Container(height: 3, width: 40,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(colors: grad))),
                const SizedBox(height: 8),
                Text(e.key, style: tsBody().copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
              ])),
          );
        }).toList()),
    ]);
  }
}
