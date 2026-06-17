import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/module_header.dart';
import '../../core/widgets/research_disclaimer.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/dna_loader.dart';
import '../../core/providers/app_providers.dart';
import 'services/cancer_service.dart';

enum _ScreenState { idle, searching, results, error }

class CancerScreen extends ConsumerStatefulWidget {
  const CancerScreen({super.key});
  @override
  ConsumerState<CancerScreen> createState() => _CancerScreenState();
}

class _CancerScreenState extends ConsumerState<CancerScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _error;
  List<CancerMutation> _mutations = [];
  final _searchCtrl = TextEditingController();
  String _filterTier = 'all';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final gene = _searchCtrl.text.trim().toUpperCase();
    if (gene.isEmpty) return;
    setState(() => _state = _ScreenState.searching);
    try {
      final mutations = await CancerService.getMutations(gene);
      setState(() {
        _mutations = mutations;
        _state = mutations.isEmpty ? _ScreenState.idle : _ScreenState.results;
      });
    } catch (e) {
      setState(() { _state = _ScreenState.error; _error = e.toString(); });
    }
  }

  void _reset() {
    setState(() { _state = _ScreenState.idle; _mutations = []; _error = null; _filterTier = 'all'; });
  }

  List<CancerMutation> get _filtered {
    if (_filterTier == 'all') return _mutations;
    return _mutations.where((m) => m.tier == _filterTier).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('Cancer Genomics', style: tsTitle(kTextPrimary))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: 'Cancer Genomics',
              subtitle: 'cBioPortal somatic mutations & hotspots',
              gradientColors: kGradCancer, icon: Icons.biotech, isDemoMode: isDemoMode),
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
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search gene (e.g. TP53, KRAS, BRAF, EGFR)',
            hintStyle: tsBody().copyWith(color: kTextMuted),
            prefixIcon: const Icon(Icons.biotech, color: kNeonRed, size: 20),
            filled: true, fillColor: kSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kNeonRed)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          style: tsBody(), onSubmitted: (_) => _search())),
        const SizedBox(width: 12),
        NeonButton(label: 'Search', icon: Icons.search, color: kNeonRed, onPressed: _search),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8,
        children: ['TP53', 'KRAS', 'BRAF', 'EGFR', 'PIK3CA', 'BRCA1'].map((g) =>
          ActionChip(label: Text(g, style: tsMono().copyWith(fontSize: 10)),
            backgroundColor: kSurface, side: const BorderSide(color: kBorder),
            onPressed: () { _searchCtrl.text = g; _search(); })).toList()),
    ]);
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return GlowCard(glowColor: kNeonRed, child: Column(children: [
          Icon(Icons.biotech, color: kNeonRed.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Search Cancer Mutations', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Enter a gene to find somatic mutations, hotspots, and cancer type frequencies '
            'from cBioPortal / TCGA.',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
        ]));
      case _ScreenState.searching:
        return const Center(child: DnaLoader(message: 'Searching cancer mutations...'));
      case _ScreenState.results:
        return _buildResults();
      case _ScreenState.error:
        return ErrorState(message: _error ?? 'Error', onRetry: _reset);
    }
  }

  Widget _buildResults() {
    final filtered = _filtered;
    final byType = CancerService.mutationByCancerType(_mutations);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Summary
      Wrap(spacing: 12, runSpacing: 12, children: [
        _summaryCard('Total', '${_mutations.length}', kNeonRed),
        _summaryCard('Hotspots', '${_mutations.where((m) => m.tier == "Hotspot").length}', kNeonAmber),
        _summaryCard('Recurrent', '${_mutations.where((m) => m.tier == "Recurrent").length}', kNeonPurple),
        _summaryCard('Cancer Types', '${byType.keys.length}', kNeonBlue),
      ]),
      const SizedBox(height: 16),

      // Cancer type bar chart
      if (byType.isNotEmpty) ...[
        Text('MUTATION FREQUENCY BY CANCER TYPE', style: tsLabel()),
        const SizedBox(height: 8),
        GlowCard(glowColor: kGradCancer[1], child: SizedBox(height: 200,
          child: _buildCancerChart(byType))),
        const SizedBox(height: 16),
      ],

      // Filter + mutations table
      Row(children: [
        Text('MUTATIONS', style: tsLabel()), const SizedBox(width: 12),
        ...['all', 'Hotspot', 'Recurrent', 'Rare'].map((f) {
          final sel = _filterTier == f;
          return Padding(padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(f == 'all' ? 'All' : f, style: tsBadge().copyWith(
              color: sel ? kVoid : kTextSecondary)),
              selected: sel, selectedColor: kNeonRed, backgroundColor: kSurface,
              side: BorderSide(color: sel ? kNeonRed : kBorder),
              onSelected: (_) => setState(() => _filterTier = f)));
        }),
        const Spacer(),
        NeonButton(label: 'Clear', icon: Icons.clear, color: kTextMuted, onPressed: _reset),
      ]),
      const SizedBox(height: 12),

      ...filtered.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlowCard(glowColor: _tierColor(m.tier), child: Row(children: [
          // Mutation badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kNeonRed.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(m.mutation, style: tsMono().copyWith(
              fontSize: 14, fontWeight: FontWeight.w700, color: kNeonRed))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${m.gene} — ${m.cancerType}', style: tsBody().copyWith(fontWeight: FontWeight.w600)),
            Row(children: [
              Text(m.consequence, style: tsLabel().copyWith(fontSize: 9)),
              if (m.clinicalSignificance != null) ...[
                const SizedBox(width: 8),
                _clinBadge(m.clinicalSignificance!),
              ],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(m.frequencyLabel, style: tsTitle(_tierColor(m.tier)).copyWith(fontSize: 16)),
            _tierBadge(m.tier),
          ]),
        ])),
      )),
    ]);
  }

  Widget _buildCancerChart(Map<String, double> byType) {
    final entries = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final colors = [kNeonRed, kNeonAmber, kNeonPurple, kNeonBlue, kNeonGreen, kNeonPink, kNeonOrange];

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: entries.first.value * 1.2,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= entries.length) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 6),
              child: Text(entries[i].key, style: tsMono().copyWith(fontSize: 8),
                textAlign: TextAlign.center));
          })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35,
          getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: tsMono().copyWith(fontSize: 8)))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true,
        getDrawingHorizontalLine: (_) => const FlLine(color: kBorder, strokeWidth: 0.5)),
      borderData: FlBorderData(show: true, border: Border.all(color: kBorder, width: 0.5)),
      barGroups: List.generate(entries.length, (i) => BarChartGroupData(x: i,
        barRods: [BarChartRodData(toY: entries[i].value,
          color: colors[i % colors.length], width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))])),
    ));
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Hotspot': return kNeonAmber;
      case 'Recurrent': return kNeonPurple;
      default: return kTextMuted;
    }
  }

  Widget _tierBadge(String tier) {
    final color = _tierColor(tier);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(tier, style: tsBadge().copyWith(color: color, fontSize: 9)));
  }

  Widget _clinBadge(String sig) {
    Color color;
    switch (sig) {
      case 'Oncogenic': color = kNeonRed; break;
      case 'Pathogenic': color = kNeonAmber; break;
      case 'Drug resistance': color = kNeonPurple; break;
      default: color = kTextMuted;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(sig, style: tsBadge().copyWith(color: color, fontSize: 8)));
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
