import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/methylation/services/methylation_service.dart';

void main() {
  group('CpGSite', () {
    test('demo sites are valid', () {
      final sites = CpGSite.demoSites();
      expect(sites.length, 8);
      expect(sites[0].cpgId, startsWith('cg'));
      expect(sites[0].betaValue, isNotNull);
    });

    test('methylation status is correct', () {
      const hyper = CpGSite(cpgId: 'cg1', chromosome: '1', position: 100, betaValue: 0.85);
      expect(hyper.methylationStatus, 'Hypermethylated');

      const hypo = CpGSite(cpgId: 'cg2', chromosome: '1', position: 200, betaValue: 0.12);
      expect(hypo.methylationStatus, 'Hypomethylated');

      const mid = CpGSite(cpgId: 'cg3', chromosome: '1', position: 300, betaValue: 0.50);
      expect(mid.methylationStatus, 'Intermediate');

      const unknown = CpGSite(cpgId: 'cg4', chromosome: '1', position: 400);
      expect(unknown.methylationStatus, 'Unknown');
    });

    test('location format is correct', () {
      final s = CpGSite.demoSites()[0];
      expect(s.location, startsWith('chr'));
    });
  });

  group('MethylationService', () {
    test('analyzeMethylation counts correctly', () {
      final sites = CpGSite.demoSites();
      final stats = MethylationService.analyzeMethylation(sites);
      expect(stats['Hypermethylated'], greaterThan(0));
      expect(stats['Hypomethylated'], greaterThan(0));
      final total = stats.values.reduce((a, b) => a + b);
      expect(total, sites.length);
    });

    test('contextDistribution works', () {
      final sites = CpGSite.demoSites();
      final ctx = MethylationService.contextDistribution(sites);
      expect(ctx.keys, isNotEmpty);
      final total = ctx.values.reduce((a, b) => a + b);
      expect(total, sites.length);
    });

    test('calculateHorvathAge returns valid result', () async {
      final clock = await MethylationService.calculateHorvathAge(CpGSite.demoSites());
      expect(clock.predictedAge, greaterThan(0));
      expect(clock.cpgSitesUsed, greaterThan(0));
      expect(clock.totalCpgSites, 353);
    });

    test('Horvath demo is valid', () {
      final clock = HorvathClock.demo();
      expect(clock.predictedAge, 42.3);
      expect(clock.ageLabel, contains('42.3'));
    });
  });
}
