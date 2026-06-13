import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/expression/services/expression_parser.dart';

Uint8List _toBytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('ExpressionParser', () {
    test('parses simple CSV with DESeq2 columns', () async {
      const csv = 'gene,log2FoldChange,pvalue,padj,baseMean\n'
          'TP53,2.5,0.001,0.01,500\n'
          'BRCA1,-1.8,0.0001,0.005,300\n'
          'EGFR,0.3,0.5,0.8,100\n';
      final result = await ExpressionParser.parse(_toBytes(csv), 'data.csv');
      expect(result.parsedRows, 3);
      expect(result.genes[0].gene, 'TP53');
      expect(result.genes[0].log2FoldChange, 2.5);
      expect(result.genes[0].isUpregulated, isTrue);
      expect(result.genes[0].isDEG, isTrue);
      expect(result.genes[1].isDownregulated, isTrue);
      expect(result.genes[2].isSignificant, isFalse);
      expect(result.detectedFormat, 'CSV');
    });

    test('parses TSV format', () async {
      const tsv = 'gene_name\tlogFC\tP.Value\tadj.P.Val\n'
          'MYC\t3.1\t0.0001\t0.001\n'
          'BCL2\t-2.0\t0.0005\t0.003\n';
      final result = await ExpressionParser.parse(_toBytes(tsv), 'data.tsv');
      expect(result.parsedRows, 2);
      expect(result.detectedFormat, 'TSV');
      expect(result.genes[0].gene, 'MYC');
      expect(result.upregulated, 1);
      expect(result.downregulated, 1);
    });

    test('handles quoted CSV fields', () async {
      const csv = '"gene","log2FoldChange","pvalue","padj"\n'
          '"TP53, tumor suppressor","2.5","0.001","0.01"\n';
      final result = await ExpressionParser.parse(_toBytes(csv), 'quoted.csv');
      expect(result.parsedRows, 1);
      expect(result.genes[0].gene, 'TP53, tumor suppressor');
    });

    test('throws on missing gene column', () async {
      const csv = 'ensembl_id,log2FoldChange,pvalue,padj\n'
          'ENSG123,2.5,0.001,0.01\n';
      expect(
        () => ExpressionParser.parse(_toBytes(csv), 'bad.csv'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on missing log2FC column', () async {
      const csv = 'gene,pvalue,padj\n'
          'TP53,0.001,0.01\n';
      expect(
        () => ExpressionParser.parse(_toBytes(csv), 'bad.csv'),
        throwsA(isA<Exception>()),
      );
    });

    test('handles NA values gracefully', () async {
      const csv = 'gene,log2FoldChange,pvalue,padj\n'
          'TP53,2.5,0.001,0.01\n'
          'NA,1.0,0.01,0.05\n'
          'BRCA1,NA,0.001,0.01\n';
      final result = await ExpressionParser.parse(_toBytes(csv), 'na.csv');
      // 'NA' gene and NA log2fc should be skipped
      expect(result.parsedRows, 1);
      expect(result.genes[0].gene, 'TP53');
    });

    test('handles empty file', () async {
      expect(
        () => ExpressionParser.parse(_toBytes(''), 'empty.csv'),
        throwsA(isA<Exception>()),
      );
    });

    test('counts DEGs correctly', () async {
      const csv = 'gene,log2FoldChange,pvalue,padj\n'
          'A,2.5,0.001,0.01\n'       // DEG up (FC>1, padj<0.05)
          'B,-1.5,0.001,0.01\n'      // DEG down
          'C,0.3,0.001,0.01\n'       // Significant but not DEG (FC<1)
          'D,2.0,0.5,0.8\n';        // Not significant
      final result = await ExpressionParser.parse(_toBytes(csv), 'degs.csv');
      expect(result.degs, 2);
      expect(result.upregulated, 2);  // A and C are significant + positive FC
      expect(result.downregulated, 1);
    });

    test('detects edgeR column names', () async {
      const csv = 'gene_symbol,logFC,PValue,FDR\n'
          'TP53,2.5,0.001,0.01\n';
      final result = await ExpressionParser.parse(_toBytes(csv), 'edger.csv');
      expect(result.parsedRows, 1);
      expect(result.genes[0].log2FoldChange, 2.5);
    });

    test('detects txt as TSV', () async {
      const txt = 'gene\tlog2FoldChange\tpvalue\tpadj\n'
          'TP53\t1.5\t0.001\t0.02\n';
      final result = await ExpressionParser.parse(_toBytes(txt), 'results.txt');
      expect(result.detectedFormat, 'TSV');
      expect(result.parsedRows, 1);
    });
  });
}
