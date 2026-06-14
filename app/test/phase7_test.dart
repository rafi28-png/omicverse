import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/variant/services/vcf_parser.dart';

Uint8List _toBytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('VcfParser', () {
    test('parses simple VCF', () async {
      const vcf = '##fileformat=VCFv4.2\n'
          '##reference=GRCh38\n'
          '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n'
          'chr17\t7675088\trs28934578\tG\tA\t100\tPASS\tDP=30\n'
          'chr13\t32936732\t.\tC\tT\t50\tPASS\tDP=20\n';
      final result = await VcfParser.parse(_toBytes(vcf), 'test.vcf');
      expect(result.variantsParsed, 2);
      expect(result.variants[0].chromosome, '17');
      expect(result.variants[0].ref, 'G');
      expect(result.variants[0].alt, 'A');
      expect(result.variants[0].filter, 'PASS');
      expect(result.referenceGenome, 'GRCh38');
    });

    test('detects GRCh37 reference', () async {
      const vcf = '##fileformat=VCFv4.1\n'
          '##reference=hg19\n'
          '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n'
          '1\t12345\t.\tA\tG\t99\tPASS\t.\n';
      final result = await VcfParser.parse(_toBytes(vcf), 'test.vcf');
      expect(result.referenceGenome, 'GRCh37');
    });

    test('skips invalid chromosomes', () async {
      const vcf = '##fileformat=VCFv4.2\n'
          '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n'
          'chrUn\t100\t.\tA\tG\t99\tPASS\t.\n'
          'chr1\t200\t.\tC\tT\t99\tPASS\t.\n';
      final result = await VcfParser.parse(_toBytes(vcf), 'test.vcf');
      expect(result.variantsParsed, 1);
      expect(result.variants[0].chromosome, '1');
    });

    test('skips multi-allelic variants', () async {
      const vcf = '##fileformat=VCFv4.2\n'
          '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n'
          'chr1\t100\t.\tA\tG,T\t99\tPASS\t.\n'
          'chr1\t200\t.\tC\tT\t99\tPASS\t.\n';
      final result = await VcfParser.parse(_toBytes(vcf), 'test.vcf');
      expect(result.variantsParsed, 1);
    });

    test('handles empty file gracefully', () async {
      final result = await VcfParser.parse(
        _toBytes('##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\n'),
        'empty.vcf',
      );
      expect(result.variantsParsed, 0);
      expect(result.variants, isEmpty);
    });

    test('handles malformed lines', () async {
      const vcf = '##fileformat=VCFv4.2\n'
          '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n'
          'chr1\t100\n'
          'garbage line\n'
          'chr1\t200\t.\tC\tT\t99\tPASS\t.\n';
      final result = await VcfParser.parse(_toBytes(vcf), 'bad.vcf');
      expect(result.variantsParsed, 1);
    });

    test('truncates at maxVariants', () async {
      final lines = StringBuffer('##fileformat=VCFv4.2\n'
          '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n');
      for (int i = 1; i <= 20; i++) {
        lines.write('chr1\t${i * 100}\t.\tA\tG\t99\tPASS\t.\n');
      }
      final result = await VcfParser.parse(
        _toBytes(lines.toString()), 'big.vcf', maxVariants: 10);
      expect(result.variantsParsed, 10);
      expect(result.isTruncated, isTrue);
      expect(result.totalVariantsInFile, 20);
    });

    test('rejects BGZF file', () async {
      final bgzf = Uint8List(100);
      bgzf[0] = 0x1F; bgzf[1] = 0x8B; bgzf[2] = 0x08;
      bgzf[3] = 0x04; bgzf[10] = 0x42; bgzf[11] = 0x43;
      expect(
        () => VcfParser.parse(bgzf, 'sample.vcf.gz'),
        throwsA(isA<Exception>()),
      );
    });

    test('normalizes chr prefix', () async {
      const vcf = '##fileformat=VCFv4.2\n'
          '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n'
          'chrX\t100\t.\tA\tG\t99\tPASS\t.\n';
      final result = await VcfParser.parse(_toBytes(vcf), 'test.vcf');
      expect(result.variants[0].chromosome, 'X');
    });
  });
}
