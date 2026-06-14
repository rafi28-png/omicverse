import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/module_header.dart';
import '../../core/widgets/privacy_upload_banner.dart';
import '../../core/widgets/research_disclaimer.dart';
import '../../core/widgets/file_upload_zone.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/dna_loader.dart';
import '../../core/services/file_upload_service.dart';
import '../../core/providers/app_providers.dart';
import 'services/expression_parser.dart';

enum _ScreenState { upload, parsing, results, error }

class ExpressionScreen extends ConsumerStatefulWidget {
  const ExpressionScreen({super.key});

  @override
  ConsumerState<ExpressionScreen> createState() => _ExpressionScreenState();
}

class _ExpressionScreenState extends ConsumerState<ExpressionScreen> {
  _ScreenState _state = _ScreenState.upload;
  String? _error;
  ExpressionParseResult? _result;
  String _filterType = 'all'; // all, up, down, deg
  String _searchQuery = '';

  Future<void> _pickFile() async {
    try {
      final file = await FileUploadService.pickAndValidate(
        module: 'expression',
        allowedExtensions: ['csv', 'tsv', 'txt'],
      );
      if (file == null) return;

      setState(() => _state = _ScreenState.parsing);

      final result = await ExpressionParser.parse(file.bytes, file.filename);
      _result = result;

      setState(() => _state = _ScreenState.results);
    } catch (e) {
      setState(() {
        _state = _ScreenState.error;
        _error = e.toString();
      });
    }
  }

  void _reset() {
    setState(() {
      _state = _ScreenState.upload;
      _error = null;
      _result = null;
      _searchQuery = '';
    });
  }

  Future<void> _loadSampleData() async {
    setState(() => _state = _ScreenState.parsing);
    await Future.delayed(const Duration(milliseconds: 600));
    const sampleCsv = 'gene,log2FoldChange,pValue,padj,baseMean\n'
        'TP53,2.45,0.00012,0.0014,1450.5\n'
        'BRCA1,-1.82,0.0024,0.012,890.2\n'
        'EGFR,3.12,0.000045,0.0008,2450.1\n'
        'MYC,1.98,0.0058,0.024,1120.3\n'
        'PTEN,-2.15,0.00095,0.0068,750.4\n'
        'MDM2,1.54,0.12,0.32,1320.0\n'
        'GAPDH,0.05,0.85,0.92,5430.2\n'
        'ACTB,-0.02,0.91,0.97,8900.5\n'
        'VEGFA,2.89,0.00021,0.0021,950.8\n'
        'IL6,3.42,0.00008,0.0011,420.2\n'
        'TNF,2.11,0.0041,0.018,610.5\n'
        'AKT1,-0.12,0.45,0.62,1850.3\n';

    try {
      final bytes = Uint8List.fromList(utf8.encode(sampleCsv));
      final result = await ExpressionParser.parse(bytes, 'sample.csv');
      setState(() {
        _result = result;
        _state = _ScreenState.results;
      });
    } catch (e) {
      setState(() {
        _state = _ScreenState.error;
        _error = e.toString();
      });
    }
  }

  List<ExpressionGene> get _filteredGenes {
    if (_result == null) return [];
    var genes = _result!.genes;

    // Apply filter
    switch (_filterType) {
      case 'up': genes = genes.where((g) => g.isUpregulated).toList(); break;
      case 'down': genes = genes.where((g) => g.isDownregulated).toList(); break;
      case 'deg': genes = genes.where((g) => g.isDEG).toList(); break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      genes = genes.where((g) =>
        g.gene.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return genes;
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Expression Analysis', style: tsTitle(kTextPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModuleHeader(
                  title: 'Expression Analysis',
                  subtitle: 'DEG analysis & volcano plot',
                  gradientColors: kGradExpression,
                  icon: Icons.show_chart,
                  isDemoMode: isDemoMode,
                ),
                const SizedBox(height: 16),
                const PrivacyUploadBanner(),
                const SizedBox(height: 24),
                _buildBody(),
                const SizedBox(height: 24),
                const ResearchDisclaimer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.upload:
        return Column(
          children: [
            FileUploadZone(
              label: 'Upload expression data (DESeq2, edgeR, limma)',
              acceptedFormats: '.csv, .tsv, .txt',
              onTap: _pickFile,
            ),
            const SizedBox(height: 16),
            Text('OR', style: tsLabel().copyWith(color: kTextMuted)),
            const SizedBox(height: 16),
            NeonButton(
              label: 'Load Sample Expression Data',
              icon: Icons.science_outlined,
              color: kNeonAmber,
              onPressed: _loadSampleData,
            ),
          ],
        );
      case _ScreenState.parsing:
        return const Center(
          child: DnaLoader(message: 'Parsing expression data...'),
        );
      case _ScreenState.results:
        return _buildResults();
      case _ScreenState.error:
        return ErrorState(
          message: _error ?? 'Unknown error',
          onRetry: _reset,
        );
    }
  }

