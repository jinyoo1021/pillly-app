import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../domain/pillly_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final currentUserProvider = Provider<PilllyUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value != null;
});

class AuthNotifier extends AsyncNotifier<PilllyUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<PilllyUser?> build() async {
    ref.listen(authStateProvider, (_, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedOut) {
          state = const AsyncValue.data(null);
        } else if (authState.event == AuthChangeEvent.signedIn) {
          state = AsyncValue.data(_repo.currentUser);
        }
      });
    });
    return _repo.currentUser;
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
          () => _repo.signUpWithEmail(
          email: email, password: password, name: name),
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
          () => _repo.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signInWithGoogle());
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signInWithApple());
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
AsyncNotifierProvider<AuthNotifier, PilllyUser?>(() => AuthNotifier());