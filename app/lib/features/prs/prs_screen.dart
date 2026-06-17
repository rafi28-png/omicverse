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
import 'services/prs_service.dart';

enum _ScreenState { idle, searching, results, detail, error }

class PrsScreen extends ConsumerStatefulWidget {
  const PrsScreen({super.key});
  @override
  ConsumerState<PrsScreen> createState() => _PrsScreenState();
}

class _PrsScreenState extends ConsumerState<PrsScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _error;
  List<PgsScore> _scores = [];
  PgsScore? _selected;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _state = _ScreenState.searching);
    try {
      final results = await PrsService.searchByTrait(q);
      setState(() {
        _scores = results;
        _state = results.isEmpty ? _ScreenState.idle : _ScreenState.results;
      });
    } catch (e) {
      setState(() { _state = _ScreenState.error; _error = e.toString(); });
    }
  }

  void _selectScore(PgsScore s) {
    setState(() { _selected = s; _state = _ScreenState.detail; });
  }

  void _reset() {
    setState(() { _state = _ScreenState.idle; _scores = []; _selected = null; _error = null; });
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('Polygenic Risk Scores', style: tsTitle(kTextPrimary))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: 'Polygenic Risk Scores',
              subtitle: 'PGS Catalog — genome-wide risk prediction',
              gradientColors: kGradPRS, icon: Icons.assessment, isDemoMode: isDemoMode),
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
          hintText: 'Search trait (e.g. breast cancer, diabetes, alzheimer)',
          hintStyle: tsBody().copyWith(color: kTextMuted),
          prefixIcon: const Icon(Icons.search, color: kNeonGold, size: 20),
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
          Icon(Icons.assessment, color: kNeonGold.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Search Polygenic Risk Scores', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Search the PGS Catalog for published polygenic risk scores by disease or trait.',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Try: cancer, diabetes, alzheimer, coronary', style: tsMono().copyWith(fontSize: 11)),
        ]));
      case _ScreenState.searching:
        return const Center(child: DnaLoader(message: 'Searching PGS Catalog...'));
      case _ScreenState.results:
        return _buildResults();
      case _ScreenState.detail:
        return _buildDetail();
      case _ScreenState.error:
        return ErrorState(message: _error ?? 'Error', onRetry: _reset);
    }
  }

  Widget _buildResults() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('${_scores.length} scores found', style: tsSubtitle()),
        const Spacer(),
        NeonButton(label: 'Clear', icon: Icons.clear, color: kTextMuted, onPressed: _reset),
      ]),
      const SizedBox(height: 12),
      ..._scores.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlowCard(glowColor: kGradPRS[0], onTap: () => _selectScore(s),
          child: Row(children: [
            Container(width: 50, height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(colors: kGradPRS,
                  begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Center(child: Text(s.pgsId.replaceAll('PGS', ''),
                style: tsMono().copyWith(fontSize: 10, color: kVoid, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.trait, style: tsBody().copyWith(fontWeight: FontWeight.w600)),
              Text(s.pgsId, style: tsMono().copyWith(fontSize: 11)),
              Row(children: [
                Text('${_formatVariantCount(s.variantCount)} variants',
                  style: tsLabel().copyWith(fontSize: 9)),
                if (s.performanceMetric != null) ...[
                  const SizedBox(width: 12),
                  Text('AUC: ${s.performanceMetric!.toStringAsFixed(2)}',
                    style: tsBadge().copyWith(color: kNeonGold)),
                ],
              ]),
            ])),
            const Icon(Icons.chevron_right, color: kTextMuted),
          ])),
      )),
    ]);
  }

  Widget _buildDetail() {
    final s = _selected!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextButton.icon(
        onPressed: () => setState(() => _state = _ScreenState.results),
        icon: const Icon(Icons.arrow_back, size: 16, color: kNeonGold),
        label: Text('Back', style: tsBody().copyWith(color: kNeonGold))),
      const SizedBox(height: 8),

      GlowCard(glowColor: kGradPRS[0], child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.trait, style: tsTitle(kNeonGold).copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text(s.name, style: tsBody().copyWith(color: kTextSecondary)),
          const SizedBox(height: 8),
          Text(s.pgsId, style: tsMono()),
        ])),
      const SizedBox(height: 12),

      Wrap(spacing: 12, runSpacing: 12, children: [
        _infoCard('Variants', _formatVariantCount(s.variantCount), kNeonGold),
        if (s.performanceMetric != null)
          _infoCard('AUC', s.performanceMetric!.toStringAsFixed(2), kNeonGreen),
        if (s.year != null)
          _infoCard('Year', '${s.year}', kNeonBlue),
        if (s.journal != null)
          _infoCard('Journal', s.journal!, kNeonPurple),
      ]),
      const SizedBox(height: 16),

      if (s.reportedTrait.isNotEmpty) ...[
        Text('REPORTED TRAIT', style: tsLabel()),
        const SizedBox(height: 8),
        GlowCard(glowColor: kNeonAmber, child: Text(s.reportedTrait, style: tsBody())),
        const SizedBox(height: 16),
      ],

      if (s.pubmedId != null) ...[
        Text('PUBLICATION', style: tsLabel()),
        const SizedBox(height: 8),
        GlowCard(glowColor: kNeonBlue, child: Row(children: [
          const Icon(Icons.article, color: kNeonBlue, size: 20),
          const SizedBox(width: 12),
          Text('PubMed: ${s.pubmedId}', style: tsMono()),
        ])),
        const SizedBox(height: 16),
      ],

      NeonButton(label: 'New Search', icon: Icons.search, color: kNeonGold, onPressed: _reset),
    ]);
  }

  Widget _infoCard(String label, String value, Color color) {
    return GlowCard(glowColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(children: [
        Text(value, style: tsTitle(color).copyWith(fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: tsLabel()),
      ]));
  }

  String _formatVariantCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return '$count';
  }
}
