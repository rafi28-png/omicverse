import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/splicing/services/splicing_service.dart';

void main() {
  group('SplicingEvent', () {
    test('demo events are valid', () {
      final events = SplicingEvent.demoEvents();
      expect(events.length, 8);
      expect(events[0].gene, 'TP53');
      expect(events[0].inclusionLevel, greaterThan(0));
    });

    test('type names resolve correctly', () {
      const se = SplicingEvent(gene: 'X', type: 'SE', exon: 'E1', inclusionLevel: 0.5);
      expect(se.typeName, 'Skipped Exon');

      const ri = SplicingEvent(gene: 'X', type: 'RI', exon: 'I1', inclusionLevel: 0.5);
      expect(ri.typeName, 'Retained Intron');

      const mxe = SplicingEvent(gene: 'X', type: 'MXE', exon: 'E2', inclusionLevel: 0.5);
      expect(mxe.typeName, 'Mutually Exclusive');
    });

    test('PSI label formats correctly', () {
      const e = SplicingEvent(gene: 'X', type: 'SE', exon: 'E1', inclusionLevel: 0.85);
      expect(e.psiLabel, '85%');
    });
  });

  group('Isoform', () {
    test('demo isoforms are valid', () {
      final isos = SplicingService.demoIsoforms('TP53');
      expect(isos.length, 5);
      expect(isos[0].isCanonical, isTrue);
      expect(isos[0].exonCount, 11);
    });

    test('canonical label is correct', () {
      final isos = SplicingService.demoIsoforms('TP53');
      expect(isos[0].label, contains('canonical'));
      expect(isos[1].label, isNot(contains('canonical')));
    });
  });

  group('SplicingService', () {
    test('eventTypeDistribution works', () {
      final events = SplicingEvent.demoEvents();
      final dist = SplicingService.eventTypeDistribution(events);
      expect(dist.keys, isNotEmpty);
      final total = dist.values.reduce((a, b) => a + b);
      expect(total, events.length);
    });

    test('getSplicingEvents filters by gene', () async {
      final events = await SplicingService.getSplicingEvents('TP53');
      expect(events, isNotEmpty);
      for (final e in events) {
        expect(e.gene, 'TP53');
      }
    });
  });
}
