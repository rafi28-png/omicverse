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
import 'services/population_service.dart';

enum _ScreenState { idle, searching, results, error }

class PopulationScreen extends ConsumerStatefulWidget {
  const PopulationScreen({super.key});
  @override
  ConsumerState<PopulationScreen> createState() => _PopulationScreenState();
}

class _PopulationScreenState extends ConsumerState<PopulationScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _error;
  PopulationVariant? _variant;
  final _chrCtrl = TextEditingController(text: '17');
  final _posCtrl = TextEditingController(text: '7674220');
  final _refCtrl = TextEditingController(text: 'G');
  final _altCtrl = TextEditingController(text: 'A');

  @override
  void dispose() {
    _chrCtrl.dispose(); _posCtrl.dispose();
    _refCtrl.dispose(); _altCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final chr = _chrCtrl.text.trim();
    final pos = int.tryParse(_posCtrl.text.trim());
    final refAllele = _refCtrl.text.trim().toUpperCase();
    final altAllele = _altCtrl.text.trim().toUpperCase();
    if (chr.isEmpty || pos == null || refAllele.isEmpty || altAllele.isEmpty) return;

    setState(() => _state = _ScreenState.searching);
    try {
      final isDemoMode = ref.read(isDemoModeProvider);
      PopulationVariant? result;
      result = await PopulationService.queryVariant(
        chromosome: chr, position: pos, reference: refAllele, alternate: altAllele);
      result ??= PopulationVariant.demoVariants().first;
      setState(() { _variant = result; _state = _ScreenState.results; });
    } catch (e) {
      setState(() { _state = _ScreenState.error; _error = e.toString(); });
    }
  }

  void _reset() {
    setState(() { _state = _ScreenState.idle; _variant = null; _error = null; });
  }

  void _loadDemo(PopulationVariant v) {
    final parts = v.variantId.split('-');
    _chrCtrl.text = parts[0];
    _posCtrl.text = parts[1];
    _refCtrl.text = parts[2];
    _altCtrl.text = parts[3];
    setState(() { _variant = v; _state = _ScreenState.results; });
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('Population Genetics', style: tsTitle(kTextPrimary))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: 'Population Genetics',
              subtitle: 'gnomAD allele frequencies across populations',
              gradientColors: kGradPopulation, icon: Icons.groups, isDemoMode: isDemoMode),
            const SizedBox(height: 24),
            _buildInputForm(),
            const SizedBox(height: 24),
            _buildBody(),
            const SizedBox(height: 24),
            const ResearchDisclaimer(),
          ]),
        )),
      ),
    );
  }

  Widget _buildInputForm() {
    return GlowCard(glowColor: kGradPopulation[0], child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VARIANT INPUT', style: tsLabel()),
        const SizedBox(height: 12),
        Row(children: [
          _inputField(_chrCtrl, 'Chr', flex: 1),
          const SizedBox(width: 8),
          _inputField(_posCtrl, 'Position', flex: 2),
          const SizedBox(width: 8),
          _inputField(_refCtrl, 'Ref', flex: 1),
          const SizedBox(width: 8),
          _inputField(_altCtrl, 'Alt', flex: 1),
          const SizedBox(width: 12),
          NeonButton(label: 'Query', icon: Icons.search, color: kGradPopulation[0], onPressed: _search),
        ]),
        const SizedBox(height: 12),
        Text('DEMO VARIANTS', style: tsLabel()),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: PopulationVariant.demoVariants().map((v) =>
          ActionChip(
            label: Text('${v.gene ?? v.variantId} ${v.rsid}', style: tsMono().copyWith(fontSize: 10)),
            backgroundColor: kSurface, side: const BorderSide(color: kBorder),
            onPressed: () => _loadDemo(v),
          )).toList()),
      ],
    ));
  }

  Widget _inputField(TextEditingController ctrl, String label, {int flex = 1}) {
    return Expanded(flex: flex, child: TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label, labelStyle: tsLabel(),
        filled: true, fillColor: kSurfaceRaised,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBorder)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      style: tsMono(),
    ));
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return GlowCard(glowColor: kGradPopulation[0], child: Column(children: [
          Icon(Icons.groups, color: kGradPopulation[0].withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Query Population Frequencies', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Enter a variant to see allele frequencies across global populations from gnomAD.',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
        ]));
      case _ScreenState.searching:
        return const Center(child: DnaLoader(message: 'Querying gnomAD...'));
      case _ScreenState.results:
        return _buildResults();
      case _ScreenState.error:
        return ErrorState(message: _error ?? 'Error', onRetry: _reset);
    }
  }

  Widget _buildResults() {
    final v = _variant!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Variant header
      GlowCard(glowColor: kGradPopulation[0], child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(v.gene ?? v.variantId, style: tsTitle(kGradPopulation[0]).copyWith(fontSize: 22)),
            if (v.rsid.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: kNeonAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4)),
                child: Text(v.rsid, style: tsMono().copyWith(fontSize: 11, color: kNeonAmber))),
            ],
          ]),
          const SizedBox(height: 4),
          Text('${v.location}  ${v.reference}>${v.alternate}', style: tsMono()),
          if (v.consequence != null)
            Text(v.consequence!.replaceAll('_', ' '), style: tsBody().copyWith(color: kTextSecondary, fontSize: 12)),
        ])),
        Column(children: [
          Text(v.populations.isNotEmpty
            ? v.populations.first.frequencyLabel : v.globalFrequency.toStringAsExponential(1),
            style: tsTitle(kNeonAmber).copyWith(fontSize: 20)),
          Text('Global AF', style: tsLabel()),
        ]),
      ])),
      const SizedBox(height: 16),

      // Population bar chart
      Text('ALLELE FREQUENCY BY POPULATION', style: tsLabel()),
      const SizedBox(height: 8),
      GlowCard(glowColor: kGradPopulation[1], child: SizedBox(
        height: 250,
        child: _buildBarChart(v.populations),
      )),
      const SizedBox(height: 16),

      // Population table
      Text('POPULATION DETAILS', style: tsLabel()),
      const SizedBox(height: 8),
      GlowCard(glowColor: kGradPopulation[0], padding: EdgeInsets.zero,
        child: ClipRRect(borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(kSurfaceRaised),
              columns: [
                DataColumn(label: Text('Population', style: tsLabel())),
                DataColumn(label: Text('AF', style: tsLabel()), numeric: true),
                DataColumn(label: Text('Rarity', style: tsLabel())),
              ],
              rows: v.populations.map((p) => DataRow(cells: [
                DataCell(Text(p.abbreviation, style: tsMono())),
                DataCell(Text(p.frequencyLabel, style: tsMono().copyWith(
                  color: p.alleleFrequency > 0.01 ? kNeonAmber : kTextPrimary))),
                DataCell(_rarityBadge(p.rarityLabel)),
              ])).toList(),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      NeonButton(label: 'New Query', icon: Icons.search, color: kGradPopulation[0], onPressed: _reset),
    ]);
  }

  Widget _buildBarChart(List<PopulationFrequency> pops) {
    if (pops.isEmpty) return Center(child: Text('No data', style: tsBody()));
    final maxAf = pops.map((p) => p.alleleFrequency).reduce((a, b) => a > b ? a : b);
    final colors = [kNeonTeal, kNeonPurple, kNeonAmber, kNeonBlue, kNeonGreen, kNeonPink, kNeonRed, kNeonOrange, kNeonGold];

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxAf * 1.3,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= pops.length) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 6),
              child: Text(pops[i].abbreviation, style: tsMono().copyWith(fontSize: 9)));
          })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50,
          getTitlesWidget: (v, _) => Text(v.toStringAsExponential(0), style: tsMono().copyWith(fontSize: 8)))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true,
        getDrawingHorizontalLine: (_) => const FlLine(color: kBorder, strokeWidth: 0.5)),
      borderData: FlBorderData(show: true, border: Border.all(color: kBorder, width: 0.5)),
      barGroups: List.generate(pops.length, (i) => BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(
          toY: pops[i].alleleFrequency,
          color: colors[i % colors.length],
          width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        )],
      )),
    ));
  }

  Widget _rarityBadge(String label) {
    Color color;
    switch (label) {
      case 'Common': color = kNeonGreen; break;
      case 'Low frequency': color = kNeonAmber; break;
      case 'Rare': color = kNeonRed; break;
      case 'Ultra-rare': color = kNeonPink; break;
      default: color = kTextMuted;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: tsBadge().copyWith(color: color)));
  }
}
