import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/module_header.dart';
import '../../core/widgets/research_disclaimer.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/dna_loader.dart';
import '../../core/providers/app_providers.dart';
import 'services/crispr_service.dart';

enum _ScreenState { idle, designing, results, error }

class CrisprScreen extends ConsumerStatefulWidget {
  const CrisprScreen({super.key});
  @override
  ConsumerState<CrisprScreen> createState() => _CrisprScreenState();
}

class _CrisprScreenState extends ConsumerState<CrisprScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _error;
  List<GuideRna> _guides = [];
  final _geneCtrl = TextEditingController();
  String _sortBy = 'onTarget'; // onTarget, offTarget, gc

  @override
  void dispose() { _geneCtrl.dispose(); super.dispose(); }

  Future<void> _design() async {
    final gene = _geneCtrl.text.trim().toUpperCase();
    if (gene.isEmpty) return;
    setState(() => _state = _ScreenState.designing);
    try {
      final guides = await CrisprService.designGuides(gene);
      setState(() {
        _guides = guides;
        _state = guides.isEmpty ? _ScreenState.idle : _ScreenState.results;
      });
    } catch (e) {
      setState(() { _state = _ScreenState.error; _error = e.toString(); });
    }
  }

  void _reset() {
    setState(() { _state = _ScreenState.idle; _guides = []; _error = null; });
  }

  List<GuideRna> get _sorted {
    final sorted = List<GuideRna>.from(_guides);
    switch (_sortBy) {
      case 'onTarget': sorted.sort((a, b) => b.onTargetScore.compareTo(a.onTargetScore)); break;
      case 'offTarget': sorted.sort((a, b) => b.offTargetScore.compareTo(a.offTargetScore)); break;
      case 'gc': sorted.sort((a, b) => (a.gcContent - 0.5).abs().compareTo((b.gcContent - 0.5).abs())); break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('CRISPR Designer', style: tsTitle(kTextPrimary))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: 'CRISPR Guide Designer',
              subtitle: 'sgRNA design & off-target analysis',
              gradientColors: kGradCRISPR, icon: Icons.content_cut, isDemoMode: isDemoMode),
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
            hintText: 'Enter gene symbol (e.g. TP53, BRCA1)',
            hintStyle: tsBody().copyWith(color: kTextMuted),
            prefixIcon: const Icon(Icons.content_cut, color: kNeonGreen, size: 20),
            filled: true, fillColor: kSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kNeonGreen)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          style: tsBody(), onSubmitted: (_) => _design())),
        const SizedBox(width: 12),
        NeonButton(label: 'Design', icon: Icons.content_cut, color: kNeonGreen, onPressed: _design),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8,
        children: CrisprService.availableGenes().map((g) =>
          ActionChip(label: Text(g, style: tsMono().copyWith(fontSize: 10)),
            backgroundColor: kSurface, side: const BorderSide(color: kBorder),
            onPressed: () { _geneCtrl.text = g; _design(); })).toList()),
    ]);
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return GlowCard(glowColor: kNeonGreen, child: Column(children: [
          Icon(Icons.content_cut, color: kNeonGreen.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Design Guide RNAs', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Enter a gene symbol to design CRISPR-Cas9 guide RNAs with on-target efficiency '
            'and off-target safety scores.',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
        ]));
      case _ScreenState.designing:
        return const Center(child: DnaLoader(message: 'Designing guide RNAs...'));
      case _ScreenState.results:
        return _buildResults();
      case _ScreenState.error:
        return ErrorState(message: _error ?? 'Error', onRetry: _reset);
    }
  }

  Widget _buildResults() {
    final guides = _sorted;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Sort controls
      Row(children: [
        Text('${guides.length} guides designed', style: tsSubtitle()),
        const Spacer(),
        Text('Sort:', style: tsLabel()), const SizedBox(width: 8),
        ...['onTarget', 'offTarget', 'gc'].map((s) {
          final sel = _sortBy == s;
          final label = s == 'onTarget' ? 'Efficiency' : s == 'offTarget' ? 'Safety' : 'GC';
          return Padding(padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(label, style: tsBadge().copyWith(
              color: sel ? kVoid : kTextSecondary)),
              selected: sel, selectedColor: kNeonGreen, backgroundColor: kSurface,
              side: BorderSide(color: sel ? kNeonGreen : kBorder),
              onSelected: (_) => setState(() => _sortBy = s)));
        }),
      ]),
      const SizedBox(height: 12),

      // Guide cards
      ...guides.asMap().entries.map((entry) {
        final i = entry.key;
        final g = entry.value;
        return Padding(padding: const EdgeInsets.only(bottom: 12),
          child: GlowCard(glowColor: _effColor(g.onTargetScore), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: _effColor(g.onTargetScore).withValues(alpha: 0.2)),
                  child: Center(child: Text('${i + 1}',
                    style: tsBadge().copyWith(color: _effColor(g.onTargetScore), fontSize: 14)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${g.targetGene} — ${g.strand == "+" ? "sense" : "antisense"}',
                    style: tsBody().copyWith(fontWeight: FontWeight.w600)),
                  Text(g.location, style: tsMono().copyWith(fontSize: 11)),
                ])),
                _effBadge(g.efficiencyLabel),
                const SizedBox(width: 8),
                _safetyBadge(g.safetyLabel),
              ]),
              const SizedBox(height: 12),

              // Sequence
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kSurfaceRaised, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Text("5'-", style: tsMono().copyWith(fontSize: 11, color: kTextMuted)),
                  Expanded(child: Text(g.sequence, style: tsMono().copyWith(
                    fontSize: 13, letterSpacing: 1.5, color: kNeonGreen))),
                  Text("-3'  ${g.pam}", style: tsMono().copyWith(fontSize: 11, color: kNeonAmber)),
                ])),
              const SizedBox(height: 10),

              // Scores
              Row(children: [
                _scoreBar('On-target', g.onTargetScore, kNeonGreen),
                const SizedBox(width: 16),
                _scoreBar('Off-target', g.offTargetScore, kNeonBlue),
                const SizedBox(width: 16),
                Text('GC: ${(g.gcContent * 100).toInt()}%', style: tsMono().copyWith(fontSize: 11)),
                const SizedBox(width: 16),
                Text('OT: ${g.offTargetCount}', style: tsMono().copyWith(fontSize: 11,
                  color: g.offTargetCount > 5 ? kNeonRed : kTextSecondary)),
              ]),
            ],
          )),
        );
      }),
      const SizedBox(height: 12),
      NeonButton(label: 'New Design', icon: Icons.content_cut, color: kNeonGreen, onPressed: _reset),
    ]);
  }

  Widget _scoreBar(String label, double score, Color color) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: tsLabel().copyWith(fontSize: 9)),
      const SizedBox(height: 4),
      Stack(children: [
        Container(height: 6, decoration: BoxDecoration(
          color: kSurfaceRaised, borderRadius: BorderRadius.circular(3))),
        FractionallySizedBox(widthFactor: score,
          child: Container(height: 6, decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(3)))),
      ]),
      Text('${(score * 100).toInt()}%', style: tsMono().copyWith(fontSize: 9, color: color)),
    ]));
  }

  Color _effColor(double score) {
    if (score >= 0.7) return kNeonGreen;
    if (score >= 0.4) return kNeonAmber;
    return kNeonRed;
  }

  Widget _effBadge(String label) {
    Color color;
    switch (label) {
      case 'High': color = kNeonGreen; break;
      case 'Medium': color = kNeonAmber; break;
      default: color = kNeonRed;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: tsBadge().copyWith(color: color)));
  }

  Widget _safetyBadge(String label) {
    Color color;
    switch (label) {
      case 'Safe': color = kNeonGreen; break;
      case 'Moderate': color = kNeonAmber; break;
      default: color = kNeonRed;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: tsBadge().copyWith(color: color)));
  }
}
