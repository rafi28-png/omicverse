import 'package:hive_flutter/hive_flutter.dart';

/// Safe accessor for Hive boxes that never throws.
/// Returns null if the box isn't open (e.g. IndexedDB failed on web).
Box<dynamic>? safeBox(String name) {
  try {
    if (Hive.isBoxOpen(name)) return Hive.box<dynamic>(name);
  } catch (_) {}
  return null;
}

/// Read a value from a Hive box safely. Returns [defaultValue] on any error.
T safeRead<T>(String boxName, String key, T defaultValue) {
  try {
    final box = safeBox(boxName);
    if (box != null) return box.get(key, defaultValue: defaultValue) as T;
  } catch (_) {}
  return defaultValue;
}

/// Write a value to a Hive box safely. No-op if box isn't open.
void safeWrite(String boxName, String key, dynamic value) {
  try {
    final box = safeBox(boxName);
    box?.put(key, value);
  } catch (_) {}
}

/// Close all Hive boxes safely. No-op if Hive wasn't initialized.
Future<void> safeCloseHive() async {
  try { await Hive.close(); } catch (_) {}
}
