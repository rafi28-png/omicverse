import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Supported file types for upload
enum FileType {
  vcf('.vcf', 'VCF (Variant Call Format)'),
  vcfGz('.vcf.gz', 'Compressed VCF'),
  csv('.csv', 'CSV (Comma-Separated Values)'),
  tsv('.tsv', 'TSV (Tab-Separated Values)'),
  txt('.txt', 'Plain Text'),
  bed('.bed', 'BED (Browser Extensible Data)'),
  fasta('.fasta', 'FASTA Sequence'),
  fa('.fa', 'FASTA Sequence'),
  fastq('.fastq', 'FASTQ Sequence');

  final String extension;
  final String description;
  const FileType(this.extension, this.description);
}

class FileValidationResult {
  final bool isValid;
  final String? error;
  final String filename;
  final int sizeBytes;
  final FileType? detectedType;
  final bool isBgzf;
  final bool sizeWarning;

  const FileValidationResult({
    required this.isValid,
    this.error,
    required this.filename,
    required this.sizeBytes,
    this.detectedType,
    this.isBgzf = false,
    this.sizeWarning = false,
  });
}

class FileValidator {
  // Platform size limits
  static const int webMaxBytes = 50 * 1024 * 1024;       // 50 MB
  static const int mobileWarnBytes = 10 * 1024 * 1024;    // 10 MB
  static const int absoluteMaxBytes = 200 * 1024 * 1024;  // 200 MB hard limit

  /// Allowed extensions per module
  static const Map<String, List<String>> moduleExtensions = {
    'variant': ['.vcf', '.vcf.gz'],
    'expression': ['.csv', '.tsv', '.txt'],
    'methylation': ['.csv', '.tsv', '.txt'],
    'genome': ['.bed', '.csv', '.tsv'],
    'crispr': ['.fasta', '.fa', '.txt'],
  };

  /// Validate a file before reading its contents
  static FileValidationResult validate({
    required String filename,
    required int sizeBytes,
    Uint8List? headerBytes,
    String? module,
  }) {
    // Empty file check
    if (sizeBytes == 0) {
      return FileValidationResult(
        isValid: false,
        error: 'File is empty. Please select a valid file.',
        filename: filename,
        sizeBytes: sizeBytes,
      );
    }

    // Absolute size limit
    if (sizeBytes > absoluteMaxBytes) {
      return FileValidationResult(
        isValid: false,
        error: 'File is too large (${_formatSize(sizeBytes)}). '
            'Maximum allowed size is ${_formatSize(absoluteMaxBytes)}.',
        filename: filename,
        sizeBytes: sizeBytes,
      );
    }

    // Web platform limit
    if (kIsWeb && sizeBytes > webMaxBytes) {
      return FileValidationResult(
        isValid: false,
        error: 'File is too large for web (${_formatSize(sizeBytes)}). '
            'Maximum for web is ${_formatSize(webMaxBytes)}. '
            'Try the desktop or mobile app for larger files.',
        filename: filename,
        sizeBytes: sizeBytes,
      );
    }

    // Detect file type
    final detectedType = _detectFileType(filename);
    if (detectedType == null) {
      final ext = filename.contains('.') ? filename.substring(filename.lastIndexOf('.')) : 'none';
      return FileValidationResult(
        isValid: false,
        error: 'Unsupported file type ($ext). '
            'Accepted formats: ${FileType.values.map((t) => t.extension).join(", ")}',
        filename: filename,
        sizeBytes: sizeBytes,
      );
    }

    // Module-specific extension check
    if (module != null && moduleExtensions.containsKey(module)) {
      final allowed = moduleExtensions[module]!;
      if (!allowed.any((ext) => filename.toLowerCase().endsWith(ext))) {
        return FileValidationResult(
          isValid: false,
          error: 'This module expects ${allowed.join(" or ")} files, '
              'but got "$filename".',
          filename: filename,
          sizeBytes: sizeBytes,
          detectedType: detectedType,
        );
      }
    }

    // BGZF detection (check magic bytes if available)
    final isBgzf = headerBytes != null && _isBgzf(headerBytes);
    if (isBgzf) {
      return FileValidationResult(
        isValid: false,
        error: 'This file uses BGZF format (block gzip from samtools/bcftools). '
            'Please convert to plain VCF or standard gzip first:\n'
            '  bgzip -d yourfile.vcf.gz\n'
            'Then upload the resulting .vcf file.',
        filename: filename,
        sizeBytes: sizeBytes,
        detectedType: detectedType,
        isBgzf: true,
      );
    }

    // Mobile size warning (not an error, just a warning)
    final sizeWarning = !kIsWeb && sizeBytes > mobileWarnBytes;

    return FileValidationResult(
      isValid: true,
      filename: filename,
      sizeBytes: sizeBytes,
      detectedType: detectedType,
      sizeWarning: sizeWarning,
    );
  }

  /// Detect BGZF format by checking magic bytes
  static bool _isBgzf(Uint8List bytes) {
    if (bytes.length < 18) return false;
    return bytes[0] == 0x1F &&
        bytes[1] == 0x8B &&
        bytes[3] == 0x04 &&   // FEXTRA flag set
        bytes[10] == 0x42 &&  // 'B' - BGZF subfield ID
        bytes[11] == 0x43;    // 'C'
  }

  /// Detect file type from filename
  static FileType? _detectFileType(String filename) {
    final lower = filename.toLowerCase();
    // Check compound extensions first
    if (lower.endsWith('.vcf.gz')) return FileType.vcfGz;
    for (final type in FileType.values) {
      if (lower.endsWith(type.extension)) return type;
    }
    return null;
  }

  /// Format file size for display
  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
