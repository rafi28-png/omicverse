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
import 'services/genome_service.dart';

enum _ScreenState { idle, searching, results, detail, error }

class GenomeScreen extends ConsumerStatefulWidget {
  const GenomeScreen({super.key});

  @override
  ConsumerState<GenomeScreen> createState() => _GenomeScreenState();
}

class _GenomeScreenState extends ConsumerState<GenomeScreen> {
  _ScreenState _state = _ScreenState.idle;
  String? _error;
  List<GeneInfo> _results = [];
  GeneInfo? _selectedGene;
  String? _sequence;
  bool _loadingSequence = false;
  final _searchCtrl = TextEditingController();
  String _selectedGenome = 'GRCh38';

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
      List<GeneInfo> results;
      results = await GenomeService.searchGene(q, assembly: _selectedGenome);

      setState(() {
        _results = results;
        _state = results.isEmpty ? _ScreenState.error : _ScreenState.results;
        if (results.isEmpty) _error = 'No genes found for "$q"';
      });
    } catch (e) {
      setState(() {
        _state = _ScreenState.error;
        _error = e.toString();
      });
    }
  }

  Future<void> _selectGene(GeneInfo gene) async {
    setState(() {
      _selectedGene = gene;
      _state = _ScreenState.detail;
    });
  }

  void _reset() {
    setState(() {
      _state = _ScreenState.idle;
      _results = [];
      _selectedGene = null;
      _sequence = null;
      _loadingSequence = false;
      _error = null;
    });
  }

  Future<void> _fetchSequence(GeneInfo gene) async {
    setState(() => _loadingSequence = true);
    // Limit to 10kb for display
    final seqEnd = gene.start + (gene.length > 10000 ? 10000 : gene.length);
    final seq = await GenomeService.fetchSequence(
      gene.chromosome, gene.start, seqEnd, assembly: _selectedGenome,
    );
    if (mounted) {
      setState(() {
        _sequence = seq;
        _loadingSequence = false;
      });
    }
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
        title: Text('Genome Browser', style: tsTitle(kTextPrimary)),
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
                  title: 'Genome Browser',
                  subtitle: 'Gene search & annotation via Ensembl',
                  gradientColors: kGradGenome,
                  icon: Icons.biotech,
                  isDemoMode: isDemoMode,
                ),
                const SizedBox(height: 24),

                // Search bar
                _buildSearchBar(),
                const SizedBox(height: 16),

                // Genome selector
                _buildGenomeSelector(),
                const SizedBox(height: 24),

                // Body
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
              hintText: 'Search gene (e.g. TP53, BRCA1, EGFR)',
              hintStyle: tsBody().copyWith(color: kTextMuted),
              prefixIcon: const Icon(Icons.search, color: kNeonTeal, size: 20),
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kNeonTeal),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: tsBody(),
            onSubmitted: (_) => _search(),
          ),
        ),
        const SizedBox(width: 12),
        NeonButton(
          label: 'Search',
          icon: Icons.search,
          color: kNeonTeal,
          onPressed: _search,
        ),
      ],
    );
  }

  Widget _buildGenomeSelector() {
    return Row(
      children: [
        Text('Assembly:', style: tsLabel()),
        const SizedBox(width: 12),
        ...['GRCh38', 'GRCh37'].map((g) {
          final selected = _selectedGenome == g;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(g, style: tsBadge().copyWith(
                color: selected ? kVoid : kTextSecondary,
              )),
              selected: selected,
              selectedColor: kNeonTeal,
              backgroundColor: kSurface,
              side: BorderSide(color: selected ? kNeonTeal : kBorder),
              onSelected: (_) => setState(() => _selectedGenome = g),
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
        return const Center(child: DnaLoader(message: 'Searching genes...'));
      case _ScreenState.results:
        return _buildResultsList();
      case _ScreenState.detail:
        return _buildGeneDetail();
      case _ScreenState.error:
        return ErrorState(message: _error ?? 'Unknown error', onRetry: _reset);
    }
  }

  Widget _buildIdleState() {
    return GlowCard(
      glowColor: kNeonTeal,
      child: Column(
        children: [
          Icon(Icons.biotech, color: kNeonTeal.withValues(alpha: 0.5), size: 48),
          const SizedBox(height: 16),
          Text('Search for a gene', style: tsTitle(kTextSecondary)),
          const SizedBox(height: 8),
          Text(
            'Enter a gene symbol (e.g. TP53) or Ensembl ID to view gene information, '
            'location, and functional annotation.',
            style: tsBody().copyWith(color: kTextMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text('Try: TP53, BRCA1, EGFR, BRAF, KRAS', style: tsMono().copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${_results.length} results', style: tsSubtitle()),
            const Spacer(),
            NeonButton(
              label: 'Clear',
              icon: Icons.clear,
              color: kTextMuted,
              onPressed: _reset,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_results.length, (i) {
          final gene = _results[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlowCard(
              glowColor: kGradGenome[0],
              onTap: () => _selectGene(gene),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kNeonTeal.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(gene.symbol.isNotEmpty ? gene.symbol[0] : '?',
                        style: tsTitle(kNeonTeal)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(gene.symbol, style: tsTitle(kTextPrimary).copyWith(fontSize: 16)),
                        Text(gene.description, style: tsBody().copyWith(fontSize: 12, color: kTextSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(gene.location, style: tsMono().copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  _biotypeChip(gene.biotype),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: kTextMuted),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGeneDetail() {
    final gene = _selectedGene!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        TextButton.icon(
          onPressed: () => setState(() => _state = _ScreenState.results),
          icon: const Icon(Icons.arrow_back, size: 16, color: kNeonTeal),
          label: Text('Back to results', style: tsBody().copyWith(color: kNeonTeal)),
        ),
        const SizedBox(height: 8),

        // Gene header
        GlowCard(
          glowColor: kGradGenome[0],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(gene.symbol, style: tsTitle(kNeonTeal).copyWith(fontSize: 28)),
                  const SizedBox(width: 12),
                  _biotypeChip(gene.biotype),
                ],
              ),
              const SizedBox(height: 4),
              Text(gene.description, style: tsBody().copyWith(color: kTextSecondary)),
              const SizedBox(height: 12),
              Text(gene.ensemblId, style: tsMono()),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Details grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _detailCard('Chromosome', 'chr${gene.chromosome}', kNeonTeal),
            _detailCard('Start', '${gene.start}', kNeonBlue),
            _detailCard('End', '${gene.end}', kNeonBlue),
            _detailCard('Strand', gene.strandLabel, kNeonPurple),
            _detailCard('Length', '${(gene.length / 1000).toStringAsFixed(1)} kb', kNeonAmber),
            _detailCard('Assembly', gene.assembly, kNeonGreen),
          ],
        ),
        const SizedBox(height: 16),

        // Action buttons
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            NeonButton(
              label: _loadingSequence ? 'Loading...' : (_sequence != null ? 'Reload Sequence' : 'Fetch Sequence'),
              icon: Icons.code,
              color: kNeonBlue,
              onPressed: _loadingSequence ? null : () => _fetchSequence(gene),
            ),
            NeonButton(
              label: 'View in Ensembl',
              icon: Icons.open_in_new,
              color: kNeonGreen,
              onPressed: () {
                // Opens Ensembl gene page
              },
            ),
            NeonButton(
              label: 'New Search',
              icon: Icons.search,
              color: kNeonTeal,
              onPressed: _reset,
            ),
          ],
        ),

        // Sequence viewer
        if (_loadingSequence) ...[
          const SizedBox(height: 16),
          const Center(child: DnaLoader(message: 'Fetching sequence...')),
        ] else if (_sequence != null) ...[
          const SizedBox(height: 16),
          GlowCard(
            glowColor: kNeonBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Genomic Sequence', style: tsSubtitle()),
                    const Spacer(),
                    Text(
                      '${_sequence!.length} bp${gene.length > 10000 ? ' (first 10kb)' : ''}',
                      style: tsMono().copyWith(fontSize: 11, color: kTextMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kVoid,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorder),
                  ),
                  child: SelectableText(
                    _formatSequence(_sequence!),
                    style: tsMono().copyWith(fontSize: 11, letterSpacing: 1.5, height: 1.6),
                    maxLines: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _seqStat('GC Content', _gcContent(_sequence!)),
                    const SizedBox(width: 16),
                    _seqStat('A', _baseCount(_sequence!, 'A')),
                    const SizedBox(width: 16),
                    _seqStat('T', _baseCount(_sequence!, 'T')),
                    const SizedBox(width: 16),
                    _seqStat('G', _baseCount(_sequence!, 'G')),
                    const SizedBox(width: 16),
                    _seqStat('C', _baseCount(_sequence!, 'C')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _biotypeChip(String biotype) {
    final color = biotype == 'protein_coding' ? kNeonGreen : kNeonAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        biotype.replaceAll('_', ' '),
        style: tsBadge().copyWith(color: color),
      ),
    );
  }

  Widget _detailCard(String label, String value, Color color) {
    return GlowCard(
      glowColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Text(value, style: tsTitle(color).copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: tsLabel()),
        ],
      ),
    );
  }

  String _formatSequence(String seq) {
    final buf = StringBuffer();
    for (int i = 0; i < seq.length; i += 60) {
      final end = (i + 60) > seq.length ? seq.length : i + 60;
      buf.writeln(seq.substring(i, end));
    }
    return buf.toString().trimRight();
  }

  String _gcContent(String seq) {
    if (seq.isEmpty) return '0%';
    final upper = seq.toUpperCase();
    final gc = upper.split('').where((c) => c == 'G' || c == 'C').length;
    return '${(gc / upper.length * 100).toStringAsFixed(1)}%';
  }

  String _baseCount(String seq, String base) {
    final count = seq.toUpperCase().split('').where((c) => c == base).length;
    return '$count (${(count / seq.length * 100).toStringAsFixed(1)}%)';
  }

  Widget _seqStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tsBadge().copyWith(color: kTextMuted)),
        Text(value, style: tsMono().copyWith(fontSize: 11)),
      ],
    );
  }
}
