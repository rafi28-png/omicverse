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
  /// Uses the 'create-user' Edge Function as the primary path (bypasses GoTrue
  /// email-send rate limits entirely). Falls back to standard auth.signUp if
  /// the function has not been deployed yet.
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

    // ── Primary path: Edge Function (no rate-limits, instant confirmation) ──
    try {
      final fnResp = await client.functions.invoke(
        'create-user',
        body: {
          'email': email,
          'password': password,
          'name': name ?? '',
          'institution': institution ?? '',
        },
      );

      if (fnResp.status == 200) {
        // User created — sign in immediately to obtain a session token.
        return await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }

      // Edge function returned a non-200 (e.g. duplicate email).
      final errMsg = (fnResp.data as Map<String, dynamic>?)?['error']
          ?? 'Registration failed (status ${fnResp.status})';
      throw AuthException(errMsg.toString());
    } on AuthException {
      rethrow; // surface duplicate-email and similar business errors
    } catch (_) {
      // Edge function not deployed yet — fall back to standard GoTrue signup.
    }

    // ── Fallback: standard GoTrue signup (may hit rate-limits on free tier) ──
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (name != null) 'name': name,
        if (institution != null) 'institution': institution,
      },
    );
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
