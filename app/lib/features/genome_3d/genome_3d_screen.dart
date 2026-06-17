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

enum _ScreenState { idle, loading, results, error }

class Genome3dScreen extends ConsumerStatefulWidget {
  const Genome3dScreen({super.key});
  @override
  ConsumerState<Genome3dScreen> createState() => _Genome3dScreenState();
}

class _Genome3dScreenState extends ConsumerState<Genome3dScreen> {
  _ScreenState _state = _ScreenState.idle;
  List<OmimDisease> _omimResults = [];
  List<DiseaseAssociation> _associations = [];
  final _geneCtrl = TextEditingController();
  String _error = '';

  @override
  void dispose() { _geneCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final gene = _geneCtrl.text.trim().toUpperCase();
    if (gene.isEmpty) return;
    setState(() => _state = _ScreenState.loading);
    try {
      final omimFuture = DiseaseGeneticsService.getOmimEntries(gene);
      final disgenetFuture = DiseaseGeneticsService.getDiseaseAssociations(gene);
      final results = await Future.wait([omimFuture, disgenetFuture]);
      setState(() {
        _omimResults = results[0] as List<OmimDisease>;
        _associations = results[1] as List<DiseaseAssociation>;
        _state = (_omimResults.isEmpty && _associations.isEmpty)
          ? _ScreenState.idle : _ScreenState.results;
      });
    } catch (e) {
      setState(() { _state = _ScreenState.error; _error = e.toString(); });
    }
  }

  void _reset() {
    setState(() { _state = _ScreenState.idle; _omimResults = []; _associations = []; _error = ''; });
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('Disease Genetics', style: tsTitle(kTextPrimary))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: 'Disease Genetics',
              subtitle: 'OMIM gene-disease links · DisGeNET association scores',
              gradientColors: kGrad3DGenome, icon: Icons.local_hospital, isDemoMode: isDemoMode),
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
            prefixIcon: const Icon(Icons.local_hospital, color: kNeonPurple, size: 20),
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
        children: ['TP53', 'BRCA1', 'EGFR', 'KRAS', 'CFTR'].map((g) =>
          ActionChip(label: Text(g, style: tsMono().copyWith(fontSize: 10)),
            backgroundColor: kSurface, side: const BorderSide(color: kBorder),
            onPressed: () { _geneCtrl.text = g; _search(); })).toList()),
    ]);
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return GlowCard(glowColor: kNeonPurple, child: Column(children: [
          Icon(Icons.local_hospital, color: kNeonPurple.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Disease Genetics Explorer', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Enter a gene to discover its disease associations from OMIM '
            '(Mendelian diseases) and DisGeNET (gene-disease scores from literature).',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
        ]));
      case _ScreenState.loading:
        return const Center(child: DnaLoader(message: 'Querying OMIM & DisGeNET...'));
      case _ScreenState.error:
        return GlowCard(glowColor: kNeonAmber, child: Text(_error, style: tsBody().copyWith(color: kNeonAmber)));
      case _ScreenState.results:
        return _buildResults();
    }
  }

  Widget _buildResults() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Summary
      Wrap(spacing: 12, runSpacing: 12, children: [
        _summaryCard('OMIM Entries', '${_omimResults.length}', kNeonPurple),
        _summaryCard('Disease Assoc.', '${_associations.length}', kNeonBlue),
        if (_associations.isNotEmpty)
          _summaryCard('Top Score', _associations.first.scoreLabel, kNeonGreen),
      ]),
      const SizedBox(height: 20),

      // OMIM results
      if (_omimResults.isNotEmpty) ...[
        Text('OMIM — MENDELIAN DISEASE ENTRIES', style: tsLabel()),
        const SizedBox(height: 8),
        ..._omimResults.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlowCard(glowColor: kNeonPurple, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 40, height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                    gradient: LinearGradient(colors: kGrad3DGenome)),
                  child: const Center(child: Icon(Icons.medical_information, color: kVoid, size: 20))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entry.shortTitle, style: tsBody().copyWith(fontWeight: FontWeight.w600)),
                  Text('MIM: ${entry.mimNumber}', style: tsMono().copyWith(fontSize: 11)),
                  if (entry.inheritance != null)
                    Text('Inheritance: ${entry.inheritance}', style: tsLabel()),
                ])),
              ]),
              if (entry.description != null) ...[
                const SizedBox(height: 10),
                Text(entry.description!, style: tsBody().copyWith(color: kTextMuted, fontSize: 12)),
              ],
              if (entry.phenotypes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('PHENOTYPES', style: tsLabel()),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6,
                  children: entry.phenotypes.take(8).map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kNeonGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4)),
                    child: Text(p, style: tsMono().copyWith(fontSize: 10, color: kNeonGreen)),
                  )).toList()),
              ],
            ],
          )),
        )),
        const SizedBox(height: 16),
      ],

      // DisGeNET associations
      if (_associations.isNotEmpty) ...[
        Text('DisGeNET — GENE-DISEASE ASSOCIATION SCORES', style: tsLabel()),
        const SizedBox(height: 8),
        ..._associations.map((assoc) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlowCard(glowColor: kNeonBlue, child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: _evidenceColor(assoc.evidenceLevel).withValues(alpha: 0.15)),
              child: Center(child: Icon(Icons.analytics, color: _evidenceColor(assoc.evidenceLevel), size: 20))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(assoc.diseaseName, style: tsBody().copyWith(fontWeight: FontWeight.w600)),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _evidenceColor(assoc.evidenceLevel).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4)),
                  child: Text(assoc.evidenceLevel, style: tsMono().copyWith(
                    fontSize: 10, color: _evidenceColor(assoc.evidenceLevel))),
                ),
                const SizedBox(width: 8),
                Text('${assoc.nPublications} publications', style: tsLabel()),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(assoc.scoreLabel, style: tsTitle(_evidenceColor(assoc.evidenceLevel)).copyWith(fontSize: 18)),
              Text('GDA Score', style: tsLabel()),
            ]),
          ])),
        )),
      ],

      const SizedBox(height: 12),
      NeonButton(label: 'New Search', icon: Icons.local_hospital, color: kNeonPurple, onPressed: _reset),
    ]);
  }

  Color _evidenceColor(String level) {
    switch (level) {
      case 'Strong': return kNeonGreen;
      case 'Moderate': return kNeonBlue;
      case 'Weak': return kNeonAmber;
      default: return kTextMuted;
    }
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
