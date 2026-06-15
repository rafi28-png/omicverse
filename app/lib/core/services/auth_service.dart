import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../navigation/app_navigator.dart';

/// Base URL for the live app — used in email redirect links.
const String _appBaseUrl = 'https://rafi28-png.github.io/omicverse/';

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

  // ─── SIGN UP ────────────────────────────────────────────────────────────────

  /// Sign up with email and password.
  /// Sends a real confirmation email via Gmail SMTP.
  /// Caller should check [needsEmailVerification] to show the "check inbox" UI.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
    String? institution,
  }) async {
    final client = _sb;
    if (client == null) {
      throw const AuthException('Supabase is not initialised. Please check your connection.');
    }
    return await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: _appBaseUrl,
      data: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (institution != null && institution.isNotEmpty) 'institution': institution,
      },
    );
  }

  /// Returns true when the user exists but email is not yet confirmed.
  static bool needsEmailVerification(AuthResponse response) {
    final user = response.user;
    return user != null && user.emailConfirmedAt == null;
  }

  /// Resend the email confirmation link.
  static Future<void> resendConfirmationEmail(String email) async {
    final client = _sb;
    if (client == null) throw const AuthException('Supabase is not initialised.');
    await client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: _appBaseUrl,
    );
  }

  // ─── PASSWORD RESET ─────────────────────────────────────────────────────────

  /// Send a password-reset link to [email].
  /// The link redirects back to the app at /reset-password.
  static Future<void> sendPasswordResetEmail(String email) async {
    final client = _sb;
    if (client == null) throw const AuthException('Supabase is not initialised.');
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: '${_appBaseUrl}reset-password',
    );
  }

  /// Update the currently signed-in user's password (used after password reset).
  static Future<void> updatePassword(String newPassword) async {
    final client = _sb;
    if (client == null) throw const AuthException('Supabase is not initialised.');
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ─── SIGN IN / OUT ─────────────────────────────────────────────────────────

  /// Sign in with email and password.
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _sb;
    if (client == null) {
      throw const AuthException('Supabase is not initialised. Please check your connection.');
    }
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out.
  static Future<void> signOut() async => (await _sb?.auth.signOut());

  // ─── USER INFO ──────────────────────────────────────────────────────────────

  static User?  get currentUser => _sb?.auth.currentUser;
  static bool   get isLoggedIn  => currentUser != null;

  // ─── ACCOUNT DELETION ──────────────────────────────────────────────────────

  /// Delete all user app data (GDPR) — calls a server-side RPC.
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
