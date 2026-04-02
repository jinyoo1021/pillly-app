import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../domain/pillly_user.dart';
import '../../../core/supabase_client.dart';

class AuthRepository {
  AuthRepository();

  SupabaseClient get _client => SupabaseClientService.client;

  // ── Current session ──────────────────────────────────

  PilllyUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return PilllyUser(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String?,
    );
  }

  bool get isAuthenticated => currentUser != null;

  // ── Email auth ───────────────────────────────────────

  Future<PilllyUser> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign up failed: no user returned');
    }

    await _upsertUserProfile(id: user.id, email: email, name: name);
    return PilllyUser(id: user.id, email: email, name: name);
  }

  Future<PilllyUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign in failed: no user returned');
    }

    return _fetchUserProfile(user.id);
  }

  // ── Google Sign-In (native SDK) ──────────────────────

  Future<PilllyUser?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: null, // Uses GoogleService-Info.plist / google-services.json
      scopes: ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('Google Sign-In failed: no ID token');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Supabase sign-in failed');
    }

    await _upsertUserProfile(
      id: user.id,
      email: user.email ?? googleUser.email,
      name: user.userMetadata?['name'] as String? ?? googleUser.displayName ?? '',
    );

    return PilllyUser(
      id: user.id,
      email: user.email ?? googleUser.email,
      name: googleUser.displayName,
    );
  }

  // ── Apple Sign-In (native SDK) ───────────────────────

  Future<PilllyUser?> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple Sign-In failed: no identity token');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: credential.authorizationCode,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Supabase sign-in failed');
    }

    final name = [
      credential.givenName,
      credential.familyName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    await _upsertUserProfile(
      id: user.id,
      email: user.email ?? credential.email ?? '',
      name: name.isNotEmpty ? name : 'Apple User',
    );

    return PilllyUser(
      id: user.id,
      email: user.email ?? credential.email ?? '',
      name: name.isNotEmpty ? name : null,
    );
  }

  // ── Token refresh ────────────────────────────────────

  Future<void> refreshSession() async {
    await _client.auth.refreshSession();
  }

  // ── Sign out ─────────────────────────────────────────

  Future<void> signOut() async {
    await _client.auth.signOut();
    // Also sign out from Google if signed in
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  // ── Auth state stream ────────────────────────────────

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // ── Private helpers ──────────────────────────────────

  Future<void> _upsertUserProfile({
    required String id,
    required String email,
    required String name,
  }) async {
    await _client.from('users').upsert({
      'id': id,
      'email': email,
      'name': name,
      'language': 'en',
      'timezone': 'Asia/Seoul',
    });
  }

  Future<PilllyUser> _fetchUserProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return PilllyUser.fromMap({
      'id': userId,
      'email': _client.auth.currentUser?.email ?? '',
      ...data,
    });
  }
}