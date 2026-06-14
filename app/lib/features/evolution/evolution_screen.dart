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
import 'services/evolution_service.dart';

enum _ScreenState { idle, searching, results, error }

class EvolutionScreen extends ConsumerStatefulWidget {
  const EvolutionScreen({super.key});
  @override
  ConsumerState<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends ConsumerState<EvolutionScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _error;
  List<OrthologGene> _orthologs = [];
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final gene = _searchCtrl.text.trim().toUpperCase();
    if (gene.isEmpty) return;
    setState(() => _state = _ScreenState.searching);
    try {
      final isDemoMode = ref.read(isDemoModeProvider);
      final orthologs = isDemoMode
        ? EvolutionService.demoOrthologs(gene)
        : await EvolutionService.getOrthologs(gene);
      setState(() {
        _orthologs = orthologs;
        _state = orthologs.isEmpty ? _ScreenState.idle : _ScreenState.results;
      });
    } catch (e) {
      setState(() { _state = _ScreenState.error; _error = e.toString(); });
    }
  }

  void _reset() {
    setState(() { _state = _ScreenState.idle; _orthologs = []; _error = null; });
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('Evolutionary Conservation', style: tsTitle(kTextPrimary))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: 'Evolutionary Conservation',
              subtitle: 'Orthologs & cross-species conservation',
              gradientColors: kGradEvolution, icon: Icons.park, isDemoMode: isDemoMode),
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
    return Row(children: [
      Expanded(child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Enter gene symbol (e.g. TP53, BRCA1)',
          hintStyle: tsBody().copyWith(color: kTextMuted),
          prefixIcon: const Icon(Icons.park, color: kNeonGold, size: 20),
          filled: true, fillColor: kSurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kNeonGold)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        style: tsBody(), onSubmitted: (_) => _search())),
      const SizedBox(width: 12),
      NeonButton(label: 'Search', icon: Icons.search, color: kNeonGold, onPressed: _search),
    ]);
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return GlowCard(glowColor: kNeonGold, child: Column(children: [
          Icon(Icons.park, color: kNeonGold.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Search Orthologs', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Enter a gene symbol to find orthologs across species and view evolutionary conservation.',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Try: TP53, BRCA1, EGFR', style: tsMono().copyWith(fontSize: 11)),
        ]));
      case _ScreenState.searching:
        return const Center(child: DnaLoader(message: 'Searching orthologs...'));
      case _ScreenState.results:
        return _buildResults();
      case _ScreenState.error:
        return ErrorState(message: _error ?? 'Error', onRetry: _reset);
    }
  }

  Widget _buildResults() {
    final sorted = List<OrthologGene>.from(_orthologs)
      ..sort((a, b) => b.percentIdentity.compareTo(a.percentIdentity));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Conservation bar chart
      Text('SEQUENCE IDENTITY ACROSS SPECIES', style: tsLabel()),
      const SizedBox(height: 8),
      GlowCard(glowColor: kGradEvolution[1], child: SizedBox(height: 280,
        child: _buildBarChart(sorted))),
      const SizedBox(height: 16),

      // Summary
      Wrap(spacing: 12, runSpacing: 12, children: [
        _summaryCard('Species', '${sorted.length}', kNeonGold),
        _summaryCard('Highly Conserved', '${sorted.where((o) => o.percentIdentity >= 90).length}', kNeonGreen),
        _summaryCard('Conserved', '${sorted.where((o) => o.percentIdentity >= 70 && o.percentIdentity < 90).length}', kNeonAmber),
        _summaryCard('Divergent', '${sorted.where((o) => o.percentIdentity < 40).length}', kNeonRed),
      ]),
      const SizedBox(height: 16),

      // Ortholog table
      Text('ORTHOLOGS', style: tsLabel()),
      const SizedBox(height: 8),
      ...sorted.map((o) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlowCard(glowColor: _conservationColor(o.percentIdentity), child: Row(children: [
          Text(_speciesEmoji(o.speciesCommon), style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o.speciesCommon, style: tsBody().copyWith(fontWeight: FontWeight.w600)),
            Text(o.species.replaceAll('_', ' '), style: tsLabel().copyWith(
              fontStyle: FontStyle.italic, fontSize: 9)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${o.percentIdentity.toStringAsFixed(1)}%',
              style: tsTitle(_conservationColor(o.percentIdentity)).copyWith(fontSize: 18)),
            _conservationBadge(o.conservationLabel),
          ]),
        ])),
      )),
      const SizedBox(height: 12),
      NeonButton(label: 'New Search', icon: Icons.search, color: kNeonGold, onPressed: _reset),
    ]);
  }

  Widget _buildBarChart(List<OrthologGene> sorted) {
    final colors = [kNeonGreen, kNeonGreen, kNeonGreen, kNeonAmber, kNeonAmber,
      kNeonAmber, kNeonOrange, kNeonOrange, kNeonRed, kNeonRed, kNeonRed];

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 105,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 6),
              child: RotatedBox(quarterTurns: 1,
                child: Text(sorted[i].speciesCommon, style: tsMono().copyWith(fontSize: 8))));
          })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35,
          getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: tsMono().copyWith(fontSize: 8)))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true,
        getDrawingHorizontalLine: (_) => const FlLine(color: kBorder, strokeWidth: 0.5)),
      borderData: FlBorderData(show: true, border: Border.all(color: kBorder, width: 0.5)),
      barGroups: List.generate(sorted.length, (i) => BarChartGroupData(x: i,
        barRods: [BarChartRodData(toY: sorted[i].percentIdentity,
          color: i < colors.length ? colors[i] : kTextMuted, width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))])),
    ));
  }

  Color _conservationColor(double pct) {
    if (pct >= 90) return kNeonGreen;
    if (pct >= 70) return kNeonAmber;
    if (pct >= 40) return kNeonOrange;
    return kNeonRed;
  }

  Widget _conservationBadge(String label) {
    Color color;
    switch (label) {
      case 'Highly conserved': color = kNeonGreen; break;
      case 'Conserved': color = kNeonAmber; break;
      case 'Moderately conserved': color = kNeonOrange; break;
      default: color = kNeonRed;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: tsBadge().copyWith(color: color, fontSize: 8)));
  }

  String _speciesEmoji(String species) {
    const emojis = {
      'Chimpanzee': '🐒', 'Gorilla': '🦍', 'Orangutan': '🦧',
      'Mouse': '🐭', 'Rat': '🐀', 'Dog': '🐕', 'Cat': '🐈',
      'Cow': '🐄', 'Chicken': '🐔', 'Zebrafish': '🐟',
      'Fruit fly': '🪰', 'C. elegans': '🪱', 'Yeast': '🍄',
      'Frog': '🐸', 'Rhesus macaque': '🐵',
    };
    return emojis[species] ?? '🧬';
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
