// Direct API verification — tests REAL HTTP calls, not demo fallback
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Ensembl REST API — Real Verification', () {
    test('xrefs/symbol returns gene IDs for TP53', () async {
      final resp = await http.get(
        Uri.parse('https://rest.ensembl.org/xrefs/symbol/homo_sapiens/TP53?content-type=application/json'),
      );
      expect(resp.statusCode, 200, reason: 'Ensembl API should be reachable');
      final data = jsonDecode(resp.body) as List;
      expect(data.isNotEmpty, true, reason: 'Should return at least one xref');
      // Filter for gene IDs starting with ENSG
      final geneIds = data.where((item) => 
        (item['id'] as String).startsWith('ENSG')).toList();
      expect(geneIds.isNotEmpty, true, reason: 'Should have at least one ENSG ID');
      expect(geneIds[0]['id'], 'ENSG00000141510');
    });

    test('lookup/id returns gene metadata for ENSG00000141510 (TP53)', () async {
      final resp = await http.get(
        Uri.parse('https://rest.ensembl.org/lookup/id/ENSG00000141510?content-type=application/json'),
      );
      expect(resp.statusCode, 200);
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      
      // Verify all fields our code reads exist
      expect(data.containsKey('id'), true, reason: 'Missing id field');
      expect(data.containsKey('display_name'), true, reason: 'Missing display_name');
      expect(data.containsKey('description'), true, reason: 'Missing description');
      expect(data.containsKey('seq_region_name'), true, reason: 'Missing seq_region_name');
      expect(data.containsKey('start'), true, reason: 'Missing start');
      expect(data.containsKey('end'), true, reason: 'Missing end');
      expect(data.containsKey('strand'), true, reason: 'Missing strand');
      expect(data.containsKey('biotype'), true, reason: 'Missing biotype');
      expect(data.containsKey('assembly_name'), true, reason: 'Missing assembly_name');
      
      // Verify values
      expect(data['display_name'], 'TP53');
      expect(data['seq_region_name'], '17');
      expect(data['biotype'], 'protein_coding');
      expect(data['assembly_name'], 'GRCh38');
      expect(data['strand'], -1);
      
      // Verify types (our code casts as num then toInt)
      expect(data['start'] is num, true, reason: 'start should be num');
      expect(data['end'] is num, true, reason: 'end should be num');
      expect(data['strand'] is num, true, reason: 'strand should be num');
    });

    test('sequence/region returns DNA for TP53 first 100bp', () async {
      final resp = await http.get(
        Uri.parse('https://rest.ensembl.org/sequence/region/homo_sapiens/17:7661779..7661879:1?content-type=application/json'),
      );
      expect(resp.statusCode, 200);
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      
      expect(data.containsKey('seq'), true, reason: 'Missing seq field');
      final seq = data['seq'] as String;
      expect(seq.isNotEmpty, true, reason: 'Sequence should not be empty');
      expect(seq.length, greaterThanOrEqualTo(90), reason: 'Should return ~100bp');
      
      // Verify it's valid DNA (only ACGTN)
      final validBases = RegExp(r'^[ACGTNacgtn]+$');
      expect(validBases.hasMatch(seq), true, reason: 'Sequence should be valid DNA: $seq');
    });

    test('GRCh37 endpoint works', () async {
      final resp = await http.get(
        Uri.parse('https://grch37.rest.ensembl.org/xrefs/symbol/homo_sapiens/TP53?content-type=application/json'),
      );
      expect(resp.statusCode, 200);
      final data = jsonDecode(resp.body) as List;
      final geneIds = data.where((item) => 
        (item['id'] as String).startsWith('ENSG')).toList();
      expect(geneIds.isNotEmpty, true);
      expect(geneIds[0]['id'], 'ENSG00000141510');
    });

    test('GRCh37 lookup returns GRCh37 assembly', () async {
      final resp = await http.get(
        Uri.parse('https://grch37.rest.ensembl.org/lookup/id/ENSG00000141510?content-type=application/json'),
      );
      expect(resp.statusCode, 200);
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      expect(data['assembly_name'], 'GRCh37');
      expect(data['display_name'], 'TP53');
      // GRCh37 coordinates differ from GRCh38
      expect(data['seq_region_name'], '17');
    });

    test('nonexistent gene returns 400 or empty', () async {
      final resp = await http.get(
        Uri.parse('https://rest.ensembl.org/xrefs/symbol/homo_sapiens/ZZZZNOTAREALEGENE?content-type=application/json'),
      );
      // Ensembl returns 400 for invalid symbols
      expect([200, 400].contains(resp.statusCode), true);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        expect(data.isEmpty, true);
      }
    });

    test('BRCA1 lookup returns correct data', () async {
      final resp = await http.get(
        Uri.parse('https://rest.ensembl.org/xrefs/symbol/homo_sapiens/BRCA1?content-type=application/json'),
      );
      expect(resp.statusCode, 200);
      final data = jsonDecode(resp.body) as List;
      final geneIds = data.where((item) => 
        (item['id'] as String).startsWith('ENSG')).toList();
      expect(geneIds.isNotEmpty, true);
      expect(geneIds[0]['id'], 'ENSG00000012048');
    });

    test('description contains Source annotation that needs cleaning', () async {
      final resp = await http.get(
        Uri.parse('https://rest.ensembl.org/lookup/id/ENSG00000141510?content-type=application/json'),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final desc = data['description'] as String;
      
      // Verify our regex would clean it
      final cleaned = desc.replaceAll(RegExp(r'\s*\[Source:.*?\]'), '').trim();
      expect(cleaned.contains('[Source:'), false, reason: 'Cleaning should remove Source tag');
      expect(cleaned.isNotEmpty, true, reason: 'Cleaned description should not be empty');
      expect(cleaned, contains('tumor protein p53'));
    });
  });
}
