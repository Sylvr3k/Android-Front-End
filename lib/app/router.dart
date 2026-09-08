import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/providers/auth_provider.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/dashboard/presentation/screens/home_screen.dart';
import '../features/evaluations/domain/evaluation_assignment.dart';
import '../features/evaluations/presentation/screens/evaluation_wizard_screen.dart';
import '../features/evaluations/presentation/screens/evaluations_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/change_password_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../shared/widgets/app_shell.dart';
import 'splash_screen.dart';

/// Bridges Riverpod state changes to go_router's `refreshListenable` without
/// ever recreating the GoRouter itself. Recreating the router (which is what
/// happens if `routerProvider`'s build function `ref.watch`es reactive auth
/// state directly) tears down and rebuilds the entire Navigator on every
/// state change — including ones unrelated to login/logout, like updating a
/// profile field — silently resetting whatever screen the user is on back
/// to `/`. This class exists solely to avoid that.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      // Only the signed-in/signed-out transition (or a load finishing)
      // should ever cause a redirect re-evaluation.
      final wasAuthed = previous?.valueOrNull != null;
      final isAuthed = next.valueOrNull != null;
      final wasLoading = previous?.isLoading ?? true;
      final isLoading = next.isLoading;

      if (wasAuthed != isAuthed || wasLoading != isLoading) {
        notifyListeners();
      }
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuthed = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';

      // Nothing that assumes a signed-in user (Home, the bottom nav shell,
      // notifications) may render until we actually know whether a stored
      // session exists — otherwise those screens fire authenticated API
      // calls before there's a token, get 401s, and (for non-autoDispose
      // providers) get stuck in that failed state permanently.
      if (authState.isLoading) {
        return isSplash ? null : '/splash';
      }

      if (!isAuthed) return isLoggingIn ? null : '/login';
      if (isLoggingIn || isSplash) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/evaluations', builder: (context, state) => const EvaluationsScreen()),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/evaluations/wizard',
        builder: (context, state) => EvaluationWizardScreen(pending: state.extra as PendingEvaluation),
      ),
      GoRoute(path: '/profile/change-password', builder: (context, state) => const ChangePasswordScreen()),
      GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfileScreen()),
    ],
  );
});
