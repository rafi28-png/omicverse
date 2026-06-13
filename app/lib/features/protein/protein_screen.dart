import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/module_header.dart';
import '../../core/widgets/research_disclaimer.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/dna_loader.dart';
import '../../core/providers/app_providers.dart';
import 'services/protein_service.dart';

enum _ScreenState { idle, searching, results, detail, error }

class ProteinScreen extends ConsumerStatefulWidget {
  const ProteinScreen({super.key});

  @override
  ConsumerState<ProteinScreen> createState() => _ProteinScreenState();
}

class _ProteinScreenState extends ConsumerState<ProteinScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _error;
  List<ProteinInfo> _results = [];
  ProteinInfo? _selected;
  final _searchCtrl = TextEditingController();

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
      final results = isDemoMode
        ? ProteinInfo.demoProteins().where((p) =>
            p.gene.toLowerCase().contains(q.toLowerCase()) ||
            p.name.toLowerCase().contains(q.toLowerCase())
          ).toList()
        : await ProteinService.searchProtein(q);

      setState(() {
        _results = results;
        _state = results.isEmpty ? _ScreenState.idle : _ScreenState.results;
      });
    } catch (e) {
      setState(() { _state = _ScreenState.error; _error = e.toString(); });
    }
  }

  void _selectProtein(ProteinInfo p) {
    setState(() { _selected = p; _state = _ScreenState.detail; });
  }

  void _reset() {
    setState(() {
      _state = _ScreenState.idle; _results = [];
      _selected = null; _error = null;
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
        title: Text('Protein Explorer', style: tsTitle(kTextPrimary)),
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
                  title: 'Protein Explorer',
                  subtitle: 'UniProt & AlphaFold structure',
                  gradientColors: kGradProtein,
                  icon: Icons.view_in_ar,
                  isDemoMode: isDemoMode,
                ),
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
              hintText: 'Search protein (e.g. TP53, BRCA1, EGFR)',
              hintStyle: tsBody().copyWith(color: kTextMuted),
              prefixIcon: const Icon(Icons.search, color: kNeonBlue, size: 20),
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
                borderSide: const BorderSide(color: kNeonBlue),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: tsBody(),
            onSubmitted: (_) => _search(),
          ),
        ),
        const SizedBox(width: 12),
        NeonButton(label: 'Search', icon: Icons.search, color: kNeonBlue, onPressed: _search),
      ],
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.idle:
        return GlowCard(
          glowColor: kNeonBlue,
          child: Column(
            children: [
              Icon(Icons.view_in_ar, color: kNeonBlue.withValues(alpha: 0.5), size: 48),
              const SizedBox(height: 16),
              Text('Search Proteins', style: tsTitle(kTextSecondary)),
              const SizedBox(height: 8),
              Text('Enter a gene symbol to find protein structure, function, '
                'and UniProt annotations.',
                style: tsBody().copyWith(color: kTextMuted), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text('Try: TP53, BRCA1, EGFR, KRAS', style: tsMono().copyWith(fontSize: 11)),
            ],
          ),
        );
      case _ScreenState.searching:
        return const Center(child: DnaLoader(message: 'Searching proteins...'));
      case _ScreenState.results:
        return _buildResults();
      case _ScreenState.detail:
        return _buildDetail();
      case _ScreenState.error:
        return ErrorState(message: _error ?? 'Error', onRetry: _reset);
    }
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${_results.length} proteins found', style: tsSubtitle()),
            const Spacer(),
            NeonButton(label: 'Clear', icon: Icons.clear, color: kTextMuted, onPressed: _reset),
          ],
        ),
        const SizedBox(height: 12),
        ..._results.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlowCard(
            glowColor: kGradProtein[0],
            onTap: () => _selectProtein(p),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [kGradProtein[0], kGradProtein[1]]),
                  ),
                  child: Center(child: Text(p.gene.isNotEmpty ? p.gene[0] : '?',
                    style: tsTitle(kVoid).copyWith(fontSize: 18))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.gene, style: tsTitle(kTextPrimary).copyWith(fontSize: 16)),
                      Text(p.name, style: tsBody().copyWith(fontSize: 12, color: kTextSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${p.uniprotId} • ${p.length} aa', style: tsMono().copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: kTextMuted),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildDetail() {
    final p = _selected!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _state = _ScreenState.results),
          icon: const Icon(Icons.arrow_back, size: 16, color: kNeonBlue),
          label: Text('Back', style: tsBody().copyWith(color: kNeonBlue)),
        ),
        const SizedBox(height: 8),

        // Header card
        GlowCard(
          glowColor: kGradProtein[0],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(p.gene, style: tsTitle(kNeonBlue).copyWith(fontSize: 28)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kNeonBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(p.uniprotId, style: tsMono().copyWith(color: kNeonBlue, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(p.name, style: tsBody().copyWith(color: kTextSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Info cards
        Wrap(
          spacing: 12, runSpacing: 12,
          children: [
            _infoCard('Length', '${p.length} aa', kNeonBlue),
            _infoCard('Organism', p.organism, kNeonGreen),
            if (p.subcellularLocation.isNotEmpty)
              _infoCard('Location', p.subcellularLocation, kNeonPurple),
          ],
        ),
        const SizedBox(height: 16),

        // Function
        if (p.function.isNotEmpty) ...[
          Text('FUNCTION', style: tsLabel()),
          const SizedBox(height: 8),
          GlowCard(
            glowColor: kNeonTeal,
            child: Text(p.function, style: tsBody()),
          ),
          const SizedBox(height: 16),
        ],

        // Keywords
        if (p.keywords.isNotEmpty) ...[
          Text('KEYWORDS', style: tsLabel()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: p.keywords.map((k) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: Text(k, style: tsMono().copyWith(fontSize: 11)),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // AlphaFold link
        if (p.alphaFoldUrl != null) ...[
          Text('3D STRUCTURE', style: tsLabel()),
          const SizedBox(height: 8),
          GlowCard(
            glowColor: kNeonAmber,
            onTap: () => launchUrl(Uri.parse(p.alphaFoldUrl!)),
            child: Row(
              children: [
                const Icon(Icons.view_in_ar, color: kNeonAmber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AlphaFold Predicted Structure', style: tsBody().copyWith(fontWeight: FontWeight.w600)),
                      Text('Click to open interactive 3D model', style: tsBody().copyWith(fontSize: 11, color: kNeonAmber)),
                      const SizedBox(height: 4),
                      Text(p.alphaFoldUrl!, style: tsMono().copyWith(fontSize: 10, color: kTextMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new, color: kNeonAmber, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        NeonButton(label: 'New Search', icon: Icons.search, color: kNeonBlue, onPressed: _reset),
      ],
    );
  }

  Widget _infoCard(String label, String value, Color color) {
    return GlowCard(
      glowColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Text(value, style: tsTitle(color).copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: tsLabel()),
        ],
      ),
    );
  }
}
