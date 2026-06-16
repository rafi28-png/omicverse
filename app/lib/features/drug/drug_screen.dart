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
import 'services/drug_service.dart';

enum _ScreenState { idle, searching, results, error }
enum _SearchMode { target, name }

class DrugScreen extends ConsumerStatefulWidget {
  const DrugScreen({super.key});
  @override
  ConsumerState<DrugScreen> createState() => _DrugScreenState();
}

class _DrugScreenState extends ConsumerState<DrugScreen> {
  _ScreenState _state = _ScreenState.idle;
  _SearchMode _mode = _SearchMode.target;
  String? _error;
  List<Drug> _drugs = [];
  final _searchCtrl = TextEditingController();
  String _filterPhase = 'all';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _state = _ScreenState.searching);
    try {
      // Always try real API — service falls back to demo on error
      final results = _mode == _SearchMode.target
        ? await DrugService.searchByTarget(q)
        : await DrugService.searchByName(q);
      setState(() {
        _drugs = results;
        _state = results.isEmpty ? _ScreenState.idle : _ScreenState.results;
      });
    } catch (e) {
      setState(() { _state = _ScreenState.error; _error = e.toString(); });
    }
  }

  void _reset() {
    setState(() { _state = _ScreenState.idle; _drugs = []; _error = null; _filterPhase = 'all'; });
  }

  List<Drug> get _filtered {
    if (_filterPhase == 'all') return _drugs;
    return _drugs.where((d) => d.phaseLabel == _filterPhase).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('Drug Discovery', style: tsTitle(kTextPrimary))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: 'Drug Discovery',
              subtitle: 'ChEMBL drug-target interactions & clinical phases',
              gradientColors: kGradDrug, icon: Icons.medication, isDemoMode: isDemoMode),
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
      // Mode toggle
      Row(children: [
        ChoiceChip(label: Text('By Target Gene', style: tsBadge().copyWith(
          color: _mode == _SearchMode.target ? kVoid : kTextSecondary)),
          selected: _mode == _SearchMode.target,
          selectedColor: kGradDrug[0], backgroundColor: kSurface,
          side: BorderSide(color: _mode == _SearchMode.target ? kGradDrug[0] : kBorder),
          onSelected: (_) => setState(() => _mode = _SearchMode.target)),
        const SizedBox(width: 8),
        ChoiceChip(label: Text('By Drug Name', style: tsBadge().copyWith(
          color: _mode == _SearchMode.name ? kVoid : kTextSecondary)),
          selected: _mode == _SearchMode.name,
          selectedColor: kGradDrug[1], backgroundColor: kSurface,
          side: BorderSide(color: _mode == _SearchMode.name ? kGradDrug[1] : kBorder),
          onSelected: (_) => setState(() => _mode = _SearchMode.name)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: _mode == _SearchMode.target
              ? 'Enter gene (e.g. EGFR, BRAF, KRAS)'
              : 'Enter drug name (e.g. Imatinib, Olaparib)',
            hintStyle: tsBody().copyWith(color: kTextMuted),
            prefixIcon: Icon(_mode == _SearchMode.target ? Icons.gps_fixed : Icons.medication,
              color: kGradDrug[0], size: 20),
            filled: true, fillColor: kSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kGradDrug[0])),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          style: tsBody(), onSubmitted: (_) => _search())),
        const SizedBox(width: 12),
        NeonButton(label: 'Search', icon: Icons.search, color: kGradDrug[0], onPressed: _search),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8,
        children: (_mode == _SearchMode.target
          ? ['EGFR', 'BRAF', 'KRAS', 'ERBB2', 'PARP1']
          : ['Imatinib', 'Olaparib', 'Sotorasib']).map((q) =>
          ActionChip(label: Text(q, style: tsMono().copyWith(fontSize: 10)),
            backgroundColor: kSurface, side: const BorderSide(color: kBorder),
            onPressed: () { _searchCtrl.text = q; _search(); })).toList()),
    ]);
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return GlowCard(glowColor: kGradDrug[0], child: Column(children: [
          Icon(Icons.medication, color: kGradDrug[0].withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Search Drug Interactions', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Search for drugs by target gene or drug name. View clinical trial phases, '
            'mechanisms of action, and indications.',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
        ]));
      case _ScreenState.searching:
        return const Center(child: DnaLoader(message: 'Searching ChEMBL...'));
      case _ScreenState.results:
        return _buildResults();
      case _ScreenState.error:
        return ErrorState(message: _error ?? 'Error', onRetry: _reset);
    }
  }

  Widget _buildResults() {
    final filtered = _filtered;
    final byPhase = DrugService.drugsByPhase(_drugs);
    final byType = DrugService.drugsByType(_drugs);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Summary
      Wrap(spacing: 12, runSpacing: 12, children: [
        _summaryCard('Total', '${_drugs.length}', kGradDrug[0]),
        ...byPhase.entries.map((e) => _summaryCard(e.key, '${e.value}', _phaseColor(e.key))),
      ]),
      const SizedBox(height: 12),
      if (byType.length > 1)
        Wrap(spacing: 12, runSpacing: 12,
          children: byType.entries.map((e) => _summaryCard(e.key, '${e.value}', kGradDrug[1])).toList()),
      const SizedBox(height: 16),

      // Filter
      Row(children: [
        Text('DRUGS', style: tsLabel()), const SizedBox(width: 12),
        ...['all', 'Approved', 'Phase III', 'Phase II', 'Phase I'].map((f) {
          final sel = _filterPhase == f;
          return Padding(padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(label: Text(f == 'all' ? 'All' : f, style: tsBadge().copyWith(
              color: sel ? kVoid : kTextSecondary, fontSize: 9)),
              selected: sel, selectedColor: kGradDrug[0], backgroundColor: kSurface,
              side: BorderSide(color: sel ? kGradDrug[0] : kBorder),
              onSelected: (_) => setState(() => _filterPhase = f)));
        }),
        const Spacer(),
        NeonButton(label: 'Clear', icon: Icons.clear, color: kTextMuted, onPressed: _reset),
      ]),
      const SizedBox(height: 12),

      // Drug cards
      ...filtered.map((d) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlowCard(glowColor: _phaseColor(d.phaseLabel), child: Row(children: [
          // Drug icon
          Container(width: 44, height: 44,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
              color: _phaseColor(d.phaseLabel).withValues(alpha: 0.15)),
            child: Center(child: Icon(
              d.type == 'Antibody' ? Icons.vaccines : Icons.medication,
              color: _phaseColor(d.phaseLabel), size: 22))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.name, style: tsBody().copyWith(fontWeight: FontWeight.w700)),
            if (d.mechanism != null)
              Text(d.mechanism!, style: tsLabel().copyWith(fontSize: 9)),
            Row(children: [
              Text(d.type, style: tsMono().copyWith(fontSize: 10)),
              if (d.targetGene != null) ...[
                const SizedBox(width: 8),
                Text('→ ${d.targetGene}', style: tsMono().copyWith(fontSize: 10, color: kNeonGreen)),
              ],
            ]),
            if (d.indication != null)
              Text(d.indication!, style: tsBody().copyWith(fontSize: 11, color: kTextMuted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _phaseBadge(d.phaseLabel),
            const SizedBox(height: 4),
            Text(d.chemblId, style: tsMono().copyWith(fontSize: 9, color: kTextMuted)),
          ]),
        ])),
      )),
    ]);
  }

  Color _phaseColor(String phase) {
    switch (phase) {
      case 'Approved': return kNeonGreen;
      case 'Phase III': return kNeonAmber;
      case 'Phase II': return kNeonBlue;
      case 'Phase I': return kNeonPurple;
      default: return kTextMuted;
    }
  }

  Widget _phaseBadge(String phase) {
    final color = _phaseColor(phase);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(phase, style: tsBadge().copyWith(color: color)));
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
