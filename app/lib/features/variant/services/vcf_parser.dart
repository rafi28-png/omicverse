import 'dart:isolate';
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';
import '../../../core/models/app_error.dart';
import '../../../core/services/chromosome_normalizer.dart';

class VcfVariant {
  final String chromosome;
  final int position;
  final String id;
  final String ref;
  final String alt;
  final String filter;
  final String info;
  const VcfVariant({
    required this.chromosome, required this.position, required this.id,
    required this.ref, required this.alt, required this.filter, required this.info,
  });
}

class VcfParseResult {
  final int totalVariantsInFile;
  final int variantsParsed;
  final bool isTruncated;
  final List<VcfVariant> variants;
  final String referenceGenome;
  const VcfParseResult({
    required this.totalVariantsInFile, required this.variantsParsed,
    required this.isTruncated, required this.variants, required this.referenceGenome,
  });
}

class VcfParser {
  static Future<VcfParseResult> parse(
    Uint8List bytes, String filename, {
    int maxVariants = 10000,
  }) async {
    return await Isolate.run(() => _parseSync(bytes, filename, maxVariants));
  }

  static VcfParseResult _parseSync(Uint8List bytes, String filename, int maxVariants) {
    Uint8List raw = bytes;

    if (filename.toLowerCase().endsWith('.gz') ||
        filename.toLowerCase().endsWith('.bgz')) {
      // FIX NEW-08: detect BGZF and reject clearly
      if (_isBgzf(bytes)) {
        throw const ValidationError(
          'This file uses BGZF format (block gzip used by samtools/bcftools). '
          'Please convert it to plain VCF or standard gzip first:\n'
          '  bgzip -d yourfile.vcf.gz\n'
          'Then upload the resulting .vcf file.');
      }
      try {
        raw = Uint8List.fromList(GZipDecoder().decodeBytes(bytes));
      } catch (_) {
        throw const ValidationError(
          'Could not decompress .vcf.gz file. '
          'Try converting to plain .vcf first and upload that.');
      }
    }

    final text = _utf8Decode(raw);
    final meta = <String>[];
    final variants = <VcfVariant>[];
    int totalLines = 0;

    for (final line in text.split('\n')) {
      if (line.isEmpty) continue;
      if (line.startsWith('##')) { meta.add(line); continue; }
      if (line.startsWith('#')) continue;
      totalLines++;
      if (variants.length >= maxVariants) continue;

      final f = line.split('\t');
      if (f.length < 5) continue;

      final chr = ChromosomeNormalizer.fromVcf(f[0]);
      if (!ChromosomeNormalizer.isValid(chr)) continue;

      final ref = f[3].trim();
      final alt = f[4].trim();
      if (ref.isEmpty || alt.isEmpty || alt == '.') continue;
      // Skip multi-allelic (comma in ALT)
      if (alt.contains(',')) continue;

      variants.add(VcfVariant(
        chromosome: chr,
        position: int.tryParse(f[1]) ?? 0,
        id: f.length > 2 && f[2] != '.' ? f[2] : '',
        ref: ref, alt: alt,
        filter: f.length > 6 ? f[6] : '.',
        info: f.length > 7 ? f[7] : '.',
      ));
    }

    return VcfParseResult(
      totalVariantsInFile: totalLines,
      variantsParsed: variants.length,
      isTruncated: variants.length >= maxVariants,
      variants: variants,
      referenceGenome: _detectRef(meta),
    );
  }

  // FIX NEW-08: reliable BGZF detection by checking magic bytes
  static bool _isBgzf(Uint8List bytes) {
    if (bytes.length < 18) return false;
    return bytes[0] == 0x1F &&
        bytes[1] == 0x8B &&
        bytes[3] == 0x04 &&   // FEXTRA flag set
        bytes[10] == 0x42 &&  // 'B' — BGZF subfield ID
        bytes[11] == 0x43;    // 'C'
  }

  static String _detectRef(List<String> meta) {
    for (final l in meta) {
      if (l.contains('38') || l.contains('hg38')) return 'GRCh38';
      if (l.contains('37') || l.contains('hg19')) return 'GRCh37';
    }
    return 'unknown';
  }

  static String _utf8Decode(Uint8List bytes) {
    try {
      return const Utf8Decoder().convert(bytes);
    } catch (_) {
      return const Utf8Decoder(allowMalformed: true).convert(bytes);
    }
  }
}
