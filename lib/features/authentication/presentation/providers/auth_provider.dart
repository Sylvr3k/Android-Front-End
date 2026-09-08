import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/auth_repository.dart';
import '../../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref.watch(secureStorageProvider));
});

/// The single source of truth for "who is signed in right now". `null`
/// means signed out; the router watches this to decide whether to show
/// the login screen or the student application shell.
final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    ref.read(apiClientProvider).onUnauthenticated = _forceLogout;

    try {
      return await ref.read(authRepositoryProvider).currentUser();
    } catch (_) {
      // No valid session (missing/expired token, or storage unavailable) —
      // treat this the same as a fresh install: show the login screen.
      try {
        await ref.read(authRepositoryProvider).clearSession();
      } catch (_) {
        // Best-effort only; still fall through to signed-out.
      }
      return null;
    }
  }

  Future<void> login({required String login, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).login(login: login, password: password));
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// Applies a freshly-updated student profile (phone/photo) to the current
  /// session without a full round-trip back to `/me`.
  void updateStudent(StudentProfile student) {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWithStudent(student));
  }

  void _forceLogout() {
    state = const AsyncData(null);
  }
}
