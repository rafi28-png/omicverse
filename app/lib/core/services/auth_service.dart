import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../navigation/app_navigator.dart';

class AuthService {
  static SupabaseClient get _sb => Supabase.instance.client;

  /// Call once in app init to monitor token refresh.
  static void setupTokenRefresh() {
    _sb.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) ctx.go('/login');
      }
    });
  }

  /// Handle deep link callback from OAuth.
  static Future<void> handleDeepLink(Uri uri) async {
    if (uri.scheme == 'io.supabase.omicverse') {
      await _sb.auth.getSessionFromUrl(uri);
    }
  }

  /// Sign up with email and password.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
    String? institution,
  }) async {
    return await _sb.auth.signUp(
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
    return await _sb.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out.
  static Future<void> signOut() async {
    await _sb.auth.signOut();
  }

  /// Get current user.
  static User? get currentUser => _sb.auth.currentUser;

  /// Check if logged in.
  static bool get isLoggedIn => _sb.auth.currentUser != null;

  /// Delete all user app data (GDPR) — uses auth.uid() internally in SQL.
  static Future<void> deleteAppData() async {
    await _sb.rpc('delete_user_data');
    await _sb.auth.signOut();
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) ctx.go('/login');
  }
}
