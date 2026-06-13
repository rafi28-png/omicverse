import 'dart:collection';

class _Lim {
  final int n;
  final Duration w;
  const _Lim(this.n, this.w);
}

class RateLimiter {
  static final _q = <String, Queue<DateTime>>{};
  static final _lim = <String, _Lim>{
    'ensembl':        const _Lim(15, Duration(seconds: 1)),
    'ncbi':           const _Lim(3,  Duration(seconds: 1)),
    'ncbi_with_key':  const _Lim(10, Duration(seconds: 1)),
    'gnomad':         const _Lim(5,  Duration(seconds: 1)),
    'kegg':           const _Lim(5,  Duration(seconds: 1)),
    'string':         const _Lim(10, Duration(seconds: 1)),
    'uniprot':        const _Lim(10, Duration(seconds: 1)),
    'gtex':           const _Lim(5,  Duration(seconds: 1)),
    'clinicaltrials': const _Lim(10, Duration(seconds: 1)),
    'dgidb':          const _Lim(10, Duration(seconds: 1)),
    'chembl':         const _Lim(10, Duration(seconds: 1)),
    'ucsc':           const _Lim(5,  Duration(seconds: 1)),
    'pgs':            const _Lim(10, Duration(seconds: 1)),
    'gdc':            const _Lim(10, Duration(seconds: 1)),
    'alphafold':      const _Lim(5,  Duration(seconds: 1)),
    'default':        const _Lim(5,  Duration(seconds: 1)),
  };

  static Future<void> throttle(String service) async {
    final lim = _lim[service] ?? _lim['default']!;
    _q[service] ??= Queue<DateTime>();
    final queue = _q[service]!;
    final now = DateTime.now();
    while (queue.isNotEmpty && now.difference(queue.first) > lim.w) {
      queue.removeFirst();
    }
    if (queue.length >= lim.n) {
      final wait = queue.first.add(lim.w).difference(DateTime.now()).inMilliseconds;
      if (wait > 0) await Future.delayed(Duration(milliseconds: wait));
    }
    queue.addLast(DateTime.now());
  }

  /// Reset all rate limit queues (useful for testing)
  static void reset() => _q.clear();
}
