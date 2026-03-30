import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/pillly_user.dart';
import '../../../core/supabase_client.dart';

class AuthRepository {
  AuthRepository();

  SupabaseClient get _client => SupabaseClientService.client;

  // Current session

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

  // Email auth

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

    // Create profile row in public.users table
    await _upsertUserProfile(
      id: user.id,
      email: email,
      name: name,
    );

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

    final profile = await _fetchUserProfile(user.id);
    return profile;
  }

  // Social auth

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.pillly.app://login-callback',
    );
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.pillly.app://login-callback',
    );
  }

  // Token refresh

  Future<void> refreshSession() async {
    await _client.auth.refreshSession();
  }

  // Sign out

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Auth state stream

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // Private helpers

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