  Widget _buildResults() {
    final r = _result!;
    final filtered = _filteredGenes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryCard('Total Genes', '${r.parsedRows}', kNeonTeal),
            _summaryCard('Upregulated', '${r.upregulated}', kNeonGreen),
            _summaryCard('Downregulated', '${r.downregulated}', kNeonRed),
            _summaryCard('DEGs (|FC|>1)', '${r.degs}', kNeonAmber),
            _summaryCard('Format', r.detectedFormat ?? '?', kNeonBlue),
          ],
        ),
        const SizedBox(height: 24),

        // Volcano plot
        Text('VOLCANO PLOT', style: tsLabel()),
        const SizedBox(height: 8),
        GlowCard(
          glowColor: kGradExpression[0],
          child: SizedBox(
            height: 350,
            child: _buildVolcanoPlot(r.genes),
          ),
        ),
        const SizedBox(height: 24),

        // Filter + search bar
        Row(
          children: [
            Text('FILTER', style: tsLabel()),
            const SizedBox(width: 12),
            ..._buildFilterChips(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search gene...',
                  hintStyle: tsBody().copyWith(color: kTextMuted),
                  prefixIcon: const Icon(Icons.search, color: kTextMuted, size: 18),
                  filled: true,
                  fillColor: kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: tsBody(),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(width: 12),
            NeonButton(
              label: 'New Analysis',
              icon: Icons.refresh,
              color: kNeonTeal,
              onPressed: _reset,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Gene table
        GlowCard(
          glowColor: kGradExpression[0],
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(kSurfaceRaised),
                dataRowColor: WidgetStateProperty.all(kSurface),
                columns: [
                  DataColumn(label: Text('Gene', style: tsLabel())),
                  DataColumn(label: Text('log2FC', style: tsLabel()), numeric: true),
                  DataColumn(label: Text('p-value', style: tsLabel()), numeric: true),
                  DataColumn(label: Text('adj. p-value', style: tsLabel()), numeric: true),
                  DataColumn(label: Text('Status', style: tsLabel())),
                ],
                rows: filtered.take(100).map((g) => DataRow(
                  cells: [
                    DataCell(Text(g.gene, style: tsMono())),
                    DataCell(Text(
                      g.log2FoldChange.toStringAsFixed(2),
                      style: tsMono().copyWith(
                        color: g.log2FoldChange > 0 ? kNeonGreen : kNeonRed,
                      ),
                    )),
                    DataCell(Text(_formatPval(g.pValue), style: tsMono())),
                    DataCell(Text(_formatPval(g.adjustedPValue), style: tsMono())),
                    DataCell(_statusBadge(g)),
                  ],
                )).toList(),
              ),
            ),
          ),
        ),

        if (filtered.length > 100) ...[
          const SizedBox(height: 12),
          Text('Showing first 100 of ${filtered.length} genes', style: tsSubtitle()),
        ],
      ],
    );
  }

  Widget _buildVolcanoPlot(List<ExpressionGene> genes) {
    final spots = <ScatterSpot>[];

    for (final g in genes) {
      if (g.adjustedPValue <= 0) continue;
      final x = g.log2FoldChange.clamp(-10.0, 10.0);
      final y = -math.log(g.adjustedPValue) / math.ln10;
      if (y.isNaN || y.isInfinite) continue;

      Color color;
      if (g.isDEG && g.isUpregulated) {
        color = kNeonGreen;
      } else if (g.isDEG && g.isDownregulated) {
        color = kNeonRed;
      } else if (g.isSignificant) {
        color = kNeonAmber.withValues(alpha: 0.5);
      } else {
        color = kTextMuted.withValues(alpha: 0.3);
      }

      spots.add(ScatterSpot(x, y.clamp(0, 50),
        dotPainter: FlDotCirclePainter(radius: 2.5, color: color),
      ));
    }

    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots,
        minX: -10, maxX: 10,
        minY: 0, maxY: 20,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: Text('log₂ Fold Change', style: tsLabel()),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(), style: tsMono().copyWith(fontSize: 10)),
              interval: 2,
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text('-log₁₀(adj. p-value)', style: tsLabel()),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(), style: tsMono().copyWith(fontSize: 10)),
              interval: 5,
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: 5,
          verticalInterval: 2,
          getDrawingHorizontalLine: (_) => const FlLine(color: kBorder, strokeWidth: 0.5),
          getDrawingVerticalLine: (_) => const FlLine(color: kBorder, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: kBorder, width: 0.5),
        ),
        scatterTouchData: ScatterTouchData(enabled: false),
      ),
    );
  }

  List<Widget> _buildFilterChips() {
    final filters = {
      'all': 'All',
      'up': 'Up ↑',
      'down': 'Down ↓',
      'deg': 'DEGs',
    };
    return filters.entries.map((e) {
      final selected = _filterType == e.key;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(e.value, style: tsBadge().copyWith(
            color: selected ? kVoid : kTextSecondary,
          )),
          selected: selected,
          selectedColor: kGradExpression[0],
          backgroundColor: kSurface,
          side: BorderSide(color: selected ? kGradExpression[0] : kBorder),
          onSelected: (_) => setState(() => _filterType = e.key),
        ),
      );
    }).toList();
  }

  Widget _summaryCard(String label, String value, Color color) {
    return GlowCard(
      glowColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Text(value, style: tsTitle(color).copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: tsLabel()),
        ],
      ),
    );
  }

  Widget _statusBadge(ExpressionGene g) {
    Color color;
    String label;
    if (g.isDEG && g.isUpregulated) {
      color = kNeonGreen; label = 'UP';
    } else if (g.isDEG && g.isDownregulated) {
      color = kNeonRed; label = 'DOWN';
    } else if (g.isSignificant) {
      color = kNeonAmber; label = 'SIG';
    } else {
      color = kTextMuted; label = 'NS';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: tsBadge().copyWith(color: color)),
    );
  }

  String _formatPval(double p) {
    if (p < 0.001) return p.toStringAsExponential(1);
    return p.toStringAsFixed(4);
  }
}
