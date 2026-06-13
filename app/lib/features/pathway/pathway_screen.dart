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
import 'services/pathway_service.dart';

enum _ScreenState { idle, searching, results, detail, error }

class PathwayScreen extends ConsumerStatefulWidget {
  const PathwayScreen({super.key});

  @override
  ConsumerState<PathwayScreen> createState() => _PathwayScreenState();
}

class _PathwayScreenState extends ConsumerState<PathwayScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _error;
  List<PathwayInfo> _pathways = [];
  PathwayInfo? _selected;
  List<InteractionPartner> _interactions = [];
  final _searchCtrl = TextEditingController();
  String _searchMode = 'pathway'; // pathway or gene

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() => _state = _ScreenState.searching);

    try {
      final isDemoMode = ref.read(isDemoModeProvider);
      List<PathwayInfo> results;

      if (isDemoMode || _searchMode == 'gene') {
        if (_searchMode == 'gene') {
          results = isDemoMode
            ? PathwayInfo.demoPathways().where((p) =>
                p.genes.any((g) => g.toLowerCase() == q.toLowerCase())).toList()
            : await PathwayService.pathwaysForGene(q);

          // Also fetch interactions
          _interactions = await PathwayService.getInteractions(q);
        } else {
          results = PathwayInfo.demoPathways().where((p) =>
            p.name.toLowerCase().contains(q.toLowerCase()) ||
            p.description.toLowerCase().contains(q.toLowerCase())
          ).toList();
        }
      } else {
        results = await PathwayService.searchPathways(q);
      }

      setState(() {
        _pathways = results;
        _state = results.isEmpty ? _ScreenState.idle : _ScreenState.results;
      });
    } catch (e) {
      setState(() { _state = _ScreenState.error; _error = e.toString(); });
    }
  }

  void _selectPathway(PathwayInfo pw) {
    setState(() { _selected = pw; _state = _ScreenState.detail; });
  }

  void _reset() {
    setState(() {
      _state = _ScreenState.idle;
      _pathways = [];
      _selected = null;
      _interactions = [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Pathway Analysis', style: tsTitle(kTextPrimary)),
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
                  title: 'Pathway Analysis',
                  subtitle: 'KEGG pathways & STRING interactions',
                  gradientColors: kGradPathway,
                  icon: Icons.account_tree,
                  isDemoMode: isDemoMode,
                ),
                const SizedBox(height: 24),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildModeSelector(),
                const SizedBox(height: 24),
                _buildBody(),
                const SizedBox(height: 16),
                // KEGG attribution (Section 18)
                GlowCard(
                  glowColor: kNeonAmber,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: kNeonAmber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pathway data from KEGG (Kanehisa Laboratories). '
                          'For non-commercial academic use. kegg.jp',
                          style: tsBody().copyWith(fontSize: 11, color: kTextMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
              hintText: _searchMode == 'pathway'
                ? 'Search pathway (e.g. cell cycle, apoptosis)'
                : 'Search gene (e.g. TP53, KRAS)',
              hintStyle: tsBody().copyWith(color: kTextMuted),
              prefixIcon: const Icon(Icons.search, color: kNeonPurple, size: 20),
              filled: true, fillColor: kSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kNeonPurple),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: tsBody(),
            onSubmitted: (_) => _search(),
          ),
        ),
        const SizedBox(width: 12),
        NeonButton(label: 'Search', icon: Icons.search, color: kNeonPurple, onPressed: _search),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Text('Search by:', style: tsLabel()),
        const SizedBox(width: 12),
        ...['pathway', 'gene'].map((m) {
          final sel = _searchMode == m;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(m[0].toUpperCase() + m.substring(1), style: tsBadge().copyWith(
                color: sel ? kVoid : kTextSecondary)),
              selected: sel,
              selectedColor: kNeonPurple,
              backgroundColor: kSurface,
              side: BorderSide(color: sel ? kNeonPurple : kBorder),
              onSelected: (_) => setState(() => _searchMode = m),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return _buildIdleState();
      case _ScreenState.searching:
        return const Center(child: DnaLoader(message: 'Searching pathways...'));
      case _ScreenState.results:
        return _buildResultsList();
      case _ScreenState.detail:
        return _buildDetail();
      case _ScreenState.error:
        return ErrorState(message: _error ?? 'Error', onRetry: _reset);
    }
  }

  Widget _buildIdleState() {
    return GlowCard(
      glowColor: kNeonPurple,
      child: Column(
        children: [
          Icon(Icons.account_tree, color: kNeonPurple.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Search Pathways', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text('Search by pathway name or gene symbol to find related KEGG pathways '
            'and STRING protein interactions.',
            style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Try: cell cycle, TP53, KRAS, apoptosis', style: tsMono().copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interactions (if gene search)
        if (_interactions.isNotEmpty) ...[
          Text('PROTEIN INTERACTIONS', style: tsLabel()),
          const SizedBox(height: 8),
          GlowCard(
            glowColor: kNeonBlue,
            child: Column(
              children: _interactions.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.score > 0.9 ? kNeonGreen : p.score > 0.7 ? kNeonAmber : kNeonRed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(p.gene, style: tsMono()),
                    const Spacer(),
                    Text('${(p.score * 100).toInt()}%', style: tsBadge().copyWith(
                      color: p.score > 0.9 ? kNeonGreen : kTextSecondary)),
                    const SizedBox(width: 8),
                    Text('STRING', style: tsLabel().copyWith(fontSize: 9)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Pathways
        Row(
          children: [
            Text('${_pathways.length} PATHWAYS', style: tsLabel()),
            const Spacer(),
            NeonButton(label: 'Clear', icon: Icons.clear, color: kTextMuted, onPressed: _reset),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_pathways.length, (i) {
          final pw = _pathways[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlowCard(
              glowColor: kGradPathway[0],
              onTap: () => _selectPathway(pw),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kNeonPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(pw.id, style: tsMono().copyWith(fontSize: 10, color: kNeonPurple)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pw.name, style: tsBody().copyWith(fontWeight: FontWeight.w600)),
                        if (pw.genes.isNotEmpty)
                          Text('${pw.genes.length} genes', style: tsLabel()),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: kTextMuted),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetail() {
    final pw = _selected!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _state = _ScreenState.results),
          icon: const Icon(Icons.arrow_back, size: 16, color: kNeonPurple),
          label: Text('Back', style: tsBody().copyWith(color: kNeonPurple)),
        ),
        const SizedBox(height: 8),
        GlowCard(
          glowColor: kGradPathway[0],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pw.name, style: tsTitle(kNeonPurple).copyWith(fontSize: 24)),
              const SizedBox(height: 4),
              Text(pw.description, style: tsBody().copyWith(color: kTextSecondary)),
              const SizedBox(height: 8),
              Text(pw.id, style: tsMono()),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (pw.genes.isNotEmpty) ...[
          Text('GENES IN PATHWAY', style: tsLabel()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pw.genes.map((g) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: Text(g, style: tsMono().copyWith(fontSize: 12)),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],

        NeonButton(label: 'New Search', icon: Icons.search, color: kNeonPurple, onPressed: _reset),
      ],
    );
  }
}
