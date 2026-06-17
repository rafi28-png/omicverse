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
import 'services/splicing_service.dart';

enum _ScreenState { idle, searching, results, error }

class SplicingScreen extends ConsumerStatefulWidget {
  const SplicingScreen({super.key});
  @override
  ConsumerState<SplicingScreen> createState() => _SplicingScreenState();
}

class _SplicingScreenState extends ConsumerState<SplicingScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _error;
  List<Isoform> _isoforms = [];
  List<SplicingEvent> _events = [];
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _search() async {
    final gene = _searchCtrl.text.trim().toUpperCase();
    if (gene.isEmpty) return;
    setState(() => _state = _ScreenState.searching);
    try {
      final isDemoMode = ref.read(isDemoModeProvider);
      _isoforms = await SplicingService.getIsoforms(gene);
      _events = await SplicingService.getSplicingEvents(gene);
      setState(() => _state = (_isoforms.isEmpty && _events.isEmpty)
        ? _ScreenState.idle : _ScreenState.results);
    } catch (e) {
      setState(() { _state = _ScreenState.error; _error = e.toString(); });
    }
  }

  void _reset() {
    setState(() { _state = _ScreenState.idle; _isoforms = []; _events = []; _error = null; });
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('Splicing Analysis', style: tsTitle(kTextPrimary))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: 'Alternative Splicing',
              subtitle: 'Isoforms & splicing event analysis',
              gradientColors: kGradSplicing, icon: Icons.call_split, isDemoMode: isDemoMode),
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
          hintText: 'Enter gene symbol (e.g. TP53, BRCA1, EGFR)',
          hintStyle: tsBody().copyWith(color: kTextMuted),
          prefixIcon: const Icon(Icons.call_split, color: kNeonPink, size: 20),
          filled: true, fillColor: kSurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kNeonPink)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        style: tsBody(), onSubmitted: (_) => _search())),
      const SizedBox(width: 12),
      NeonButton(label: 'Analyze', icon: Icons.call_split, color: kNeonPink, onPressed: _search),
    ]);
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return GlowCard(glowColor: kNeonPink, child: Column(children: [
          Icon(Icons.call_split, color: kNeonPink.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Analyze Splicing', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Enter a gene to view transcript isoforms, alternative splicing events, '
            'and exon inclusion levels (PSI).',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Try: TP53, BRCA1, EGFR, KRAS', style: tsMono().copyWith(fontSize: 11)),
        ]));
      case _ScreenState.searching:
        return const Center(child: DnaLoader(message: 'Analyzing splicing...'));
      case _ScreenState.results:
        return _buildResults();
      case _ScreenState.error:
        return ErrorState(message: _error ?? 'Error', onRetry: _reset);
    }
  }

  Widget _buildResults() {
    final canonical = _isoforms.where((i) => i.isCanonical).toList();
    final eventDist = SplicingService.eventTypeDistribution(_events);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Summary
      Wrap(spacing: 12, runSpacing: 12, children: [
        _summaryCard('Isoforms', '${_isoforms.length}', kNeonPink),
        _summaryCard('Canonical', '${canonical.length}', kNeonGreen),
        _summaryCard('Events', '${_events.length}', kNeonPurple),
        _summaryCard('Event Types', '${eventDist.keys.length}', kNeonAmber),
      ]),
      const SizedBox(height: 16),

      // Isoform visualization
      Text('TRANSCRIPT ISOFORMS', style: tsLabel()),
      const SizedBox(height: 8),
      ..._isoforms.map((iso) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlowCard(
          glowColor: iso.isCanonical ? kNeonGreen : kGradSplicing[0],
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(iso.transcriptId, style: tsMono().copyWith(
                fontWeight: iso.isCanonical ? FontWeight.w700 : FontWeight.w400)),
              if (iso.isCanonical) ...[
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: kNeonGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4)),
                  child: Text('CANONICAL', style: tsBadge().copyWith(color: kNeonGreen))),
              ],
              const Spacer(),
              if (iso.tpm != null)
                Text('${iso.tpm!.toStringAsFixed(1)} TPM', style: tsMono().copyWith(
                  fontSize: 11, color: iso.tpm! > 10 ? kNeonAmber : kTextSecondary)),
            ]),
            const SizedBox(height: 8),
            // Exon blocks visualization
            _buildExonBlocks(iso),
            const SizedBox(height: 6),
            Row(children: [
              Text('${iso.exonCount} exons', style: tsLabel()),
              const SizedBox(width: 12),
              Text('${iso.length} bp', style: tsLabel()),
              const SizedBox(width: 12),
              Text(iso.biotype.replaceAll('_', ' '), style: tsLabel().copyWith(
                color: iso.biotype == 'protein_coding' ? kNeonGreen : kNeonAmber)),
            ]),
          ]),
        ),
      )),
      const SizedBox(height: 16),

      // Splicing events
      if (_events.isNotEmpty) ...[
        Text('ALTERNATIVE SPLICING EVENTS', style: tsLabel()),
        const SizedBox(height: 8),
        ..._events.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlowCard(glowColor: _eventColor(e.type), child: Row(children: [
            Container(width: 50,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _eventColor(e.type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text(e.type, style: tsBadge().copyWith(
                color: _eventColor(e.type), fontSize: 11)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e.typeName} — ${e.exon}', style: tsBody().copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('Tissue: ${e.tissue}', style: tsLabel()),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(e.psiLabel, style: tsTitle(_psiColor(e.inclusionLevel)).copyWith(fontSize: 18)),
              Text('PSI', style: tsLabel()),
            ]),
          ])),
        )),
      ],
      const SizedBox(height: 12),
      NeonButton(label: 'New Analysis', icon: Icons.call_split, color: kNeonPink, onPressed: _reset),
    ]);
  }

  Widget _buildExonBlocks(Isoform iso) {
    return SizedBox(height: 16,
      child: Row(children: List.generate(iso.exonCount, (i) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: iso.isCanonical ? kNeonGreen.withValues(alpha: 0.4) : kNeonPink.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: iso.isCanonical ? kNeonGreen : kNeonPink, width: 0.5)),
        ),
      ))),
    );
  }

  Color _eventColor(String type) {
    const colors = {'SE': kNeonPink, 'A5SS': kNeonPurple, 'A3SS': kNeonBlue,
      'MXE': kNeonAmber, 'RI': kNeonGreen};
    return colors[type] ?? kTextMuted;
  }

  Color _psiColor(double psi) {
    if (psi >= 0.7) return kNeonGreen;
    if (psi >= 0.3) return kNeonAmber;
    return kNeonRed;
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
