import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/core/services/file_validator.dart';

void main() {
  group('FileValidator', () {
    test('rejects empty file', () {
      final result = FileValidator.validate(
        filename: 'test.vcf',
        sizeBytes: 0,
      );
      expect(result.isValid, isFalse);
      expect(result.error, contains('empty'));
    });

    test('rejects file exceeding absolute max', () {
      final result = FileValidator.validate(
        filename: 'huge.vcf',
        sizeBytes: 300 * 1024 * 1024, // 300 MB
      );
      expect(result.isValid, isFalse);
      expect(result.error, contains('too large'));
    });

    test('rejects unsupported extension', () {
      final result = FileValidator.validate(
        filename: 'data.xlsx',
        sizeBytes: 1000,
      );
      expect(result.isValid, isFalse);
      expect(result.error, contains('Unsupported'));
    });

    test('rejects wrong extension for module', () {
      final result = FileValidator.validate(
        filename: 'data.csv',
        sizeBytes: 1000,
        module: 'variant',
      );
      expect(result.isValid, isFalse);
      expect(result.error, contains('.vcf'));
    });

    test('detects BGZF magic bytes', () {
      // BGZF magic: 1F 8B 08 04 ... then at 10-11: 42 43
      final bgzfHeader = Uint8List(20);
      bgzfHeader[0] = 0x1F;
      bgzfHeader[1] = 0x8B;
      bgzfHeader[2] = 0x08;
      bgzfHeader[3] = 0x04;
      bgzfHeader[10] = 0x42; // 'B'
      bgzfHeader[11] = 0x43; // 'C'

      final result = FileValidator.validate(
        filename: 'sample.vcf.gz',
        sizeBytes: 5000,
        headerBytes: bgzfHeader,
      );
      expect(result.isValid, isFalse);
      expect(result.isBgzf, isTrue);
      expect(result.error, contains('BGZF'));
      expect(result.error, contains('bgzip'));
    });

    test('accepts valid VCF file', () {
      final result = FileValidator.validate(
        filename: 'variants.vcf',
        sizeBytes: 5000,
        module: 'variant',
      );
      expect(result.isValid, isTrue);
      expect(result.error, isNull);
      expect(result.detectedType, FileType.vcf);
    });

    test('accepts valid VCF.GZ file without BGZF', () {
      // Normal gzip header (not BGZF)
      final gzipHeader = Uint8List(20);
      gzipHeader[0] = 0x1F;
      gzipHeader[1] = 0x8B;
      gzipHeader[2] = 0x08;
      gzipHeader[3] = 0x00; // No FEXTRA flag

      final result = FileValidator.validate(
        filename: 'variants.vcf.gz',
        sizeBytes: 5000,
        headerBytes: gzipHeader,
        module: 'variant',
      );
      expect(result.isValid, isTrue);
      expect(result.detectedType, FileType.vcfGz);
      expect(result.isBgzf, isFalse);
    });

    test('accepts CSV for expression module', () {
      final result = FileValidator.validate(
        filename: 'deseq2_results.csv',
        sizeBytes: 2000,
        module: 'expression',
      );
      expect(result.isValid, isTrue);
      expect(result.detectedType, FileType.csv);
    });

    test('accepts TSV for expression module', () {
      final result = FileValidator.validate(
        filename: 'counts.tsv',
        sizeBytes: 3000,
        module: 'expression',
      );
      expect(result.isValid, isTrue);
      expect(result.detectedType, FileType.tsv);
    });

    test('detects file type correctly for each extension', () {
      expect(
        FileValidator.validate(filename: 'a.vcf', sizeBytes: 1).detectedType,
        FileType.vcf,
      );
      expect(
        FileValidator.validate(filename: 'a.vcf.gz', sizeBytes: 1).detectedType,
        FileType.vcfGz,
      );
      expect(
        FileValidator.validate(filename: 'a.csv', sizeBytes: 1).detectedType,
        FileType.csv,
      );
      expect(
        FileValidator.validate(filename: 'a.tsv', sizeBytes: 1).detectedType,
        FileType.tsv,
      );
      expect(
        FileValidator.validate(filename: 'a.bed', sizeBytes: 1).detectedType,
        FileType.bed,
      );
      expect(
        FileValidator.validate(filename: 'a.fasta', sizeBytes: 1).detectedType,
        FileType.fasta,
      );
    });

    test('no file type detected returns null', () {
      final result = FileValidator.validate(
        filename: 'data.unknown',
        sizeBytes: 100,
      );
      expect(result.isValid, isFalse);
      expect(result.detectedType, isNull);
    });
  });
}
