import 'dart:isolate';
import 'dart:typed_data';
import 'dart:convert';
import 'package:csv/csv.dart';
import '../../../core/models/app_error.dart';

class ExpressionGene {
  final String gene;
  final double log2FoldChange;
  final double pValue;
  final double adjustedPValue;
  final double? baseMean;

  const ExpressionGene({
    required this.gene,
    required this.log2FoldChange,
    required this.pValue,
    required this.adjustedPValue,
    this.baseMean,
  });

  bool get isUpregulated => log2FoldChange > 0 && adjustedPValue < 0.05;
  bool get isDownregulated => log2FoldChange < 0 && adjustedPValue < 0.05;
  bool get isSignificant => adjustedPValue < 0.05;
  bool get isHighFC => log2FoldChange.abs() > 1.0;
  bool get isDEG => isSignificant && isHighFC;

  String get regulationLabel {
    if (!isSignificant) return 'NS';
    if (isUpregulated) return 'Up';
    if (isDownregulated) return 'Down';
    return 'NS';
  }
}

class ExpressionParseResult {
  final List<ExpressionGene> genes;
  final int totalRows;
  final int parsedRows;
  final String? detectedFormat;

  const ExpressionParseResult({
    required this.genes,
    required this.totalRows,
    required this.parsedRows,
    this.detectedFormat,
  });

  int get upregulated => genes.where((g) => g.isUpregulated).length;
  int get downregulated => genes.where((g) => g.isDownregulated).length;
  int get degs => genes.where((g) => g.isDEG).length;
}

class ExpressionParser {
  /// Parse CSV/TSV expression data in an Isolate
  static Future<ExpressionParseResult> parse(
    Uint8List bytes,
    String filename,
  ) async {
    return await Isolate.run(() => _parseSync(bytes, filename));
  }

  static ExpressionParseResult _parseSync(Uint8List bytes, String filename) {
    final text = _utf8Decode(bytes);
    if (text.trim().isEmpty) {
      throw const ValidationError('File is empty.');
    }

    // Detect delimiter: TSV or CSV
    final isTsv = filename.toLowerCase().endsWith('.tsv') ||
        filename.toLowerCase().endsWith('.txt');
    final delimiter = isTsv ? '\t' : ',';

    // Use csv package for proper parsing (handles quoted fields)
    final converter = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers: false,
      allowInvalid: true,
    );
    final rows = converter.convert(text);

    if (rows.isEmpty) {
      throw const ValidationError('No data rows found in file.');
    }

    // Find header row and detect columns
    final header = rows[0].map((e) => e.toString().trim().toLowerCase()).toList();
    final colMap = _detectColumns(header);

    if (colMap['gene'] == null) {
      throw ValidationError(
        'Could not find a gene column. Expected one of: '
        'gene, gene_name, gene_symbol, Gene, symbol, geneid.\n'
        'Found columns: ${rows[0].join(", ")}');
    }
    if (colMap['log2fc'] == null) {
      throw ValidationError(
        'Could not find a log2 fold change column. Expected one of: '
        'log2FoldChange, log2FC, logFC, log2_fold_change.\n'
        'Found columns: ${rows[0].join(", ")}');
    }

    final genes = <ExpressionGene>[];
    int totalRows = 0;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      totalRows++;

      final gene = _getString(row, colMap['gene']!);
      if (gene.isEmpty || gene == 'NA' || gene == 'na') continue;

      final log2fc = _getDouble(row, colMap['log2fc']!);
      if (log2fc == null) continue;

      final pval = _getDouble(row, colMap['pvalue'] ?? -1) ?? 1.0;
      final padj = _getDouble(row, colMap['padj'] ?? colMap['pvalue'] ?? -1) ?? pval;
      final baseMean = _getDouble(row, colMap['basemean'] ?? -1);

      genes.add(ExpressionGene(
        gene: gene,
        log2FoldChange: log2fc,
        pValue: pval,
        adjustedPValue: padj,
        baseMean: baseMean,
      ));
    }

    return ExpressionParseResult(
      genes: genes,
      totalRows: totalRows,
      parsedRows: genes.length,
      detectedFormat: isTsv ? 'TSV' : 'CSV',
    );
  }

  /// Flexible column detection — matches common DESeq2/edgeR/limma outputs
  static Map<String, int?> _detectColumns(List<String> header) {
    final map = <String, int?>{
      'gene': null,
      'log2fc': null,
      'pvalue': null,
      'padj': null,
      'basemean': null,
    };

    final geneNames = ['gene', 'gene_name', 'gene_symbol', 'symbol', 'geneid',
      'gene_id', 'name', 'genes', 'id'];
    final fcNames = ['log2foldchange', 'log2fc', 'logfc', 'log2_fold_change',
      'fc', 'foldchange', 'fold_change', 'lfc'];
    final pNames = ['pvalue', 'p_value', 'pval', 'p.value', 'p'];
    final padjNames = ['padj', 'p_adj', 'adjusted_pvalue', 'adj_pvalue',
      'fdr', 'q_value', 'qvalue', 'adj.p.val', 'p.adj'];
    final bmNames = ['basemean', 'base_mean', 'averageexpression', 'aveexpr',
      'logcpm', 'rpkm', 'tpm', 'fpkm'];

    for (int i = 0; i < header.length; i++) {
      final h = header[i].replaceAll(RegExp(r'["\s]'), '').toLowerCase();
      if (map['gene'] == null && geneNames.contains(h)) map['gene'] = i;
      if (map['log2fc'] == null && fcNames.contains(h)) map['log2fc'] = i;
      if (map['pvalue'] == null && pNames.contains(h)) map['pvalue'] = i;
      if (map['padj'] == null && padjNames.contains(h)) map['padj'] = i;
      if (map['basemean'] == null && bmNames.contains(h)) map['basemean'] = i;
    }

    return map;
  }

  static String _getString(List<dynamic> row, int idx) {
    if (idx < 0 || idx >= row.length) return '';
    return row[idx].toString().trim();
  }

  static double? _getDouble(List<dynamic> row, int idx) {
    if (idx < 0 || idx >= row.length) return null;
    final s = row[idx].toString().trim();
    if (s.isEmpty || s == 'NA' || s == 'na' || s == 'NaN' || s == 'Inf' || s == '-Inf') {
      return null;
    }
    return double.tryParse(s);
  }

  static String _utf8Decode(Uint8List bytes) {
    try {
      return const Utf8Decoder().convert(bytes);
    } catch (_) {
      return const Utf8Decoder(allowMalformed: true).convert(bytes);
    }
  }
}
