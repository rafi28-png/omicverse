import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Future<bool> isOffline() async {
    final results = await Connectivity().checkConnectivity();
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }

  static Future<bool> isOnline() async => !(await isOffline());
}
