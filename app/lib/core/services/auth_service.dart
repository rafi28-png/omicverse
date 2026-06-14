import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../navigation/app_navigator.dart';

class AuthService {
  static SupabaseClient? get _sb {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Call once in app init to monitor token refresh.
  static void setupTokenRefresh() {
    final client = _sb;
    if (client == null) return;
    client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) ctx.go('/login');
      }
    });
  }

  /// Handle deep link callback from OAuth.
  static Future<void> handleDeepLink(Uri uri) async {
    final client = _sb;
    if (client == null) return;
    if (uri.scheme == 'io.supabase.omicverse') {
      await client.auth.getSessionFromUrl(uri);
    }
  }

  /// Sign up with email and password.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
    String? institution,
  }) async {
    final client = _sb;
    if (client == null) {
      throw const AuthException('Supabase connection is not initialized. Please configure it in settings.');
    }
    try {
      // Bypasses GoTrue limits by directly inserting into auth.users (if the RPC is configured)
      await client.rpc('register_user_bypass', params: {
        'user_email': email,
        'user_password': password,
        'user_name': name ?? '',
        'user_institution': institution ?? '',
      });
      // Once created, sign in immediately to generate auth session cookies/tokens
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // If the function does not exist or fails, fall back to standard Supabase auth
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('does not exist') || errStr.contains('404')) {
        return await client.auth.signUp(
          email: email,
          password: password,
          data: {
            if (name != null) 'name': name,
            if (institution != null) 'institution': institution,
          },
        );
      }
      rethrow;
    }
  }

  /// Sign in with email and password.
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _sb;
    if (client == null) {
      throw const AuthException('Supabase connection is not initialized. Please configure it in settings.');
    }
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out.
  static Future<void> signOut() async {
    final client = _sb;
    if (client == null) return;
    await client.auth.signOut();
  }

  /// Get current user.
  static User? get currentUser {
    final client = _sb;
    if (client == null) return null;
    return client.auth.currentUser;
  }

  /// Check if logged in.
  static bool get isLoggedIn {
    final client = _sb;
    if (client == null) return false;
    return client.auth.currentUser != null;
  }

  /// Delete all user app data (GDPR) — uses auth.uid() internally in SQL.
  static Future<void> deleteAppData() async {
    final client = _sb;
    if (client == null) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) ctx.go('/login');
      return;
    }
    await client.rpc('delete_user_data');
    await client.auth.signOut();
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) ctx.go('/login');
  }
}
