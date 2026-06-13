import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'services/vcf_parser.dart';
import 'services/variant_annotation_service.dart';

enum _ScreenState { upload, parsing, annotating, results, error }

class VariantScreen extends ConsumerStatefulWidget {
  const VariantScreen({super.key});

  @override
  ConsumerState<VariantScreen> createState() => _VariantScreenState();
}

class _VariantScreenState extends ConsumerState<VariantScreen> {
  _ScreenState _state = _ScreenState.upload;
  String? _error;
  VcfParseResult? _parseResult;
  List<AnnotatedVariant>? _annotated;
  String _selectedGenome = 'GRCh38';
  String _filterType = 'all'; // all, pass, rare, pathogenic

  Future<void> _pickFile() async {
    try {
      final file = await FileUploadService.pickAndValidate(
        module: 'variant',
        allowedExtensions: ['vcf', 'gz'],
      );
      if (file == null) return;

      setState(() => _state = _ScreenState.parsing);

      final result = await VcfParser.parse(file.bytes, file.filename);
      _parseResult = result;

      if (result.referenceGenome != 'unknown') {
        _selectedGenome = result.referenceGenome;
      }

      setState(() => _state = _ScreenState.annotating);

      // Only annotate first 50 variants for demo speed
      final toAnnotate = result.variants.take(50).toList();
      final isDemoMode = ref.read(isDemoModeProvider);
      _annotated = await VariantAnnotationService.annotate(toAnnotate, isDemoMode: isDemoMode);

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
      _parseResult = null;
      _annotated = null;
    });
  }

  Future<void> _loadSampleData() async {
    setState(() => _state = _ScreenState.parsing);
    await Future.delayed(const Duration(milliseconds: 600));
    const sampleVcf = '##fileformat=VCFv4.2\n'
        '##reference=GRCh38\n'
        '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n'
        '17\t7673802\t.\tA\tG\t100\tPASS\t.\n'
        '17\t7674220\t.\tC\tT\t100\tPASS\t.\n'
        '13\t32315474\t.\tT\tG\t100\tPASS\t.\n'
        '7\t55181378\t.\tG\tA\t100\tPASS\t.\n'
        '1\t43350284\t.\tC\tT\t100\tPASS\t.\n';

    try {
      final bytes = Uint8List.fromList(utf8.encode(sampleVcf));
      final result = await VcfParser.parse(bytes, 'sample.vcf');
      _parseResult = result;
      _selectedGenome = result.referenceGenome;

      setState(() => _state = _ScreenState.annotating);
      final toAnnotate = result.variants.take(50).toList();
      final isDemoMode = ref.read(isDemoModeProvider);
      _annotated = await VariantAnnotationService.annotate(toAnnotate, isDemoMode: isDemoMode);

      setState(() => _state = _ScreenState.results);
    } catch (e) {
      setState(() {
        _state = _ScreenState.error;
        _error = e.toString();
      });
    }
  }

  List<AnnotatedVariant> get _filteredVariants {
    if (_annotated == null) return [];
    switch (_filterType) {
      case 'pass':
        return _annotated!.where((v) => v.variant.filter == 'PASS').toList();
      case 'rare':
        return _annotated!.where((v) => v.isRare).toList();
      case 'pathogenic':
        return _annotated!.where((v) => v.isPathogenic).toList();
      default:
        return _annotated!;
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
        title: Text('Variant Analysis', style: tsTitle(kTextPrimary)),
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
                  title: 'Variant Analysis',
                  subtitle: 'VCF parsing & annotation',
                  gradientColors: kGradVariant,
                  icon: Icons.compare_arrows,
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
        return _buildUpload();
      case _ScreenState.parsing:
        return const Center(
          child: DnaLoader(message: 'Parsing VCF file...'),
        );
      case _ScreenState.annotating:
        return Center(
          child: Column(
            children: [
              const DnaLoader(message: 'Annotating variants...'),
              const SizedBox(height: 16),
              if (_parseResult != null)
                Text(
                  '${_parseResult!.variantsParsed} variants found',
                  style: tsSubtitle(),
                ),
            ],
          ),
        );
      case _ScreenState.results:
        return _buildResults();
      case _ScreenState.error:
        return ErrorState(
          message: _error ?? 'Unknown error occurred',
          onRetry: _reset,
        );
    }
  }

  Widget _buildUpload() {
    return Column(
      children: [
        // Reference genome selector
        GlowCard(
          glowColor: kGradVariant[0],
          child: Row(
            children: [
              Text('Reference Genome:', style: tsBody()),
              const SizedBox(width: 16),
              ..._buildGenomeChips(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FileUploadZone(
          label: 'Upload VCF file',
          acceptedFormats: '.vcf, .vcf.gz',
          onTap: _pickFile,
        ),
        const SizedBox(height: 16),
        Text('OR', style: tsLabel().copyWith(color: kTextMuted)),
        const SizedBox(height: 16),
        NeonButton(
          label: 'Load Sample VCF (GRCh38)',
          icon: Icons.science_outlined,
          color: kNeonAmber,
          onPressed: _loadSampleData,
        ),
      ],
    );
  }

  List<Widget> _buildGenomeChips() {
    return ['GRCh38', 'GRCh37'].map((g) {
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
    }).toList();
  }

  Widget _buildResults() {
    final filtered = _filteredVariants;
    final result = _parseResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryCard('Total Parsed', '${result.variantsParsed}', kNeonTeal),
            _summaryCard('Genome', _selectedGenome, kNeonBlue),
            _summaryCard('PASS Only',
              '${_annotated!.where((v) => v.variant.filter == "PASS").length}',
              kNeonGreen),
            _summaryCard('Rare (<1%)',
              '${_annotated!.where((v) => v.isRare).length}',
              kNeonAmber),
            if (result.isTruncated)
              _summaryCard('Truncated',
                '${result.totalVariantsInFile} total',
                kNeonRed),
          ],
        ),
        const SizedBox(height: 20),

        // Filter bar
        Row(
          children: [
            Text('FILTER', style: tsLabel()),
            const SizedBox(width: 12),
            ..._buildFilterChips(),
            const Spacer(),
            NeonButton(
              label: 'New Analysis',
              icon: Icons.refresh,
              color: kNeonTeal,
              onPressed: _reset,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Variant table
        GlowCard(
          glowColor: kGradVariant[0],
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(kSurfaceRaised),
                dataRowColor: WidgetStateProperty.all(kSurface),
                columns: [
                  DataColumn(label: Text('Chr', style: tsLabel())),
                  DataColumn(label: Text('Pos', style: tsLabel())),
                  DataColumn(label: Text('Ref', style: tsLabel())),
                  DataColumn(label: Text('Alt', style: tsLabel())),
                  DataColumn(label: Text('Gene', style: tsLabel())),
                  DataColumn(label: Text('Consequence', style: tsLabel())),
                  DataColumn(label: Text('gnomAD Freq', style: tsLabel())),
                  DataColumn(label: Text('Filter', style: tsLabel())),
                ],
                rows: filtered.take(100).map((av) => DataRow(
                  cells: [
                    DataCell(Text(av.variant.chromosome, style: tsMono())),
                    DataCell(Text('${av.variant.position}', style: tsMono())),
                    DataCell(Text(av.variant.ref, style: tsMono().copyWith(
                      color: kNeonGreen))),
                    DataCell(Text(av.variant.alt, style: tsMono().copyWith(
                      color: kNeonRed))),
                    DataCell(Text(av.gene ?? '-', style: tsBody())),
                    DataCell(Text(av.consequence ?? '-', style: tsBody().copyWith(
                      fontSize: 11))),
                    DataCell(Text(av.frequencyDisplay, style: tsMono().copyWith(
                      color: av.isRare ? kNeonAmber : kTextSecondary))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: av.variant.filter == 'PASS'
                          ? kNeonGreen.withValues(alpha: 0.12)
                          : kNeonRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(av.variant.filter, style: tsBadge().copyWith(
                        color: av.variant.filter == 'PASS'
                          ? kNeonGreen : kNeonRed)),
                    )),
                  ],
                )).toList(),
              ),
            ),
          ),
        ),

        if (filtered.length > 100) ...[
          const SizedBox(height: 12),
          Text(
            'Showing first 100 of ${filtered.length} variants',
            style: tsSubtitle(),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildFilterChips() {
    final filters = {
      'all': 'All',
      'pass': 'PASS',
      'rare': 'Rare (<1%)',
      'pathogenic': 'Pathogenic',
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
          selectedColor: kGradVariant[0],
          backgroundColor: kSurface,
          side: BorderSide(color: selected ? kGradVariant[0] : kBorder),
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
}
