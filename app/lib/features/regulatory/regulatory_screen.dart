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
import 'services/regulatory_service.dart';

enum _ScreenState { idle, searching, results, error }

class RegulatoryScreen extends ConsumerStatefulWidget {
  const RegulatoryScreen({super.key});

  @override
  ConsumerState<RegulatoryScreen> createState() => _RegulatoryScreenState();
}

class _RegulatoryScreenState extends ConsumerState<RegulatoryScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _error;
  List<RegulatoryElement> _elements = [];
  List<TranscriptionFactor> _tfs = [];
  final _searchCtrl = TextEditingController();
  String _filterType = 'all';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _state = _ScreenState.searching);
    try {
      _elements = await RegulatoryService.searchByGene(q);
      _tfs = await RegulatoryService.getTFsForGene(q);
      setState(() => _state = _elements.isEmpty && _tfs.isEmpty
        ? _ScreenState.idle : _ScreenState.results);
    } catch (e) {
      setState(() { _state = _ScreenState.error; _error = e.toString(); });
    }
  }

  void _reset() {
    setState(() { _state = _ScreenState.idle; _elements = []; _tfs = []; _error = null; });
  }

  List<RegulatoryElement> get _filtered {
    if (_filterType == 'all') return _elements;
    return _elements.where((e) =>
      e.type.toLowerCase().contains(_filterType.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('Regulatory Elements', style: tsTitle(kTextPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModuleHeader(title: 'Regulatory Elements',
                  subtitle: 'ENCODE cCREs & TF binding',
                  gradientColors: kGradRegulatory, icon: Icons.tune, isDemoMode: isDemoMode),
                const SizedBox(height: 24),
                _buildSearchBar(),
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

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search gene for regulatory elements (e.g. TP53)',
              hintStyle: tsBody().copyWith(color: kTextMuted),
              prefixIcon: const Icon(Icons.search, color: kNeonPink, size: 20),
              filled: true, fillColor: kSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kNeonPink)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: tsBody(), onSubmitted: (_) => _search(),
          ),
        ),
        const SizedBox(width: 12),
        NeonButton(label: 'Search', icon: Icons.search, color: kNeonPink, onPressed: _search),
      ],
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return GlowCard(glowColor: kNeonPink, child: Column(children: [
          Icon(Icons.tune, color: kNeonPink.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Search Regulatory Elements', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Enter a gene to find nearby ENCODE cis-regulatory elements (cCREs), '
            'promoters, enhancers, and TF binding sites.',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Try: TP53, BRCA1, EGFR', style: tsMono().copyWith(fontSize: 11)),
        ]));
      case _ScreenState.searching:
        return const Center(child: DnaLoader(message: 'Searching regulatory elements...'));
      case _ScreenState.results:
        return _buildResults();
      case _ScreenState.error:
        return ErrorState(message: _error ?? 'Error', onRetry: _reset);
    }
  }

  Widget _buildResults() {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Wrap(spacing: 12, runSpacing: 12, children: [
          _summaryCard('Elements', '${_elements.length}', kNeonPink),
          _summaryCard('Promoters', '${_elements.where((e) => e.type.contains("Promoter")).length}', kNeonGreen),
          _summaryCard('Enhancers', '${_elements.where((e) => e.type.contains("Enhancer")).length}', kNeonAmber),
          _summaryCard('CTCF', '${_elements.where((e) => e.type.contains("CTCF")).length}', kNeonBlue),
          _summaryCard('TFs', '${_tfs.length}', kNeonPurple),
        ]),
        const SizedBox(height: 16),

        // Filter chips
        Row(children: [
          Text('FILTER', style: tsLabel()), const SizedBox(width: 12),
          ...['all', 'Promoter', 'Enhancer', 'CTCF'].map((f) {
            final sel = _filterType == f;
            return Padding(padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f == 'all' ? 'All' : f, style: tsBadge().copyWith(
                  color: sel ? kVoid : kTextSecondary)),
                selected: sel, selectedColor: kNeonPink, backgroundColor: kSurface,
                side: BorderSide(color: sel ? kNeonPink : kBorder),
                onSelected: (_) => setState(() => _filterType = f)));
          }),
          const Spacer(),
          NeonButton(label: 'Clear', icon: Icons.clear, color: kTextMuted, onPressed: _reset),
        ]),
        const SizedBox(height: 16),

        // Elements table
        if (filtered.isNotEmpty) ...[
          Text('REGULATORY ELEMENTS', style: tsLabel()),
          const SizedBox(height: 8),
          ...filtered.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlowCard(
              glowColor: _typeColor(e.type),
              child: Row(children: [
                _typeBadge(e.type),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.id, style: tsMono().copyWith(fontSize: 12)),
                    Text(e.location, style: tsBody().copyWith(fontSize: 12, color: kTextSecondary)),
                  ],
                )),
                if (e.score != null)
                  Text('${(e.score! * 100).toInt()}%', style: tsBadge().copyWith(
                    color: e.score! > 0.9 ? kNeonGreen : kTextSecondary)),
                const SizedBox(width: 8),
                Text(e.source, style: tsLabel().copyWith(fontSize: 9)),
              ]),
            ),
          )),
        ],

        // TF binding
        if (_tfs.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('TRANSCRIPTION FACTOR BINDING', style: tsLabel()),
          const SizedBox(height: 8),
          GlowCard(glowColor: kNeonPurple, child: Column(
            children: _tfs.map((tf) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tf.score > 0.9 ? kNeonGreen : tf.score > 0.8 ? kNeonAmber : kNeonRed)),
                const SizedBox(width: 12),
                Text(tf.name, style: tsMono().copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text('→ ${tf.target}', style: tsBody().copyWith(fontSize: 12, color: kTextSecondary)),
                const Spacer(),
                Text(tf.cellType, style: tsLabel().copyWith(fontSize: 9)),
                const SizedBox(width: 8),
                Text('${(tf.score * 100).toInt()}%', style: tsBadge().copyWith(
                  color: tf.score > 0.9 ? kNeonGreen : kTextSecondary)),
              ]),
            )).toList(),
          )),
        ],
      ],
    );
  }

  Color _typeColor(String type) {
    if (type.contains('Promoter')) return kNeonGreen;
    if (type.contains('Enhancer')) return kNeonAmber;
    if (type.contains('CTCF')) return kNeonBlue;
    return kNeonPink;
  }

  Widget _typeBadge(String type) {
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(type, style: tsBadge().copyWith(color: color, fontSize: 9)),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return GlowCard(glowColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(children: [
        Text(value, style: tsTitle(color).copyWith(fontSize: 22)),
        const SizedBox(height: 4),
        Text(label, style: tsLabel()),
      ]));
  }
}
