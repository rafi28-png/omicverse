import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

// FIX NEW-15: increment this when cache data structure changes.
const int kCacheSchemaVersion = 1;

class CacheEntry {
  final String data;
  final DateTime expiresAt;
  CacheEntry({required this.data, required this.expiresAt});
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Map<String, dynamic> toJson() =>
    {'data': data, 'expiresAt': expiresAt.toIso8601String()};
  factory CacheEntry.fromJson(Map<String, dynamic> j) =>
    CacheEntry(data: j['data'] as String, expiresAt: DateTime.parse(j['expiresAt'] as String));
}

class CacheService {
  static const int maxEntries = 200;
  static final _mem = <String, CacheEntry>{};
  static late Box<dynamic> _hive;
  static late Box<dynamic> _prefs;

  static Future<void> init() async {
    _hive = Hive.box<dynamic>('cache');
    _prefs = Hive.box<dynamic>('preferences');

    // FIX NEW-15: clear cache if schema version changed
    final storedVersion = _prefs.get('cacheSchemaVersion', defaultValue: 0) as int;
    if (storedVersion < kCacheSchemaVersion) {
      await _hive.clear();
      await _prefs.put('cacheSchemaVersion', kCacheSchemaVersion);
    } else {
      await _cleanExpired();
    }
  }

  static String _key(String svc, String ep, Map<String, dynamic>? p) =>
    md5.convert(utf8.encode('$svc:$ep:${p?.toString() ?? ''}')).toString();

  static Future<String?> get(String svc, String ep, {Map<String, dynamic>? params}) async {
    final k = _key(svc, ep, params);
    final mem = _mem[k];
    if (mem != null && !mem.isExpired) return mem.data;
    final raw = _hive.get(k);
    if (raw != null) {
      try {
        final e = CacheEntry.fromJson(Map<String, dynamic>.from(jsonDecode(raw as String) as Map));
        if (!e.isExpired) { _mem[k] = e; return e.data; }
      } catch (_) { await _hive.delete(k); }
    }
    return null;
  }

  static Future<void> set(String svc, String ep, String data, {
    Map<String, dynamic>? params,
    Duration ttl = const Duration(hours: 24),
  }) async {
    final k = _key(svc, ep, params);
    final e = CacheEntry(data: data, expiresAt: DateTime.now().add(ttl));
    _mem[k] = e;
    if (_mem.length > maxEntries) _mem.remove(_mem.keys.first);
    await _hive.put(k, jsonEncode(e.toJson()));
  }

  static Future<void> clearAll() async { _mem.clear(); await _hive.clear(); }

  static Future<void> _cleanExpired() async {
    final del = <String>[];
    for (final k in _hive.keys) {
      try {
        final raw = _hive.get(k);
        if (raw != null) {
          final e = CacheEntry.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw as String) as Map));
          if (e.isExpired) del.add(k.toString());
        }
      } catch (_) { del.add(k.toString()); }
    }
    for (final k in del) {
      await _hive.delete(k);
    }
  }
}
