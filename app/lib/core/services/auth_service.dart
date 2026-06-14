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
  /// Sends a real confirmation email via the configured SMTP (Gmail).
  /// Returns the AuthResponse — caller should check [needsEmailVerification]
  /// on the returned user to decide whether to show the "check your inbox" UI.
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

    return await client.auth.signUp(
      email: email,
      password: password,
      // After the user clicks the confirmation link in their inbox,
      // Supabase redirects them back to the live app.
      emailRedirectTo: 'https://rafi28-png.github.io/omicverse/',
      data: {
        if (name != null) 'name': name,
        if (institution != null) 'institution': institution,
      },
    );
  }

  /// Returns true when a signup response has a user but the email is not
  /// yet confirmed — i.e. the user must click the link in their inbox.
  static bool needsEmailVerification(AuthResponse response) {
    final user = response.user;
    return user != null && user.emailConfirmedAt == null;
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
