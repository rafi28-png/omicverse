import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/module_header.dart';
import '../../core/widgets/research_disclaimer.dart';
import '../../core/widgets/dna_loader.dart';
import '../../core/providers/app_providers.dart';
import 'services/methylation_service.dart';

class MethylationScreen extends ConsumerStatefulWidget {
  const MethylationScreen({super.key});
  @override
  ConsumerState<MethylationScreen> createState() => _MethylationScreenState();
}

class _MethylationScreenState extends ConsumerState<MethylationScreen> {
  bool _loaded = false;
  List<CpGSite> _sites = [];
  HorvathClock? _clock;
  String _filterStatus = 'all';

  void _loadDemo() async {
    setState(() => _loaded = false);
    _sites = CpGSite.demoSites();
    _clock = await MethylationService.calculateHorvathAge(_sites);
    setState(() => _loaded = true);
  }

  List<CpGSite> get _filtered {
    if (_filterStatus == 'all') return _sites;
    return _sites.where((s) => s.methylationStatus == _filterStatus).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadDemo();
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('Epigenome / Methylation', style: tsTitle(kTextPrimary))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: 'DNA Methylation',
              subtitle: 'CpG analysis & Horvath epigenetic clock',
              gradientColors: kGradEpigenome, icon: Icons.access_time, isDemoMode: isDemoMode),
            const SizedBox(height: 24),
            if (!_loaded) const Center(child: DnaLoader(message: 'Loading methylation data...'))
            else ...[
              _buildHorvathCard(),
              const SizedBox(height: 16),
              _buildSummaryCards(),
              const SizedBox(height: 16),
              _buildBetaDistribution(),
              const SizedBox(height: 16),
              _buildFilterAndTable(),
            ],
            const SizedBox(height: 24),
            const ResearchDisclaimer(),
          ]),
        )),
      ),
    );
  }

  Widget _buildHorvathCard() {
    final clock = _clock!;
    return GlowCard(glowColor: kGradEpigenome[0], child: Row(children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: LinearGradient(colors: kGradEpigenome)),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(clock.predictedAge.toStringAsFixed(0),
            style: tsTitle(kVoid).copyWith(fontSize: 28, fontWeight: FontWeight.w900)),
          Text('years', style: tsBadge().copyWith(color: kVoid)),
        ]))),
      const SizedBox(width: 20),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HORVATH EPIGENETIC CLOCK', style: tsLabel()),
        const SizedBox(height: 4),
        Text('Predicted Age: ${clock.ageLabel}', style: tsBody().copyWith(fontWeight: FontWeight.w600)),
        Text(clock.accelerationLabel, style: tsMono().copyWith(
          color: clock.ageAcceleration.abs() > 2 ? kNeonAmber : kNeonGreen)),
        Text('${clock.cpgSitesUsed}/${clock.totalCpgSites} CpG sites used', style: tsLabel()),
      ])),
    ]));
  }

  Widget _buildSummaryCards() {
    final stats = MethylationService.analyzeMethylation(_sites);
    final ctx = MethylationService.contextDistribution(_sites);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('METHYLATION STATUS', style: tsLabel()),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _summaryCard('Total', '${_sites.length}', kGradEpigenome[0]),
        _summaryCard('Hyper', '${stats["Hypermethylated"]}', kNeonRed),
        _summaryCard('Hypo', '${stats["Hypomethylated"]}', kNeonGreen),
        _summaryCard('Intermediate', '${stats["Intermediate"]}', kNeonAmber),
      ]),
      const SizedBox(height: 16),
      Text('GENOMIC CONTEXT', style: tsLabel()),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 12,
        children: ctx.entries.map((e) =>
          _summaryCard(e.key, '${e.value}', kGradEpigenome[1])).toList()),
    ]);
  }

  Widget _buildBetaDistribution() {
    final betas = _sites.where((s) => s.betaValue != null).map((s) => s.betaValue!).toList();
    if (betas.isEmpty) return const SizedBox.shrink();

    // Build histogram buckets (0-0.1, 0.1-0.2, ..., 0.9-1.0)
    final buckets = List.filled(10, 0);
    for (final b in betas) {
      final idx = (b * 10).floor().clamp(0, 9);
      buckets[idx]++;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BETA VALUE DISTRIBUTION', style: tsLabel()),
      const SizedBox(height: 8),
      GlowCard(glowColor: kGradEpigenome[1], child: SizedBox(height: 200,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (buckets.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
              getTitlesWidget: (v, _) => Text('${(v.toInt()) / 10}',
                style: tsMono().copyWith(fontSize: 8)))),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: tsMono().copyWith(fontSize: 8)))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true,
            getDrawingHorizontalLine: (_) => FlLine(color: kBorder, strokeWidth: 0.5)),
          borderData: FlBorderData(show: true, border: Border.all(color: kBorder, width: 0.5)),
          barGroups: List.generate(10, (i) => BarChartGroupData(x: i,
            barRods: [BarChartRodData(toY: buckets[i].toDouble(),
              color: i < 3 ? kNeonGreen : i < 7 ? kNeonAmber : kNeonRed,
              width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))])),
        )),
      )),
    ]);
  }

  Widget _buildFilterAndTable() {
    final filtered = _filtered;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('CPG SITES', style: tsLabel()), const SizedBox(width: 12),
        ...['all', 'Hypermethylated', 'Hypomethylated', 'Intermediate'].map((f) {
          final sel = _filterStatus == f;
          final label = f == 'all' ? 'All' : f == 'Hypermethylated' ? 'Hyper' : f == 'Hypomethylated' ? 'Hypo' : 'Mid';
          return Padding(padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(label, style: tsBadge().copyWith(
              color: sel ? kVoid : kTextSecondary)),
              selected: sel, selectedColor: kGradEpigenome[0], backgroundColor: kSurface,
              side: BorderSide(color: sel ? kGradEpigenome[0] : kBorder),
              onSelected: (_) => setState(() => _filterStatus = f)));
        }),
      ]),
      const SizedBox(height: 12),
      GlowCard(glowColor: kGradEpigenome[0], padding: EdgeInsets.zero,
        child: ClipRRect(borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(kSurfaceRaised),
              columns: [
                DataColumn(label: Text('CpG ID', style: tsLabel())),
                DataColumn(label: Text('Location', style: tsLabel())),
                DataColumn(label: Text('Gene', style: tsLabel())),
                DataColumn(label: Text('Beta', style: tsLabel()), numeric: true),
                DataColumn(label: Text('Status', style: tsLabel())),
                DataColumn(label: Text('Context', style: tsLabel())),
              ],
              rows: filtered.map((s) => DataRow(cells: [
                DataCell(Text(s.cpgId, style: tsMono().copyWith(fontSize: 11))),
                DataCell(Text(s.location, style: tsMono().copyWith(fontSize: 11))),
                DataCell(Text(s.nearestGene ?? '', style: tsMono().copyWith(fontSize: 11))),
                DataCell(Text(s.betaValue?.toStringAsFixed(2) ?? '-', style: tsMono().copyWith(
                  color: s.betaValue != null && s.betaValue! > 0.7 ? kNeonRed
                    : s.betaValue != null && s.betaValue! < 0.3 ? kNeonGreen : kTextPrimary))),
                DataCell(_statusBadge(s.methylationStatus)),
                DataCell(Text(s.context ?? '', style: tsLabel().copyWith(fontSize: 9))),
              ])).toList(),
            )))),
    ]);
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'Hypermethylated': color = kNeonRed; break;
      case 'Hypomethylated': color = kNeonGreen; break;
      case 'Intermediate': color = kNeonAmber; break;
      default: color = kTextMuted;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: tsBadge().copyWith(color: color, fontSize: 9)));
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
