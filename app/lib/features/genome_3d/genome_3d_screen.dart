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
import 'services/genome_3d_service.dart';

enum _ScreenState { idle, loading, results }

class Genome3dScreen extends ConsumerStatefulWidget {
  const Genome3dScreen({super.key});
  @override
  ConsumerState<Genome3dScreen> createState() => _Genome3dScreenState();
}

class _Genome3dScreenState extends ConsumerState<Genome3dScreen> {
  _ScreenState _state = _ScreenState.idle;
  List<TAD> _tads = [];
  List<ChromatinLoop> _loops = [];
  final _geneCtrl = TextEditingController();

  @override
  void dispose() { _geneCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final gene = _geneCtrl.text.trim().toUpperCase();
    if (gene.isEmpty) return;
    setState(() => _state = _ScreenState.loading);
    final data = await Genome3dService.getByGene(gene);
    setState(() {
      _tads = data['tads'] as List<TAD>;
      _loops = data['loops'] as List<ChromatinLoop>;
      _state = _ScreenState.results;
    });
  }

  void _reset() {
    setState(() { _state = _ScreenState.idle; _tads = []; _loops = []; });
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('3D Genome', style: tsTitle(kTextPrimary))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: '3D Genome Organization',
              subtitle: 'TADs, chromatin loops & compartments',
              gradientColors: kGrad3DGenome, icon: Icons.threed_rotation, isDemoMode: isDemoMode),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildBody(),
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
            hintText: 'Enter gene (e.g. TP53, BRCA1, EGFR, KRAS)',
            hintStyle: tsBody().copyWith(color: kTextMuted),
            prefixIcon: const Icon(Icons.threed_rotation, color: kNeonPurple, size: 20),
            filled: true, fillColor: kSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kNeonPurple)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          style: tsBody(), onSubmitted: (_) => _search())),
        const SizedBox(width: 12),
        NeonButton(label: 'Search', icon: Icons.search, color: kNeonPurple, onPressed: _search),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8,
        children: ['TP53', 'BRCA1', 'EGFR', 'KRAS', 'BRAF'].map((g) =>
          ActionChip(label: Text(g, style: tsMono().copyWith(fontSize: 10)),
            backgroundColor: kSurface, side: const BorderSide(color: kBorder),
            onPressed: () { _geneCtrl.text = g; _search(); })).toList()),
    ]);
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return GlowCard(glowColor: kNeonPurple, child: Column(children: [
          Icon(Icons.threed_rotation, color: kNeonPurple.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Explore 3D Genome', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Enter a gene to view its topologically associated domain (TAD), '
            'chromatin loops, and 3D organization context.',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
        ]));
      case _ScreenState.loading:
        return const Center(child: DnaLoader(message: 'Loading 3D structure...'));
      case _ScreenState.results:
        return _buildResults();
    }
  }

  Widget _buildResults() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Summary
      Wrap(spacing: 12, runSpacing: 12, children: [
        _summaryCard('TADs', '${_tads.length}', kNeonPurple),
        _summaryCard('Loops', '${_loops.length}', kNeonBlue),
        if (_tads.isNotEmpty)
          _summaryCard('Genes in TAD', '${_tads.first.genes.length}', kNeonGreen),
      ]),
      const SizedBox(height: 16),

      // TADs
      if (_tads.isNotEmpty) ...[
        Text('TOPOLOGICALLY ASSOCIATED DOMAINS', style: tsLabel()),
        const SizedBox(height: 8),
        ..._tads.map((tad) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlowCard(glowColor: kNeonPurple, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: LinearGradient(colors: kGrad3DGenome)),
                  child: const Center(child: Icon(Icons.square_rounded, color: kVoid, size: 20))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tad.name ?? 'TAD', style: tsBody().copyWith(fontWeight: FontWeight.w600)),
                  Text(tad.location, style: tsMono().copyWith(fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(tad.sizeLabel, style: tsTitle(kNeonPurple).copyWith(fontSize: 16)),
                  if (tad.insulation != null)
                    Text('IS: ${tad.insulation!.toStringAsFixed(1)}',
                      style: tsMono().copyWith(fontSize: 10, color: kNeonAmber)),
                ]),
              ]),
              const SizedBox(height: 10),
              // TAD visualization bar
              _buildTadBar(tad),
              const SizedBox(height: 8),
              Text('GENES IN TAD', style: tsLabel()),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 6,
                children: tad.genes.map((g) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kNeonGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4)),
                  child: Text(g, style: tsMono().copyWith(fontSize: 11, color: kNeonGreen)),
                )).toList()),
            ],
          )),
        )),
        const SizedBox(height: 16),
      ],

      // Loops
      if (_loops.isNotEmpty) ...[
        Text('CHROMATIN LOOPS', style: tsLabel()),
        const SizedBox(height: 8),
        ..._loops.map((loop) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlowCard(glowColor: kNeonBlue, child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: kNeonBlue.withValues(alpha: 0.15)),
              child: const Center(child: Icon(Icons.link, color: kNeonBlue, size: 20))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loop.label, style: tsBody().copyWith(fontWeight: FontWeight.w600)),
              Text('chr${loop.chromosome}', style: tsMono().copyWith(fontSize: 11)),
              Text('Distance: ${loop.distanceLabel}', style: tsLabel()),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(loop.score.toStringAsFixed(1), style: tsTitle(kNeonBlue).copyWith(fontSize: 18)),
              Text('Score', style: tsLabel()),
            ]),
          ])),
        )),
      ],

      const SizedBox(height: 12),
      NeonButton(label: 'New Search', icon: Icons.threed_rotation, color: kNeonPurple, onPressed: _reset),
    ]);
  }

  Widget _buildTadBar(TAD tad) {
    return Container(height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(colors: [
          kNeonPurple.withValues(alpha: 0.3),
          kNeonBlue.withValues(alpha: 0.3),
          kNeonPurple.withValues(alpha: 0.3),
        ]),
        border: Border.all(color: kNeonPurple.withValues(alpha: 0.5), width: 1)),
      child: Row(
        children: tad.genes.asMap().entries.map((e) =>
          Expanded(child: Center(child: Text(e.value,
            style: tsMono().copyWith(fontSize: 8, color: kNeonGreen))))).toList(),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return GlowCard(glowColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(children: [
        Text(value, style: tsTitle(color).copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: tsLabel()),
      ]));
  }
}
